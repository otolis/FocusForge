import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/board_model.dart';
import '../../../domain/board_table_column.dart';
import '../../providers/board_detail_provider.dart';
import '../../providers/board_table_provider.dart';
import '../column_config_sheet.dart';
import '../group_config_sheet.dart';
import 'add_item_row.dart';
import 'group_footer_widget.dart';
import 'group_header_widget.dart';
import 'table_data_row.dart';
import 'table_header_row.dart';

/// Main Monday.com-style table widget with sticky name column,
/// horizontally scrollable data columns, and synced scrolling.
///
/// Uses 4 [ScrollController]s for scroll sync:
/// - [_fixedVerticalController] / [_scrollableVerticalController] for
///   vertical scroll sync between fixed and scrollable sections.
/// - [_headerHorizontalController] / [_dataHorizontalController] for
///   horizontal scroll sync between header and data sections.
class BoardTableWidget extends ConsumerStatefulWidget {
  final String boardId;

  const BoardTableWidget({super.key, required this.boardId});

  @override
  ConsumerState<BoardTableWidget> createState() => _BoardTableWidgetState();
}

class _BoardTableWidgetState extends ConsumerState<BoardTableWidget> {
  late final ScrollController _fixedVerticalController;
  late final ScrollController _scrollableVerticalController;
  late final ScrollController _headerHorizontalController;
  late final ScrollController _dataHorizontalController;

  bool _syncingVertical = false;
  bool _syncingHorizontal = false;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _fixedVerticalController = ScrollController();
    _scrollableVerticalController = ScrollController();
    _headerHorizontalController = ScrollController();
    _dataHorizontalController = ScrollController();

    // Sync vertical scroll
    _fixedVerticalController.addListener(_onFixedVerticalScroll);
    _scrollableVerticalController.addListener(_onScrollableVerticalScroll);

