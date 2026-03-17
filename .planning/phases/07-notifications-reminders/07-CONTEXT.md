# Phase 7: Notifications & Reminders - Context

**Gathered:** 2026-03-18
**Status:** Ready for planning

<domain>
## Phase Boundary

Deliver FCM push notifications for task deadlines, habit reminders, and AI planner time blocks. Notifications use adaptive timing that learns from user completion patterns. Users can configure preferences (per-category defaults, per-task overrides, quiet hours) from a dedicated notification settings screen. Server-side delivery via Supabase Edge Function on cron schedule.

</domain>

<decisions>
## Implementation Decisions

### Notification triggers
- **Three notification sources**: task deadlines, habit check-in reminders, and AI planner time block notifications
- **Task deadlines**: two-stage default reminders (1 day before + 1 hour before). User can customize timing per task
- **Habit reminders**: per-habit reminder time if set by user (e.g., "Meditate" at 7 AM); fallback to global daily summary reminder for habits without a specific time (e.g., 8 AM -- "You have 3 habits to do today")
- **Planner time blocks**: morning summary notification when the day's plan is ready ("Your plan for today is ready -- 6 items scheduled") + individual time block reminders before each block starts. Users can toggle block-level reminders off independently

### Adaptive timing logic
- **Dual-signal adaptation**: tracks both deadline proximity patterns (how close to deadline user completes tasks) AND time-of-day responsiveness (when user acts on notifications vs ignores them)
- **If procrastinating**: shift task reminders earlier (e.g., from 1hr to 3hrs before deadline)
- **If responsive window detected**: shift reminders to times user is most likely to act
- **Data window**: last 2 weeks of completion data -- adapts quickly to changing behavior, good for portfolio demo
- **Transparent adaptation**: show a small insight when timing changes (e.g., "Reminder moved earlier -- you tend to complete tasks closer to deadline"). Displayed as a subtitle on the notification or in notification history

### Preferences & settings UI
- **Organization**: Claude's discretion on whether single section in settings or dedicated notification preferences screen (based on final option count)
- **Category-level defaults**: separate timing/toggle controls for tasks, habits, and planner notifications in settings
- **Per-task override**: optional custom reminder timing on task creation/edit form (overrides category default)
- **Quiet hours**: configurable time range picker (e.g., 10 PM -- 7 AM) during which no notifications fire
- **Master toggle**: global notifications on/off at the top

### Delivery architecture
- **Server-side only**: Supabase Edge Function on cron schedule checks upcoming deadlines/reminders and sends FCM push notifications
- **Cron frequency**: Claude's discretion based on Supabase cron capabilities and reminder precision needs
- **Actionable notifications**: include "Complete" and "Snooze" action buttons directly on notifications -- user can act without opening the app
- **Tap action**: tapping the notification body opens the app to the relevant item (task detail, habit, planner)
- **FCM integration**: firebase_messaging Flutter package for receiving push; server sends via FCM HTTP API from Edge Function

### Claude's Discretion
- Notification preferences screen layout vs inline settings section
- Cron frequency for the reminder check Edge Function
- Exact adaptive algorithm implementation (weighted averages, simple heuristics, etc.)
- Database schema for notification preferences, reminder schedules, and completion tracking
- FCM token management and refresh strategy
- Notification channel/category configuration for Android
- Snooze duration options (5/15/30 min or custom)
- Edge Function implementation details (Deno/TypeScript)
- How "Complete" action from notification triggers task/habit completion in Supabase

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Requirements
- `.planning/REQUIREMENTS.md` -- PLAN-04 (adaptive reminders learning from completion patterns) and UX-03 (FCM push notifications for deadline reminders with configurable timing)

### Prior context
- `.planning/phases/01-foundation-auth/01-CONTEXT.md` -- Theme decisions (warm amber/teal, friendly vibe), architecture patterns (Clean Architecture, Riverpod, go_router)
- `.planning/phases/02-task-management/02-CONTEXT.md` -- Task model with deadlines, priority, categories -- notifications trigger based on these
- `.planning/phases/04-habit-tracking/04-CONTEXT.md` -- Habit model with frequency, check-in patterns -- habit reminders deferred to this phase
- `.planning/phases/05-ai-daily-planner/05-CONTEXT.md` -- Planner items with scheduled time blocks -- planner notifications trigger from these

### Existing code
- `lib/features/settings/presentation/screens/settings_screen.dart` -- Existing settings screen (has placeholder comment for notification preferences)
- `lib/core/router/app_router.dart` -- Router config for adding notification settings route
- `lib/features/profile/domain/profile_model.dart` -- Profile model pattern (fromJson/toJson/copyWith) to follow for notification preferences model
- `lib/features/auth/data/auth_repository.dart` -- SupabaseClient injection pattern for notification repository
- `supabase/migrations/00001_create_profiles.sql` -- Migration and RLS pattern to follow for notification tables

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `AppButton`, `AppTextField`, `LoadingOverlay` shared widgets -- reuse for notification settings UI
- Settings screen at `lib/features/settings/presentation/screens/settings_screen.dart` -- integrate notification preferences here
- Material 3 theme with amber/teal color scheme -- notification settings UI follows established palette

### Established Patterns
- Clean Architecture: data/domain/presentation layers per feature
- Riverpod 2 providers with SupabaseClient injection for repositories
- fromJson/toJson/copyWith on models (see Profile model)
- go_router ShellRoute for navigation

### Integration Points
- Settings screen: add notification preferences section or link to dedicated screen
- Task model (Phase 2): needs reminder_offset field or separate reminders table
- Habit model (Phase 4): needs reminder_time field
- Planner model (Phase 5): needs notification toggle for time blocks
- Supabase Edge Functions: second Edge Function in the project (first is AI planner from Phase 5)
- FCM: new dependency -- firebase_messaging + firebase_core in pubspec.yaml

</code_context>

<specifics>
## Specific Ideas

- Adaptive timing transparency builds trust and showcases the AI/ML aspect of the app -- great for portfolio demos
- Two-stage task reminders (1 day + 1 hour) prevent last-minute scrambles without being annoying
- Habit reminders with per-habit time + global fallback gives flexibility without requiring setup for every habit
- Actionable notifications (Complete/Snooze) reduce friction -- user can check off a habit from the notification tray
- Morning planner summary notification is a nice daily touchpoint ("Your plan for today is ready")

</specifics>

<deferred>
## Deferred Ideas

None -- discussion stayed within phase scope

</deferred>

---

*Phase: 07-notifications-reminders*
*Context gathered: 2026-03-18*
