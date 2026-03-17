-- Migration: 00002_create_habits.sql
-- Creates the habits and habit_logs tables with RLS policies and indexes.

-- habits table: stores habit definitions
create table public.habits (
  id uuid default gen_random_uuid() primary key,
  user_id uuid not null references auth.users on delete cascade,
  name text not null,
  description text,
  frequency text not null default 'daily' check (frequency in ('daily', 'weekly', 'custom')),
  target_count integer not null default 1 check (target_count >= 1),
  custom_days integer[] default null,
  icon text,
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

alter table public.habits enable row level security;

create policy "Users can view own habits"
  on public.habits for select
  using ((select auth.uid()) = user_id);

create policy "Users can insert own habits"
  on public.habits for insert
  with check ((select auth.uid()) = user_id);

create policy "Users can update own habits"
  on public.habits for update
  using ((select auth.uid()) = user_id)
  with check ((select auth.uid()) = user_id);

create policy "Users can delete own habits"
  on public.habits for delete
  using ((select auth.uid()) = user_id);

-- habit_logs table: stores completion entries
create table public.habit_logs (
  id uuid default gen_random_uuid() primary key,
  habit_id uuid not null references public.habits on delete cascade,
  completed_date date not null default current_date,
  count integer not null default 1 check (count >= 1),
  created_at timestamptz default now(),
  unique (habit_id, completed_date)
);

alter table public.habit_logs enable row level security;

-- Users can view logs for their own habits
create policy "Users can view own habit logs"
  on public.habit_logs for select
  using (
    exists (
      select 1 from public.habits
      where habits.id = habit_logs.habit_id
      and habits.user_id = (select auth.uid())
    )
  );

-- Users can insert logs for their own habits
create policy "Users can insert own habit logs"
  on public.habit_logs for insert
  with check (
    exists (
      select 1 from public.habits
      where habits.id = habit_logs.habit_id
      and habits.user_id = (select auth.uid())
    )
  );

-- Users can update logs for their own habits
create policy "Users can update own habit logs"
  on public.habit_logs for update
  using (
    exists (
      select 1 from public.habits
      where habits.id = habit_logs.habit_id
      and habits.user_id = (select auth.uid())
    )
  );

-- Users can delete logs for their own habits
create policy "Users can delete own habit logs"
  on public.habit_logs for delete
  using (
    exists (
      select 1 from public.habits
      where habits.id = habit_logs.habit_id
      and habits.user_id = (select auth.uid())
    )
  );

-- Indexes for common queries
create index idx_habits_user_id on public.habits(user_id);
create index idx_habit_logs_habit_id on public.habit_logs(habit_id);
create index idx_habit_logs_completed_date on public.habit_logs(completed_date);
create index idx_habit_logs_habit_date on public.habit_logs(habit_id, completed_date);
