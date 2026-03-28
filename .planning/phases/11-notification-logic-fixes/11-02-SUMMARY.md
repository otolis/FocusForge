---
phase: 11-notification-logic-fixes
plan: 02
subsystem: notifications
tags: [supabase, scheduled-reminders, push-notifications, repositories]

# Dependency graph
requires:
  - phase: 11-01
    provides: "scheduled_reminders table and notification_preferences table schema"
provides:
  - "Initial scheduled_reminders rows inserted by task, habit, and planner repositories"
  - "_scheduleReminders helper in TaskRepository"
  - "_scheduleHabitReminder helper in HabitRepository"
  - "Planner block reminder scheduling in PlannerRepository.saveSchedule"
affects: [11-notification-logic-fixes, send-reminders-edge-function]

# Tech tracking
tech-stack:
  added: []
  patterns: ["Non-critical reminder scheduling co-located with DB writes, wrapped in try/catch"]

key-files:
  created: []
  modified:
    - lib/features/tasks/data/task_repository.dart
    - lib/features/habits/data/habit_repository.dart
    - lib/features/planner/data/planner_repository.dart

key-decisions:
  - "Reminder scheduling is non-critical: try/catch wrapped so failures never break primary CRUD operations"
  - "Task reminders use idempotent delete-then-insert pattern for update safety"
  - "Planner reminders scope delete by date range and reminder_type to avoid cross-day collisions"

patterns-established:
  - "Reminder scheduling co-located with repository DB writes, not in viewmodel or service layer"
  - "User preferences read inline from notification_preferences table with sensible fallback defaults"

requirements-completed: [NOTIF-06]

# Metrics
duration: 2min
completed: 2026-03-28
---

# Phase 11 Plan 02: Initial Reminder Scheduling Summary

**Scheduled_reminders row insertion in task, habit, and planner repositories so send-reminders Edge Function has data to deliver**

## Performance

- **Duration:** 2 min
- **Started:** 2026-03-28T14:08:40Z
- **Completed:** 2026-03-28T14:10:55Z
- **Tasks:** 2
- **Files modified:** 3

## Accomplishments
- TaskRepository.createTask and updateTask now insert scheduled_reminders rows at user's configured task_default_offsets before deadline
- HabitRepository.createHabit inserts a habit_reminder row at user's habit_daily_summary_time
- PlannerRepository.saveSchedule inserts planner_block reminders at configured offset before each time block
- All scheduling is idempotent (delete unsent before re-insert) and non-critical (try/catch wrapped)
- deleteTask and deleteHabit clean up unsent reminders

## Task Commits

Each task was committed atomically:

1. **Task 1: Add reminder scheduling to TaskRepository** - `89b2c30` (feat)
2. **Task 2: Add reminder scheduling to HabitRepository and PlannerRepository** - `e0ee1a8` (feat)

## Files Created/Modified
- `lib/features/tasks/data/task_repository.dart` - Added _scheduleReminders helper, called from createTask/updateTask, cleanup in deleteTask
- `lib/features/habits/data/habit_repository.dart` - Added _scheduleHabitReminder helper, called from createHabit, cleanup in deleteHabit
- `lib/features/planner/data/planner_repository.dart` - Added planner_block reminder scheduling in saveSchedule after upsert

## Decisions Made
- Reminder scheduling is non-critical: try/catch wrapped so failures never break primary CRUD operations
- Task reminders use idempotent delete-then-insert pattern for update safety
- Planner reminders scope delete by date range and reminder_type to avoid cross-day collisions
- Repositories read user preferences inline with sensible defaults (no dependency on notification service)

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered
None

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- All three repositories now insert scheduled_reminders rows, giving the send-reminders Edge Function data to query
- Ready for Phase 11 Plan 03 (quiet hours timezone support) which builds on these same notification_preferences

## Self-Check: PASSED

All files exist, all commits verified.

---
*Phase: 11-notification-logic-fixes*
*Completed: 2026-03-28*
