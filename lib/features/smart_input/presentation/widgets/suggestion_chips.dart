import 'package:flutter/material.dart';

import '../../../../core/utils/extensions.dart';
import '../../domain/parsed_task_input.dart';

/// Displays editable suggestion chips for parsed task fields.
///
/// Shows chips for deadline, priority, and category when present.
/// Each chip can be tapped to trigger an edit callback, or deleted
/// via the close icon to clear that field.
class SuggestionChips extends StatelessWidget {
  final ParsedTaskInput parsed;
  final ValueChanged<DateTime>? onEditDeadline;
  final ValueChanged<String>? onEditPriority;
  final ValueChanged<String>? onEditCategory;
  final VoidCallback? onClearDeadline;
  final VoidCallback? onClearPriority;
  final VoidCallback? onClearCategory;

  const SuggestionChips({
    super.key,
    required this.parsed,
    this.onEditDeadline,
    this.onEditPriority,
    this.onEditCategory,
    this.onClearDeadline,
    this.onClearPriority,
    this.onClearCategory,
  });

  @override
  Widget build(BuildContext context) {
    final chips = <Widget>[];

    if (parsed.suggestedDeadline != null) {
      chips.add(
        InputChip(
          avatar: Icon(Icons.calendar_today,
              size: 16, color: context.colorScheme.primary),
          label: Text(_formatDate(parsed.suggestedDeadline!)),
          onPressed: () => onEditDeadline?.call(parsed.suggestedDeadline!),
          deleteIcon: const Icon(Icons.close, size: 14),
          onDeleted: onClearDeadline,
        ),
      );
    }

    if (parsed.suggestedPriority != null) {
      chips.add(
        InputChip(
          avatar: Icon(_priorityIcon(parsed.suggestedPriority!),
              size: 16,
              color: _priorityColor(parsed.suggestedPriority!)),
          label: Text(parsed.suggestedPriority!),
          onPressed: () => onEditPriority?.call(parsed.suggestedPriority!),
          deleteIcon: const Icon(Icons.close, size: 14),
          onDeleted: onClearPriority,
        ),
      );
    }

    if (parsed.suggestedCategory != null) {
      final confidenceLabel = parsed.categoryConfidence > 0
          ? ' (${(parsed.categoryConfidence * 100).toStringAsFixed(0)}%)'
          : '';
      chips.add(
        InputChip(
          avatar: Icon(Icons.label_outline,
              size: 16, color: context.colorScheme.tertiary),
          label: Text(
              '${parsed.suggestedCategory!.displayName}$confidenceLabel'),
          onPressed: () =>
              onEditCategory?.call(parsed.suggestedCategory!.displayName),
          deleteIcon: const Icon(Icons.close, size: 14),
          onDeleted: onClearCategory,
        ),
      );
    }

    if (chips.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Wrap(spacing: 8, runSpacing: 4, children: chips),
    );
  }

  /// Formats a [date] for display in the deadline chip.
  ///
  /// Returns "Today" or "Tomorrow" for near dates, otherwise
  /// "Mon DD, YYYY" format.
  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = DateTime(now.year, now.month, now.day + 1);
    final dateOnly = DateTime(date.year, date.month, date.day);

    if (dateOnly == today) return 'Today';
    if (dateOnly == tomorrow) return 'Tomorrow';

    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  /// Returns an icon representing the given [priority] level.
  IconData _priorityIcon(String priority) {
    switch (priority) {
      case 'P1':
        return Icons.priority_high;
      case 'P2':
        return Icons.flag;
      case 'P3':
        return Icons.flag_outlined;
      case 'P4':
        return Icons.outlined_flag;
      default:
        return Icons.flag;
    }
  }

  /// Returns a color representing the given [priority] level.
  Color _priorityColor(String priority) {
    switch (priority) {
      case 'P1':
        return Colors.red;
      case 'P2':
        return Colors.orange;
      case 'P3':
        return Colors.blue;
      case 'P4':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }
}
