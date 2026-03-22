import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/utils/extensions.dart';
import '../../domain/board_model.dart';

/// Renders a single card inside an AppFlowyBoard column.
///
/// Displays the card title with a priority color indicator, optional
/// due date, and optional assignee avatar. The [onTap] callback is
/// triggered when the user taps the card (as opposed to a long-press
/// drag gesture which is handled by AppFlowyBoard).
class KanbanCardWidget extends StatelessWidget {
  const KanbanCardWidget({
    super.key,
    required this.card,
    this.onTap,
  });

  /// The board card data to render.
  final BoardCard card;

  /// Called when the user taps this card (opens detail sheet).
  final VoidCallback? onTap;

  /// Maps priority values (1-4) to display colors.
  static const _priorityColors = {
    1: Colors.red,
    2: Colors.orange,
    3: Colors.blue,
    4: Colors.grey,
  };

  @override
  Widget build(BuildContext context) {
    final priorityColor = _priorityColors[card.priority] ?? Colors.grey;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: context.colorScheme.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: context.colorScheme.outlineVariant.withValues(alpha: 0.3),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Title row with priority indicator
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 4,
                  height: 20,
                  decoration: BoxDecoration(
                    color: priorityColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    card.title,
                    style: context.textTheme.bodyMedium,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),

            // Due date row
            if (card.dueDate != null) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  Icon(
                    Icons.schedule,
                    size: 14,
                    color: context.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    DateFormat('MMM d').format(card.dueDate!),
                    style: context.textTheme.bodySmall?.copyWith(
                      color: context.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],

            // Assignee avatar
            if (card.assigneeId != null) ...[
              const SizedBox(height: 6),
              Align(
                alignment: Alignment.centerRight,
                child: CircleAvatar(
                  radius: 10,
                  backgroundColor: context.colorScheme.primaryContainer,
                  child: Text(
                    (card.assigneeId ?? '?')[0].toUpperCase(),
                    style: context.textTheme.labelSmall?.copyWith(
                      fontSize: 9,
                      color: context.colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
