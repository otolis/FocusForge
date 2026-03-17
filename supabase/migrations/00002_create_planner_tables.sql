-- Migration: 00002_create_planner_tables.sql
-- Creates the plannable_items and generated_schedules tables for the AI Daily Planner.

-- Table: plannable_items
-- Stores individual items the user wants scheduled into their day.
create table public.plannable_items (
  id uuid default gen_random_uuid() primary key,
  user_id uuid not null references auth.users on delete cascade,
  title text not null,
  duration_minutes integer not null check (duration_minutes in (15, 30, 45, 60, 90, 120)),
  energy_level text not null check (energy_level in ('high', 'medium', 'low')),
  plan_date date not null default current_date,
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

alter table public.plannable_items enable row level security;

create policy "Users can view own plannable items"
  on public.plannable_items for select
  using ((select auth.uid()) = user_id);

create policy "Users can insert own plannable items"
  on public.plannable_items for insert
  with check ((select auth.uid()) = user_id);

create policy "Users can update own plannable items"
  on public.plannable_items for update
  using ((select auth.uid()) = user_id)
  with check ((select auth.uid()) = user_id);

create policy "Users can delete own plannable items"
  on public.plannable_items for delete
  using ((select auth.uid()) = user_id);

create index idx_plannable_items_user_date
  on public.plannable_items (user_id, plan_date);

-- Table: generated_schedules
-- Stores the AI-generated schedule blocks for a given user and date.
create table public.generated_schedules (
  id uuid default gen_random_uuid() primary key,
  user_id uuid not null references auth.users on delete cascade,
  plan_date date not null,
  schedule_blocks jsonb not null default '[]'::jsonb,
  constraints_text text,
  created_at timestamptz default now(),
  unique(user_id, plan_date)
);

alter table public.generated_schedules enable row level security;

create policy "Users can view own generated schedules"
  on public.generated_schedules for select
  using ((select auth.uid()) = user_id);

create policy "Users can insert own generated schedules"
  on public.generated_schedules for insert
  with check ((select auth.uid()) = user_id);

create policy "Users can update own generated schedules"
  on public.generated_schedules for update
  using ((select auth.uid()) = user_id)
  with check ((select auth.uid()) = user_id);

create policy "Users can delete own generated schedules"
  on public.generated_schedules for delete
  using ((select auth.uid()) = user_id);

create index idx_generated_schedules_user_date
  on public.generated_schedules (user_id, plan_date);
