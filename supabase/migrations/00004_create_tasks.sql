-- Migration: 00004_create_tasks.sql
-- Creates the tasks, categories, and recurrence_rules tables with RLS,
-- full-text search index + RPC, recurring instance generator, and updated_at triggers.

-- ============================================================
-- Categories table
-- ============================================================
create table public.categories (
  id uuid default gen_random_uuid() primary key,
  user_id uuid not null references auth.users on delete cascade,
  name text not null,
  color_index int not null default 0,
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

create index categories_user_id on public.categories using btree (user_id);

alter table public.categories enable row level security;

create policy "Users can view own categories"
  on public.categories for select
  using ((select auth.uid()) = user_id);

create policy "Users can insert own categories"
  on public.categories for insert
  with check ((select auth.uid()) = user_id);

create policy "Users can update own categories"
  on public.categories for update
  using ((select auth.uid()) = user_id)
  with check ((select auth.uid()) = user_id);

create policy "Users can delete own categories"
  on public.categories for delete
  using ((select auth.uid()) = user_id);

-- ============================================================
-- Tasks table
-- ============================================================
create table public.tasks (
  id uuid default gen_random_uuid() primary key,
  user_id uuid not null references auth.users on delete cascade,
  title text not null,
  description text,
  priority int not null default 2,
  category_id uuid references public.categories on delete set null,
  deadline timestamptz,
  is_completed boolean default false,
  completed_at timestamptz,
  recurrence_rule_id uuid,
  parent_task_id uuid references public.tasks on delete cascade,
  created_at timestamptz default now(),
  updated_at timestamptz default now(),
  fts tsvector generated always as (
    to_tsvector('english', coalesce(title, '') || ' ' || coalesce(description, ''))
  ) stored
);

create index tasks_fts on public.tasks using gin (fts);
create index tasks_user_id on public.tasks using btree (user_id);
create index tasks_deadline on public.tasks using btree (deadline);
create index tasks_category on public.tasks using btree (category_id);

alter table public.tasks enable row level security;

create policy "Users can view own tasks"
  on public.tasks for select
  using ((select auth.uid()) = user_id);

create policy "Users can insert own tasks"
  on public.tasks for insert
  with check ((select auth.uid()) = user_id);

create policy "Users can update own tasks"
  on public.tasks for update
  using ((select auth.uid()) = user_id)
  with check ((select auth.uid()) = user_id);

create policy "Users can delete own tasks"
  on public.tasks for delete
  using ((select auth.uid()) = user_id);

-- ============================================================
-- Recurrence rules table
-- ============================================================
create table public.recurrence_rules (
  id uuid default gen_random_uuid() primary key,
  task_id uuid not null references public.tasks on delete cascade,
  type text not null,
  interval_days int,
  days_of_week int[],
  day_of_month int,
  created_at timestamptz default now()
);

alter table public.tasks
  add constraint fk_recurrence_rule
  foreign key (recurrence_rule_id) references public.recurrence_rules on delete set null;

alter table public.recurrence_rules enable row level security;

create policy "Users can view own recurrence rules"
  on public.recurrence_rules for select
  using (exists (select 1 from public.tasks where tasks.id = recurrence_rules.task_id and tasks.user_id = (select auth.uid())));

create policy "Users can insert own recurrence rules"
  on public.recurrence_rules for insert
  with check (exists (select 1 from public.tasks where tasks.id = recurrence_rules.task_id and tasks.user_id = (select auth.uid())));

create policy "Users can update own recurrence rules"
  on public.recurrence_rules for update
  using (exists (select 1 from public.tasks where tasks.id = recurrence_rules.task_id and tasks.user_id = (select auth.uid())))
  with check (exists (select 1 from public.tasks where tasks.id = recurrence_rules.task_id and tasks.user_id = (select auth.uid())));

create policy "Users can delete own recurrence rules"
  on public.recurrence_rules for delete
  using (exists (select 1 from public.tasks where tasks.id = recurrence_rules.task_id and tasks.user_id = (select auth.uid())));

-- ============================================================
-- Full-text search RPC function with prefix matching
-- ============================================================
create or replace function search_tasks(p_user_id uuid, p_query text)
returns setof public.tasks as $$
begin
  return query
  select * from public.tasks
  where user_id = p_user_id
    and fts @@ to_tsquery('english', replace(trim(p_query), ' ', ' & ') || ':*')
  order by ts_rank(fts, to_tsquery('english', replace(trim(p_query), ' ', ' & ') || ':*')) desc;
end;
$$ language plpgsql security definer;

-- ============================================================
-- Recurring instance generation function
-- ============================================================
create or replace function generate_recurring_instances(p_task_id uuid)
returns void as $$
declare
  v_rule recurrence_rules%rowtype;
  v_task tasks%rowtype;
  v_next_date date;
  v_end_date date := current_date + interval '14 days';
  v_last_instance date;
begin
  select * into v_task from tasks where id = p_task_id;
  select * into v_rule from recurrence_rules where task_id = p_task_id;
  if v_rule is null then return; end if;

  -- Skip generation if the anchor task has no deadline (cannot compute next dates).
  if v_task.deadline is null then return; end if;

  select max(deadline::date) into v_last_instance
  from tasks where parent_task_id = p_task_id;

  v_next_date := coalesce(v_last_instance + 1, v_task.deadline::date);

  while v_next_date <= v_end_date loop
    if v_rule.type = 'daily' then
      null;
    elsif v_rule.type = 'weekly' then
      if not (extract(isodow from v_next_date)::int = any(v_rule.days_of_week)) then
        v_next_date := v_next_date + 1;
        continue;
      end if;
    elsif v_rule.type = 'monthly' then
      if extract(day from v_next_date)::int != v_rule.day_of_month then
        v_next_date := v_next_date + 1;
        continue;
      end if;
    elsif v_rule.type = 'custom' then
      if (v_next_date - v_task.deadline::date) % v_rule.interval_days != 0 then
        v_next_date := v_next_date + 1;
        continue;
      end if;
    end if;

    insert into tasks (user_id, title, description, priority, category_id, deadline, parent_task_id, recurrence_rule_id)
    select v_task.user_id, v_task.title, v_task.description, v_task.priority,
           v_task.category_id, v_next_date::timestamptz, p_task_id, v_rule.id
    where not exists (
      select 1 from tasks where parent_task_id = p_task_id and deadline::date = v_next_date
    );

    v_next_date := v_next_date + 1;
  end loop;
end;
$$ language plpgsql security definer;

-- ============================================================
-- Updated_at trigger (reusable for all tables)
-- ============================================================
create or replace function public.update_updated_at()
returns trigger as $$
begin
  new.updated_at = now();
  return new;
end;
$$ language plpgsql;

create trigger set_updated_at before update on public.categories
  for each row execute function public.update_updated_at();
create trigger set_updated_at before update on public.tasks
  for each row execute function public.update_updated_at();
