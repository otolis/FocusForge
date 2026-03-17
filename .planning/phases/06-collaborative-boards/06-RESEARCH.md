# Phase 6: Collaborative Boards - Research

**Researched:** 2026-03-18
**Domain:** Supabase Realtime (Postgres Changes + Presence), Flutter Kanban UI, Role-Based RLS
**Confidence:** HIGH

## Summary

Phase 6 introduces the first realtime feature in FocusForge -- collaborative Kanban boards with live sync and presence. The technical domain spans three areas: (1) Supabase Realtime for instant database change propagation and user presence tracking, (2) a Kanban board UI with cross-column drag-and-drop on mobile, and (3) multi-user RLS policies using a board_members junction table. All three areas have well-documented, production-ready solutions in the current ecosystem.

The `appflowy_board` package (v0.1.2, 223 likes, MPL-2.0 dual-licensed) provides the best Kanban board widget for this project -- it supports multi-group drag-and-drop out of the box, uses `provider` internally (which coexists fine with `flutter_riverpod`), and has a clean builder API for cards, headers, and footers. For Supabase Realtime, the `supabase_flutter ^2.12.0` SDK already in the project provides the typed `onPostgresChanges()`, `onPresenceSync()`, `onPresenceJoin()`, and `onPresenceLeave()` APIs needed for both database sync and live presence indicators.

The RLS pattern for multi-user access is straightforward: a `board_members` junction table with `(board_id, user_id, role)` enables membership-based policies. Each table (boards, columns, cards) gets SELECT/INSERT/UPDATE/DELETE policies that check membership via `EXISTS` subquery against `board_members`. Supabase Realtime respects these RLS policies, so each user only receives changes for boards they are a member of.

**Primary recommendation:** Use `appflowy_board` for Kanban UI, Supabase Realtime Postgres Changes for live sync, Supabase Presence for online indicators, and membership-based RLS with a `board_members` junction table.

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
- Boards get a 5th tab in the bottom navigation bar (Tasks, Habits, Planner, Boards, Profile)
- Board list screen displays boards as a card grid (2-column) -- each card shows board name, member avatar chips, and column count
- FAB on board list screen to create a new board
- New boards start with 3 default columns: To Do, In Progress, Done (user can rename/add/remove later)
- Tap a board card to open full-screen Kanban view
- Horizontal scroll with swipeable columns on mobile -- each column takes ~85% screen width
- Cards show: title, assignee avatar chip, priority color indicator, due date if set
- Long-press to initiate drag-and-drop of cards between columns (prevents accidental drags)
- Column management: add, rename, reorder, and delete columns (owner/editor only)
- Tap card to open bottom sheet with full details and edit capability
- Empty columns show subtle dashed outline with "+ Add card" prompt
- Invite flow: email input field on board settings screen -- sends invite, recipient sees board on login
- Three roles with clear permissions: Owner (full control), Editor (add/move/edit cards, manage columns), Viewer (read-only)
- Member avatars displayed at top-right of board header, overflow to "+N" chip when >4 members
- Role assignment via dropdown next to each member in board settings
- Green dot on member avatars when online, dimmed avatar when offline
- Optimistic UI: card moves and edits appear instantly, sync in background
- Conflict handling: last-write-wins with subtle toast notification when another user's change arrives
- Supabase Realtime channel per board -- subscribes to card inserts/updates/deletes and column changes

### Claude's Discretion
- Drag-and-drop library choice (flutter built-in vs third-party package)
- Card detail bottom sheet layout and field arrangement
- Board settings screen layout
- Exact RLS policy structure for multi-role access
- Database schema design (boards, columns, cards, members tables)
- Realtime channel configuration and subscription management
- Animation/transition details for card drag and column swipe

