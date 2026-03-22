-- Migration: 00007_create_notification_tables.sql
-- Creates notification_preferences, scheduled_reminders, and completion_patterns
-- tables with RLS policies. Adds FCM token columns to profiles. Creates a trigger
-- to auto-insert default notification preferences on user signup.

-- ============================================================================
-- 1. Add FCM token columns to profiles
-- ============================================================================

alter table public.profiles
  add column if not exists fcm_token text,
  add column if not exists fcm_token_updated_at timestamptz;

-- ============================================================================
-- 2. Notification preferences table
-- ============================================================================

create table public.notification_preferences (
  id uuid not null default gen_random_uuid() primary key,
  user_id uuid not null references auth.users(id) on delete cascade unique,
  enabled boolean default true,
  task_reminders_enabled boolean default true,
  task_default_offsets jsonb default '[1440, 60]'::jsonb,
  habit_reminders_enabled boolean default true,
  habit_daily_summary_time time default '08:00',
  planner_summary_enabled boolean default true,
  planner_block_reminders_enabled boolean default true,
  planner_block_offset integer default 15,
  quiet_hours_enabled boolean default false,
  quiet_start time default '22:00',
  quiet_end time default '07:00',
  snooze_duration integer default 15,
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

alter table public.notification_preferences enable row level security;

create policy "Users can manage own notification preferences"
  on public.notification_preferences for all
  using ((select auth.uid()) = user_id)
  with check ((select auth.uid()) = user_id);

-- ============================================================================
-- 3. Scheduled reminders table
-- ============================================================================

create table public.scheduled_reminders (
  id uuid not null default gen_random_uuid() primary key,
  user_id uuid not null references auth.users(id) on delete cascade,
  reminder_type text not null check (reminder_type in ('task_deadline', 'habit_reminder', 'planner_summary', 'planner_block')),
  item_id uuid not null,
  remind_at timestamptz not null,
  title text not null,
  body text not null,
  insight text,
  deep_link_route text,
  sent boolean default false,
  sent_at timestamptz,
  snoozed_from uuid references public.scheduled_reminders(id),
  created_at timestamptz default now()
);

-- Index for efficient querying of unsent reminders due for sending.
create index idx_pending_reminders
  on public.scheduled_reminders (remind_at)
  where sent = false;

alter table public.scheduled_reminders enable row level security;

create policy "Users can view own reminders"
  on public.scheduled_reminders for select
  using ((select auth.uid()) = user_id);

create policy "Users can insert own reminders"
  on public.scheduled_reminders for insert
  with check ((select auth.uid()) = user_id);

-- ============================================================================
-- 4. Completion patterns table (adaptive timing data)
-- ============================================================================

create table public.completion_patterns (
  id uuid not null default gen_random_uuid() primary key,
  user_id uuid not null references auth.users(id) on delete cascade,
  item_type text not null check (item_type in ('task', 'habit')),
  item_id uuid not null,
  deadline_at timestamptz,
  completed_at timestamptz not null,
  reminder_sent_at timestamptz,
  response_delay_minutes integer,
  created_at timestamptz default now()
);

-- Index for querying recent patterns per user (adaptive timing analysis).
create index idx_completion_patterns_user_recent
  on public.completion_patterns (user_id, created_at desc);

alter table public.completion_patterns enable row level security;

create policy "Users can manage own completion patterns"
  on public.completion_patterns for all
  using ((select auth.uid()) = user_id)
  with check ((select auth.uid()) = user_id);

-- ============================================================================
-- 5. Auto-create default notification preferences on user signup
-- ============================================================================

create or replace function public.handle_new_user_notifications()
returns trigger
language plpgsql
security definer set search_path = ''
as $$
begin
  insert into public.notification_preferences (user_id)
  values (new.id);
  return new;
end;
$$;

create trigger on_auth_user_created_notifications
  after insert on auth.users
  for each row execute procedure public.handle_new_user_notifications();
