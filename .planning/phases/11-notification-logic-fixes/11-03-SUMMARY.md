---
phase: 11-notification-logic-fixes
plan: 03
subsystem: notifications
tags: [timezone, quiet-hours, edge-function, supabase, postgresql, dart]

# Dependency graph
requires:
  - phase: 07-notifications
    provides: notification_preferences table, pending_reminders view, send-reminders Edge Function
provides:
  - timezone column on notification_preferences table
  - timezone-aware pending_reminders view
  - timezone-aware isInQuietHours function in send-reminders Edge Function
  - timezone field in NotificationPreferences Dart model
affects: [settings-ui, notification-preferences-screen]

# Tech tracking
tech-stack:
  added: []
  patterns: [toLocaleString-timezone-conversion, IANA-timezone-identifiers]

key-files:
  created:
    - supabase/migrations/00011_add_timezone_to_notification_prefs.sql
  modified:
    - lib/features/notifications/domain/notification_preferences.dart
    - supabase/functions/send-reminders/index.ts

key-decisions:
  - "toLocaleString with timeZone option for UTC-to-local conversion in Deno Edge Function (no external library needed)"
  - "NULL timezone defaults to UTC -- safe fallback for existing users without timezone set"
  - "Invalid timezone strings caught with try/catch, falling back to getUTCHours"

patterns-established:
  - "Timezone handling: IANA identifiers stored as nullable text, NULL = UTC fallback"
  - "copyWith clearTimezone pattern: bool flag to explicitly set nullable field to null"

requirements-completed: [NOTIF-07]

# Metrics
duration: 2min
completed: 2026-03-28
---

# Phase 11 Plan 03: Timezone-Aware Quiet Hours Summary

**Timezone column on notification_preferences with IANA identifier, updated pending_reminders view, and toLocaleString-based UTC-to-local conversion in send-reminders Edge Function**

## Performance

- **Duration:** 2 min
- **Started:** 2026-03-28T14:08:31Z
- **Completed:** 2026-03-28T14:10:35Z
- **Tasks:** 2
- **Files modified:** 3

## Accomplishments
- SQL migration adds timezone text column to notification_preferences with NULL default and IANA format comment
- Pending_reminders view recreated to expose np.timezone for Edge Function consumption
- NotificationPreferences Dart model gains timezone field with full fromJson/toJson/copyWith support including clearTimezone pattern
- isInQuietHours function in send-reminders Edge Function now converts UTC to user's local time via toLocaleString before quiet hours comparison
- Invalid timezone strings gracefully fall back to UTC via try/catch

## Task Commits

Each task was committed atomically:

1. **Task 1: SQL migration for timezone column and updated pending_reminders view** - `f679c34` (feat)
2. **Task 2: Update send-reminders Edge Function for timezone-aware quiet hours** - `9cfd09a` (feat)

## Files Created/Modified
- `supabase/migrations/00011_add_timezone_to_notification_prefs.sql` - Adds timezone column and recreates pending_reminders view
- `lib/features/notifications/domain/notification_preferences.dart` - Adds timezone field to Dart model (field, constructor, fromJson, toJson, copyWith)
- `supabase/functions/send-reminders/index.ts` - Timezone-aware isInQuietHours with UTC fallback

## Decisions Made
- Used toLocaleString with timeZone option for timezone conversion -- no external library needed, works natively in Deno runtime
- NULL timezone defaults to UTC -- safe for existing users who haven't set a timezone yet
- Invalid IANA strings caught with try/catch, falling back to getUTCHours/getUTCMinutes
- copyWith uses clearTimezone bool pattern to allow explicitly setting timezone back to null

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered
None

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- Timezone infrastructure complete; settings UI can now expose a timezone picker that writes to notification_preferences.timezone
- Edge Function will automatically use any timezone value written by the client
- Existing users unaffected (NULL timezone = UTC behavior, same as before)

## Self-Check: PASSED

All files exist, all commits verified.

---
*Phase: 11-notification-logic-fixes*
*Completed: 2026-03-28*