### Deferred Ideas (OUT OF SCOPE)
None -- discussion stayed within phase scope
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|-----------------|
| BOARD-01 | User can create boards with Kanban columns and drag-and-drop cards between columns | `appflowy_board` provides multi-group board with drag-and-drop; database schema for boards/columns/cards tables; default column creation pattern |
| BOARD-02 | Board changes sync instantly across all connected users via Supabase Realtime | `onPostgresChanges()` API for INSERT/UPDATE/DELETE on cards and columns tables; one Realtime channel per board; RLS ensures per-board filtering |
| BOARD-03 | User can invite members to boards by email and assign roles (owner/editor/viewer) | `board_members` junction table with role enum; RLS policies check membership + role for write operations; invite creates pending membership row |
| BOARD-04 | User can see live presence indicators showing who is online on a shared board | `onPresenceSync()`/`onPresenceJoin()`/`onPresenceLeave()` APIs; `track()` sends user info on subscribe; green dot overlay on AvatarWidget |
</phase_requirements>

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| supabase_flutter | ^2.12.0 | Realtime subscriptions (Postgres Changes + Presence), database CRUD, auth context | Already in project; provides typed `onPostgresChanges()`, presence APIs |
| appflowy_board | ^0.1.2 | Kanban board widget with multi-group drag-and-drop | 223 likes, verified publisher (AppFlowy.io), builder pattern for cards/headers/footers, MPL-2.0 license option |
| flutter_riverpod | ^3.3.1 | State management for board data, realtime subscriptions | Already in project; established pattern |
| go_router | ^17.1.0 | Board list and board detail routing | Already in project; add /boards tab route + /boards/:id detail route |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| equatable | ^2.0.5 | Value equality for board/card/column models | Transitive via appflowy_board; also useful for our own models |
| uuid | ^4.5.0 | Generate unique IDs for optimistic card/column creation | Client-side ID generation before Supabase sync |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| appflowy_board | Flutter built-in LongPressDraggable + DragTarget | Full control but 500+ lines of custom code for cross-column drag, auto-scroll, placeholder insertion; appflowy_board handles all of this |
| appflowy_board | kanban_board (pub.dev) | Depends on flutter_riverpod ^2.3.6 which conflicts with our ^3.3.1; only 42 likes |
| appflowy_board | boardview | Unverified publisher, simpler API but less customizable, no typed callbacks |
| Custom presence | Supabase Broadcast only | Would need manual presence tracking; Supabase Presence is purpose-built for this |

**Installation:**
```bash
flutter pub add appflowy_board uuid
```

**Note on appflowy_board license:** The package is dual-licensed (MPL-2.0 / AGPL-3.0). Use under MPL-2.0 -- this only requires sharing modifications to the library's own source files, not the application code. No special action needed unless you modify the package source.

**Note on appflowy_board + provider coexistence:** `appflowy_board` depends on `provider ^6.1.2` internally. This does NOT conflict with `flutter_riverpod ^3.3.1` -- they are separate packages that coexist in the same project without issues.

## Architecture Patterns

### Recommended Project Structure
```
lib/features/boards/
  data/
    board_repository.dart          # CRUD for boards table
    board_column_repository.dart   # CRUD for board_columns table
    board_card_repository.dart     # CRUD for board_cards table
    board_member_repository.dart   # CRUD for board_members table + invite logic
    board_realtime_service.dart    # Realtime channel management (Postgres Changes + Presence)
  domain/
    board_model.dart               # Board, BoardColumn, BoardCard, BoardMember models
    board_role.dart                # BoardRole enum (owner, editor, viewer)
  presentation/
    providers/
      board_list_provider.dart     # List of boards the user is a member of
      board_detail_provider.dart   # Single board state with columns, cards, members
      board_realtime_provider.dart # Manages realtime subscription lifecycle
      board_presence_provider.dart # Tracks online members for current board
    screens/
      board_list_screen.dart       # 2-column card grid with FAB
      board_detail_screen.dart     # Full-screen Kanban view (appflowy_board)
      board_settings_screen.dart   # Member management, column config, board settings
    widgets/
      board_grid_card.dart         # Card in the board list grid
      kanban_card_widget.dart      # Card rendered inside appflowy_board column
      member_avatar_row.dart       # Horizontal avatar row with "+N" overflow and presence dots
      card_detail_sheet.dart       # Bottom sheet for card viewing/editing
      column_header_widget.dart    # Column header with name + menu (rename/delete)
      empty_column_placeholder.dart # Dashed outline with "+ Add card"
```

### Pattern 1: Realtime Channel Per Board
**What:** Create one Supabase Realtime channel per board that subscribes to Postgres Changes on `board_cards` and `board_columns` tables (filtered by `board_id`), plus Presence for online members.
**When to use:** Whenever a user opens a board detail screen.
**Example:**
```dart
// Source: https://supabase.com/docs/reference/dart/subscribe
class BoardRealtimeService {
  BoardRealtimeService(this._client);
  final SupabaseClient _client;
  RealtimeChannel? _channel;

  void subscribeTo({
    required String boardId,
    required String userId,
    required String displayName,
    required void Function(PostgresChangePayload) onCardChange,
    required void Function(PostgresChangePayload) onColumnChange,
    required void Function() onPresenceSync,
  }) {
    _channel = _client.channel('board:$boardId')
      .onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'board_cards',
        filter: PostgresChangeFilter(
          type: PostgresChangeFilterType.eq,
          column: 'board_id',
          value: boardId,
        ),
        callback: onCardChange,
      )
      .onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'board_columns',
        filter: PostgresChangeFilter(
          type: PostgresChangeFilterType.eq,
          column: 'board_id',
          value: boardId,
        ),
        callback: onColumnChange,
      )
      .onPresenceSync((_) => onPresenceSync())
      .onPresenceJoin((_) => onPresenceSync())
      .onPresenceLeave((_) => onPresenceSync());

    _channel!.subscribe((status, error) async {
      if (status == RealtimeSubscribeStatus.subscribed) {
        await _channel!.track({
          'user_id': userId,
          'display_name': displayName,
          'online_at': DateTime.now().toIso8601String(),
        });
      }
    });
  }

  List<Map<String, dynamic>> get onlineMembers {
    if (_channel == null) return [];
    final state = _channel!.presenceState();
    // presenceState() returns Map<String, List<Presence>>
    return state.values
        .expand((presences) => presences)
        .map((p) => p.payload)
        .toList();
  }

  Future<void> unsubscribe() async {
    if (_channel != null) {
      await _client.removeChannel(_channel!);
      _channel = null;
    }
  }
}
```

