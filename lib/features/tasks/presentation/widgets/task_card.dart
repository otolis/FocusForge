import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

import '../../../../core/utils/extensions.dart';
import '../../../../shared/widgets/celebration_overlay.dart';
import '../../domain/task_model.dart';
import 'category_chip.dart';
import 'deadline_chip.dart';
import 'priority_badge.dart';
import 'recurrence_label.dart';

/// A card displaying a single task with swipe actions for complete and delete.
///
/// Uses [flutter_slidable] for bidirectional swipe gestures:
/// - Swipe right: green "Complete" action
/// - Swipe left: red "Delete" action with dismiss behavior
class TaskCard extends StatelessWidget {
  const TaskCard({
    super.key,
    required this.task,
    required this.onTap,
    required this.onToggleComplete,
    required this.onDelete,
    this.recurrenceDisplayLabel,
  });

  final Task task;
  final VoidCallback onTap;
  final Function(String) onToggleComplete;
  final Function(String) onDelete;
  final String? recurrenceDisplayLabel;

  @override
  Widget build(BuildContext context) {
    return Slidable(
      key: ValueKey(task.id),
      startActionPane: ActionPane(
        motion: const BehindMotion(),
        children: [
          SlidableAction(
            onPressed: (_) {
              HapticFeedback.mediumImpact();
              if (!task.isCompleted) {
                CelebrationOverlay.show(
                  context,
                  animationAsset: CelebrationAssets.taskComplete,
                );
              }
              onToggleComplete(task.id);
            },
            backgroundColor: context.colorScheme.primary,
            foregroundColor: context.colorScheme.onPrimary,
            icon: Icons.check_circle,
            label: 'Complete',
          ),
        ],
      ),
      endActionPane: ActionPane(
        motion: const BehindMotion(),
        dismissible: DismissiblePane(
          onDismissed: () => onDelete(task.id),
        ),
        children: [
          SlidableAction(
            onPressed: (_) {
              HapticFeedback.mediumImpact();
              onDelete(task.id);
            },
            backgroundColor: context.colorScheme.error,
            foregroundColor: context.colorScheme.onError,
            icon: Icons.delete,
            label: 'Delete',
          ),
        ],
      ),
      child: Card(
        elevation: 0,
        color: context.colorScheme.surfaceContainerLow,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Leading checkbox
                SizedBox(
                  width: 24,
                  height: 24,
                  child: Checkbox(
                    value: task.isCompleted,
                    onChanged: (_) => onToggleComplete(task.id),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Expanded content column
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title row with priority badge
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              task.title,
                              style:
                                  context.textTheme.titleMedium?.copyWith(
                                decoration: task.isCompleted
                                    ? TextDecoration.lineThrough
                                    : null,
                                color: task.isCompleted
                                    ? context.colorScheme.onSurfaceVariant
                                    : null,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          PriorityBadge(priority: task.priority),
                        ],
                      ),
                      const SizedBox(height: 6),
                      // Metadata row: category, deadline, recurrence
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: [
                          CategoryChip(category: task.category),
                          DeadlineChip(
                            deadline: task.deadline,
                            isCompleted: task.isCompleted,
                          ),
                          RecurrenceLabel(
                            displayLabel: recurrenceDisplayLabel,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
