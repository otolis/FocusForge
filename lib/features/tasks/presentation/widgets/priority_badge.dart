import 'package:flutter/material.dart';

import '../../../../core/utils/extensions.dart';
import '../../../../core/utils/priority_color.dart';
import '../../domain/task_model.dart';

/// A small colored badge displaying the priority level (P1-P4).
///
/// Uses theme-aware [priorityColor] utility so colors adapt to
/// light/dark mode automatically.
class PriorityBadge extends StatelessWidget {
  const PriorityBadge({super.key, required this.priority});

  final Priority priority;

  /// Returns the theme-aware color for the given [Priority].
  static Color colorFor(Priority priority, ColorScheme cs) {
    return priorityColor(priority.index + 1, cs);
  }

  /// Short labels for each priority level.
  static const Map<Priority, String> _labels = {
    Priority.p1: 'P1',
    Priority.p2: 'P2',
    Priority.p3: 'P3',
    Priority.p4: 'P4',
  };

  @override
  Widget build(BuildContext context) {
    final color = colorFor(priority, context.colorScheme);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        _labels[priority]!,
        style: context.textTheme.labelSmall?.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
