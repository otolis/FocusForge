import 'package:flutter/material.dart';

import '../../../../core/utils/extensions.dart';

/// A header widget for date-grouped task sections.
///
/// Uses [colorScheme.error] for the "Overdue" section to visually distinguish
/// past-due tasks, and [colorScheme.primary] for all other sections.
class DateSectionHeader extends StatelessWidget {
  const DateSectionHeader({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final isOverdue = title == 'Overdue';
    final color =
        isOverdue ? context.colorScheme.error : context.colorScheme.primary;

    return Padding(
      padding: const EdgeInsets.only(left: 16, top: 20, bottom: 8),
      child: Text(
        title,
        style: context.textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}
