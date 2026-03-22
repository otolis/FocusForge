---
phase: 07-notifications-reminders
verified: 2026-03-22T13:30:00Z
status: passed
score: 17/17 must-haves verified
re_verification: false
human_verification:
  - test: "Trigger a deadline notification and verify Complete and Snooze action buttons appear on the Android notification"
    expected: "Two action buttons labeled 'Complete' and 'Snooze' appear below the notification body; tapping Complete dismisses the notification"
    why_human: "Requires a real Android device with FCM wired to a Firebase project and a deployed Edge Function"
  - test: "Navigate to Settings > Notifications, toggle a category off, navigate away, and return"
    expected: "The preference persists and the category card is shown as disabled on return"
    why_human: "Persistence round-trip through Supabase requires a live backend"
  - test: "Enable quiet hours from 22:00 to 07:00 and confirm no notifications arrive during that window"
    expected: "Zero notifications delivered during the quiet window; notifications resume immediately after 07:00"
    why_human: "Time-based filtering requires wall-clock verification against a running Edge Function"
  - test: "Background action handler: tap Snooze on a notification while the app is terminated"
    expected: "A new scheduled_reminder is inserted with remind_at = now + snooze_duration"
    why_human: "Background action handler currently stubs with debugPrint — the Supabase background-isolate wiring is deferred to Phase 8 integration (documented decision)"
---

# Phase 7: Notifications & Reminders Verification Report

**Phase Goal:** Users receive timely push notifications for deadlines with adaptive reminder timing
**Verified:** 2026-03-22T13:30:00Z
**Status:** passed
**Re-verification:** No — initial verification

---

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | Notification preferences table exists in Supabase with RLS policies | VERIFIED | `00007_create_notification_tables.sql` lines 18-42: table created, RLS enabled, policy covering all operations |
| 2 | Scheduled reminders table exists with index on unsent reminders | VERIFIED | `00007_create_notification_tables.sql` lines 48-77: table + `idx_pending_reminders` partial index `where sent = false` |
| 3 | Completion patterns table exists for adaptive timing data | VERIFIED | `00007_create_notification_tables.sql` lines 83-104: table + `idx_completion_patterns_user_recent` index |
| 4 | FCM token columns exist on profiles table | VERIFIED | `00007_create_notification_tables.sql` lines 10-12: `fcm_token` and `fcm_token_updated_at` columns added |
| 5 | NotificationPreferences model serializes to/from JSON correctly | VERIFIED | `notification_preferences.dart`: `fromJson`, `toJson`, `copyWith`, `defaults` factory all present and substantive; `notification_repository_test.dart` has 6 round-trip tests |
| 6 | NotificationRepository can CRUD preferences via Supabase client | VERIFIED | `notification_repository.dart`: 6 methods — `getPreferences`, `updatePreferences`, `storeFcmToken`, `clearFcmToken`, `recordCompletion`, `getRecentCompletions` — all wired to Supabase |
| 7 | NotificationService initializes FCM, manages token lifecycle, and displays local notifications with action buttons | VERIFIED | `notification_service.dart`: singleton, `initialize()` method, 3 Android channels, `_showLocalNotification` with Complete/Snooze `AndroidNotificationAction`, `manageFcmToken`, `clearToken`, both `@pragma('vm:entry-point')` background handlers |
| 8 | Riverpod providers expose notification preferences and repository | VERIFIED | `notification_providers.dart`: `notificationRepositoryProvider` and `notificationPreferencesProvider` both wired |
| 9 | Edge Function queries pending reminders and sends FCM data-only messages | VERIFIED | `send-reminders/index.ts`: queries `pending_reminders` view, sends to `fcm.googleapis.com/v1/projects/...`, no `notification` field (data-only confirmed), `android: { priority: 'high' }` |
| 10 | Quiet hours filtering prevents notifications during user's configured quiet window | VERIFIED | `send-reminders/index.ts` lines 35-54: `isInQuietHours` handles midnight wrap-around; `quiet_hours_test.dart` covers 15 test cases including wrapping edge cases |
| 11 | Adaptive timing algorithm adjusts reminder offsets based on 2-week completion patterns | VERIFIED | `send-reminders/index.ts` lines 67-125: dual-signal algorithm (deadline proximity + response delay), 3-completion minimum threshold; `adaptive_timing_test.dart` covers procrastination and fast-responder detection |
| 12 | Transparent insight messages are generated when timing shifts | VERIFIED | `send-reminders/index.ts` lines 116-121: insight strings generated for both signals; `subText: data['insight']` used in `notification_service.dart` line 251 |
| 13 | pg_cron schedule triggers the Edge Function every minute | VERIFIED | `00007c_setup_cron_schedule.sql`: `cron.schedule('send-reminders-cron', '* * * * *', ...)` with `net.http_post` to `/functions/v1/send-reminders` |
| 14 | Pending reminders view joins tasks/habits/planner with preferences and profiles | VERIFIED | `00007b_create_pending_reminders_view.sql`: view joins `scheduled_reminders`, `profiles`, `notification_preferences`; filters `sent = false`, `fcm_token is not null`, `np.enabled = true` |
| 15 | User can access notification settings from the main Settings screen | VERIFIED | `settings_screen.dart` line 80: `onTap: () => context.push('/settings/notifications')` with Notifications tile |
| 16 | User can toggle master notifications, categories, quiet hours, and snooze duration | VERIFIED | `notification_settings_screen.dart`: master SwitchListTile, 3 `CategoryToggleCard` instances, `QuietHoursPicker`, snooze `DropdownButton` — all wired to `_updatePrefs` which calls `updatePreferences` |
| 17 | Notification settings persist to Supabase via NotificationRepository | VERIFIED | `notification_settings_screen.dart` line 40: `ref.read(notificationRepositoryProvider).updatePreferences(updated)` called on every preference change |

