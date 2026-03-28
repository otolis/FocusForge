---
phase: 09-redesign-boards-ui-monday-layout
plan: 04
subsystem: ui, state-management
tags: [flutter, riverpod, material3, monday.com, table-view, scroll-sync, drag-reorder, config-sheets, view-switcher]

# Dependency graph
requires:
  - phase: 09-redesign-boards-ui-monday-layout
    provides: Board/BoardCard/BoardGroup domain models, ColumnType enum, TableColumnDef, StatusLabelDef, BoardMetadata
  - phase: 09-redesign-boards-ui-monday-layout
    provides: 9 cell type widgets (StatusCell, PriorityCell, PersonCell, TimelineCell, DueDateCell, TextCell, NumberCell, CheckboxCell, LinkCell)
  - phase: 09-redesign-boards-ui-monday-layout
    provides: 5 structural widgets (GroupHeaderWidget, GroupFooterWidget, AddItemRow, TableHeaderRow, TableDataRow)
provides:
  - BoardTableProvider with editing cell, column widths, collapsed groups, resize, row reorder, column reorder
  - BoardTableWidget with 4-way scroll sync, sticky name column, row drag reorder
  - ViewSwitcher with Table and Kanban tabs
  - StatusConfigSheet for status label management with 10 preset colors
  - ColumnConfigSheet for adding/editing table columns with type selection
  - GroupConfigSheet for creating/editing groups with name and color
  - Extended BoardDetailNotifier with updateCardField, addCardToGroup, updateBoardMetadata, setCardsByColumn, setBoard
  - Refactored BoardDetailScreen with Table/Kanban tab container
affects: [09-05-PLAN]

# Tech tracking
tech-stack:
  added: []
  patterns: [4 ScrollController scroll sync pattern, LongPressDraggable/DragTarget for row reorder within groups, NeverScrollableScrollPhysics during column resize, DraggableScrollableSheet for config bottom sheets]

key-files:
  created:
    - lib/features/boards/presentation/providers/board_table_provider.dart
    - lib/features/boards/presentation/widgets/table/board_table_widget.dart
    - lib/features/boards/presentation/widgets/view_switcher.dart
    - lib/features/boards/presentation/widgets/status_config_sheet.dart
    - lib/features/boards/presentation/widgets/column_config_sheet.dart
    - lib/features/boards/presentation/widgets/group_config_sheet.dart
  modified:
    - lib/features/boards/presentation/providers/board_detail_provider.dart
    - lib/features/boards/presentation/screens/board_detail_screen.dart

key-decisions:
  - "BoardTableProvider is a separate StateNotifier from BoardDetailProvider -- table-specific state (editing, widths, collapse) isolated from board data state"
  - "Row reorder uses LongPressDraggable/DragTarget instead of ReorderableListView -- avoids nesting conflicts with outer ListView"
  - "Column reorder uses index-based onReorder callback from TableHeaderRow, persisted via metadata update"
  - "Table view is default (activeIndex=0) per locked user decision"
  - "Config sheets use kPresetColors constant shared between StatusConfigSheet and GroupConfigSheet"
  - "DropdownButtonFormField uses initialValue instead of deprecated value parameter"

patterns-established:
  - "4-way scroll sync: fixedVertical/scrollableVertical for vertical sync, headerHorizontal/dataHorizontal for horizontal sync with bool guards to prevent recursion"
  - "Optimistic update with rollback pattern: setCardsByColumn/setBoard for direct state injection from table provider"
  - "Config sheet pattern: StatefulWidget with controllers, save callback, Navigator.pop on save"

requirements-completed: [BOARD-TABLE-PROVIDER, BOARD-TABLE-WIDGET, BOARD-TABLE-CONFIG, BOARD-VIEW-SWITCHER]

# Metrics
duration: 7min
completed: 2026-03-28
---

# Phase 9 Plan 04: Table Provider, Widget Composition, Config Sheets, and View Switcher

**BoardTableProvider with row/column reorder, BoardTableWidget with 4-way scroll sync and sticky column, 3 config sheets, ViewSwitcher, and board detail screen refactored to Table/Kanban tab container**

## Performance

- **Duration:** 7 min
- **Started:** 2026-03-28T12:20:17Z
- **Completed:** 2026-03-28T12:27:30Z
- **Tasks:** 2
- **Files modified:** 8

