---
phase: 05-ai-daily-planner
plan: 03
subsystem: ui
tags: [flutter, drag-and-drop, longpressdraggable, drag-target, material3, planner, timeline]

# Dependency graph
requires:
  - phase: 05-ai-daily-planner/02
    provides: TimelineWidget, TimeBlockCard, PlannerScreen, timeline sub-widgets
provides:
  - Drag-to-reschedule interaction for daily planner timeline
  - DraggableTimeBlockCard wrapper with LongPressDraggable and vertical axis constraint
  - DragTarget on timeline with 15-minute snap-on-drop and push-down displacement
  - Auto-save after block movement with 2s debounce
affects: [08-integration]

# Tech tracking
tech-stack:
  added: []
  patterns: [longpress-draggable-wrapper, drag-target-coordinate-conversion, debounced-auto-save]

key-files:
  created: []
  modified:
    - lib/features/planner/presentation/widgets/time_block_card.dart
    - lib/features/planner/presentation/widgets/timeline_widget.dart
    - lib/features/planner/presentation/screens/planner_screen.dart

key-decisions:
  - "Default 500ms long-press delay preserved to avoid scroll-drag conflicts (per RESEARCH.md pitfall)"
  - "DragTarget wraps entire timeline Stack for global coordinate conversion via globalToLocal"
  - "Save debounced at 2 seconds to avoid excessive Supabase writes during rapid dragging"

patterns-established:
  - "LongPressDraggable Wrapper: DraggableTimeBlockCard wraps TimeBlockCard with vertical axis constraint, elevation 8 feedback, and ghost outline"
  - "Coordinate Conversion: DragTarget uses GlobalKey + globalToLocal + scroll offset to convert drop position to snapped minute"
  - "Debounced Auto-save: Timer-based 2s debounce on block movement before persisting to Supabase"

requirements-completed: [PLAN-03]

# Metrics
duration: 1min
completed: 2026-03-22
---

# Phase 5 Plan 3: Drag-to-Reschedule Summary

**LongPressDraggable block cards with vertical axis constraint, 15-minute snap-on-drop via DragTarget coordinate conversion, push-down overlap displacement, and debounced 2s auto-save to Supabase**

## Performance

- **Duration:** 1 min
- **Started:** 2026-03-22T12:59:24Z
- **Completed:** 2026-03-22T13:00:33Z
- **Tasks:** 2 (1 auto + 1 checkpoint auto-approved)
- **Files modified:** 3

## Accomplishments
- Added DraggableTimeBlockCard wrapper with LongPressDraggable, vertical axis constraint, Material elevation 8 feedback, and 0.3 opacity ghost outline at original position
- Converted TimelineWidget to StatefulWidget with DragTarget, ScrollController, GlobalKey for coordinate conversion, 15-minute snap alignment, and enhanced guide line visibility during drag
- Wired onBlockMoved callback in PlannerScreen triggering moveBlock (instant UI with resolveOverlaps) plus debounced 2s saveCurrentSchedule for Supabase persistence

## Task Commits

Each task was committed atomically:

1. **Task 1: Add LongPressDraggable, DragTarget, and snap-on-drop** - `af9ffd9` (feat)
2. **Task 2: Verify planner screen rendering and interactions** - auto-approved checkpoint

## Files Created/Modified
- `lib/features/planner/presentation/widgets/time_block_card.dart` - Added DraggableTimeBlockCard wrapper with LongPressDraggable, elevation 8 feedback, ghost outline
- `lib/features/planner/presentation/widgets/timeline_widget.dart` - Converted to StatefulWidget with DragTarget, ScrollController, coordinate conversion, snap logic, enhanced guide lines during drag
- `lib/features/planner/presentation/screens/planner_screen.dart` - Added onBlockMoved callback with moveBlock + debounced saveCurrentSchedule, Timer field, dispose cleanup

## Decisions Made
- Default 500ms long-press delay preserved to avoid scroll-drag conflicts (per RESEARCH.md pitfall about setting Duration.zero)
- DragTarget wraps entire timeline Stack for global coordinate conversion via globalToLocal + scroll offset
- Save debounced at 2 seconds to avoid excessive Supabase writes during rapid sequential drags
- Timer cancelled in dispose() to prevent memory leaks from pending saves

## Deviations from Plan
None - plan executed exactly as written.

## Issues Encountered
None

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- Phase 5 (AI Daily Planner) is now complete with all 3 plans executed
- Full interactive planner with AI generation, timeline visualization, and drag-to-reschedule
- Ready for Phase 8 integration (wiring real tasks and habits into planner)

## Self-Check: PASSED

- All 3 modified files exist on disk
- Commit af9ffd9 (Task 1) verified in git log

---
*Phase: 05-ai-daily-planner*
*Completed: 2026-03-22*
