---
phase: 07-notifications-reminders
plan: 01
subsystem: notifications
tags: [fcm, firebase, flutter_local_notifications, supabase, riverpod, push-notifications]

# Dependency graph
requires:
  - phase: 01-foundation
    provides: Supabase profiles table, auth triggers, AuthRepository DI pattern
provides:
  - Database schema for notification_preferences, scheduled_reminders, completion_patterns tables
  - FCM token columns on profiles table
  - NotificationPreferences and CompletionPattern domain models
  - NotificationRepository with 6 CRUD methods
  - NotificationService singleton with FCM init, 3 channels, local notification display, token lifecycle
  - Riverpod providers for notification repository and preferences
  - Firebase packages (firebase_core, firebase_messaging, flutter_local_notifications)
affects: [07-02 edge-function, 07-03 settings-ui, 08-integration]

# Tech tracking
tech-stack:
  added: [firebase_core ^4.5.0, firebase_messaging ^16.1.2, flutter_local_notifications ^21.0.0]
  patterns: [FCM data-only messages with local notification display, top-level background handlers with @pragma, notification channel per feature area, adaptive timing via completion patterns]

key-files:
  created:
    - supabase/migrations/00007_create_notification_tables.sql
    - lib/features/notifications/domain/notification_preferences.dart
    - lib/features/notifications/domain/completion_pattern.dart
    - lib/features/notifications/data/notification_repository.dart
    - lib/features/notifications/presentation/providers/notification_providers.dart
    - lib/core/services/notification_service.dart
    - test/unit/features/notifications/notification_repository_test.dart
    - test/unit/features/notifications/notification_service_test.dart
  modified:
    - pubspec.yaml
    - lib/main.dart

key-decisions:
  - "Global notificationNavigatorKey for deep-link navigation (separate from router's private _rootNavigatorKey)"
  - "Three notification channels: task_reminders (high), habit_reminders (default), planner_notifications (default)"
  - "FCM data-only messages displayed as local notifications for full control over content and actions"
  - "Complete and Snooze action buttons on all notification types"
  - "Background action handler stubs (debugPrint) until Supabase background isolate init is wired"

patterns-established:
  - "FCM background handler: top-level function with @pragma('vm:entry-point') and Firebase.initializeApp()"
  - "Notification channel per feature area with appropriate importance levels"
  - "subText field for adaptive timing insight transparency"
  - "Notification deep-link via payload route field + GoRouter.push"

requirements-completed: [UX-03]

# Metrics
duration: 5min
completed: 2026-03-22
---

# Phase 7 Plan 1: Notification Data Foundation Summary

**FCM notification service with 3 channels, Complete/Snooze actions, token lifecycle, and Supabase schema for preferences/reminders/completion patterns**

## Performance

- **Duration:** 5 min
- **Started:** 2026-03-22T12:59:25Z
- **Completed:** 2026-03-22T13:04:25Z
- **Tasks:** 2
- **Files modified:** 10

## Accomplishments
- Database migration with notification_preferences, scheduled_reminders, and completion_patterns tables, all with RLS policies and appropriate indexes
- NotificationService singleton handling FCM initialization, 3 Android notification channels, local notification display with Complete/Snooze action buttons, FCM token lifecycle, and deep-link navigation from all app states
- Domain models (NotificationPreferences, CompletionPattern) following project patterns with fromJson/toJson/copyWith
- NotificationRepository with 6 CRUD methods for preferences, tokens, and completion patterns
- Riverpod providers for notification repository and preferences

## Task Commits

Each task was committed atomically:

1. **Task 1: Database migration, domain models, and repository** - `3f0282d` (feat)
2. **Task 2: NotificationService with FCM init, token lifecycle, and local notification display** - `f57127e` (feat)

## Files Created/Modified
- `supabase/migrations/00007_create_notification_tables.sql` - 3 tables + RLS + FCM columns + auto-create trigger
- `lib/features/notifications/domain/notification_preferences.dart` - NotificationPreferences model with defaults factory
- `lib/features/notifications/domain/completion_pattern.dart` - CompletionPattern model for adaptive timing
- `lib/features/notifications/data/notification_repository.dart` - Supabase CRUD for preferences, tokens, patterns
- `lib/features/notifications/presentation/providers/notification_providers.dart` - Riverpod providers
- `lib/core/services/notification_service.dart` - FCM singleton with channels, actions, token lifecycle
- `lib/main.dart` - Firebase.initializeApp() + NotificationService().initialize()
- `pubspec.yaml` - firebase_core, firebase_messaging, flutter_local_notifications added
- `test/unit/features/notifications/notification_repository_test.dart` - Repository and model tests
- `test/unit/features/notifications/notification_service_test.dart` - Service singleton and payload tests

## Decisions Made
- Created separate `notificationNavigatorKey` global key rather than making router's `_rootNavigatorKey` public, to keep navigation concerns separated
- Used three notification channels mapped by feature area (tasks=high importance, habits/planner=default)
- FCM data-only messages displayed as local notifications for full control over content, actions, and appearance
- Background action handler stubs use debugPrint until Supabase background isolate initialization is wired (will be completed in integration phase)
- subText field carries adaptive timing insight for user transparency

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered
None

## User Setup Required
None - no external service configuration required. Firebase project configuration (google-services.json) will be needed when wiring to a real Firebase project.

## Next Phase Readiness
- Database schema ready for Plan 02 (Edge Function for smart-notify)
- NotificationService ready for Plan 03 (settings UI to toggle preferences)
- NotificationRepository provides the data layer Plan 02 and 03 consume

## Self-Check: PASSED

- All 9 created files verified on disk
- Both task commits (3f0282d, f57127e) verified in git log

---
*Phase: 07-notifications-reminders*
*Completed: 2026-03-22*
