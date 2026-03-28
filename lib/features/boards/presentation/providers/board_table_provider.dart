import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/board_card_repository.dart';
import '../../data/board_group_repository.dart';
import '../../data/board_repository.dart';
import '../../domain/board_model.dart';
import '../../domain/board_table_column.dart';
import 'board_detail_provider.dart';
import 'board_list_provider.dart';

/// Provides a [BoardGroupRepository] instance to the widget tree.
final boardGroupRepositoryProvider = Provider<BoardGroupRepository>((ref) {
  return BoardGroupRepository();
});

/// Table-specific state that is independent from the board detail state.
///
/// Manages editing cell tracking, column widths, collapsed groups,
/// and resize state for the Monday.com-style table view.
class BoardTableState {
  /// Currently editing cell in "{cardId}_{columnId}" format.
  /// Only one cell can be in edit mode at a time.
  final String? editingCellId;

  /// Column widths keyed by column def id. Initialised from
  /// [BoardMetadata.columnDefs] and updated during resize.
  final Map<String, double> columnWidths;

  /// IDs of groups that are currently collapsed (rows hidden).
  final Set<String> collapsedGroupIds;

  /// True while a column resize drag is in progress. Disables
  /// horizontal scrolling to prevent scroll fighting.
  final bool isResizing;

  const BoardTableState({
    this.editingCellId,
    this.columnWidths = const {},
    this.collapsedGroupIds = const {},
    this.isResizing = false,
  });

  BoardTableState copyWith({
    String? editingCellId,
    bool clearEditing = false,
    Map<String, double>? columnWidths,
    Set<String>? collapsedGroupIds,
    bool? isResizing,
  }) {
    return BoardTableState(
      editingCellId:
          clearEditing ? null : (editingCellId ?? this.editingCellId),
      columnWidths: columnWidths ?? this.columnWidths,
      collapsedGroupIds: collapsedGroupIds ?? this.collapsedGroupIds,
      isResizing: isResizing ?? this.isResizing,
    );
  }
}

/// Provider for table-specific state, keyed by board ID.
final boardTableProvider =
    StateNotifierProvider.family<BoardTableNotifier, BoardTableState, String>(
  (ref, boardId) => BoardTableNotifier(ref, boardId),
);

/// Manages table-view state: editing cell, column widths, collapsed groups,
/// row reorder within groups, and column reorder.
class BoardTableNotifier extends StateNotifier<BoardTableState> {
  BoardTableNotifier(this._ref, String boardId)
      : super(const BoardTableState());

  final Ref _ref;
  Timer? _resizeDebounce;

  @override
  void dispose() {
    _resizeDebounce?.cancel();
    super.dispose();
  }

  // ---------------------------------------------------------------
  // Initialisation
  // ---------------------------------------------------------------

  /// Populate [columnWidths] from the board metadata column definitions.
  /// Called once on first build of the table widget.
  void initFromMetadata(BoardMetadata metadata) {
    final widths = <String, double>{};
    for (final col in metadata.columnDefs) {
      widths[col.id] = col.width;
    }
    state = state.copyWith(columnWidths: widths);
  }

  // ---------------------------------------------------------------
  // Editing
  // ---------------------------------------------------------------

  /// Sets the currently editing cell. Previous cell auto-saves via UI.
  void startEditing(String cellId) {
    state = state.copyWith(editingCellId: cellId);
  }

  /// Clears the editing cell.
  void stopEditing() {
    state = state.copyWith(clearEditing: true);
  }

  // ---------------------------------------------------------------
  // Column resize
  // ---------------------------------------------------------------

  /// Updates a column width by [delta], clamped to 60-400 px.
  void resizeColumn(String columnId, double delta) {
    final current = state.columnWidths[columnId] ?? 150;
    final newWidth = (current + delta).clamp(60.0, 400.0);
    final updated = Map<String, double>.from(state.columnWidths);
    updated[columnId] = newWidth;
    state = state.copyWith(columnWidths: updated, isResizing: true);
  }

  /// Ends the resize gesture. Debounces 500ms then persists widths
  /// to board metadata via [BoardRepository.updateMetadata].
  void endResize(String boardId) {
    state = state.copyWith(isResizing: false);

    _resizeDebounce?.cancel();
    _resizeDebounce = Timer(const Duration(milliseconds: 500), () {
      _persistColumnWidths(boardId);
    });
  }

  Future<void> _persistColumnWidths(String boardId) async {
    final detailState = _ref.read(boardDetailProvider(boardId));
    final board = detailState.board;
    if (board == null) return;

    final updatedDefs = board.metadata.columnDefs.map((col) {
      final w = state.columnWidths[col.id];
      return w != null ? col.copyWith(width: w) : col;
    }).toList();

    final updatedMetadata = BoardMetadata(
      columnDefs: updatedDefs,
      statusLabels: board.metadata.statusLabels,
      groups: board.metadata.groups,
    );

    final boardRepo = _ref.read(boardRepositoryProvider);
    await boardRepo.updateMetadata(boardId, updatedMetadata.toJson());
  }

  // ---------------------------------------------------------------
  // Group collapse
  // ---------------------------------------------------------------

  /// Toggles whether a group's rows are visible.
  void toggleGroupCollapse(String groupId) {
    final updated = Set<String>.from(state.collapsedGroupIds);
    if (updated.contains(groupId)) {
      updated.remove(groupId);
    } else {
      updated.add(groupId);
    }
    state = state.copyWith(collapsedGroupIds: updated);
  }

