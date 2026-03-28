-- Migration: 00011_add_timezone_to_notification_prefs.sql
-- Adds timezone column to notification_preferences for timezone-aware quiet hours.
-- Updates the pending_reminders view to expose the timezone to the Edge Function.

-- ============================================================================
-- 1. Add timezone column (IANA format, e.g., 'Europe/Athens', 'America/New_York')
-- ============================================================================

ALTER TABLE public.notification_preferences
  ADD COLUMN IF NOT EXISTS timezone text DEFAULT NULL;

COMMENT ON COLUMN public.notification_preferences.timezone IS
  'IANA timezone identifier (e.g., Europe/Athens). NULL falls back to UTC in quiet hours evaluation.';

-- ============================================================================
-- 2. Recreate pending_reminders view to include timezone
-- ============================================================================

CREATE OR REPLACE VIEW public.pending_reminders AS
SELECT
  sr.id,
  sr.user_id,
  sr.reminder_type,
  sr.item_id,
  sr.remind_at,
  sr.title,
  sr.body,
  sr.insight,
  sr.deep_link_route,
  p.fcm_token,
  np.enabled AS notifications_enabled,
  np.task_reminders_enabled,
  np.habit_reminders_enabled,
  np.planner_summary_enabled,
  np.planner_block_reminders_enabled,
  np.quiet_hours_enabled,
  np.quiet_start,
  np.quiet_end,
  np.snooze_duration,
  np.timezone
FROM public.scheduled_reminders sr
JOIN public.profiles p ON p.id = sr.user_id
JOIN public.notification_preferences np ON np.user_id = sr.user_id
WHERE sr.sent = false
  AND p.fcm_token IS NOT NULL
  AND np.enabled = true;

COMMENT ON VIEW public.pending_reminders IS
  'Pending notification reminders joined with user preferences and FCM tokens. Used by send-reminders Edge Function.';