**Score:** 17/17 truths verified

---

### Required Artifacts

| Artifact | Expected | Status | Details |
|----------|---------|--------|---------|
| `supabase/migrations/00007_create_notification_tables.sql` | DB schema for 3 tables + FCM columns + trigger | VERIFIED | 125 lines; all 3 tables, RLS policies, indexes, `handle_new_user_notifications` trigger |
| `supabase/migrations/00007b_create_pending_reminders_view.sql` | View joining reminders + preferences + profiles | VERIFIED | 37 lines; joins 3 tables, filters unsent/enabled/token-present |
| `supabase/migrations/00007c_setup_cron_schedule.sql` | pg_cron job every minute | VERIFIED | 35 lines; pg_cron + pg_net, Vault-secured credentials, every-minute schedule |
| `supabase/functions/send-reminders/index.ts` | Edge Function with FCM delivery pipeline | VERIFIED | 293 lines; full pipeline: query, filter, adaptive insight, FCM send, mark-sent, stale-token cleanup |
| `lib/features/notifications/domain/notification_preferences.dart` | NotificationPreferences model | VERIFIED | 169 lines; `fromJson`, `toJson`, `copyWith`, `defaults` factory — all fields present |
| `lib/features/notifications/domain/completion_pattern.dart` | CompletionPattern model | VERIFIED | 95 lines; `fromJson`, `toJson`, `copyWith`, `responseDelayMinutes` present |
| `lib/features/notifications/data/notification_repository.dart` | Supabase CRUD for preferences, tokens, patterns | VERIFIED | 87 lines; all 6 methods wired to Supabase, DI pattern followed |
| `lib/core/services/notification_service.dart` | FCM singleton with channels, actions, token lifecycle | VERIFIED | 321 lines; singleton, 3 channels, Complete/Snooze actions, `subText` insight, `manageFcmToken`, `clearToken`, 2 `@pragma` handlers |
| `lib/features/notifications/presentation/providers/notification_providers.dart` | Riverpod providers | VERIFIED | 24 lines; both providers wired |
| `lib/features/notifications/presentation/screens/notification_settings_screen.dart` | Notification settings screen | VERIFIED | 353 lines; master toggle, 3 categories with sub-settings, quiet hours, snooze, saves via repository |
| `lib/features/notifications/presentation/widgets/category_toggle_card.dart` | Category toggle card widget | VERIFIED | 100 lines; `AnimatedCrossFade`, `Switch`, icon colour based on enabled state |
| `lib/features/notifications/presentation/widgets/quiet_hours_picker.dart` | Quiet hours picker widget | VERIFIED | 127 lines; `SwitchListTile`, `showTimePicker`, `AnimatedCrossFade` |
| `lib/features/notifications/presentation/widgets/reminder_offset_selector.dart` | Reminder offset chip selector | VERIFIED | 79 lines; `FilterChip` per offset, multi-select, `1440` and `60` present |
| `lib/features/settings/presentation/screens/settings_screen.dart` | Updated settings screen with notification tile | VERIFIED | Notifications tile at line 71, subtitle "Reminders, quiet hours, and preferences", Appearance and About cards preserved |
| `lib/core/router/app_router.dart` | Router with `/settings/notifications` route | VERIFIED | `path: '/settings/notifications'` at line 204, `NotificationSettingsScreen` import at line 20 |
| `lib/main.dart` | Firebase + NotificationService init | VERIFIED | `Firebase.initializeApp()` line 14, `NotificationService().initialize()` line 24, `firebase_core` import line 1 |
| `pubspec.yaml` | Firebase packages | VERIFIED | `firebase_core: ^4.5.0`, `firebase_messaging: ^16.1.2`, `flutter_local_notifications: ^21.0.0` |
| `test/unit/features/notifications/notification_repository_test.dart` | Repository and model unit tests | VERIFIED | 280 lines; 10 tests covering fromJson/toJson/copyWith/defaults/round-trip for both models |
| `test/unit/features/notifications/notification_service_test.dart` | Service unit tests | VERIFIED | Exists |
| `test/unit/features/notifications/adaptive_timing_test.dart` | Adaptive timing algorithm tests | VERIFIED | `AdaptiveTimingCalculator` Dart port, procrastination and fast-responder detection tested |
| `test/unit/features/notifications/quiet_hours_test.dart` | Quiet hours algorithm tests | VERIFIED | `QuietHoursChecker` with 22:00/07:00 wrapping midnight tests |
| `test/widget/features/notifications/notification_settings_test.dart` | Widget tests | VERIFIED | 15 widget tests covering all components |

