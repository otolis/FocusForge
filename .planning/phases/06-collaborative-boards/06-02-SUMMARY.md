---
phase: 06-collaborative-boards
plan: 02
subsystem: ui, navigation, kanban
tags: [flutter, appflowy_board, kanban, drag-and-drop, riverpod, go_router, material3]

# Dependency graph
requires:
  - phase: 06-collaborative-boards
    provides: Board/BoardColumn/BoardCard/BoardMember models, boardListProvider, boardDetailProvider, boardRealtimeProvider, BoardRepository
  - phase: 01-foundation
    provides: AppShell with NavigationBar, GoRouter configuration, Material 3 theme, extensions
provides:
  - Boards tab as 5th NavigationDestination in app shell (Tasks, Habits, Planner, Boards, Profile)
  - /boards route in ShellRoute and /boards/:id detail route outside ShellRoute
  - BoardListScreen with 2-column grid, empty state, error state, and create board dialog
  - BoardGridCard widget showing board name, column count, and creation date
  - BoardDetailScreen with full AppFlowyBoard Kanban view and drag-and-drop
  - KanbanCardWidget with priority color bar, due date, and assignee avatar
  - ColumnHeaderWidget with card count badge and management PopupMenuButton
  - EmptyColumnPlaceholder with add card prompt
  - CardDetailSheet for viewing/editing card details via modal bottom sheet
affects: [06-03-member-management, 08-integration]

# Tech tracking
tech-stack:
  added: []
  patterns: [AppFlowyBoardController sync with Riverpod via hash-based diffing, BoardCardItem extending AppFlowyGroupItem, modal bottom sheet with DraggableScrollableSheet for card editing]

key-files:
  created:
    - lib/features/boards/presentation/screens/board_list_screen.dart
    - lib/features/boards/presentation/screens/board_detail_screen.dart
    - lib/features/boards/presentation/widgets/board_grid_card.dart
    - lib/features/boards/presentation/widgets/kanban_card_widget.dart
    - lib/features/boards/presentation/widgets/column_header_widget.dart
    - lib/features/boards/presentation/widgets/empty_column_placeholder.dart
    - lib/features/boards/presentation/widgets/card_detail_sheet.dart
  modified:
    - lib/shared/widgets/app_shell.dart
    - lib/core/router/app_router.dart

key-decisions:
  - "AppFlowyBoardController synced with Riverpod state using hash-based diffing to avoid interrupting mid-gesture drags"
  - "BoardCardItem class extends AppFlowyGroupItem bridging domain BoardCard to appflowy_board widget"
  - "Column headers hide edit controls (PopupMenuButton) when user role is viewer"
  - "Card detail bottom sheet uses DraggableScrollableSheet (min 0.5, max 0.9) for scrollable editing"
  - "Empty column footer shows add-card placeholder; non-empty columns render SizedBox.shrink"

patterns-established:
  - "AppFlowyBoard controller sync pattern: compute hash of column/card structure, only rebuild controller groups when hash changes"
  - "Card priority color mapping: P1=red, P2=orange, P3=blue, P4=grey as 4px left-side color bar"
  - "Board grid card pattern: Card with InkWell, surfaceContainerLow background, 16px border radius"

requirements-completed: [BOARD-01, BOARD-02]

# Metrics
duration: 5min
completed: 2026-03-22
---

# Phase 6 Plan 02: Board UI Screens Summary

**Board list screen with 2-column card grid, full-screen Kanban board with AppFlowyBoard drag-and-drop, card detail bottom sheet, and 5th navigation tab wiring**

## Performance

- **Duration:** 5 min
- **Started:** 2026-03-22T11:51:13Z
- **Completed:** 2026-03-22T11:56:35Z
- **Tasks:** 2
- **Files modified:** 9 (7 created, 2 modified)

## Accomplishments
- Added Boards as 5th tab in bottom navigation with dashboard icon, wired /boards and /boards/:id routes
- Board list screen displays boards in a 2-column card grid with FAB for creating new boards, including loading/error/empty states
- Board detail screen renders full Kanban board via AppFlowyBoard with 85% screen width columns, long-press drag-and-drop between columns, and card detail editing via bottom sheet
- Column management (rename/delete) restricted to editors and owners via role-based UI controls

## Task Commits

Each task was committed atomically:

1. **Task 1: Add Boards tab to navigation and build Board List Screen** - `1a2bf9f` (feat)
2. **Task 2: Board detail screen with appflowy_board Kanban view** - `a91317a` (feat)

## Files Created/Modified
- `lib/shared/widgets/app_shell.dart` - Added 5th NavigationDestination (Boards) with dashboard icons
- `lib/core/router/app_router.dart` - Added /boards ShellRoute and /boards/:id detail route, imported BoardListScreen and BoardDetailScreen
- `lib/features/boards/presentation/screens/board_list_screen.dart` - ConsumerWidget with GridView.builder, FAB create dialog, loading/error/empty states
- `lib/features/boards/presentation/widgets/board_grid_card.dart` - Card widget showing board name, column count, creation date with InkWell navigation
- `lib/features/boards/presentation/screens/board_detail_screen.dart` - ConsumerStatefulWidget with AppFlowyBoardController, card/header/footer builders, hash-based state sync
- `lib/features/boards/presentation/widgets/kanban_card_widget.dart` - Card display with priority color bar, due date, assignee avatar, onTap callback
- `lib/features/boards/presentation/widgets/column_header_widget.dart` - Column name, card count badge, PopupMenuButton with rename/add/delete (editor/owner only)
- `lib/features/boards/presentation/widgets/empty_column_placeholder.dart` - Outlined container with add icon and "Add card" text
- `lib/features/boards/presentation/widgets/card_detail_sheet.dart` - Modal bottom sheet with title, description, priority ChoiceChips, date picker, save/delete actions

## Decisions Made
- AppFlowyBoardController is synced with Riverpod state using a hash-based diffing approach (string hash of column IDs, names, card IDs, and positions) to avoid destroying mid-gesture drags on every rebuild
- BoardCardItem extends AppFlowyGroupItem with a simple `card.id` override for the `id` getter, keeping the full BoardCard domain object available
- Column header PopupMenuButton only appears when `canEdit` is true (owner or editor role), viewers see read-only headers
- Card detail uses DraggableScrollableSheet with 0.5-0.9 child size range for comfortable editing on various screen sizes
- Empty columns show the add-card placeholder as a footer; non-empty columns return SizedBox.shrink to avoid wasted space

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered
- Task 1 and Task 2 files were committed by parallel phase agents running concurrently (commits 1a2bf9f and a91317a). Files were verified to contain the exact intended content.

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- All board UI screens complete and ready for Plan 03 (Member Management) to add board settings screen wiring
- Board detail screen already has settings icon button placeholder for Plan 03 to connect
- Realtime subscription activates when board detail screen mounts (via ref.watch of boardRealtimeProvider)
- Card detail sheet save/delete actions wire through boardDetailProvider notifier for optimistic updates

## Self-Check: PASSED

- All 9 files verified present on disk (7 created, 2 modified)
- Both task commits verified in git history (1a2bf9f, a91317a)
