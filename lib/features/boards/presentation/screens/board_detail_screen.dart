import 'package:appflowy_board/appflowy_board.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/extensions.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../domain/board_model.dart';
import '../providers/board_detail_provider.dart';
import '../providers/board_realtime_provider.dart';
import '../widgets/card_detail_sheet.dart';
import '../widgets/column_header_widget.dart';
import '../widgets/empty_column_placeholder.dart';
import '../widgets/kanban_card_widget.dart';

/// Custom item class that extends [AppFlowyGroupItem] to bridge
/// [BoardCard] domain objects with the appflowy_board widget.
class BoardCardItem extends AppFlowyGroupItem {
  final BoardCard card;

  BoardCardItem({required this.card});

  @override
  String get id => card.id;
}

/// Full-screen Kanban board view using [AppFlowyBoard].
///
/// Displays board columns as horizontally scrollable groups, each
/// taking 85% of screen width. Cards are long-press draggable between
/// columns. Watches [boardDetailProvider] for state and activates
/// [boardRealtimeProvider] for live updates from other users.
class BoardDetailScreen extends ConsumerStatefulWidget {
  const BoardDetailScreen({super.key, required this.boardId});

  /// The ID of the board to display.
  final String boardId;

  @override
  ConsumerState<BoardDetailScreen> createState() => _BoardDetailScreenState();
}

class _BoardDetailScreenState extends ConsumerState<BoardDetailScreen> {
  late final AppFlowyBoardController _boardController;

  /// Hash of last synced state to avoid redundant rebuilds that would
  /// interrupt mid-gesture drags.
  String _lastSyncHash = '';

  @override
  void initState() {
    super.initState();
    _boardController = AppFlowyBoardController(
      onMoveGroupItem: (groupId, fromIndex, toIndex) {
        ref
            .read(boardDetailProvider(widget.boardId).notifier)
            .reorderCard(groupId, fromIndex, toIndex);
      },
      onMoveGroupItemToGroup: (fromGroupId, fromIndex, toGroupId, toIndex) {
        final state = ref.read(boardDetailProvider(widget.boardId));
        final cards = state.cardsByColumn[fromGroupId] ?? [];
        if (fromIndex < cards.length) {
          final card = cards[fromIndex];
          final newPosition = toIndex * 1000;
          ref.read(boardDetailProvider(widget.boardId).notifier).moveCard(
                cardId: card.id,
                fromColumnId: fromGroupId,
                toColumnId: toGroupId,
                newPosition: newPosition,
              );
        }
      },
    );
  }

  @override
  void dispose() {
    _boardController.dispose();
    super.dispose();
  }

  /// Computes a simple hash of the board state to detect changes.
  String _computeSyncHash(BoardDetailState state) {
    final buffer = StringBuffer();
    for (final col in state.columns) {
      buffer.write('${col.id}:${col.name}|');
      final cards = state.cardsByColumn[col.id] ?? [];
      for (final card in cards) {
        buffer.write('${card.id}:${card.position},');
      }
      buffer.write(';');
    }
    return buffer.toString();
  }

  /// Syncs the [AppFlowyBoardController] with the current Riverpod state.
  ///
  /// Only performs a full sync when the column/card structure actually
  /// changes, to avoid killing mid-gesture drags.
  void _syncControllerWithState(BoardDetailState state) {
    final newHash = _computeSyncHash(state);
    if (newHash == _lastSyncHash) return;
    _lastSyncHash = newHash;

    // Clear and rebuild all groups
    _boardController.clear();
    for (final column in state.columns) {
      final cards = state.cardsByColumn[column.id] ?? [];
      final items = cards.map((c) => BoardCardItem(card: c)).toList();
      final group = AppFlowyGroupData(
        id: column.id,
        name: column.name,
        items: items,
      );
      _boardController.addGroup(group);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(boardDetailProvider(widget.boardId));

    // Activate realtime subscription by watching the provider
    ref.watch(boardRealtimeProvider(widget.boardId));

    if (state.isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Loading...')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (state.error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Board')),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Could not load board. Check your connection.',
                style: context.textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () => ref
                    .read(boardDetailProvider(widget.boardId).notifier)
                    .refresh(),
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    // Sync controller with current state
    _syncControllerWithState(state);

    return Scaffold(
      appBar: AppBar(
        title: Text(state.board?.name ?? 'Board'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Board settings',
            onPressed: () {
              // Will be wired in Plan 03
            },
          ),
        ],
      ),
      body: AppFlowyBoard(
        controller: _boardController,
        cardBuilder: (context, group, groupItem) {
          final item = groupItem as BoardCardItem;
          return AppFlowyGroupCard(
            key: ValueKey(item.card.id),
            child: KanbanCardWidget(
              card: item.card,
              onTap: () => showCardDetailSheet(
                context,
                ref,
                item.card,
                widget.boardId,
              ),
            ),
          );
        },
        headerBuilder: (context, columnData) {
          final columnId = columnData.headerData.groupId;
          final column = state.columns
              .where((c) => c.id == columnId)
              .firstOrNull;
          final cardCount = state.cardsByColumn[columnId]?.length ?? 0;

          return ColumnHeaderWidget(
            columnName: column?.name ?? columnData.headerData.groupName,
            cardCount: cardCount,
            userRole: state.currentUserRole,
            onRename: (newName) => ref
                .read(boardDetailProvider(widget.boardId).notifier)
                .renameColumn(columnId, newName),
            onDelete: () => ref
                .read(boardDetailProvider(widget.boardId).notifier)
                .deleteColumn(columnId),
            onAddCard: () => _showAddCardDialog(columnId),
          );
        },
        footerBuilder: (context, columnData) {
          final columnId = columnData.headerData.groupId;
          final cards = state.cardsByColumn[columnId];
          if (cards == null || cards.isEmpty) {
            return EmptyColumnPlaceholder(
              onAddCard: () => _showAddCardDialog(columnId),
            );
          }
          return const SizedBox.shrink();
        },
        groupConstraints: BoxConstraints.tightFor(
          width: MediaQuery.of(context).size.width * 0.85,
        ),
        config: AppFlowyBoardConfig(
          groupBackgroundColor: context.colorScheme.surfaceContainerLow,
        ),
      ),
    );
  }

  void _showAddCardDialog(String columnId) {
    final titleController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Add Card'),
          content: AppTextField(
            label: 'Card title',
            controller: titleController,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) {
              _createCard(dialogContext, columnId, titleController);
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                _createCard(dialogContext, columnId, titleController);
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  void _createCard(
    BuildContext dialogContext,
    String columnId,
    TextEditingController titleController,
  ) async {
    final title = titleController.text.trim();
    if (title.isEmpty) return;

    Navigator.of(dialogContext).pop();

    try {
      await ref
          .read(boardDetailProvider(widget.boardId).notifier)
          .addCard(columnId: columnId, title: title);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not add card. Please try again.')),
        );
      }
    }
  }
}