---

### Key Link Verification

| From | To | Via | Status | Details |
|------|----|-----|--------|---------|
| `notification_repository.dart` | `notification_preferences` table | `from('notification_preferences')` | WIRED | Lines 24 and 36 — both `getPreferences` and `updatePreferences` query the correct table |
| `notification_service.dart` | `notification_repository.dart` | `storeFcmToken` call | WIRED | `manageFcmToken` calls `repo.storeFcmToken` at lines 302 and 306 |
| `notification_providers.dart` | `notification_repository.dart` | `NotificationRepository()` instantiation | WIRED | Line 11: provider creates `NotificationRepository()` instance |
| `send-reminders/index.ts` | `pending_reminders` view | `from('pending_reminders')` | WIRED | Line 161: `supabase.from('pending_reminders').select('*').lte(...)` |
| `send-reminders/index.ts` | FCM HTTP v1 API | `fetch` to `fcm.googleapis.com` | WIRED | Line 221: `https://fcm.googleapis.com/v1/projects/${serviceAccount.project_id}/messages:send` |
| `00007c_setup_cron_schedule.sql` | `send-reminders/index.ts` | pg_net HTTP POST | WIRED | Line 26: URL concatenated to `/functions/v1/send-reminders` |
| `notification_settings_screen.dart` | `notification_providers.dart` | `ref.watch(notificationPreferencesProvider(...))` | WIRED | Line 80: watches provider with userId |
| `notification_settings_screen.dart` | `notification_repository.dart` | `updatePreferences` | WIRED | Line 40: `ref.read(notificationRepositoryProvider).updatePreferences(updated)` |
| `settings_screen.dart` | `notification_settings_screen.dart` | `context.push('/settings/notifications')` | WIRED | Line 80: onTap navigates to correct route |
| `app_router.dart` | `notification_settings_screen.dart` | `GoRoute(path: '/settings/notifications', ...)` | WIRED | Lines 20 (import) and 204 (route definition) |

