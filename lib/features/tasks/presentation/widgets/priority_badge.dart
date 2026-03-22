import 'package:flutter/material.dart';

import '../../../../core/utils/extensions.dart';
import '../../domain/task_model.dart';

/// A small colored badge displaying the priority level (P1-P4).
///
/// Colors are chosen for quick visual distinction:
/// P1 = urgent red, P2 = warning orange, P3 = default blue, P4 = low-priority
/// blue-grey.
class PriorityBadge extends StatelessWidget {
  const PriorityBadge({super.key, required this.priority});

  final Priority priority;

  /// Maps each priority to its display color.
  static const Map<Priority, Color> priorityColors = {
    Priority.p1: Color(0xFFD32F2F), // urgent red
    Priority.p2: Color(0xFFF57C00), // warning orange
    Priority.p3: Color(0xFF1976D2), // default blue
    Priority.p4: Color(0xFF78909C), // low-priority blue-grey
  };

  /// Short labels for each priority level.
  static const Map<Priority, String> _labels = {
    Priority.p1: 'P1',
    Priority.p2: 'P2',
    Priority.p3: 'P3',
    Priority.p4: 'P4',
  };

  @override
  Widget build(BuildContext context) {
    final color = priorityColors[priority]!;
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
