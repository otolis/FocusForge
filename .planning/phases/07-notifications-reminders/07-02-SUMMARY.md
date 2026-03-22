---
phase: 07-notifications-reminders
plan: 02
subsystem: notifications
tags: [fcm, edge-function, deno, pg_cron, adaptive-timing, quiet-hours, push-notifications]

# Dependency graph
requires:
  - phase: 07-notifications-reminders (plan 01)
    provides: notification_preferences, scheduled_reminders, completion_patterns tables and profiles.fcm_token column
provides:
  - pending_reminders database view for notification delivery queries
  - send-reminders Edge Function with FCM delivery pipeline
  - pg_cron schedule triggering Edge Function every minute
  - Adaptive timing algorithm for procrastination and fast-responder detection
  - Quiet hours filtering with midnight wrap-around
affects: [07-notifications-reminders, 08-integration]

# Tech tracking
tech-stack:
  added: [google-auth-library@9 (npm, Edge Function), pg_cron, pg_net]
  patterns: [cron-triggered Edge Function, data-only FCM messages, Vault secrets for cron auth, dual-signal adaptive algorithm]

key-files:
  created:
    - supabase/functions/send-reminders/index.ts
    - supabase/migrations/00007b_create_pending_reminders_view.sql
    - supabase/migrations/00007c_setup_cron_schedule.sql
    - test/unit/features/notifications/adaptive_timing_test.dart
    - test/unit/features/notifications/quiet_hours_test.dart
  modified: []

key-decisions:
  - "Data-only FCM messages (no notification field) to give Flutter full control over display with action buttons"
  - "Vault secrets for pg_cron HTTP auth -- project URL and anon key stored securely in Supabase Vault"
  - "Adaptive insight generated server-side only for task_deadline reminders (not habits/planner)"
  - "Stale FCM token cleanup on UNREGISTERED/NOT_FOUND errors from FCM API"

patterns-established:
  - "Cron-triggered Edge Function: pg_cron -> pg_net HTTP POST -> Edge Function for scheduled background work"
  - "Database view as query layer: pending_reminders view encapsulates multi-table join for Edge Function consumption"
  - "Dual-signal adaptive algorithm: deadline proximity + response delay with 3-completion minimum threshold"

requirements-completed: [PLAN-04]

# Metrics
duration: 4min
completed: 2026-03-22
---

# Phase 7 Plan 2: Server-Side Notification Delivery Summary

**Cron-triggered Edge Function delivering FCM data-only push notifications with adaptive timing insights and quiet hours filtering**

## Performance

- **Duration:** 4 min
- **Started:** 2026-03-22T12:59:30Z
- **Completed:** 2026-03-22T13:03:10Z
- **Tasks:** 2
- **Files created:** 5

## Accomplishments
- Created pending_reminders database view joining scheduled_reminders, profiles, and notification_preferences for single-query notification delivery
- Built send-reminders Edge Function with full FCM delivery pipeline: category filtering, quiet hours, adaptive insights, stale token cleanup
- Set up pg_cron schedule triggering the Edge Function every minute via pg_net HTTP POST with Vault-secured credentials
- Implemented dual-signal adaptive timing algorithm detecting procrastination and fast-responder patterns from 2-week completion data
- Created comprehensive Dart unit tests for adaptive timing (8 tests) and quiet hours (15 tests) algorithms

## Task Commits

Each task was committed atomically:

1. **Task 1: Pending reminders view and cron schedule migrations** - `f86ac18` (feat)
2. **Task 2: send-reminders Edge Function with adaptive timing and quiet hours** - `872700c` (feat)

## Files Created/Modified
- `supabase/migrations/00007b_create_pending_reminders_view.sql` - Database view joining scheduled_reminders with notification_preferences and profiles
- `supabase/migrations/00007c_setup_cron_schedule.sql` - pg_cron job triggering Edge Function every minute via pg_net
- `supabase/functions/send-reminders/index.ts` - Edge Function: query pending reminders, filter, apply adaptive insights, send FCM
- `test/unit/features/notifications/adaptive_timing_test.dart` - 8 tests for AdaptiveTimingCalculator Dart port
- `test/unit/features/notifications/quiet_hours_test.dart` - 15 tests for QuietHoursChecker Dart port

## Decisions Made
- Data-only FCM messages (no `notification` field) ensure Flutter app has full control over notification display via flutter_local_notifications, enabling action buttons in all app states
- Vault secrets used for pg_cron HTTP auth rather than hardcoded credentials -- requires manual one-time setup via Supabase Dashboard
- Adaptive insight generation limited to task_deadline reminder type only (habits and planner blocks don't need procrastination detection)
- Stale FCM tokens automatically cleaned when FCM returns UNREGISTERED or NOT_FOUND, preventing repeated delivery failures

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered
None

## User Setup Required
**Vault secrets must be configured manually** before the cron schedule works:
- Run two SQL commands via Supabase Dashboard SQL Editor to set `project_url` and `anon_key` secrets in Vault
- Place Firebase service account JSON at `supabase/functions/service-account.json` for FCM auth

## Next Phase Readiness
- Server-side notification delivery pipeline complete
- Plan 03 (Flutter-side FCM handling, notification display, action buttons) can proceed
- Requires Plan 01 tables to be deployed first for the view and Edge Function to work

## Self-Check: PASSED

All 5 created files verified on disk. Both task commits (f86ac18, 872700c) confirmed in git log.

---
*Phase: 07-notifications-reminders*
*Completed: 2026-03-22*
