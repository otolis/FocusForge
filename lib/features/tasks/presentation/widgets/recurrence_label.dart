import 'package:flutter/material.dart';

import '../../../../core/utils/extensions.dart';

/// A small row with a repeat icon and a recurrence description label.
///
/// Returns [SizedBox.shrink] when [displayLabel] is null or empty.
class RecurrenceLabel extends StatelessWidget {
  const RecurrenceLabel({super.key, required this.displayLabel});

  final String? displayLabel;

  @override
  Widget build(BuildContext context) {
    if (displayLabel == null || displayLabel!.isEmpty) {
      return const SizedBox.shrink();
    }

    final color = context.colorScheme.tertiary;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.repeat, size: 12, color: color),
        const SizedBox(width: 4),
        Text(
          displayLabel!,
          style: context.textTheme.labelSmall?.copyWith(color: color),
        ),
      ],
    );
  }
}
