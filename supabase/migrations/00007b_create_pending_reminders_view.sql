-- Migration: 00007b_create_pending_reminders_view.sql
-- Creates a view joining scheduled_reminders with notification_preferences
-- and profiles to provide the send-reminders Edge Function with all data
-- needed for notification delivery in a single query.

create or replace view public.pending_reminders as
select
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
  np.enabled as notifications_enabled,
  np.task_reminders_enabled,
  np.habit_reminders_enabled,
  np.planner_summary_enabled,
  np.planner_block_reminders_enabled,
  np.quiet_hours_enabled,
  np.quiet_start,
  np.quiet_end,
  np.snooze_duration
from public.scheduled_reminders sr
join public.profiles p on p.id = sr.user_id
join public.notification_preferences np on np.user_id = sr.user_id
where sr.sent = false
  and p.fcm_token is not null
  and np.enabled = true;

-- Ensure the view is accessible and documented
comment on view public.pending_reminders is
  'Pending notification reminders joined with user preferences and FCM tokens. Used by send-reminders Edge Function.';
