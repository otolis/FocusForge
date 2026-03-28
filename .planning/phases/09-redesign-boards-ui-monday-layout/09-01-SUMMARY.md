---
phase: 09-redesign-boards-ui-monday-layout
plan: 01
subsystem: database, domain
tags: [supabase, postgresql, jsonb, dart, flutter, boards, table-view, monday.com]

# Dependency graph
requires:
  - phase: 06-collaborative-boards
    provides: Board, BoardCard, BoardColumn, BoardMember domain models and Supabase schema
provides:
  - BoardGroup model for table-view groups
  - TableColumnDef model for column definitions (type, name, width, position)
  - StatusLabelDef model for custom status labels with colors
  - BoardMetadata aggregate (columnDefs, statusLabels, groups) with defaults
  - ColumnType enum (9 column types)
  - Extended Board with metadata JSONB field
  - Extended BoardCard with startDate, statusLabel, statusColor, groupId, customFields
  - Migration 00009 for table-view schema (metadata on boards, new fields on board_cards)
  - BoardGroupRepository for group CRUD via metadata JSONB
  - BoardRepository.updateMetadata method
  - Extended BoardCardRepository.createCard/updateCard with table-view fields
affects: [09-02-PLAN, 09-03-PLAN, 09-04-PLAN]

# Tech tracking
tech-stack:
  added: []
  patterns: [JSONB metadata on boards for table-view config, group storage in metadata not separate table]

key-files:
  created:
    - lib/features/boards/domain/board_table_column.dart
    - lib/features/boards/data/board_group_repository.dart
    - supabase/migrations/00009_board_table_view.sql
    - test/unit/boards/board_metadata_test.dart
  modified:
    - lib/features/boards/domain/board_model.dart
    - lib/features/boards/data/board_repository.dart
    - lib/features/boards/data/board_card_repository.dart

key-decisions:
  - "Groups stored in boards.metadata JSONB, not a separate table -- simpler schema, fewer joins"
  - "ColumnType uses snake_case serialization for due_date to match DB convention"
  - "BoardMetadata provides sensible defaults when null/empty for backward compat with pre-table-view boards"

patterns-established:
  - "JSONB metadata pattern: Board-level config stored as typed JSONB with defaults on null"
  - "Backward-compatible model extension: new nullable/defaulted fields on existing models"
  - "Group repository thin wrapper: operates on parent JSONB, not separate table"

requirements-completed: [BOARD-TABLE-MODELS, BOARD-TABLE-MIGRATION, BOARD-TABLE-REPOS]

# Metrics
duration: 6min
completed: 2026-03-28
---

# Phase 9 Plan 01: Domain Models, Migration, and Repositories for Table View

**Extended Board/BoardCard models with metadata JSONB, created BoardGroup/TableColumnDef/StatusLabelDef/ColumnType/BoardMetadata types, migration 00009, and repository extensions for Monday.com-style table view**

## Performance

- **Duration:** 6 min
- **Started:** 2026-03-28T01:37:30Z
- **Completed:** 2026-03-28T01:43:32Z
- **Tasks:** 2
- **Files modified:** 7

## Accomplishments
- All 6 domain model classes/enums created with fromJson/toJson roundtrip serialization
- Migration 00009 extends boards (metadata JSONB) and board_cards (5 new columns) with group index
- Backward compatibility verified: Board.fromJson and BoardCard.fromJson work with and without new fields
- 19 unit tests passing for complete model serialization coverage
- Static analysis: 0 issues across all boards code

## Task Commits

Each task was committed atomically:

1. **Task 1 (RED): Failing tests** - `1eee4cc` (test)
2. **Task 1 (GREEN): Domain models implementation** - `28e6567` (feat)
3. **Task 2: Migration + Repository extensions** - `a095012` (feat)

## Files Created/Modified
- `lib/features/boards/domain/board_table_column.dart` - ColumnType enum, TableColumnDef, StatusLabelDef, BoardMetadata with defaults
- `lib/features/boards/domain/board_model.dart` - Extended Board with metadata, extended BoardCard with 5 new fields, added BoardGroup
- `lib/features/boards/data/board_repository.dart` - Added updateMetadata method
- `lib/features/boards/data/board_card_repository.dart` - Extended createCard/updateCard with table-view fields
- `lib/features/boards/data/board_group_repository.dart` - New repository for group CRUD via metadata JSONB
- `supabase/migrations/00009_board_table_view.sql` - Schema extension for table view support
- `test/unit/boards/board_metadata_test.dart` - 19 unit tests for all model serialization

## Decisions Made
- Groups stored in `boards.metadata` JSONB array rather than a separate table -- simpler schema, fewer joins, matches the Monday.com pattern where groups are board-level config
- ColumnType.dueDate serializes as `due_date` (snake_case) to match database column naming convention
- BoardMetadata.fromJson returns full defaults when metadata is null or empty map, ensuring backward compatibility with existing boards
- Used `const` constructors throughout for performance

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered
None

## User Setup Required

**Database migration required.** Run `supabase/migrations/00009_board_table_view.sql` on your Supabase instance to add:
- `metadata` JSONB column to `boards` table
- `start_date`, `status_label`, `status_color`, `group_id`, `custom_fields` columns to `board_cards` table
- `idx_board_cards_group` index
- Updated `create_board_with_defaults` RPC

## Next Phase Readiness
- Domain models ready for table-view widget consumption (09-02: Cell widgets and table row)
- Repositories ready for provider integration (09-03: Providers and state management)
- Migration ready for deployment
- Existing Kanban view code not broken (backward compatible models)

## Self-Check: PASSED

All 8 files verified present. All 3 commits verified in git log.

---
*Phase: 09-redesign-boards-ui-monday-layout*
*Completed: 2026-03-28*
