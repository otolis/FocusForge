---
phase: 06-collaborative-boards
plan: 01
subsystem: database, realtime, state-management
tags: [supabase, rls, realtime, postgres-changes, presence, riverpod, kanban, appflowy_board]

# Dependency graph
requires:
  - phase: 01-foundation
    provides: Supabase client setup, auth repository pattern, profile model pattern, RLS migration pattern
provides:
  - Board, BoardColumn, BoardCard, BoardMember domain models with fromJson/toJson/copyWith
  - BoardRepository with RPC-based atomic board creation
  - BoardColumnRepository, BoardCardRepository, BoardMemberRepository for CRUD
  - BoardRealtimeService for Postgres Changes + Presence subscription per board
  - boardListProvider, boardDetailProvider, boardRealtimeProvider, boardPresenceProvider
  - SQL migration with 4 tables, 16 RLS policies, 2 RPC functions, 6 indexes
affects: [06-02-board-ui-screens, 06-03-member-management, 08-integration]

# Tech tracking
tech-stack:
  added: [appflowy_board ^0.1.2, uuid ^4.5.0]
  patterns: [membership-based RLS, realtime per-board channel, optimistic UI with rollback, family provider keyed by boardId]

key-files:
  created:
    - supabase/migrations/00003_create_boards.sql
    - lib/features/boards/domain/board_role.dart
    - lib/features/boards/domain/board_model.dart
    - lib/features/boards/data/board_repository.dart
    - lib/features/boards/data/board_column_repository.dart
    - lib/features/boards/data/board_card_repository.dart
    - lib/features/boards/data/board_member_repository.dart
    - lib/features/boards/data/board_realtime_service.dart
    - lib/features/boards/presentation/providers/board_list_provider.dart
    - lib/features/boards/presentation/providers/board_detail_provider.dart
    - lib/features/boards/presentation/providers/board_realtime_provider.dart
    - lib/features/boards/presentation/providers/board_presence_provider.dart
  modified:
    - pubspec.yaml

key-decisions:
  - "Migration numbered 00003 (not 00002 as planned) because 00002_create_planner_tables.sql already exists from another parallel phase"
  - "Realtime channel per board with filtered Postgres Changes on board_cards and board_columns only -- boards and board_members excluded from realtime publication"
  - "REPLICA IDENTITY FULL on cards/columns for complete DELETE event payloads"
  - "Gap strategy (1000 increments) for card/column positions to enable insertions without renumbering"

patterns-established:
  - "Membership-based RLS: EXISTS subquery against board_members junction table for all board-related tables"
  - "Atomic board creation: RPC function create_board_with_defaults inserts board + owner + 3 default columns in one transaction"
  - "Secure email invite: RPC function invite_board_member with SECURITY DEFINER to access auth.users"
  - "Optimistic UI with rollback: Save old state, update local immediately, persist to server, rollback on failure"
  - "Realtime lifecycle: Family provider subscribes on creation, unsubscribes on dispose via ref.onDispose"
  - "Profile join pattern: board_members select with profiles:user_id(display_name, avatar_url) for display data"

requirements-completed: [BOARD-01, BOARD-02, BOARD-03, BOARD-04]

# Metrics
duration: 5min
completed: 2026-03-18
---

# Phase 6 Plan 01: Board Data Foundation Summary

**Complete data layer for collaborative Kanban boards: PostgreSQL schema with membership-based RLS, domain models, CRUD repositories, Supabase Realtime service with Presence, and Riverpod providers with optimistic UI**

## Performance

- **Duration:** 5 min
- **Started:** 2026-03-17T23:13:46Z
- **Completed:** 2026-03-17T23:19:04Z
- **Tasks:** 3
- **Files modified:** 13 (12 created, 1 modified)

## Accomplishments
- Database schema with 4 tables, board_role enum, 16 RLS policies, 6 indexes, 2 RPC functions, Realtime publication, and REPLICA IDENTITY FULL
- Domain models (Board, BoardColumn, BoardCard, BoardMember) following existing Profile pattern with fromJson/toJson/copyWith
- 5 data-layer files: 4 CRUD repositories with Supabase client injection + 1 realtime service with Postgres Changes and Presence
- 4 Riverpod providers: board list, board detail with optimistic UI, realtime lifecycle management, and presence tracking

## Task Commits

Each task was committed atomically:

1. **Task 1: Database migration + dependency setup** - `97f8839` (feat)
2. **Task 2: Domain models and data repositories** - `1737cd2` (feat)
3. **Task 3: Riverpod providers for board state management** - `b73a9c0` (feat)

## Files Created/Modified
- `supabase/migrations/00003_create_boards.sql` - Board tables, RLS policies, RPC functions, indexes, realtime config
- `pubspec.yaml` - Added appflowy_board and uuid dependencies
- `lib/features/boards/domain/board_role.dart` - BoardRole enum (owner, editor, viewer)
- `lib/features/boards/domain/board_model.dart` - Board, BoardColumn, BoardCard, BoardMember models
- `lib/features/boards/data/board_repository.dart` - Board CRUD with RPC-based atomic creation
- `lib/features/boards/data/board_column_repository.dart` - Column CRUD with batch reorder
- `lib/features/boards/data/board_card_repository.dart` - Card CRUD with partial update
- `lib/features/boards/data/board_member_repository.dart` - Member management with profile join and RPC invite
- `lib/features/boards/data/board_realtime_service.dart` - Per-board Realtime channel with Postgres Changes + Presence
- `lib/features/boards/presentation/providers/board_list_provider.dart` - AsyncNotifier for board list
- `lib/features/boards/presentation/providers/board_detail_provider.dart` - StateNotifier with optimistic card moves and remote change callbacks
- `lib/features/boards/presentation/providers/board_realtime_provider.dart` - Realtime subscription lifecycle with auto-cleanup
- `lib/features/boards/presentation/providers/board_presence_provider.dart` - Online member tracking per board

## Decisions Made
- Migration file numbered 00003 instead of 00002 because 00002_create_planner_tables.sql already existed from a parallel phase execution
- Realtime publication limited to board_cards and board_columns (not boards or board_members) since only cards and columns change frequently enough to warrant live sync
- REPLICA IDENTITY FULL set on cards and columns to ensure DELETE events contain the full old record for proper handling
- Gap strategy (1000-increment positions) chosen for card and column ordering to allow insertions without renumbering

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Migration filename collision with existing 00002**
- **Found during:** Task 1 (Database migration creation)
- **Issue:** Plan specified `00002_create_boards.sql` but `00002_create_planner_tables.sql` already existed from parallel Phase 5 execution
- **Fix:** Used `00003_create_boards.sql` instead
- **Files modified:** supabase/migrations/00003_create_boards.sql
- **Verification:** Migration file created and contains all expected content
- **Committed in:** 97f8839 (Task 1 commit)

---

**Total deviations:** 1 auto-fixed (1 blocking)
**Impact on plan:** Trivial filename change. No functional impact.

## Issues Encountered
None

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- Complete data layer ready for Plan 02 (Board UI Screens) to consume
- Models, repositories, and providers are all importable and type-safe
- Realtime service is ready to subscribe/unsubscribe when board detail screen is opened
- Plan 03 (Member Management) can use BoardMemberRepository and boardPresenceProvider

## Self-Check: PASSED

- All 12 created files verified present on disk
- All 3 task commits verified in git history (97f8839, 1737cd2, b73a9c0)

---
*Phase: 06-collaborative-boards*
*Completed: 2026-03-18*
