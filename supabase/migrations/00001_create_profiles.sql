-- Migration: 00001_create_profiles.sql
-- Creates the profiles table linked to auth.users with RLS policies,
-- an auto-creation trigger on signup, and an avatars storage bucket.

create table public.profiles (
  id uuid not null references auth.users on delete cascade,
  display_name text,
  avatar_url text,
  energy_pattern jsonb default '{"peak_hours": [9,10,11], "low_hours": [14,15]}'::jsonb,
  onboarding_completed boolean default false,
  created_at timestamptz default now(),
  updated_at timestamptz default now(),
  primary key (id)
);

alter table public.profiles enable row level security;

-- Users can read their own profile
create policy "Users can view own profile"
  on public.profiles for select
  using ((select auth.uid()) = id);

-- Users can update their own profile
create policy "Users can update own profile"
  on public.profiles for update
  using ((select auth.uid()) = id)
  with check ((select auth.uid()) = id);

-- Users can insert their own profile (fallback if trigger fails)
create policy "Users can insert own profile"
  on public.profiles for insert
  with check ((select auth.uid()) = id);

-- Auto-create profile on signup
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer set search_path = ''
as $$
begin
  insert into public.profiles (id, display_name, avatar_url)
  values (
    new.id,
    coalesce(new.raw_user_meta_data ->> 'full_name', new.raw_user_meta_data ->> 'name', ''),
    coalesce(new.raw_user_meta_data ->> 'avatar_url', '')
  );
  return new;
end;
$$;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure public.handle_new_user();

-- Storage bucket for avatars
insert into storage.buckets (id, name, public)
values ('avatars', 'avatars', true);

-- Storage policy: users can upload their own avatar
create policy "Users can upload own avatar"
  on storage.objects for insert
  with check (bucket_id = 'avatars' and (select auth.uid())::text = (storage.foldername(name))[1]);

-- Storage policy: anyone can view avatars (public bucket)
create policy "Avatars are publicly accessible"
  on storage.objects for select
  using (bucket_id = 'avatars');

-- Storage policy: users can update their own avatar
create policy "Users can update own avatar"
  on storage.objects for update
  using (bucket_id = 'avatars' and (select auth.uid())::text = (storage.foldername(name))[1]);