### Pattern 2: Optimistic UI with Last-Write-Wins
**What:** Apply changes to local state immediately, then push to Supabase. When a Realtime event arrives, reconcile -- if the event matches our optimistic update, ignore it; if it's from another user, apply it and show a toast.
**When to use:** Card moves (drag-and-drop), card edits, column changes.
**Example:**
```dart
// In board detail provider / notifier:
Future<void> moveCard({
  required String cardId,
  required String fromColumnId,
  required String toColumnId,
  required int newPosition,
}) async {
  // 1. Optimistic: update local state immediately
  state = state.copyWithCardMoved(cardId, fromColumnId, toColumnId, newPosition);

  // 2. Persist to Supabase (last-write-wins)
  try {
    await _cardRepository.updateCard(
      cardId: cardId,
      columnId: toColumnId,
      position: newPosition,
    );
  } catch (e) {
    // 3. Rollback on failure
    state = state.copyWithCardMoved(cardId, toColumnId, fromColumnId, oldPosition);
  }
}
```

### Pattern 3: AppFlowyBoard Integration with Riverpod
**What:** Bridge `AppFlowyBoardController` (which uses `provider` internally) with Riverpod state by creating the controller in the widget and syncing it with Riverpod providers.
**When to use:** Board detail screen.
**Example:**
```dart
// Board detail screen bridges appflowy_board controller with Riverpod
class BoardDetailScreen extends ConsumerStatefulWidget {
  final String boardId;
  const BoardDetailScreen({super.key, required this.boardId});

  @override
  ConsumerState<BoardDetailScreen> createState() => _BoardDetailScreenState();
}

class _BoardDetailScreenState extends ConsumerState<BoardDetailScreen> {
  late final AppFlowyBoardController _boardController;

  @override
  void initState() {
    super.initState();
    _boardController = AppFlowyBoardController(
      onMoveGroupItem: (groupId, fromIndex, toIndex) {
        // Card reordered within same column
        ref.read(boardDetailProvider(widget.boardId).notifier)
            .reorderCard(groupId, fromIndex, toIndex);
      },
      onMoveGroupItemToGroup: (fromGroupId, fromIndex, toGroupId, toIndex) {
        // Card moved between columns -- the key Kanban interaction
        ref.read(boardDetailProvider(widget.boardId).notifier)
            .moveCardBetweenColumns(fromGroupId, fromIndex, toGroupId, toIndex);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final boardState = ref.watch(boardDetailProvider(widget.boardId));
    // Sync Riverpod state -> AppFlowyBoardController groups
    _syncControllerWithState(boardState);

    return AppFlowyBoard(
      controller: _boardController,
      cardBuilder: (context, group, groupItem) {
        final card = groupItem as BoardCardItem;
        return AppFlowyGroupCard(
          key: ValueKey(card.id),
          child: KanbanCardWidget(card: card),
        );
      },
      headerBuilder: (context, columnData) {
        return ColumnHeaderWidget(columnData: columnData);
      },
      footerBuilder: (context, columnData) {
        return AppFlowyGroupFooter(
          icon: const Icon(Icons.add, size: 20),
          title: const Text('Add card'),
          height: 50,
          onAddButtonClick: () => _showAddCardDialog(columnData.headerData.groupId),
        );
      },
      groupConstraints: BoxConstraints.tightFor(
        width: MediaQuery.of(context).size.width * 0.85,
      ),
      config: AppFlowyBoardConfig(
        groupBackgroundColor: Theme.of(context).colorScheme.surfaceContainerLow,
      ),
    );
  }

  @override
  void dispose() {
    _boardController.dispose();
    super.dispose();
  }
}
```

### Pattern 4: Membership-Based RLS Policies
**What:** All board-related tables use the `board_members` junction table to determine access. SELECT requires membership. INSERT/UPDATE require editor or owner role. DELETE on boards requires owner role.
**When to use:** Every board-related table.
**Example:**
```sql
-- Source: Supabase RLS documentation pattern
-- https://supabase.com/docs/guides/database/postgres/row-level-security

-- Board members can view boards they belong to
CREATE POLICY "Members can view boards"
  ON public.boards FOR SELECT TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.board_members
      WHERE board_members.board_id = boards.id
      AND board_members.user_id = (SELECT auth.uid())
    )
  );

-- Only owners can delete boards
CREATE POLICY "Owners can delete boards"
  ON public.boards FOR DELETE TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.board_members
      WHERE board_members.board_id = boards.id
      AND board_members.user_id = (SELECT auth.uid())
      AND board_members.role = 'owner'
    )
  );

-- Editors and owners can insert cards
CREATE POLICY "Editors can insert cards"
  ON public.board_cards FOR INSERT TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.board_members
      WHERE board_members.board_id = board_cards.board_id
      AND board_members.user_id = (SELECT auth.uid())
      AND board_members.role IN ('owner', 'editor')
    )
  );
```

