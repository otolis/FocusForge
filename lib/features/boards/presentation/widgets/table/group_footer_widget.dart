import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../domain/board_table_column.dart';

/// Which section of the split footer to render.
///
/// The table view has a fixed (sticky) name column on the left and a
/// horizontally scrollable data section on the right. Each section
/// renders its own footer content to avoid cross-boundary overflow.
enum FooterSection {
  /// Render for the fixed (sticky) 200 px name column.
  /// Shows only the item count text.
  fixed,

  /// Render for the scrollable data columns.
  /// Shows the status distribution bar and date range.
  scrollable,
}

/// Summary footer displayed below each group's rows.
///
/// When [section] is [FooterSection.fixed], renders a compact item
/// count that fits inside the 200 px sticky column.
///
/// When [section] is [FooterSection.scrollable], renders the colored
/// status distribution bar and date range across the full scrollable
/// width.
class GroupFooterWidget extends StatelessWidget {
  final int itemCount;

  /// Which half of the split table to render for.
  final FooterSection section;

  /// Maps status label name to count of items with that status.
  final Map<String, int> statusCounts;

  /// Status label definitions for color lookup.
  final List<StatusLabelDef> statusLabels;

  final DateTime? earliestDate;
  final DateTime? latestDate;

  const GroupFooterWidget({
    super.key,
    required this.itemCount,
    required this.section,
    required this.statusCounts,
    required this.statusLabels,
    this.earliestDate,
    this.latestDate,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final decoration = BoxDecoration(
      color: colorScheme.surface,
      border: Border(
        top: BorderSide(
          color: colorScheme.outlineVariant.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
    );

    if (section == FooterSection.fixed) {
      return Container(
        height: 32,
        decoration: decoration,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        alignment: Alignment.centerLeft,
        child: Text(
          '$itemCount items',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w400,
            color: colorScheme.onSurfaceVariant,
          ),
          overflow: TextOverflow.ellipsis,
        ),
      );
    }

    // FooterSection.scrollable
    return Container(
      height: 32,
      decoration: decoration,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          // Status distribution bar
          Expanded(child: _buildStatusBar(colorScheme)),

          const SizedBox(width: 12),

          // Date range span
          Text(
            _formatDateRange(),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w400,
              color: colorScheme.onSurfaceVariant,
            ),
            overflow: TextOverflow.ellipsis,
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