---

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
|-------------|------------|-------------|--------|----------|
| PLAN-04 | 07-02, 07-03 | User receives adaptive reminders that learn from completion patterns and adjust timing | SATISFIED | `send-reminders/index.ts`: dual-signal algorithm queries 2-week `completion_patterns`, generates insight strings for procrastination and fast-responder patterns; insight delivered via FCM `data.insight` and displayed via `subText` in local notification |
| UX-03 | 07-01, 07-03 | User receives FCM push notifications for deadline reminders with configurable timing | SATISFIED | Full pipeline: FCM initialized in `main.dart`, 3 Android channels, deadline reminders scheduled in `scheduled_reminders`, Edge Function delivers data-only FCM messages every minute; `NotificationSettingsScreen` provides configurable timing, quiet hours, and snooze controls |

No orphaned requirements found — both PLAN-04 and UX-03 mapped to Phase 7 in REQUIREMENTS.md are claimed by plans and have implementation evidence.

---

### Anti-Patterns Found

| File | Lines | Pattern | Severity | Impact |
|------|-------|---------|----------|--------|
| `lib/core/services/notification_service.dart` | 113-125 | `onBackgroundNotificationAction` uses `debugPrint` stubs for Complete and Snooze actions | WARNING | Background notification actions (tap Complete or Snooze while app is terminated) do not execute Supabase operations. This was a **documented decision** in 07-01-SUMMARY.md: "Background action handler stubs use debugPrint until Supabase background isolate initialization is wired (will be completed in integration phase)." Not a blocker for Phase 7 goal delivery. |

No MISSING or STUB artifacts found. No other TODO/FIXME/placeholder patterns detected.

---

### Human Verification Required

**1. FCM Push Notification End-to-End**

**Test:** Deploy the Edge Function and Firebase project, insert a `scheduled_reminder` row with `remind_at = now`, wait up to 1 minute, and observe notification on an Android device.
**Expected:** A headed-up notification appears with the correct title/body/insight, and Complete/Snooze action buttons are visible.
**Why human:** Requires a real Firebase project (`google-services.json`), a deployed Supabase Edge Function, and a physical Android device.

**2. Notification Settings Persistence**

**Test:** Navigate to Settings > Notifications, disable Habit Reminders, close and re-open the app, then navigate to notification settings again.
**Expected:** Habit Reminders toggle remains off.
**Why human:** Persistence round-trip through Supabase requires a live backend with deployed migrations.

**3. Quiet Hours End-to-End**

**Test:** Set quiet hours to start 1 minute from now (e.g., 14:00-14:05), then observe whether a pending reminder is skipped by the Edge Function.
**Expected:** The reminder's `sent` column stays `false` during the window; after the window, it is sent normally.
**Why human:** Requires live Edge Function execution and wall-clock timing.

**4. Background Action Handler (Deferred)**

**Test:** While app is terminated, tap the Snooze button on a notification.
**Expected:** A new `scheduled_reminders` row is inserted with `remind_at = now + snooze_duration`. *(Currently stubs with debugPrint — deferred to Phase 8 integration.)*
**Why human:** Requires Phase 8 Supabase background-isolate wiring to be complete before this can be tested.

---

### Summary

Phase 7 achieves its goal. The complete notification pipeline is implemented across all three plans:

- **Plan 01** (data foundation): All 3 database tables with RLS, FCM columns on profiles, domain models, repository, NotificationService singleton, Riverpod providers, and Firebase packages are wired into app startup.
- **Plan 02** (server-side delivery): The `send-reminders` Edge Function runs on a 1-minute pg_cron schedule, queries the `pending_reminders` view, applies category filters and quiet hours (with midnight wrap-around), generates adaptive timing insights from 2-week completion patterns, and sends data-only FCM messages with stale-token cleanup.
- **Plan 03** (settings UI): `NotificationSettingsScreen` provides all configurable controls (master toggle, 3 category cards with sub-settings, quiet hours picker, snooze duration selector), persists immediately to Supabase, and is reachable from the settings screen via router at `/settings/notifications`.

The one documented limitation — background action handler stubs for Complete/Snooze — is a known deferred item explicitly noted in the SUMMARY and planned for Phase 8 integration. It does not block the phase goal.

All 6 commits verified in git: `3f0282d`, `f57127e`, `f86ac18`, `872700c`, `b035faa`, `f760075`.

---

_Verified: 2026-03-22T13:30:00Z_
_Verifier: Claude (gsd-verifier)_
