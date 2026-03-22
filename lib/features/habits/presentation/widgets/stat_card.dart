import 'package:flutter/material.dart';

import '../../../../core/utils/extensions.dart';

/// A summary statistic card displaying a label and value with an optional icon.
///
/// Used in the habit detail screen stats grid for best streak, current streak,
/// total completions, and completion rate.
class StatCard extends StatelessWidget {
  const StatCard({
    super.key,
    required this.label,
    required this.value,
    this.icon,
    this.iconColor,
  });

  /// Descriptive label shown above the value (e.g. "Best Streak").
  final String label;

  /// The stat value to display prominently (e.g. "14 days").
  final String value;

  /// Optional icon displayed inline with the label.
  final IconData? icon;

  /// Color for the optional icon. Defaults to theme's onSurfaceVariant.
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null)
              Row(
                children: [
                  Icon(icon, size: 16, color: iconColor),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      label,
                      style: context.textTheme.bodySmall?.copyWith(
                        color: context.colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              )
            else
              Text(
                label,
                style: context.textTheme.bodySmall?.copyWith(
                  color: context.colorScheme.onSurfaceVariant,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            const SizedBox(height: 4),
            Text(
              value,
              style: context.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