### Anti-Patterns to Avoid
- **Subscribing to all boards at once:** Subscribe to one board's Realtime channel at a time (the currently viewed board). Subscribing to multiple boards wastes connections and causes RLS check overhead.
- **Storing column order in a separate table:** Use a `position` integer column on `board_columns` and `board_cards` instead. Simpler, fewer joins.
- **Using Supabase Broadcast instead of Postgres Changes:** Broadcast doesn't persist data -- you'd need to manually sync. Postgres Changes is the correct choice because changes go through the database (persistence + RLS enforcement).
- **Putting role checks in Flutter code only:** Always enforce roles in RLS policies. Flutter-side checks are for UI affordances (hiding buttons), not security.
- **Using `FOR ALL` policies:** Always write separate SELECT, INSERT, UPDATE, DELETE policies. `FOR ALL` makes debugging access issues nearly impossible.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Kanban board with cross-column drag-and-drop | Custom LongPressDraggable + DragTarget + auto-scroll + placeholder insertion | `appflowy_board` | 500+ lines of tricky gesture handling, scroll coordination, and placeholder management; appflowy_board solves all of this |
| Live presence tracking | Custom heartbeat polling + cleanup timers | Supabase Realtime Presence | Built-in join/leave/sync events, automatic cleanup on disconnect, no polling needed |
| Realtime database sync | Custom WebSocket + manual message handling | Supabase Realtime Postgres Changes | RLS-integrated, typed payloads, automatic reconnection, filter support |
| Unique ID generation | Custom timestamp-based IDs | `uuid` package | RFC 4122 compliant, collision-resistant, standard pattern for optimistic inserts |
| Column/card ordering | Linked list or separate ordering table | Integer `position` column with gap strategy | Simple, well-understood, easy to reorder with UPDATE |

**Key insight:** The heaviest custom-code risk is the Kanban drag-and-drop. Flutter's built-in `LongPressDraggable` + `DragTarget` handles single-item drag well but doesn't provide: auto-scroll when dragging near edges, placeholder insertion showing where the card will land, cross-list coordination, or smooth animations during reorder. `appflowy_board` handles all of these.

## Common Pitfalls

### Pitfall 1: Realtime Disabled by Default on New Tables
**What goes wrong:** You create `boards`, `board_columns`, `board_cards` tables but Realtime subscriptions receive nothing.
**Why it happens:** Supabase disables Realtime replication for new tables by default. You must explicitly add tables to the `supabase_realtime` publication.
**How to avoid:** Include `ALTER PUBLICATION supabase_realtime ADD TABLE board_cards, board_columns;` in the migration. Only add tables that need realtime -- `boards` and `board_members` don't need it (changes are infrequent, triggered by explicit user actions).
**Warning signs:** `onPostgresChanges` callback never fires despite successful `subscribe()`.

### Pitfall 2: RLS Blocks Realtime DELETE Events
**What goes wrong:** Users don't receive DELETE notifications for cards/columns because Supabase cannot verify RLS access on deleted records.
**Why it happens:** By design, "RLS policies are not applied to DELETE statements, because there is no way for Postgres to verify that a user has access to a deleted record."
**How to avoid:** Set `REPLICA IDENTITY FULL` on `board_cards` and `board_columns` tables so the full old record is sent with DELETE events. Even though RLS isn't checked, the Realtime filter on `board_id` ensures only relevant deletes are received. For extra safety, verify the `board_id` in the Flutter callback before applying the change.
**Warning signs:** Cards disappear for the deleter but not for other board members.

### Pitfall 3: Realtime Performance Bottleneck with RLS
**What goes wrong:** Realtime events are delayed or dropped under load.
**Why it happens:** Every change event triggers an RLS check for each subscribed user. With 100 subscribers, one INSERT triggers 100 authorization checks on a single thread.
**How to avoid:** For a portfolio app, this won't be an issue (< 10 concurrent users). If scaling later, consider using Realtime Broadcast to re-stream changes after server-side filtering. For now, keep tables in the `supabase_realtime` publication minimal.
**Warning signs:** Increasing latency between database write and Realtime callback.

