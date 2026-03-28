import 'package:flutter/material.dart';

import '../../../domain/board_model.dart';
import '../../../domain/board_table_column.dart';
import '../cells/checkbox_cell.dart';
import '../cells/due_date_cell.dart';
import '../cells/link_cell.dart';
import '../cells/number_cell.dart';
import '../cells/person_cell.dart';
import '../cells/priority_cell.dart';
import '../cells/status_cell.dart';
import '../cells/text_cell.dart';
import '../cells/timeline_cell.dart';

/// A scrollable data row rendering cells for a single [BoardCard].
///
/// Dispatches to the appropriate cell widget based on each column's
/// [ColumnType]. Applies zebra striping based on [rowIndex] parity.
class TableDataRow extends StatelessWidget {
  /// The card whose data is rendered in this row.
  final BoardCard card;

  /// Column definitions excluding the sticky name column.
  final List<TableColumnDef> columns;

  /// Row position index (0-based) for zebra striping.
  final int rowIndex;

  /// The currently editing cell ID in "{cardId}_{columnId}" format.
  final String? editingCellId;

  /// Board members for person cell name/avatar lookup.
  final List<BoardMember> members;

  /// Called when a cell is tapped to enter edit mode.
  final void Function(String cardId, String columnId) onCellTap;

  /// Called when a cell value changes.
  final void Function(String cardId, String columnId, dynamic value)
      onCellChanged;

  const TableDataRow({
    super.key,
    required this.card,
    required this.columns,
    required this.rowIndex,
    this.editingCellId,
    required this.members,
    required this.onCellTap,
    required this.onCellChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Zebra striping colors
    final bgColor = rowIndex.isEven
        ? Color(isDark ? 0xFF1E1B16 : 0xFFFFFBF5)
        : Color(isDark ? 0xFF252118 : 0xFFF5F0E8);

    return Container(
      height: 36,
      decoration: BoxDecoration(
        color: bgColor,
        border: Border(
          bottom: BorderSide(
            color: colorScheme.outlineVariant.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final column in columns) _buildCell(column),
        ],
      ),
    );
  }

  Widget _buildCell(TableColumnDef column) {
    return SizedBox(
      width: column.width,
      height: 36,
      child: switch (column.type) {
        ColumnType.status => StatusCell(
            statusLabel: card.statusLabel,
            statusColor: card.statusColor,
            onTap: () => onCellTap(card.id, column.id),
          ),
        ColumnType.priority => PriorityCell(
            priority: card.priority,
            onTap: () => onCellTap(card.id, column.id),
          ),
        ColumnType.person => PersonCell(
            assigneeName: _findMemberName(card.assigneeId),
            avatarUrl: _findMemberAvatar(card.assigneeId),
            onTap: () => onCellTap(card.id, column.id),
          ),
        ColumnType.timeline => TimelineCell(
            startDate: card.startDate,
            endDate: card.dueDate,
            barColor: _statusColor(),
            onTap: () => onCellTap(card.id, column.id),
          ),
        ColumnType.dueDate => DueDateCell(
            dueDate: card.dueDate,
            onTap: () => onCellTap(card.id, column.id),
          ),
        ColumnType.text => TextCell(
            value: column.id == 'col_desc'
                ? (card.description ?? '')
                : (card.customFields[column.id]?.toString() ?? ''),
            isEditing: editingCellId == '${card.id}_${column.id}',
            onTap: () => onCellTap(card.id, column.id),
            onChanged: (v) => onCellChanged(card.id, column.id, v),
          ),
        ColumnType.number => NumberCell(
            value: card.customFields[column.id],
            isEditing: editingCellId == '${card.id}_${column.id}',
            onTap: () => onCellTap(card.id, column.id),
            onChanged: (v) => onCellChanged(card.id, column.id, v),
          ),
        ColumnType.checkbox => CheckboxCell(
            value: card.customFields[column.id] == true,
            onChanged: (v) => onCellChanged(card.id, column.id, v),
          ),
        ColumnType.link => LinkCell(
            value: card.customFields[column.id]?.toString() ?? '',
            isEditing: editingCellId == '${card.id}_${column.id}',
            onTap: () => onCellTap(card.id, column.id),
            onChanged: (v) => onCellChanged(card.id, column.id, v),
          ),
      },
    );
  }

  /// Looks up the display name for a board member by user ID.
  String? _findMemberName(String? userId) {
    if (userId == null) return null;
    for (final member in members) {
      if (member.userId == userId) return member.displayName;
    }
    return null;
  }

  /// Looks up the avatar URL for a board member by user ID.
  String? _findMemberAvatar(String? userId) {
    if (userId == null) return null;
    for (final member in members) {
      if (member.userId == userId) return member.avatarUrl;
    }
    return null;
  }

  /// Returns the card's status color parsed from hex, or a default blue.
  Color _statusColor() {
    if (card.statusColor != null && card.statusColor!.isNotEmpty) {
      try {
        return Color(
            int.parse(card.statusColor!.replaceFirst('#', '0xFF')));
      } catch (_) {
        // Fall through to default
      }
    }
    return const Color(0xFF579BFC); // Default blue
  }
}
