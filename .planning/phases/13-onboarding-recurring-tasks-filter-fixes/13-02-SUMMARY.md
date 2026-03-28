---
phase: 13-onboarding-recurring-tasks-filter-fixes
plan: 02
subsystem: tasks
tags: [flutter, supabase, recurrence, recurring-tasks, state-management]

# Dependency graph
requires:
  - phase: 13-onboarding-recurring-tasks-filter-fixes
    provides: recurrence_model.dart, recurrence_picker.dart, task_form_screen.dart scaffold
provides:
  - Recurrence rule loading on edit form open
  - Recurrence rule upsert on all-future save
  - Future instance cleanup and regeneration with updated pattern
affects: [tasks, planner]

# Tech tracking
tech-stack:
  added: []
  patterns: [ValueKey for async widget reinstantiation, conditional upsert with type-based field nulling]

key-files:
  created: []
  modified:
    - lib/features/tasks/presentation/screens/task_form_screen.dart

key-decisions:
  - "ValueKey on RecurrencePicker forces destroy+recreate cycle when async config loads, since initState only reads initial values once"
  - "Delete incomplete future instances before regeneration to avoid NOT EXISTS guard blocking new pattern"
  - "Guard recurrence rule upsert with null checks on both _recurrenceConfig and parent.recurrenceRuleId"

patterns-established:
  - "ValueKey for async widget reinstantiation: when a StatefulWidget reads props in initState, use ValueKey to force recreation on async data load"

requirements-completed: [RECTASK-01]

# Metrics
duration: 2min
completed: 2026-03-28
---

# Phase 13 Plan 02: Recurring Task Edit Lifecycle Summary

**Recurrence rule load-on-edit, upsert-on-save, and future instance cleanup for recurring task editing**

## Performance

- **Duration:** 2 min
- **Started:** 2026-03-28T14:54:27Z
- **Completed:** 2026-03-28T14:56:08Z
- **Tasks:** 2
- **Files modified:** 1

## Accomplishments
- Editing a recurring task now pre-populates the recurrence picker with the existing rule (type, days of week, day of month, custom interval)
- Saving "all future instances" upserts the recurrence rule, deletes stale incomplete future children, and regenerates instances with the updated pattern
- Saving "this instance only" remains unchanged -- only updates that single task's fields

## Task Commits

Each task was committed atomically:

1. **Task 1: Load existing recurrence rule when editing a recurring task** - `1b38d3e` (feat)
2. **Task 2: Upsert recurrence rule and regenerate instances on "all future" save** - `bf5e0a9` (feat)

**Plan metadata:** TBD (docs: complete plan)

## Files Created/Modified
- `lib/features/tasks/presentation/screens/task_form_screen.dart` - Added _loadRecurrenceRule method, ValueKey on RecurrencePicker, recurrence rule upsert and instance cleanup in _saveRecurringTask

## Decisions Made
- ValueKey on RecurrencePicker forces destroy+recreate cycle when async config loads, since initState only reads initial values once
- Delete incomplete future instances before regeneration to avoid the NOT EXISTS guard in generate_recurring_instances blocking new pattern insertion
- Guard recurrence rule upsert with null checks on both _recurrenceConfig and parent.recurrenceRuleId for safety

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered
None

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- Recurring task editing lifecycle is complete
- Phase 13 plans (01 onboarding bypass + 02 recurring task edit) can proceed independently

## Self-Check: PASSED

All artifacts verified:
- task_form_screen.dart: FOUND
- Commit 1b38d3e (Task 1): FOUND
- Commit bf5e0a9 (Task 2): FOUND
- 13-02-SUMMARY.md: FOUND

---
*Phase: 13-onboarding-recurring-tasks-filter-fixes*
*Completed: 2026-03-28*
