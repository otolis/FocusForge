import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/board_column_repository.dart';
import '../../data/board_card_repository.dart';
import '../../data/board_member_repository.dart';
import '../../domain/board_model.dart';
import '../../domain/board_role.dart';
import '../../domain/board_table_column.dart';
import 'board_list_provider.dart';

/// Provides a [BoardColumnRepository] instance to the widget tree.
final boardColumnRepositoryProvider = Provider<BoardColumnRepository>((ref) {
  return BoardColumnRepository();
});

/// Provides a [BoardCardRepository] instance to the widget tree.
final boardCardRepositoryProvider = Provider<BoardCardRepository>((ref) {
  return BoardCardRepository();
});

/// Provides a [BoardMemberRepository] instance to the widget tree.
final boardMemberRepositoryProvider = Provider<BoardMemberRepository>((ref) {
  return BoardMemberRepository();
});

/// State for a single board, including its columns, cards, members,
/// and the current user's role.
class BoardDetailState {
  final Board? board;
  final List<BoardColumn> columns;
  final Map<String, List<BoardCard>> cardsByColumn;
  final List<BoardMember> members;
  final BoardRole currentUserRole;
  final bool isLoading;
  final String? error;

  const BoardDetailState({
    this.board,
    this.columns = const [],
    this.cardsByColumn = const {},
    this.members = const [],
    this.currentUserRole = BoardRole.viewer,
    this.isLoading = true,
    this.error,
  });

  BoardDetailState copyWith({
    Board? board,
    List<BoardColumn>? columns,
    Map<String, List<BoardCard>>? cardsByColumn,
    List<BoardMember>? members,
    BoardRole? currentUserRole,
    bool? isLoading,
    String? error,
  }) {
    return BoardDetailState(
      board: board ?? this.board,
      columns: columns ?? this.columns,
      cardsByColumn: cardsByColumn ?? this.cardsByColumn,
      members: members ?? this.members,
      currentUserRole: currentUserRole ?? this.currentUserRole,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }

  /// Whether the current user can edit (add/move/update cards, manage columns).
  bool get canEdit =>
      currentUserRole == BoardRole.owner ||
      currentUserRole == BoardRole.editor;

  /// Whether the current user is the board owner.
  bool get isOwner => currentUserRole == BoardRole.owner;
}

/// Manages the state for a single board detail view.
///
/// Family provider keyed by board ID. Loads board, columns, cards,
/// members, and user role on creation. Provides optimistic UI for
/// card moves and edits, plus callbacks for realtime integration.
final boardDetailProvider = StateNotifierProvider.family<
    BoardDetailNotifier, BoardDetailState, String>(
  (ref, boardId) => BoardDetailNotifier(ref, boardId),
);

class BoardDetailNotifier extends StateNotifier<BoardDetailState> {
  BoardDetailNotifier(this._ref, this._boardId)
      : super(const BoardDetailState()) {
    _load();
  }

  final Ref _ref;
  final String _boardId;

  /// Loads all board data in parallel.
  Future<void> _load() async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      final boardRepo = _ref.read(boardRepositoryProvider);
      final columnRepo = _ref.read(boardColumnRepositoryProvider);
      final cardRepo = _ref.read(boardCardRepositoryProvider);
      final memberRepo = _ref.read(boardMemberRepositoryProvider);

      final results = await Future.wait([
        boardRepo.getBoard(_boardId),
        columnRepo.getColumns(_boardId),
        cardRepo.getCards(_boardId),
        memberRepo.getMembers(_boardId),
        memberRepo.getCurrentUserRole(_boardId),
      ]);

      final board = results[0] as Board;
      final columns = results[1] as List<BoardColumn>;
      final cards = results[2] as List<BoardCard>;
      final members = results[3] as List<BoardMember>;
      final role = results[4] as BoardRole;

      // Group cards by column ID
      final cardsByColumn = <String, List<BoardCard>>{};
      for (final col in columns) {
        cardsByColumn[col.id] = [];
      }
      for (final card in cards) {
        cardsByColumn.putIfAbsent(card.columnId, () => []);
        cardsByColumn[card.columnId]!.add(card);
      }

