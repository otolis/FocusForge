---
phase: 02-task-management
plan: 01
subsystem: database, tasks
tags: [supabase, postgresql, rls, fts, riverpod, dart, flutter]

# Dependency graph
requires:
  - phase: 01-foundation
    provides: Supabase setup, auth, profile model pattern, Riverpod provider pattern
provides:
  - Task, Category, RecurrenceRule, TaskFilter domain models with full serialization
  - TaskRepository with CRUD, filtered queries, FTS search via RPC, recurring instance generation
  - CategoryRepository with CRUD for user categories
  - Riverpod providers (taskListProvider, categoryListProvider, taskFilterProvider, filteredTaskListProvider, completedTaskListProvider)
  - Supabase migration with 3 tables (tasks, categories, recurrence_rules), 12 RLS policies, GIN FTS index, search RPC, recurrence generator
affects: [02-02, 02-03, 03-smart-task-input, 05-ai-daily-planner, 08-integration]

# Tech tracking
tech-stack:
  added: [flutter_slidable ^4.0.3, intl ^0.19.0, uuid ^4.5.1]
  patterns: [AsyncNotifier for mutable async state, optimistic update with rollback, TaskFilter clear-flag pattern in copyWith]

key-files:
  created:
    - supabase/migrations/00004_create_tasks.sql
    - lib/features/tasks/domain/task_model.dart
    - lib/features/tasks/domain/category_model.dart
    - lib/features/tasks/domain/recurrence_model.dart
    - lib/features/tasks/domain/task_filter.dart
    - lib/features/tasks/data/task_repository.dart
    - lib/features/tasks/data/category_repository.dart
    - lib/features/tasks/presentation/providers/task_provider.dart
    - lib/features/tasks/presentation/providers/category_provider.dart
    - lib/features/tasks/presentation/providers/task_filter_provider.dart
    - test/unit/tasks/task_model_test.dart
    - test/unit/tasks/category_model_test.dart
    - test/unit/tasks/recurrence_model_test.dart
    - test/unit/tasks/task_filter_test.dart
  modified:
    - pubspec.yaml

key-decisions:
  - "Migration numbered 00004 (not 00002) to avoid conflict with parallel phase migrations (habits=00002, planner=00002, boards=00003)"
  - "Task.toJson excludes id, created_at, fts, and joined category data -- server-managed fields"
  - "RecurrenceRule.displayLabel uses _ordinal helper for human-readable monthly labels (1st, 2nd, 15th)"
  - "filteredTaskListProvider filters out completed tasks by default; completedTaskListProvider serves them separately"
  - "Optimistic update pattern with try/catch rollback on toggleComplete and deleteTask"

patterns-established:
  - "AsyncNotifier pattern: TaskListNotifier/CategoryListNotifier for mutable async lists with CRUD methods"
  - "Optimistic update: mutate state immediately, revert on API failure"
  - "Clear-flag copyWith: bool clearCategory = false pattern for nullable field updates"
  - "Derived provider: filteredTaskListProvider watches both taskListProvider and taskFilterProvider"

requirements-completed: [TASK-01, TASK-03, TASK-04, TASK-05]

# Metrics
duration: 4min
completed: 2026-03-18
---

# Phase 2 Plan 1: Task Data Foundation Summary

**Supabase migration with 3 tables (tasks, categories, recurrence_rules), 12 RLS policies, FTS search, plus Dart domain models, repositories, and Riverpod providers for full task management data layer**

## Performance

- **Duration:** 4 min
- **Started:** 2026-03-18T01:17:31+02:00
- **Completed:** 2026-03-18T01:20:56+02:00
- **Tasks:** 3 (with TDD on Task 2: RED + GREEN commits)
- **Files created:** 15

## Accomplishments
- Created Supabase migration with tasks, categories, and recurrence_rules tables including 12 RLS policies, GIN FTS index, search_tasks RPC, generate_recurring_instances function, and updated_at triggers
- Built 4 domain models (Task, Category, RecurrenceRule, TaskFilter) with complete JSON serialization matching Supabase schema
- Implemented TaskRepository and CategoryRepository following the established DI pattern (optional SupabaseClient param)
- Created 5 Riverpod providers including AsyncNotifier-based task/category lists with optimistic update + rollback
- Wrote 31 unit tests across 4 test files covering model serialization, filter logic, and recurrence display labels