## Accomplishments
- BoardTableProvider manages all table-specific state: editing cell ID, column widths, collapsed groups, resize flag, with methods for row reorder (within groups) and column reorder (with metadata persistence)
- BoardTableWidget composes sticky 200px name column with horizontally scrollable data columns, 4 ScrollControllers for synced scrolling, LongPressDraggable/DragTarget for row reorder
- ViewSwitcher renders Table (default) and Kanban tabs with primary underline active indicator
- 3 config sheets (Status, Column, Group) with proper form controls and save callbacks
- BoardDetailScreen refactored from Kanban-only to tab container with _activeViewIndex=0 (Table default)
- Existing Kanban view fully preserved in _buildKanbanView method
- BoardDetailNotifier extended with 5 new methods for table view support
- Static analysis: 0 issues across entire boards feature

## Task Commits

Each task was committed atomically:

1. **Task 1: BoardTableProvider + config sheets** - `3ce5504` (feat)
2. **Task 2: BoardTableWidget + ViewSwitcher + board detail refactor** - `1298455` (feat)

## Files Created/Modified
- `lib/features/boards/presentation/providers/board_table_provider.dart` - BoardTableState, BoardTableNotifier with editing/resize/collapse/reorder state, boardGroupRepositoryProvider
- `lib/features/boards/presentation/widgets/table/board_table_widget.dart` - Main table composition with 4 scroll controllers, sticky column, row drag reorder, group rendering
- `lib/features/boards/presentation/widgets/view_switcher.dart` - Table/Kanban tab switcher with Icons.grid_view and Icons.view_column
- `lib/features/boards/presentation/widgets/status_config_sheet.dart` - DraggableScrollableSheet with editable status labels, 10 preset color picker
- `lib/features/boards/presentation/widgets/column_config_sheet.dart` - Column name field + DropdownButtonFormField type selector, create/edit modes
- `lib/features/boards/presentation/widgets/group_config_sheet.dart` - Group name field + color picker, create/edit modes
- `lib/features/boards/presentation/providers/board_detail_provider.dart` - Added updateCardField, addCardToGroup, updateBoardMetadata, setCardsByColumn, setBoard, _findCard, _updateCardInState
- `lib/features/boards/presentation/screens/board_detail_screen.dart` - Refactored to tab container with ViewSwitcher, Table default, Kanban preserved, status config AppBar button

## Decisions Made
- BoardTableProvider is a separate StateNotifier keyed by boardId, not merged into BoardDetailProvider, keeping table-specific concerns isolated from board data loading/realtime
- Row reorder uses LongPressDraggable/DragTarget pattern (not ReorderableListView) to avoid nesting conflicts with the outer ListView that renders groups
- Column resize sets NeverScrollableScrollPhysics on the horizontal SingleChildScrollView to prevent scroll fighting during resize drags
- Table view is the default (activeIndex=0) when opening a board, per locked user decision
- DropdownButtonFormField uses `initialValue` instead of deprecated `value` parameter (Flutter 3.33+)

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Fixed missing BoardMetadata import in board_detail_screen.dart**
- **Found during:** Task 2
- **Issue:** BoardMetadata is defined in board_table_column.dart, not board_model.dart. The _showStatusConfig method needed to construct BoardMetadata objects.
- **Fix:** Added import for `../../domain/board_table_column.dart` to the screen file.
- **Files modified:** `lib/features/boards/presentation/screens/board_detail_screen.dart`
- **Commit:** `1298455`

**2. [Rule 1 - Bug] Fixed deprecated `value` parameter on DropdownButtonFormField**
- **Found during:** Task 1
- **Issue:** Flutter 3.33+ deprecates `value` parameter in favor of `initialValue` on DropdownButtonFormField.
- **Fix:** Changed to `initialValue` parameter.
- **Files modified:** `lib/features/boards/presentation/widgets/column_config_sheet.dart`
- **Commit:** `3ce5504`

## Issues Encountered
None beyond the auto-fixed items above.

## User Setup Required
None -- all changes are pure Flutter presentation and state management code.

## Next Phase Readiness
- All table view components wired and rendering: provider, widget, config sheets, view switcher
- Board detail screen supports both Table and Kanban views
- Ready for Plan 09-05 (if any) for polish, testing, or integration tasks
- 59 + 0 = 59 existing widget tests still passing (no new tests in this plan -- test coverage for new widgets deferred)

## Self-Check: PASSED