### Pitfall 4: Position Gaps and Reordering Conflicts
**What goes wrong:** Two users reorder cards simultaneously, resulting in duplicate position values or unexpected ordering.
**Why it happens:** Optimistic UI updates position locally before the database confirms.
**How to avoid:** Use a "gap strategy" -- assign positions with gaps (e.g., 1000, 2000, 3000). When inserting between two items, use the midpoint. When gaps get too small (< 1), renormalize all positions in a single transaction. Last-write-wins naturally resolves most conflicts.
**Warning signs:** Cards appearing in wrong order after concurrent edits.

### Pitfall 5: Realtime Channel Leak
**What goes wrong:** Navigating between boards accumulates orphaned Realtime channels, degrading performance.
**Why it happens:** Channel not unsubscribed when leaving board detail screen.
**How to avoid:** Unsubscribe (call `_client.removeChannel(channel)`) in the widget's `dispose()` method or when the Riverpod provider is disposed. Supabase auto-cleans after 30 seconds of disconnect, but explicit cleanup is better practice.
**Warning signs:** Console warnings about multiple subscriptions, increasing memory usage.

### Pitfall 6: appflowy_board State Synchronization
**What goes wrong:** Board UI shows stale data because `AppFlowyBoardController` state diverges from Riverpod state after a Realtime update.
**Why it happens:** `AppFlowyBoardController` has its own internal state. When a Realtime event updates the Riverpod provider, the controller must also be updated.
**How to avoid:** Treat the Riverpod provider as the source of truth. When Riverpod state changes (from Realtime or local action), diff against the controller's current groups and apply incremental updates using `controller.addGroup()`, `controller.removeGroup()`, `controller.getGroupController(id)!.add()`, etc. Do NOT recreate the entire controller on every change -- that kills drag-and-drop mid-gesture.
**Warning signs:** Drag-and-drop resets mid-gesture, cards flickering or duplicating.

## Code Examples