  // ---------------------------------------------------------------
  // Card field update (inline editing)
  // ---------------------------------------------------------------

  /// Delegates inline cell edits to [BoardDetailNotifier.updateCardField].
  Future<void> updateCardField(
    String boardId,
    String cardId,
    String fieldKey,
    dynamic value,
  ) async {
    await _ref
        .read(boardDetailProvider(boardId).notifier)
        .updateCardField(cardId, fieldKey, value);
  }

  /// Delegates batch field updates to [BoardDetailNotifier.updateCardFields].
  ///
  /// Use this when multiple related fields must be updated atomically
  /// (e.g. status_label + status_color) to avoid race conditions.
  Future<void> updateCardFields(
    String boardId,
    String cardId,
    Map<String, dynamic> fields,
  ) async {
    await _ref
        .read(boardDetailProvider(boardId).notifier)
        .updateCardFields(cardId, fields);
  }

  // ---------------------------------------------------------------
  // Row reorder within a group
  // ---------------------------------------------------------------

  /// Reorders a card within its group by moving it from [oldIndex] to
  /// [newIndex]. Optimistically updates state, then persists positions
  /// via [BoardCardRepository.updateCard]. Rolls back on failure.
  Future<void> reorderCard(
    String boardId,
    String groupId,
    int oldIndex,
    int newIndex,
  ) async {
    final detailNotifier = _ref.read(boardDetailProvider(boardId).notifier);
    final detailState = _ref.read(boardDetailProvider(boardId));

    // Collect all cards from all columns
    final allCards =
        detailState.cardsByColumn.values.expand((c) => c).toList();

    // Filter to this group, sorted by position
    final groupCards = allCards
        .where((c) => c.groupId == groupId)
        .toList()
      ..sort((a, b) => a.position.compareTo(b.position));

    if (oldIndex < 0 || oldIndex >= groupCards.length) return;
    if (newIndex < 0 || newIndex >= groupCards.length) return;

    // Save pre-reorder state for rollback
    final oldCardsByColumn = Map<String, List<BoardCard>>.from(
      detailState.cardsByColumn
          .map((k, v) => MapEntry(k, List<BoardCard>.from(v))),
    );

    // Reorder
    final card = groupCards.removeAt(oldIndex);
    groupCards.insert(newIndex, card);

    // Recalculate positions using gap-based strategy
    for (int i = 0; i < groupCards.length; i++) {
      groupCards[i] = groupCards[i].copyWith(position: (i + 1) * 1000);
    }

    // Optimistically update the detail state
    final updatedCardsByColumn = Map<String, List<BoardCard>>.from(
      detailState.cardsByColumn
          .map((k, v) => MapEntry(k, List<BoardCard>.from(v))),
    );

    for (final updated in groupCards) {
      for (final entry in updatedCardsByColumn.entries) {
        final idx = entry.value.indexWhere((c) => c.id == updated.id);
        if (idx != -1) {
          entry.value[idx] = updated;
          break;
        }
      }
    }

    detailNotifier.setCardsByColumn(updatedCardsByColumn);

    // Persist
    try {
      final cardRepo = _ref.read(boardCardRepositoryProvider);
      await Future.wait(
        groupCards
            .map((c) => cardRepo.updateCard(c.id, position: c.position)),
      );
    } catch (_) {
      // Rollback
      detailNotifier.setCardsByColumn(oldCardsByColumn);
    }
  }

  // ---------------------------------------------------------------
  // Column reorder
  // ---------------------------------------------------------------

  /// Reorders a column definition by moving it to [newIndex].
  /// Optimistically updates the metadata column order and persists
  /// the updated metadata to the board.
  Future<void> reorderColumn(
    String boardId,
    String columnId,
    int newIndex,
  ) async {
    final detailState = _ref.read(boardDetailProvider(boardId));
    final board = detailState.board;
    if (board == null) return;

    final columns = List<TableColumnDef>.from(board.metadata.columnDefs);
    final oldIndex = columns.indexWhere((c) => c.id == columnId);
    if (oldIndex == -1) return;

    final column = columns.removeAt(oldIndex);
    columns.insert(newIndex, column);

    // Recalculate positions
    for (int i = 0; i < columns.length; i++) {
      columns[i] = columns[i].copyWith(position: (i + 1) * 1000);
    }

    final updatedMetadata = BoardMetadata(
      columnDefs: columns,
      statusLabels: board.metadata.statusLabels,
      groups: board.metadata.groups,
    );

    // Optimistic update
    final updatedBoard = board.copyWith(metadata: updatedMetadata);
    _ref.read(boardDetailProvider(boardId).notifier).setBoard(updatedBoard);

    // Update column widths map order
    final widths = <String, double>{};
    for (final col in columns) {
      widths[col.id] = state.columnWidths[col.id] ?? col.width;
    }
    state = state.copyWith(columnWidths: widths);

    // Persist
    try {
      final boardRepo = _ref.read(boardRepositoryProvider);
      await boardRepo.updateMetadata(boardId, updatedMetadata.toJson());
    } catch (_) {
      // Rollback
      _ref
          .read(boardDetailProvider(boardId).notifier)
          .setBoard(board);
    }
  }
}