      state = state.copyWith(
        board: board,
        columns: columns,
        cardsByColumn: cardsByColumn,
        members: members,
        currentUserRole: role,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Optimistic card move between columns.
  ///
  /// Updates local state immediately, then persists to Supabase.
  /// After inserting the moved card, re-normalizes positions in the
  /// destination column (1000, 2000, 3000...) to prevent duplicate
  /// position values. Rolls back on failure.
  Future<void> moveCard({
    required String cardId,
    required String fromColumnId,
    required String toColumnId,
    required int newPosition,
  }) async {
    // Save old state for rollback
    final oldCardsByColumn = Map<String, List<BoardCard>>.from(
      state.cardsByColumn
          .map((k, v) => MapEntry(k, List<BoardCard>.from(v))),
    );

    // Optimistic update
    final updatedCardsByColumn = Map<String, List<BoardCard>>.from(
      state.cardsByColumn
          .map((k, v) => MapEntry(k, List<BoardCard>.from(v))),
    );

    final fromCards = updatedCardsByColumn[fromColumnId] ?? [];
    final cardIndex = fromCards.indexWhere((c) => c.id == cardId);
    if (cardIndex == -1) return;

    final card = fromCards.removeAt(cardIndex);
    final movedCard = card.copyWith(
      columnId: toColumnId,
      position: newPosition,
    );

    final toCards = updatedCardsByColumn[toColumnId] ?? [];
    // Insert at the correct position based on newPosition value
    int insertIndex = toCards.indexWhere((c) => c.position > newPosition);
    if (insertIndex == -1) insertIndex = toCards.length;
    toCards.insert(insertIndex, movedCard);

    // Re-normalize positions in destination column to prevent duplicates
    for (int i = 0; i < toCards.length; i++) {
      toCards[i] = toCards[i].copyWith(position: (i + 1) * 1000);
    }

    updatedCardsByColumn[fromColumnId] = fromCards;
    updatedCardsByColumn[toColumnId] = toCards;
    state = state.copyWith(cardsByColumn: updatedCardsByColumn);

    // Persist all destination column cards with normalized positions
    try {
      final cardRepo = _ref.read(boardCardRepositoryProvider);
      await Future.wait(
        toCards.map((c) => cardRepo.updateCard(
              c.id,
              columnId: toColumnId,
              position: c.position,
            )),
      );
    } catch (e) {
      // Rollback
      state = state.copyWith(cardsByColumn: oldCardsByColumn);
    }
  }

  /// Optimistic card reorder within the same column.
  Future<void> reorderCard(
      String columnId, int oldIndex, int newIndex) async {
    final oldCardsByColumn = Map<String, List<BoardCard>>.from(
      state.cardsByColumn
          .map((k, v) => MapEntry(k, List<BoardCard>.from(v))),
    );

    final updatedCardsByColumn = Map<String, List<BoardCard>>.from(
      state.cardsByColumn
          .map((k, v) => MapEntry(k, List<BoardCard>.from(v))),
    );

    final cards = updatedCardsByColumn[columnId] ?? [];
    if (oldIndex < 0 || oldIndex >= cards.length) return;
    if (newIndex < 0 || newIndex >= cards.length) return;

    final card = cards.removeAt(oldIndex);
    cards.insert(newIndex, card);

    // Recalculate positions with gap strategy
    for (int i = 0; i < cards.length; i++) {
      cards[i] = cards[i].copyWith(position: (i + 1) * 1000);
    }

    updatedCardsByColumn[columnId] = cards;
    state = state.copyWith(cardsByColumn: updatedCardsByColumn);

    // Persist position changes
    try {
      final cardRepo = _ref.read(boardCardRepositoryProvider);
      await Future.wait(
        cards.map((c) => cardRepo.updateCard(c.id, position: c.position)),
      );
    } catch (e) {
      state = state.copyWith(cardsByColumn: oldCardsByColumn);
    }
  }

  /// Adds a new card to a column.
  Future<void> addCard({
    required String columnId,
    required String title,
    String? description,
    int priority = 3,
    DateTime? dueDate,
  }) async {
    final cardsInColumn = state.cardsByColumn[columnId] ?? [];
    final lastPosition =
        cardsInColumn.isEmpty ? 0 : cardsInColumn.last.position;
    final newPosition = lastPosition + 1000;

    final cardRepo = _ref.read(boardCardRepositoryProvider);
    final card = await cardRepo.createCard(
      boardId: _boardId,
      columnId: columnId,
      title: title,
      description: description,
      priority: priority,
      dueDate: dueDate,
      position: newPosition,
    );

    final updatedCardsByColumn = Map<String, List<BoardCard>>.from(
      state.cardsByColumn
          .map((k, v) => MapEntry(k, List<BoardCard>.from(v))),
    );
    updatedCardsByColumn.putIfAbsent(columnId, () => []);
    updatedCardsByColumn[columnId]!.add(card);
    state = state.copyWith(cardsByColumn: updatedCardsByColumn);
  }

  /// Updates a card's mutable fields.
  Future<void> updateCard(
    String cardId, {
    String? title,
    String? description,
    String? assigneeId,
    int? priority,
    DateTime? dueDate,
  }) async {
    final cardRepo = _ref.read(boardCardRepositoryProvider);
    await cardRepo.updateCard(
      cardId,
      title: title,
      description: description,
      assigneeId: assigneeId,
      priority: priority,
      dueDate: dueDate,
    );

    // Update local state
    final updatedCardsByColumn = Map<String, List<BoardCard>>.from(
      state.cardsByColumn
          .map((k, v) => MapEntry(k, List<BoardCard>.from(v))),
    );

    for (final entry in updatedCardsByColumn.entries) {
      final idx = entry.value.indexWhere((c) => c.id == cardId);
      if (idx != -1) {
        entry.value[idx] = entry.value[idx].copyWith(
          title: title,
          description: description,
          assigneeId: assigneeId,
          priority: priority,
          dueDate: dueDate,
        );
        break;
      }
    }

    state = state.copyWith(cardsByColumn: updatedCardsByColumn);
  }

  /// Deletes a card optimistically.
  Future<void> deleteCard(String cardId, String columnId) async {
    final oldCardsByColumn = Map<String, List<BoardCard>>.from(
      state.cardsByColumn
          .map((k, v) => MapEntry(k, List<BoardCard>.from(v))),
    );

    final updatedCardsByColumn = Map<String, List<BoardCard>>.from(
      state.cardsByColumn
          .map((k, v) => MapEntry(k, List<BoardCard>.from(v))),
    );
    updatedCardsByColumn[columnId]?.removeWhere((c) => c.id == cardId);
    state = state.copyWith(cardsByColumn: updatedCardsByColumn);

    try {
      final cardRepo = _ref.read(boardCardRepositoryProvider);
      await cardRepo.deleteCard(cardId);
    } catch (e) {
      state = state.copyWith(cardsByColumn: oldCardsByColumn);
    }
  }

  /// Adds a new column to the board.
  Future<void> addColumn(String name) async {
    final lastPosition =
        state.columns.isEmpty ? 0 : state.columns.last.position;
    final newPosition = lastPosition + 1000;

    final columnRepo = _ref.read(boardColumnRepositoryProvider);
    final column = await columnRepo.createColumn(
      boardId: _boardId,
      name: name,
      position: newPosition,
    );

    state = state.copyWith(
      columns: [...state.columns, column],
      cardsByColumn: {
        ...state.cardsByColumn,
        column.id: <BoardCard>[],
      },
    );
  }

  /// Renames a column.
  Future<void> renameColumn(String columnId, String newName) async {
    final columnRepo = _ref.read(boardColumnRepositoryProvider);
    await columnRepo.updateColumn(columnId, name: newName);

    state = state.copyWith(
      columns: state.columns
          .map((c) => c.id == columnId ? c.copyWith(name: newName) : c)
          .toList(),
    );
  }

  /// Deletes a column and its cards.
  Future<void> deleteColumn(String columnId) async {
    final columnRepo = _ref.read(boardColumnRepositoryProvider);
    await columnRepo.deleteColumn(columnId);

    final updatedCardsByColumn =
        Map<String, List<BoardCard>>.from(state.cardsByColumn);
    updatedCardsByColumn.remove(columnId);

    state = state.copyWith(
      columns: state.columns.where((c) => c.id != columnId).toList(),
      cardsByColumn: updatedCardsByColumn,
    );
  }

  /// Called by the realtime service when a card change arrives from
  /// another user.
  ///
  /// Applies INSERT, UPDATE, or DELETE changes to the local state.
  void onRemoteCardChange(BoardCard card, String eventType) {
    final updatedCardsByColumn = Map<String, List<BoardCard>>.from(
      state.cardsByColumn
          .map((k, v) => MapEntry(k, List<BoardCard>.from(v))),
    );

    switch (eventType.toUpperCase()) {
      case 'INSERT':
        updatedCardsByColumn.putIfAbsent(card.columnId, () => []);
        // Avoid duplicates (might be our own optimistic insert)
        if (!updatedCardsByColumn[card.columnId]!
            .any((c) => c.id == card.id)) {
          updatedCardsByColumn[card.columnId]!.add(card);
          updatedCardsByColumn[card.columnId]!
              .sort((a, b) => a.position.compareTo(b.position));
        }
        break;

      case 'UPDATE':
        // Remove from old column (may have moved)
        for (final entry in updatedCardsByColumn.entries) {
          entry.value.removeWhere((c) => c.id == card.id);
        }
        // Add to current column
        updatedCardsByColumn.putIfAbsent(card.columnId, () => []);
        updatedCardsByColumn[card.columnId]!.add(card);
        updatedCardsByColumn[card.columnId]!
            .sort((a, b) => a.position.compareTo(b.position));
        break;

      case 'DELETE':
        for (final entry in updatedCardsByColumn.entries) {
          entry.value.removeWhere((c) => c.id == card.id);
        }
        break;
    }

    state = state.copyWith(cardsByColumn: updatedCardsByColumn);
  }

  /// Called by the realtime service when a column change arrives from
  /// another user.
  void onRemoteColumnChange(BoardColumn column, String eventType) {
    switch (eventType.toUpperCase()) {
      case 'INSERT':
        if (!state.columns.any((c) => c.id == column.id)) {
          final updatedColumns = [...state.columns, column];
          updatedColumns.sort((a, b) => a.position.compareTo(b.position));
          final updatedCardsByColumn =
              Map<String, List<BoardCard>>.from(state.cardsByColumn);
          updatedCardsByColumn.putIfAbsent(column.id, () => []);
          state = state.copyWith(
            columns: updatedColumns,
            cardsByColumn: updatedCardsByColumn,
          );
        }
        break;

      case 'UPDATE':
        state = state.copyWith(
          columns: state.columns
              .map((c) => c.id == column.id ? column : c)
              .toList()
            ..sort((a, b) => a.position.compareTo(b.position)),
        );
        break;

      case 'DELETE':
        final updatedCardsByColumn =
            Map<String, List<BoardCard>>.from(state.cardsByColumn);
        updatedCardsByColumn.remove(column.id);
        state = state.copyWith(
          columns: state.columns.where((c) => c.id != column.id).toList(),
          cardsByColumn: updatedCardsByColumn,
        );
        break;
    }
  }

  // ─── Table-view helpers ─────────────────────────────

  /// Directly sets the cards-by-column map. Used by [BoardTableNotifier]
  /// for optimistic row reorder updates and rollbacks.
  void setCardsByColumn(Map<String, List<BoardCard>> cardsByColumn) {
    state = state.copyWith(cardsByColumn: cardsByColumn);
  }

  /// Directly sets the board object. Used by [BoardTableNotifier]
  /// for optimistic column reorder metadata updates and rollbacks.
  void setBoard(Board board) {
    state = state.copyWith(board: board);
  }

  /// Updates a single field on a card. Used by table view inline editing.
  ///
  /// Optimistically updates local state, then persists to Supabase.
  /// Rolls back on failure.
  Future<void> updateCardField(
      String cardId, String field, dynamic value) async {
    final oldState = state;
    // Optimistic update
    _updateCardInState(cardId, field, value);
    try {
      final cardRepo = _ref.read(boardCardRepositoryProvider);
      switch (field) {
        case 'status_label':
          await cardRepo.updateCard(cardId, statusLabel: value as String?);
        case 'status_color':
          await cardRepo.updateCard(cardId, statusColor: value as String?);
        case 'priority':
          await cardRepo.updateCard(cardId, priority: value as int?);
        case 'assignee_id':
          await cardRepo.updateCard(cardId, assigneeId: value as String?);
        case 'due_date':
          await cardRepo.updateCard(cardId, dueDate: value as DateTime?);
        case 'start_date':
          await cardRepo.updateCard(cardId, startDate: value as DateTime?);
        case 'title':
          await cardRepo.updateCard(cardId, title: value as String?);
        case 'description':
          await cardRepo.updateCard(cardId, description: value as String?);
        case 'group_id':
          await cardRepo.updateCard(cardId, groupId: value as String?);
        default:
          // Custom field -- update customFields JSONB
          final card = _findCard(cardId);
          if (card != null) {
            final updatedCustom =
                Map<String, dynamic>.from(card.customFields);
            updatedCustom[field] = value;
            await cardRepo.updateCard(cardId, customFields: updatedCustom);
          }
      }
    } catch (e) {
      state = oldState; // Rollback
    }
  }

  /// Adds a new card to a specific group via the table view's AddItemRow.
  ///
  /// Places the card in the first Kanban column with the given [groupId].
  Future<void> addCardToGroup({
    required String groupId,
    required String title,
  }) async {
    final firstColumn =
        state.columns.isNotEmpty ? state.columns.first : null;
    if (firstColumn == null) return;

    final cardRepo = _ref.read(boardCardRepositoryProvider);
    final allCards =
        state.cardsByColumn.values.expand((c) => c).toList();
    final groupCards =
        allCards.where((c) => c.groupId == groupId).toList();
    final lastPos = groupCards.isEmpty
        ? 0
        : groupCards
            .map((c) => c.position)
            .reduce((a, b) => a > b ? a : b);

    final card = await cardRepo.createCard(
      boardId: _boardId,
      columnId: firstColumn.id,
      title: title,
      position: lastPos + 1000,
      groupId: groupId,
    );

    final updatedCardsByColumn = Map<String, List<BoardCard>>.from(
      state.cardsByColumn
          .map((k, v) => MapEntry(k, List<BoardCard>.from(v))),
    );
    updatedCardsByColumn.putIfAbsent(firstColumn.id, () => []);
    updatedCardsByColumn[firstColumn.id]!.add(card);
    state = state.copyWith(cardsByColumn: updatedCardsByColumn);
  }

  /// Updates the board's table-view metadata and persists to Supabase.
  Future<void> updateBoardMetadata(BoardMetadata metadata) async {
    final boardRepo = _ref.read(boardRepositoryProvider);
    await boardRepo.updateMetadata(_boardId, metadata.toJson());
    state = state.copyWith(board: state.board?.copyWith(metadata: metadata));
  }

  // ─── Private helpers ──────────────────────────────

  /// Finds a card by ID across all columns.
  BoardCard? _findCard(String cardId) {
    for (final cards in state.cardsByColumn.values) {
      for (final card in cards) {
        if (card.id == cardId) return card;
      }
    }
    return null;
  }

  /// Updates a single field on a card in local state.
  void _updateCardInState(String cardId, String field, dynamic value) {
    final updatedCardsByColumn = Map<String, List<BoardCard>>.from(
      state.cardsByColumn
          .map((k, v) => MapEntry(k, List<BoardCard>.from(v))),
    );

    for (final entry in updatedCardsByColumn.entries) {
      final idx = entry.value.indexWhere((c) => c.id == cardId);
      if (idx != -1) {
        final card = entry.value[idx];
        BoardCard updated;
        switch (field) {
          case 'status_label':
            updated = card.copyWith(statusLabel: value as String?);
          case 'status_color':
            updated = card.copyWith(statusColor: value as String?);
          case 'priority':
            updated = card.copyWith(priority: value as int?);
          case 'assignee_id':
            updated = card.copyWith(assigneeId: value as String?);
          case 'due_date':
            updated = card.copyWith(dueDate: value as DateTime?);
          case 'start_date':
            updated = card.copyWith(startDate: value as DateTime?);
          case 'title':
            updated = card.copyWith(title: value as String?);
          case 'description':
            updated = card.copyWith(description: value as String?);
          case 'group_id':
            updated = card.copyWith(groupId: value as String?);
          default:
            // Custom field
            final customFields =
                Map<String, dynamic>.from(card.customFields);
            customFields[field] = value;
            updated = card.copyWith(customFields: customFields);
        }
        entry.value[idx] = updated;
        break;
      }
    }

    state = state.copyWith(cardsByColumn: updatedCardsByColumn);
  }

  /// Refreshes all data from the server.
  Future<void> refresh() async {
    await _load();
  }
}