### Database Schema (Migration)
```sql
-- Source: Supabase RLS docs + project patterns from 00001_create_profiles.sql

-- Board roles enum
CREATE TYPE board_role AS ENUM ('owner', 'editor', 'viewer');

-- Boards table
CREATE TABLE public.boards (
  id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
  name text NOT NULL,
  created_by uuid NOT NULL REFERENCES auth.users ON DELETE CASCADE,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Board members junction table
CREATE TABLE public.board_members (
  id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
  board_id uuid NOT NULL REFERENCES public.boards ON DELETE CASCADE,
  user_id uuid NOT NULL REFERENCES auth.users ON DELETE CASCADE,
  role board_role NOT NULL DEFAULT 'viewer',
  invited_at timestamptz DEFAULT now(),
  UNIQUE(board_id, user_id)
);

-- Board columns (Kanban columns)
CREATE TABLE public.board_columns (
  id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
  board_id uuid NOT NULL REFERENCES public.boards ON DELETE CASCADE,
  name text NOT NULL,
  position int NOT NULL DEFAULT 0,
  created_at timestamptz DEFAULT now()
);

-- Board cards
CREATE TABLE public.board_cards (
  id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
  board_id uuid NOT NULL REFERENCES public.boards ON DELETE CASCADE,
  column_id uuid NOT NULL REFERENCES public.board_columns ON DELETE CASCADE,
  title text NOT NULL,
  description text,
  assignee_id uuid REFERENCES auth.users,
  priority int DEFAULT 3, -- 1=P1(highest) to 4=P4(lowest)
  due_date timestamptz,
  position int NOT NULL DEFAULT 0,
  created_by uuid NOT NULL REFERENCES auth.users,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Enable RLS on all tables
ALTER TABLE public.boards ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.board_members ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.board_columns ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.board_cards ENABLE ROW LEVEL SECURITY;

-- Enable Realtime ONLY on tables that need it
ALTER PUBLICATION supabase_realtime ADD TABLE board_cards, board_columns;

-- Set replica identity full for DELETE event payloads
ALTER TABLE board_cards REPLICA IDENTITY FULL;
ALTER TABLE board_columns REPLICA IDENTITY FULL;

-- Indexes for RLS policy performance (critical per Supabase docs)
CREATE INDEX idx_board_members_user ON public.board_members(user_id);
CREATE INDEX idx_board_members_board ON public.board_members(board_id);
CREATE INDEX idx_board_members_board_user ON public.board_members(board_id, user_id);
CREATE INDEX idx_board_cards_board ON public.board_cards(board_id);
CREATE INDEX idx_board_cards_column ON public.board_cards(column_id);
CREATE INDEX idx_board_columns_board ON public.board_columns(board_id);

-- RLS Policies: boards
CREATE POLICY "Members can view boards"
  ON public.boards FOR SELECT TO authenticated
  USING (EXISTS (
    SELECT 1 FROM public.board_members
    WHERE board_members.board_id = boards.id
    AND board_members.user_id = (SELECT auth.uid())
  ));

CREATE POLICY "Authenticated users can create boards"
  ON public.boards FOR INSERT TO authenticated
  WITH CHECK ((SELECT auth.uid()) = created_by);

CREATE POLICY "Owners can update boards"
  ON public.boards FOR UPDATE TO authenticated
  USING (EXISTS (
    SELECT 1 FROM public.board_members
    WHERE board_members.board_id = boards.id
    AND board_members.user_id = (SELECT auth.uid())
    AND board_members.role = 'owner'
  ));

CREATE POLICY "Owners can delete boards"
  ON public.boards FOR DELETE TO authenticated
  USING (EXISTS (
    SELECT 1 FROM public.board_members
    WHERE board_members.board_id = boards.id
    AND board_members.user_id = (SELECT auth.uid())
    AND board_members.role = 'owner'
  ));

-- RLS Policies: board_members
CREATE POLICY "Members can view board members"
  ON public.board_members FOR SELECT TO authenticated
  USING (EXISTS (
    SELECT 1 FROM public.board_members AS bm
    WHERE bm.board_id = board_members.board_id
    AND bm.user_id = (SELECT auth.uid())
  ));

CREATE POLICY "Owners can manage members"
  ON public.board_members FOR INSERT TO authenticated
  WITH CHECK (EXISTS (
    SELECT 1 FROM public.board_members AS bm
    WHERE bm.board_id = board_members.board_id
    AND bm.user_id = (SELECT auth.uid())
    AND bm.role = 'owner'
  ) OR board_members.user_id = (SELECT auth.uid())); -- allow self-insert for board creator

CREATE POLICY "Owners can update member roles"
  ON public.board_members FOR UPDATE TO authenticated
  USING (EXISTS (
    SELECT 1 FROM public.board_members AS bm
    WHERE bm.board_id = board_members.board_id
    AND bm.user_id = (SELECT auth.uid())
    AND bm.role = 'owner'
  ));

CREATE POLICY "Owners can remove members"
  ON public.board_members FOR DELETE TO authenticated
  USING (EXISTS (
    SELECT 1 FROM public.board_members AS bm
    WHERE bm.board_id = board_members.board_id
    AND bm.user_id = (SELECT auth.uid())
    AND bm.role = 'owner'
  ) OR board_members.user_id = (SELECT auth.uid())); -- allow self-removal

-- RLS Policies: board_columns
CREATE POLICY "Members can view columns"
  ON public.board_columns FOR SELECT TO authenticated
  USING (EXISTS (
    SELECT 1 FROM public.board_members
    WHERE board_members.board_id = board_columns.board_id
    AND board_members.user_id = (SELECT auth.uid())
  ));

CREATE POLICY "Editors can insert columns"
  ON public.board_columns FOR INSERT TO authenticated
  WITH CHECK (EXISTS (
    SELECT 1 FROM public.board_members
    WHERE board_members.board_id = board_columns.board_id
    AND board_members.user_id = (SELECT auth.uid())
    AND board_members.role IN ('owner', 'editor')
  ));

CREATE POLICY "Editors can update columns"
  ON public.board_columns FOR UPDATE TO authenticated
  USING (EXISTS (
    SELECT 1 FROM public.board_members
    WHERE board_members.board_id = board_columns.board_id
    AND board_members.user_id = (SELECT auth.uid())
    AND board_members.role IN ('owner', 'editor')
  ));

CREATE POLICY "Editors can delete columns"
  ON public.board_columns FOR DELETE TO authenticated
  USING (EXISTS (
    SELECT 1 FROM public.board_members
    WHERE board_members.board_id = board_columns.board_id
    AND board_members.user_id = (SELECT auth.uid())
    AND board_members.role IN ('owner', 'editor')
  ));

-- RLS Policies: board_cards (same pattern as columns)
CREATE POLICY "Members can view cards"
  ON public.board_cards FOR SELECT TO authenticated
  USING (EXISTS (
    SELECT 1 FROM public.board_members
    WHERE board_members.board_id = board_cards.board_id
    AND board_members.user_id = (SELECT auth.uid())
  ));

CREATE POLICY "Editors can insert cards"
  ON public.board_cards FOR INSERT TO authenticated
  WITH CHECK (EXISTS (
    SELECT 1 FROM public.board_members
    WHERE board_members.board_id = board_cards.board_id
    AND board_members.user_id = (SELECT auth.uid())
    AND board_members.role IN ('owner', 'editor')
  ));

CREATE POLICY "Editors can update cards"
  ON public.board_cards FOR UPDATE TO authenticated
  USING (EXISTS (
    SELECT 1 FROM public.board_members
    WHERE board_members.board_id = board_cards.board_id
    AND board_members.user_id = (SELECT auth.uid())
    AND board_members.role IN ('owner', 'editor')
  ));

CREATE POLICY "Editors can delete cards"
  ON public.board_cards FOR DELETE TO authenticated
  USING (EXISTS (
    SELECT 1 FROM public.board_members
    WHERE board_members.board_id = board_cards.board_id
    AND board_members.user_id = (SELECT auth.uid())
    AND board_members.role IN ('owner', 'editor')
  ));
```

