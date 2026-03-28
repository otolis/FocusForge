---
phase: quick
plan: 260328-4wf
subsystem: ui
tags: [flutter, planner, ux, riverpod]

provides:
  - "Filtered plannable items panel that hides scheduled items"
  - "Persistent Regenerate FAB after AI schedule generation"
affects: [planner]

tech-stack:
  added: []
  patterns: [schedule-block-id-filtering]

key-files:
  created: []
  modified:
    - lib/features/planner/presentation/screens/planner_screen.dart

key-decisions:
  - "Regenerate FAB replaces small add FAB when blocks exist -- add item still accessible via panel header and app bar import button"
  - "Panel hides entirely when all items scheduled rather than showing empty panel"

patterns-established:
  - "Filter plannable items by matching PlannableItem.id against ScheduleBlock.itemId set"

requirements-completed: []

duration: 1min
completed: 2026-03-28
---

# Quick Task 260328-4wf: Fix Planner UX Summary

**Filter scheduled items from plannable panel and show persistent Regenerate FAB after AI schedule generation**

## Performance

- **Duration:** 1 min
- **Started:** 2026-03-28T01:33:50Z
- **Completed:** 2026-03-28T01:35:04Z
- **Tasks:** 1
- **Files modified:** 1

## Accomplishments
- Plannable items panel now filters out items that have been scheduled into time blocks (by matching PlannableItem.id against ScheduleBlock.itemId)
- Panel hides entirely when all items are scheduled (no misleading "X items to schedule" count)
- FAB persists after generation with "Regenerate" label and refresh icon for easy re-planning
- Initial "Plan My Day" FAB preserved for first-time generation (no blocks yet)

## Task Commits

Each task was committed atomically:

1. **Task 1: Filter scheduled items from panel and keep FAB as regenerate button** - `cf4a867` (fix)

## Files Created/Modified
- `lib/features/planner/presentation/screens/planner_screen.dart` - Added ScheduleBlock import, filtered plannable items by scheduled block IDs, replaced small add FAB with extended Regenerate FAB when blocks exist

## Decisions Made
- Regenerate FAB replaces the small "+" add FAB when schedule blocks exist. Users can still add items via the panel header "+" icon and the app bar import button, so the add-item affordance is not lost.
- Panel hides entirely (SizedBox.shrink) when all items are scheduled, rather than showing an empty panel with a zero count.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered
None

## User Setup Required
None - no external service configuration required.

---
*Quick task: 260328-4wf*
*Completed: 2026-03-28*
