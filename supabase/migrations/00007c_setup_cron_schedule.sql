-- Migration: 00007c_setup_cron_schedule.sql
-- Enables pg_cron and pg_net extensions, then schedules the send-reminders
-- Edge Function to run every 1 minute via HTTP POST.
--
-- IMPORTANT: Before this migration runs, you must manually set up two
-- Vault secrets via the Supabase Dashboard SQL Editor:
--
--   select vault.create_secret('https://YOUR_PROJECT_REF.supabase.co', 'project_url');
--   select vault.create_secret('YOUR_SUPABASE_ANON_KEY', 'anon_key');
--
-- Replace YOUR_PROJECT_REF with your actual Supabase project reference
-- and YOUR_SUPABASE_ANON_KEY with the anon/public key from your project settings.

-- Enable pg_cron and pg_net if not already enabled
-- (Supabase enables these by default, but be explicit)
create extension if not exists pg_cron;
create extension if not exists pg_net;

-- Schedule the send-reminders Edge Function to run every 1 minute
-- This checks for pending reminders and sends FCM push notifications
select cron.schedule(
  'send-reminders-cron',
  '* * * * *',
  $$
  select net.http_post(
    url := (select decrypted_secret from vault.decrypted_secrets where name = 'project_url') || '/functions/v1/send-reminders',
    headers := jsonb_build_object(
      'Content-Type', 'application/json',
      'Authorization', 'Bearer ' || (select decrypted_secret from vault.decrypted_secrets where name = 'anon_key')
    ),
    body := jsonb_build_object('time', now()::text)
  );
  $$
);
