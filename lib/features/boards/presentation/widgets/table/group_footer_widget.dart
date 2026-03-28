import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../domain/board_table_column.dart';

/// Summary footer displayed below each group's rows.
///
/// Shows item count, a colored status distribution bar, and the date range
/// spanned by items in the group.
class GroupFooterWidget extends StatelessWidget {
  final int itemCount;

  /// Maps status label name to count of items with that status.
  final Map<String, int> statusCounts;

  /// Status label definitions for color lookup.
  final List<StatusLabelDef> statusLabels;

  final DateTime? earliestDate;
  final DateTime? latestDate;

  const GroupFooterWidget({
    super.key,
    required this.itemCount,
    required this.statusCounts,
    required this.statusLabels,
    this.earliestDate,
    this.latestDate,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      height: 32,
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: colorScheme.outlineVariant.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          // Item count label
          SizedBox(
            width: 80,
            child: Text(
              '$itemCount items',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w400,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(width: 8),

          // Status distribution bar
          Expanded(child: _buildStatusBar(colorScheme)),

          const SizedBox(width: 8),

          // Date range span
          SizedBox(
            width: 120,
            child: Text(
              _formatDateRange(),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w400,
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.end,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBar(ColorScheme colorScheme) {
    final total = statusCounts.values.fold<int>(0, (sum, c) => sum + c);

    if (total == 0) {
      // No items have a status -- show full gray bar
      return Container(
        height: 8,
        decoration: BoxDecoration(
          color: colorScheme.outlineVariant.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(4),
        ),
      );
    }

    // Build a map from label name to color for quick lookup
    final colorMap = <String, Color>{};
    for (final label in statusLabels) {
      colorMap[label.name] = _parseHex(label.color);
    }

    // Create segments proportional to counts
    final segments = <Widget>[];
    for (final entry in statusCounts.entries) {
      if (entry.value <= 0) continue;
      final color =
          colorMap[entry.key] ?? colorScheme.outlineVariant;
      segments.add(
        Flexible(
          flex: entry.value,
          child: Container(
            height: 8,
            color: color,
          ),
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: SizedBox(
        height: 8,
        child: Row(children: segments),
      ),
    );
  }

  String _formatDateRange() {
    if (earliestDate == null && latestDate == null) {
      return '\u2014'; // em dash
    }

    final fmt = DateFormat('MMM d');

    if (earliestDate != null && latestDate != null) {
      return '${fmt.format(earliestDate!)} - ${fmt.format(latestDate!)}';
    }

    if (earliestDate != null) return fmt.format(earliestDate!);
    return fmt.format(latestDate!);
  }

  static Color _parseHex(String hex) {
    final buffer = StringBuffer();
    final cleaned = hex.replaceAll('#', '');
    buffer.write('FF');
    buffer.write(cleaned);
    return Color(int.parse(buffer.toString(), radix: 16));
  }
}