## Task Commits

Each task was committed atomically:

1. **Task 1: Supabase migration and pubspec dependencies** - `c0a3698` (feat)
2. **Task 2 RED: Failing tests for domain models** - `e0ab257` (test)
3. **Task 2 GREEN: Domain model implementations** - `d127c40` (feat)
4. **Task 3: Repositories and Riverpod providers** - `2dbc1a8` (feat)

## Files Created/Modified
- `supabase/migrations/00004_create_tasks.sql` - 3 tables, 12 RLS policies, FTS, search RPC, recurrence generator, triggers
- `lib/features/tasks/domain/task_model.dart` - Task model with Priority/TaskStatus enums, fromJson (nested Category), toJson, copyWith
- `lib/features/tasks/domain/category_model.dart` - Category model with 10 preset Material 3 colors
- `lib/features/tasks/domain/recurrence_model.dart` - RecurrenceRule model with displayLabel for human-readable output
- `lib/features/tasks/domain/task_filter.dart` - TaskFilter model with isEmpty, copyWith with clear flags
- `lib/features/tasks/data/task_repository.dart` - CRUD, filtered queries, FTS search via RPC, recurring generation
- `lib/features/tasks/data/category_repository.dart` - Category CRUD with DI-friendly constructor
- `lib/features/tasks/presentation/providers/task_provider.dart` - taskRepositoryProvider + taskListProvider (AsyncNotifier)
- `lib/features/tasks/presentation/providers/category_provider.dart` - categoryRepositoryProvider + categoryListProvider (AsyncNotifier)
- `lib/features/tasks/presentation/providers/task_filter_provider.dart` - taskFilterProvider + filteredTaskListProvider + completedTaskListProvider
- `test/unit/tasks/task_model_test.dart` - 7 tests for Task model serialization
- `test/unit/tasks/category_model_test.dart` - 6 tests for Category model
- `test/unit/tasks/recurrence_model_test.dart` - 9 tests for RecurrenceRule model
- `test/unit/tasks/task_filter_test.dart` - 9 tests for TaskFilter model
- `pubspec.yaml` - Added flutter_slidable, intl dependencies

## Decisions Made
- **Migration numbering:** Used 00004 instead of planned 00002 to avoid conflicts with parallel phase migrations (habits already took 00002, planner took 00002, boards took 00003)
- **Optimistic updates:** toggleComplete and deleteTask use optimistic state mutation with try/catch rollback on API failure
- **Separated completed tasks:** filteredTaskListProvider excludes completed tasks; completedTaskListProvider serves them separately for UI flexibility

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Migration numbered 00004 instead of 00002**
- **Found during:** Task 1 (Supabase migration)
- **Issue:** Plan specified 00002_create_tasks.sql but 00002 was already taken by parallel phase migrations (habits, planner)
- **Fix:** Numbered the migration 00004_create_tasks.sql to follow existing sequence
- **Files modified:** supabase/migrations/00004_create_tasks.sql
- **Verification:** File exists with correct numbering, no conflicts
- **Committed in:** c0a3698

---

**Total deviations:** 1 auto-fixed (1 blocking)
**Impact on plan:** Minor naming change only. No functional or scope impact.

## Issues Encountered
None beyond the migration numbering deviation.

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- Task data foundation complete: domain models, repositories, and providers ready for UI consumption
- Plans 02-02 (task list UI) and 02-03 (task create/edit form) can proceed immediately
- Smart input (Phase 3) can reference task models for integration
- AI planner (Phase 5) can query tasks via taskRepositoryProvider

## Self-Check: PASSED

- All 15 files verified present on disk
- All 4 commit hashes verified in git history (c0a3698, e0ab257, d127c40, 2dbc1a8)

---
*Phase: 02-task-management*
*Completed: 2026-03-18*