    // Sync horizontal scroll
    _headerHorizontalController.addListener(_onHeaderHorizontalScroll);
    _dataHorizontalController.addListener(_onDataHorizontalScroll);
  }

  @override
  void dispose() {
    _fixedVerticalController.removeListener(_onFixedVerticalScroll);
    _scrollableVerticalController.removeListener(_onScrollableVerticalScroll);
    _headerHorizontalController.removeListener(_onHeaderHorizontalScroll);
    _dataHorizontalController.removeListener(_onDataHorizontalScroll);
    _fixedVerticalController.dispose();
    _scrollableVerticalController.dispose();
    _headerHorizontalController.dispose();
    _dataHorizontalController.dispose();
    super.dispose();
  }

  void _onFixedVerticalScroll() {
    if (_syncingVertical) return;
    _syncingVertical = true;
    if (_scrollableVerticalController.hasClients) {
      _scrollableVerticalController
          .jumpTo(_fixedVerticalController.offset);
    }
    _syncingVertical = false;
  }

  void _onScrollableVerticalScroll() {
    if (_syncingVertical) return;
    _syncingVertical = true;
    if (_fixedVerticalController.hasClients) {
      _fixedVerticalController
          .jumpTo(_scrollableVerticalController.offset);
    }
    _syncingVertical = false;
  }

  void _onHeaderHorizontalScroll() {
    if (_syncingHorizontal) return;
    _syncingHorizontal = true;
    if (_dataHorizontalController.hasClients) {
      _dataHorizontalController
          .jumpTo(_headerHorizontalController.offset);
    }
    _syncingHorizontal = false;
  }

  void _onDataHorizontalScroll() {
    if (_syncingHorizontal) return;
    _syncingHorizontal = true;
    if (_headerHorizontalController.hasClients) {
      _headerHorizontalController
          .jumpTo(_dataHorizontalController.offset);
    }
    _syncingHorizontal = false;
  }

  @override
  Widget build(BuildContext context) {
    final detailState = ref.watch(boardDetailProvider(widget.boardId));
    final tableState = ref.watch(boardTableProvider(widget.boardId));
    final colorScheme = Theme.of(context).colorScheme;

    final board = detailState.board;
    if (board == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final metadata = board.metadata;

    // Initialize column widths on first build
    if (!_initialized) {
      _initialized = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref
            .read(boardTableProvider(widget.boardId).notifier)
            .initFromMetadata(metadata);
      });
    }

    final scrollableColumns = List<TableColumnDef>.from(metadata.columnDefs)
      ..sort((a, b) => a.position.compareTo(b.position));

    // Apply current widths from state
    final displayColumns = scrollableColumns.map((col) {
      final w = tableState.columnWidths[col.id];
      return w != null ? col.copyWith(width: w) : col;
    }).toList();

    final totalScrollableWidth =
        displayColumns.fold<double>(0, (sum, c) => sum + c.width) + 48;

    // Build row items for both fixed and scrollable columns
    final groups = List<BoardGroup>.from(metadata.groups)
      ..sort((a, b) => a.position.compareTo(b.position));
    final allCards =
        detailState.cardsByColumn.values.expand((c) => c).toList();

    return Column(
      children: [
        // ── Header row ──
        _buildHeaderRow(
          displayColumns,
          totalScrollableWidth,
          colorScheme,
          metadata,
        ),

        // ── Data section ──
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Sticky name column (200px)
              SizedBox(
                width: 200,
                child: ListView(
                  controller: _fixedVerticalController,
                  children: _buildFixedColumnItems(
                    groups,
                    allCards,
                    tableState,
                    detailState,
                    metadata,
                  ),
                ),
              ),

              // Scrollable data columns
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  controller: _dataHorizontalController,
                  physics: tableState.isResizing
                      ? const NeverScrollableScrollPhysics()
                      : null,
                  child: SizedBox(
                    width: totalScrollableWidth,
                    child: ListView(
                      controller: _scrollableVerticalController,
                      children: _buildScrollableColumnItems(
                        groups,
                        allCards,
                        displayColumns,
                        tableState,
                        detailState,
                        metadata,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ─── Header Row ─────────────────────────────────────

  Widget _buildHeaderRow(
    List<TableColumnDef> displayColumns,
    double totalScrollableWidth,
    ColorScheme colorScheme,
    BoardMetadata metadata,
  ) {
    return Row(
      children: [
        // Fixed "Item" header
        Container(
          width: 200,
          height: 40,
          color: colorScheme.surfaceContainerHighest,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          alignment: Alignment.centerLeft,
          child: Text(
            'Item',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: colorScheme.onSurface,
            ),
          ),
        ),

        // Scrollable column headers
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            controller: _headerHorizontalController,
            child: TableHeaderRow(
              columns: displayColumns,
              onResize: (columnIndex, delta) {
                final col = displayColumns[columnIndex];
                ref
                    .read(boardTableProvider(widget.boardId).notifier)
                    .resizeColumn(col.id, delta);
              },
              onResizeEnd: () {
                ref
                    .read(boardTableProvider(widget.boardId).notifier)
                    .endResize(widget.boardId);
              },
              onAddColumn: () => _showColumnConfigSheet(metadata),
              onReorder: (oldIndex, newIndex) {
                final column = displayColumns[oldIndex];
                ref
                    .read(boardTableProvider(widget.boardId).notifier)
                    .reorderColumn(widget.boardId, column.id, newIndex);
              },
            ),
          ),
        ),
      ],
    );
  }

  // ─── Fixed Column Items ─────────────────────────────

  List<Widget> _buildFixedColumnItems(
    List<BoardGroup> groups,
    List<BoardCard> allCards,
    BoardTableState tableState,
    BoardDetailState detailState,
    BoardMetadata metadata,
  ) {
    final items = <Widget>[];

    for (final group in groups) {
      final groupCards = allCards
          .where((c) => c.groupId == group.id)
          .toList()
        ..sort((a, b) => a.position.compareTo(b.position));

      // Also collect cards with no groupId into the first group
      if (group == groups.first) {
        final ungrouped = allCards.where((c) =>
            c.groupId == null || c.groupId!.isEmpty);
        for (final card in ungrouped) {
          if (!groupCards.any((gc) => gc.id == card.id)) {
            groupCards.add(card);
          }
        }
        groupCards.sort((a, b) => a.position.compareTo(b.position));
      }

      final isCollapsed =
          tableState.collapsedGroupIds.contains(group.id);

      // Group header
      items.add(GroupHeaderWidget(
        group: group,
        itemCount: groupCards.length,
        isCollapsed: isCollapsed,
        onToggle: () => ref
            .read(boardTableProvider(widget.boardId).notifier)
            .toggleGroupCollapse(group.id),
        onLongPress: () => _showGroupConfigSheet(group, metadata),
      ));

      if (!isCollapsed) {
        // Card rows -- using LongPressDraggable/DragTarget for row reorder
        for (int i = 0; i < groupCards.length; i++) {
          final card = groupCards[i];
          items.add(
            _buildDraggableNameCell(
              card: card,
              index: i,
              groupId: group.id,
              groupCards: groupCards,
              tableState: tableState,
            ),
          );
        }

        // Footer (fixed column — item count only)
        items.add(GroupFooterWidget(
          itemCount: groupCards.length,
          section: FooterSection.fixed,
          statusCounts: _computeStatusCounts(groupCards),
          statusLabels: metadata.statusLabels,
          earliestDate: _earliestDate(groupCards),
          latestDate: _latestDate(groupCards),
        ));

        // Add item row
        items.add(AddItemRow(
          onSubmit: (title) async {
            try {
              await ref
                  .read(boardDetailProvider(widget.boardId).notifier)
                  .addCardToGroup(groupId: group.id, title: title);
            } catch (e) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Could not add item. Please try again.'),
                  ),
                );
              }
            }
          },
        ));
      }
    }

    // "+ Add group" row
    items.add(
      GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => _showGroupConfigSheet(null, metadata),
        child: Container(
          height: 36,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          alignment: Alignment.centerLeft,
          child: Text(
            '+ Add group',
            style: TextStyle(
              fontSize: 14,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ),
      ),
    );

    return items;
  }

  /// Wraps a name cell in LongPressDraggable + DragTarget for row reorder.
  Widget _buildDraggableNameCell({
    required BoardCard card,
    required int index,
    required String groupId,
    required List<BoardCard> groupCards,
    required BoardTableState tableState,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = index.isEven
        ? Color(isDark ? 0xFF1E1B16 : 0xFFFFFBF5)
        : Color(isDark ? 0xFF252118 : 0xFFF5F0E8);
    final colorScheme = Theme.of(context).colorScheme;

    final nameCell = Container(
      height: 36,
      width: 200,
      decoration: BoxDecoration(
        color: bgColor,
        border: Border(
          bottom: BorderSide(
            color: colorScheme.outlineVariant.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8),
      alignment: Alignment.centerLeft,
      child: Text(
        card.title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: colorScheme.onSurface,
        ),
        overflow: TextOverflow.ellipsis,
        maxLines: 1,
      ),
    );

    return DragTarget<String>(
      key: ValueKey('drag_target_${card.id}'),
      onWillAcceptWithDetails: (details) {
        // Only accept cards from the same group
        final draggedCardId = details.data;
        return groupCards.any((c) => c.id == draggedCardId) &&
            draggedCardId != card.id;
      },
      onAcceptWithDetails: (details) {
        final draggedCardId = details.data;
        final oldIndex =
            groupCards.indexWhere((c) => c.id == draggedCardId);
        if (oldIndex != -1 && oldIndex != index) {
          ref
              .read(boardTableProvider(widget.boardId).notifier)
              .reorderCard(widget.boardId, groupId, oldIndex, index);
        }
      },
      builder: (context, candidateData, rejectedData) {
        return LongPressDraggable<String>(
          data: card.id,
          axis: Axis.vertical,
          feedback: Material(
            elevation: 4,
            child: Container(
              height: 36,
              width: 200,
              color: colorScheme.surfaceContainerHighest,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              alignment: Alignment.centerLeft,
              child: Text(
                card.title,
                style: TextStyle(
                  fontSize: 14,
                  color: colorScheme.onSurface,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          childWhenDragging: Opacity(
            opacity: 0.5,
            child: nameCell,
          ),
          child: candidateData.isNotEmpty
              ? Container(
                  decoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(
                        color: colorScheme.primary,
                        width: 2,
                      ),
                    ),
                  ),
                  child: nameCell,
                )
              : nameCell,
        );
      },
    );
  }

  // ─── Scrollable Column Items ────────────────────────

  List<Widget> _buildScrollableColumnItems(
    List<BoardGroup> groups,
    List<BoardCard> allCards,
    List<TableColumnDef> displayColumns,
    BoardTableState tableState,
    BoardDetailState detailState,
    BoardMetadata metadata,
  ) {
    final items = <Widget>[];

    for (final group in groups) {
      final groupCards = allCards
          .where((c) => c.groupId == group.id)
          .toList()
        ..sort((a, b) => a.position.compareTo(b.position));

      // Also collect cards with no groupId into the first group
      if (group == groups.first) {
        final ungrouped = allCards.where((c) =>
            c.groupId == null || c.groupId!.isEmpty);
        for (final card in ungrouped) {
          if (!groupCards.any((gc) => gc.id == card.id)) {
            groupCards.add(card);
          }
        }
        groupCards.sort((a, b) => a.position.compareTo(b.position));
      }

      final isCollapsed =
          tableState.collapsedGroupIds.contains(group.id);

      // Colored bar matching group header height
      items.add(Container(
        height: 40,
        color: _parseHex(group.color),
      ));

      if (!isCollapsed) {
        // Data rows
        for (int i = 0; i < groupCards.length; i++) {
          items.add(TableDataRow(
            card: groupCards[i],
            columns: displayColumns,
            rowIndex: i,
            editingCellId: tableState.editingCellId,
            members: detailState.members,
            onCellTap: (cardId, columnId) {
              _handleCellTap(
                cardId,
                columnId,
                displayColumns,
                metadata,
                detailState.members,
              );
            },
            onCellChanged: (cardId, columnId, value) {
              // Map column id to field key
              final fieldKey = _columnToFieldKey(columnId, displayColumns);
              ref
                  .read(boardTableProvider(widget.boardId).notifier)
                  .updateCardField(
                      widget.boardId, cardId, fieldKey, value);
            },
          ));
        }

        // Footer (scrollable column — status bar + date range)
        items.add(GroupFooterWidget(
          itemCount: groupCards.length,
          section: FooterSection.scrollable,
          statusCounts: _computeStatusCounts(groupCards),
          statusLabels: metadata.statusLabels,
          earliestDate: _earliestDate(groupCards),
          latestDate: _latestDate(groupCards),
        ));

        // Add item row placeholder (same height)
        items.add(const SizedBox(height: 36));
      }
    }

    // "+ Add group" placeholder
    items.add(const SizedBox(height: 36));

    return items;
  }

  // ─── Cell Tap Dispatch ─────────────────────────────

  /// Dispatches cell taps to the appropriate handler based on column type.
  ///
  /// Text, number, and link cells enter inline edit mode via [startEditing].
  /// Status, priority, person, due date, and timeline cells show picker UIs.
  void _handleCellTap(
    String cardId,
    String columnId,
    List<TableColumnDef> displayColumns,
    BoardMetadata metadata,
    List<BoardMember> members,
  ) {
    final col = displayColumns.firstWhere(
      (c) => c.id == columnId,
      orElse: () => const TableColumnDef(
        id: '',
        type: ColumnType.text,
        name: '',
        position: 0,
      ),
    );

    switch (col.type) {
      case ColumnType.status:
        _showStatusPicker(cardId, metadata.statusLabels);
      case ColumnType.priority:
        _showPriorityPicker(cardId);
      case ColumnType.person:
        _showPersonPicker(cardId, members);
      case ColumnType.dueDate:
        _showDatePicker(cardId);
      case ColumnType.timeline:
        _showTimelinePicker(cardId);
      case ColumnType.text:
      case ColumnType.number:
      case ColumnType.link:
        ref
            .read(boardTableProvider(widget.boardId).notifier)
            .startEditing('${cardId}_$columnId');
      case ColumnType.checkbox:
        break; // Handled via onChanged, not onTap
    }
  }

  // ─── Picker UIs ──────────────────────────────────

  /// Shows a bottom sheet to pick a status label for a card.
  void _showStatusPicker(String cardId, List<StatusLabelDef> statusLabels) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) {
        final cs = Theme.of(ctx).colorScheme;
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Text(
                  'Select Status',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: cs.onSurface,
                  ),
                ),
              ),
              for (final label in statusLabels)
                ListTile(
                  leading: CircleAvatar(
                    radius: 12,
                    backgroundColor: _parseHex(label.color),
                  ),
                  title: Text(label.name),
                  onTap: () {
                    Navigator.pop(ctx);
                    // Update status_label and status_color atomically
                    // to avoid race conditions from two concurrent calls
                    ref
                        .read(boardTableProvider(widget.boardId).notifier)
                        .updateCardFields(widget.boardId, cardId, {
                      'status_label': label.name,
                      'status_color': label.color,
                    });
                  },
                ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  /// Shows a bottom sheet to pick a priority level (1-4) for a card.
  void _showPriorityPicker(String cardId) {
    const priorities = [
      (value: 1, label: 'Critical', color: Color(0xFFE2445C)),
      (value: 2, label: 'High', color: Color(0xFFFDAB3D)),
      (value: 3, label: 'Medium', color: Color(0xFF579BFC)),
      (value: 4, label: 'Low', color: Color(0xFFC4C4C4)),
    ];

    showModalBottomSheet(
      context: context,
      builder: (ctx) {
        final cs = Theme.of(ctx).colorScheme;
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Text(
                  'Select Priority',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: cs.onSurface,
                  ),
                ),
              ),
              for (final p in priorities)
                ListTile(
                  leading: CircleAvatar(
                    radius: 12,
                    backgroundColor: p.color,
                  ),
                  title: Text(p.label),
                  onTap: () {
                    Navigator.pop(ctx);
                    ref
                        .read(boardTableProvider(widget.boardId).notifier)
                        .updateCardField(
                            widget.boardId, cardId, 'priority', p.value);
                  },
                ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  /// Shows a bottom sheet to pick/unassign a board member for a card.
  void _showPersonPicker(String cardId, List<BoardMember> members) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) {
        final cs = Theme.of(ctx).colorScheme;
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Text(
                  'Assign Person',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: cs.onSurface,
                  ),
                ),
              ),
              // Unassign option
              ListTile(
                leading: Icon(
                  Icons.person_off_outlined,
                  color: cs.onSurfaceVariant,
                ),
                title: const Text('Unassigned'),
                onTap: () {
                  Navigator.pop(ctx);
                  ref
                      .read(boardTableProvider(widget.boardId).notifier)
                      .updateCardField(
                          widget.boardId, cardId, 'assignee_id', null);
                },
              ),
              for (final member in members)
                ListTile(
                  leading: CircleAvatar(
                    radius: 16,
                    backgroundColor: cs.primaryContainer,
                    backgroundImage: member.avatarUrl != null
                        ? NetworkImage(member.avatarUrl!)
                        : null,
                    child: member.avatarUrl == null
                        ? Text(
                            _memberInitials(member.displayName ?? ''),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: cs.onPrimaryContainer,
                            ),
                          )
                        : null,
                  ),
                  title: Text(member.displayName ?? member.userId),
                  onTap: () {
                    Navigator.pop(ctx);
                    ref
                        .read(boardTableProvider(widget.boardId).notifier)
                        .updateCardField(
                            widget.boardId, cardId, 'assignee_id', member.userId);
                  },
                ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  /// Shows a date picker for due date selection.
  Future<void> _showDatePicker(String cardId) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 5),
    );
    if (picked != null) {
      ref
          .read(boardTableProvider(widget.boardId).notifier)
          .updateCardField(widget.boardId, cardId, 'due_date', picked);
    }
  }

  /// Shows a date range picker for timeline (start + end date) selection.
  Future<void> _showTimelinePicker(String cardId) async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 5),
    );
    if (picked != null) {
      // Update start_date and due_date atomically
      ref.read(boardTableProvider(widget.boardId).notifier).updateCardFields(
        widget.boardId,
        cardId,
        {
          'start_date': picked.start,
          'due_date': picked.end,
        },
      );
    }
  }

  /// Extracts up to 2 initials from a display name.
  static String _memberInitials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : '';
  }

  // ─── Helpers ────────────────────────────────────────

  /// Maps a column def ID to the corresponding card field key.
  String _columnToFieldKey(
      String columnId, List<TableColumnDef> columns) {
    final col = columns.firstWhere(
      (c) => c.id == columnId,
      orElse: () => const TableColumnDef(
        id: '',
        type: ColumnType.text,
        name: '',
        position: 0,
      ),
    );

    return switch (col.type) {
      ColumnType.status => 'status_label',
      ColumnType.priority => 'priority',
      ColumnType.person => 'assignee_id',
      ColumnType.timeline => 'start_date',
      ColumnType.dueDate => 'due_date',
      ColumnType.text => col.id == 'col_desc' ? 'description' : col.id,
      ColumnType.number => col.id,
      ColumnType.checkbox => col.id,
      ColumnType.link => col.id,
    };
  }

  Map<String, int> _computeStatusCounts(List<BoardCard> cards) {
    final counts = <String, int>{};
    for (final card in cards) {
      final label = card.statusLabel ?? 'Not Started';
      counts[label] = (counts[label] ?? 0) + 1;
    }
    return counts;
  }

  DateTime? _earliestDate(List<BoardCard> cards) {
    DateTime? earliest;
    for (final card in cards) {
      final date = card.startDate ?? card.dueDate;
      if (date != null && (earliest == null || date.isBefore(earliest))) {
        earliest = date;
      }
    }
    return earliest;
  }

  DateTime? _latestDate(List<BoardCard> cards) {
    DateTime? latest;
    for (final card in cards) {
      final date = card.dueDate ?? card.startDate;
      if (date != null && (latest == null || date.isAfter(latest))) {
        latest = date;
      }
    }
    return latest;
  }

  void _showColumnConfigSheet(BoardMetadata metadata) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => ColumnConfigSheet(
        onSave: (column) {
          // Set position after existing columns
          final maxPos = metadata.columnDefs.isEmpty
              ? 0
              : metadata.columnDefs
                  .map((c) => c.position)
                  .reduce((a, b) => a > b ? a : b);
          final positioned =
              column.copyWith(position: maxPos + 1000);
          final updatedMetadata = BoardMetadata(
            columnDefs: [...metadata.columnDefs, positioned],
            statusLabels: metadata.statusLabels,
            groups: metadata.groups,
          );
          ref
              .read(boardDetailProvider(widget.boardId).notifier)
              .updateBoardMetadata(updatedMetadata);
        },
      ),
    );
  }

  void _showGroupConfigSheet(
      BoardGroup? existingGroup, BoardMetadata metadata) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => GroupConfigSheet(
        existingGroup: existingGroup,
        onSave: (group) async {
          try {
            if (existingGroup != null) {
              // Edit existing group
              final updatedGroups = metadata.groups
                  .map((g) => g.id == group.id ? group : g)
                  .toList();
              final updatedMetadata = BoardMetadata(
                columnDefs: metadata.columnDefs,
                statusLabels: metadata.statusLabels,
                groups: updatedGroups,
              );
              await ref
                  .read(boardDetailProvider(widget.boardId).notifier)
                  .updateBoardMetadata(updatedMetadata);
            } else {
              // New group -- set position
              final maxPos = metadata.groups.isEmpty
                  ? 0
                  : metadata.groups
                      .map((g) => g.position)
                      .reduce((a, b) => a > b ? a : b);
              final positioned = BoardGroup(
                id: group.id,
                name: group.name,
                color: group.color,
                position: maxPos + 1000,
              );
              final updatedMetadata = BoardMetadata(
                columnDefs: metadata.columnDefs,
                statusLabels: metadata.statusLabels,
                groups: [...metadata.groups, positioned],
              );
              await ref
                  .read(boardDetailProvider(widget.boardId).notifier)
                  .updateBoardMetadata(updatedMetadata);
            }
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(existingGroup != null
                      ? 'Could not update group. Please try again.'
                      : 'Could not add group. Please try again.'),
                ),
              );
            }
          }
        },
      ),
    );
  }

  static Color _parseHex(String hex) {
    final cleaned = hex.replaceAll('#', '');
    return Color(int.parse('FF$cleaned', radix: 16));
  }
}
