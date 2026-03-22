import 'package:flutter/material.dart';

import '../../../../core/utils/date_helpers.dart';
import '../../../../core/utils/extensions.dart';

/// A small row with a clock icon and formatted deadline text.
///
/// Shows the deadline in red when overdue and the task is not yet completed.
/// Returns [SizedBox.shrink] when [deadline] is null.
class DeadlineChip extends StatelessWidget {
  const DeadlineChip({
    super.key,
    required this.deadline,
    this.isCompleted = false,
  });

  final DateTime? deadline;
  final bool isCompleted;

  @override
  Widget build(BuildContext context) {
    if (deadline == null) return const SizedBox.shrink();

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final deadlineDate =
        DateTime(deadline!.year, deadline!.month, deadline!.day);
    final isOverdue = deadlineDate.isBefore(today) && !isCompleted;

    final color = isOverdue
        ? context.colorScheme.error
        : context.colorScheme.onSurfaceVariant;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.schedule, size: 14, color: color),
        const SizedBox(width: 4),
        Text(
          formatDeadline(deadline!),
          style: context.textTheme.labelSmall?.copyWith(color: color),
        ),
      ],
    );
  }
}