### Board Model (follows project Profile pattern)
```dart
// Source: project pattern from lib/features/profile/domain/profile_model.dart

enum BoardRole { owner, editor, viewer }

class Board {
  final String id;
  final String name;
  final String createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Board({
    required this.id,
    required this.name,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Board.fromJson(Map<String, dynamic> json) {
    return Board(
      id: json['id'] as String,
      name: json['name'] as String,
      createdBy: json['created_by'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'created_by': createdBy,
    'updated_at': DateTime.now().toIso8601String(),
  };

  Board copyWith({String? name}) {
    return Board(
      id: id,
      name: name ?? this.name,
      createdBy: createdBy,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}
```

### AppFlowyBoard Item Integration
```dart
// Custom item class that extends AppFlowyGroupItem for appflowy_board
class BoardCardItem extends AppFlowyGroupItem {
  final String cardId;
  final String title;
  final String? assigneeName;
  final String? assigneeAvatarUrl;
  final int priority;
  final DateTime? dueDate;

  BoardCardItem({
    required this.cardId,
    required this.title,
    this.assigneeName,
    this.assigneeAvatarUrl,
    this.priority = 3,
    this.dueDate,
  });

  @override
  String get id => cardId;
}
```

### Presence Indicator on Avatar
```dart
// Extends existing AvatarWidget with online status
class PresenceAvatar extends StatelessWidget {
  final String? displayName;
  final String? avatarUrl;
  final bool isOnline;
  final double radius;

  const PresenceAvatar({
    super.key,
    this.displayName,
    this.avatarUrl,
    this.isOnline = false,
    this.radius = 16,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Opacity(
          opacity: isOnline ? 1.0 : 0.5,
          child: AvatarWidget(
            displayName: displayName,
            avatarUrl: avatarUrl,
            radius: radius,
          ),
        ),
        if (isOnline)
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: Colors.green,
                shape: BoxShape.circle,
                border: Border.all(
                  color: Theme.of(context).colorScheme.surface,
                  width: 1.5,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| `supabase.channel().on()` | `supabase.channel().onPostgresChanges()` | supabase_flutter v2.0 (2024) | Type-safe callbacks with `PostgresChangePayload` |
| Manual presence with heartbeats | `onPresenceSync` / `onPresenceJoin` / `onPresenceLeave` | supabase_flutter v2.0 (2024) | Three typed presence methods replace single `.on('presence', ...)` |
| `Draggable` for mobile kanban | `LongPressDraggable` or package solutions | Flutter 3.x | Long-press prevents accidental drags during scroll |
| Custom board widget | `appflowy_board` | 2023-2024 | Purpose-built widget with cross-group drag, auto-scroll, builders |

**Deprecated/outdated:**
- `.on()` method for Realtime: Removed in supabase_flutter v2. Use `.onPostgresChanges()`, `.onBroadcast()`, and presence methods.
- `PostgresChangeFilter` string-based syntax: Replaced with typed `PostgresChangeFilter` object in v2.

## Open Questions

1. **Board creation + default columns atomicity**
   - What we know: When creating a board, we also need to create the owner membership row and 3 default columns.
   - What's unclear: Whether Supabase's Dart client supports multi-table transactions or if we need a database function.
   - Recommendation: Create a PostgreSQL function `create_board_with_defaults(name, user_id)` that inserts into `boards`, `board_members`, and `board_columns` in a single transaction. Call it via `.rpc()`.

2. **Invite flow: email-based vs user-ID-based**
   - What we know: Users enter an email to invite. We need to find the profile matching that email.
   - What's unclear: The profiles table doesn't store email -- that's in `auth.users`. RLS prevents reading other users' auth data.
   - Recommendation: Add an `email` column to `profiles` (populated by the signup trigger), or create a database function that looks up user_id by email (with `security definer`). The function approach is more secure.

3. **appflowy_board horizontal column sizing on mobile**
   - What we know: User wants columns to take ~85% screen width with horizontal swiping.
   - What's unclear: Whether `groupConstraints` with percentage-based width plays well with `appflowy_board`'s internal horizontal scroll.
   - Recommendation: Use `MediaQuery.of(context).size.width * 0.85` in `groupConstraints`. Test scrolling behavior. Fallback: wrap in `PageView` and disable `appflowy_board`'s native horizontal scroll.

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | flutter_test + mockito 5.4.4 |
| Config file | none -- Flutter SDK not installed on machine, tests verified via content |
| Quick run command | `flutter test test/unit/boards/` |
| Full suite command | `flutter test` |

### Phase Requirements to Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| BOARD-01 | Board/column/card models fromJson/toJson/copyWith | unit | `flutter test test/unit/boards/board_model_test.dart -x` | Wave 0 |
| BOARD-01 | BoardRepository CRUD operations | unit | `flutter test test/unit/boards/board_repository_test.dart -x` | Wave 0 |
| BOARD-01 | BoardCardItem extends AppFlowyGroupItem correctly | unit | `flutter test test/unit/boards/board_card_item_test.dart -x` | Wave 0 |
| BOARD-02 | BoardRealtimeService subscribes/unsubscribes correctly | unit | `flutter test test/unit/boards/board_realtime_service_test.dart -x` | Wave 0 |
| BOARD-02 | Realtime callback updates provider state | unit | `flutter test test/unit/boards/board_detail_provider_test.dart -x` | Wave 0 |
| BOARD-03 | BoardMember model with role enum | unit | `flutter test test/unit/boards/board_member_test.dart -x` | Wave 0 |
| BOARD-03 | BoardMemberRepository invite/role-change operations | unit | `flutter test test/unit/boards/board_member_repository_test.dart -x` | Wave 0 |
| BOARD-04 | Presence state parsing extracts online user list | unit | `flutter test test/unit/boards/board_presence_test.dart -x` | Wave 0 |
| BOARD-01 | RLS policies enforce membership access | manual-only | Requires live Supabase instance | N/A |
| BOARD-02 | Cross-device realtime sync | manual-only | Requires two connected clients | N/A |

### Sampling Rate
- **Per task commit:** `flutter test test/unit/boards/`
- **Per wave merge:** `flutter test`
- **Phase gate:** Full suite green before `/gsd:verify-work`

### Wave 0 Gaps
- [ ] `test/unit/boards/board_model_test.dart` -- covers BOARD-01 model layer
- [ ] `test/unit/boards/board_repository_test.dart` -- covers BOARD-01 CRUD
- [ ] `test/unit/boards/board_card_item_test.dart` -- covers BOARD-01 appflowy integration
- [ ] `test/unit/boards/board_realtime_service_test.dart` -- covers BOARD-02
- [ ] `test/unit/boards/board_detail_provider_test.dart` -- covers BOARD-02 state
- [ ] `test/unit/boards/board_member_test.dart` -- covers BOARD-03
- [ ] `test/unit/boards/board_member_repository_test.dart` -- covers BOARD-03
- [ ] `test/unit/boards/board_presence_test.dart` -- covers BOARD-04

## Sources

### Primary (HIGH confidence)
- [Supabase Dart API Reference - Subscribe](https://supabase.com/docs/reference/dart/subscribe) -- onPostgresChanges, onPresenceSync, onPresenceJoin, onPresenceLeave full API
- [Supabase Postgres Changes](https://supabase.com/docs/guides/realtime/postgres-changes) -- RLS interaction, replica identity, publication setup
- [Supabase Presence Docs](https://supabase.com/docs/guides/realtime/presence) -- Presence payload, track, sync events
- [Supabase RLS Docs](https://supabase.com/docs/guides/database/postgres/row-level-security) -- Policy patterns, performance tips, `(SELECT auth.uid())` caching
- [appflowy_board GitHub README](https://github.com/AppFlowy-IO/appflowy-board) -- Controller API, builder pattern, callbacks
- [appflowy_board pub.dev](https://pub.dev/packages/appflowy_board) -- Version 0.1.2, 223 likes, MPL-2.0 dual license
- [Flutter LongPressDraggable API](https://api.flutter.dev/flutter/widgets/LongPressDraggable-class.html) -- Built-in drag widget reference
- [RealtimeChannel class docs](https://pub.dev/documentation/supabase_flutter/latest/supabase_flutter/RealtimeChannel-class.html) -- Full typed API reference

### Secondary (MEDIUM confidence)
- [Supabase RBAC Guide](https://supabase.com/docs/guides/database/postgres/custom-claims-and-role-based-access-control-rbac) -- Custom claims pattern for roles
- [Multi-Tenant RLS on Supabase](https://www.antstack.com/blog/multi-tenant-applications-with-rls-on-supabase-postgress/) -- Multi-tenant RLS patterns applicable to board access

### Tertiary (LOW confidence)
- [kanban_board pub.dev](https://pub.dev/packages/kanban_board) -- Alternative evaluated; depends on flutter_riverpod ^2.3.6 (incompatible)
- [boardview pub.dev](https://pub.dev/packages/boardview) -- Alternative evaluated; unverified publisher

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH -- All libraries are well-documented with official APIs confirmed via docs
- Architecture: HIGH -- Patterns follow established project conventions (Clean Architecture, Riverpod) and verified Supabase Realtime API
- Pitfalls: HIGH -- Documented in official Supabase docs (RLS + Realtime interactions, replica identity, publication setup)
- Drag-and-drop library choice: MEDIUM -- appflowy_board is the best available option but last updated Apr 2024; may need minor workarounds for Flutter 3.29 compatibility

**Research date:** 2026-03-18
**Valid until:** 2026-04-17 (30 days -- stable domain, all libraries mature)
