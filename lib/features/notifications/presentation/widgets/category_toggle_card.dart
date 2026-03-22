import 'package:flutter/material.dart';

import '../../../../core/utils/extensions.dart';

/// A reusable Material 3 card for toggling a notification category on/off.
///
/// Displays an icon, title, subtitle, and toggle switch. When the category
/// is enabled, optional [children] widgets are revealed with a smooth
/// expand/collapse animation via [AnimatedCrossFade].
///
/// Used on the notification settings screen for task, habit, and planner
/// notification category sections.
class CategoryToggleCard extends StatelessWidget {
  const CategoryToggleCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.enabled,
    required this.onToggled,
    this.children = const [],
  });

  /// Display title for the category (e.g. "Task Reminders").
  final String title;

  /// Brief description shown below the title.
  final String subtitle;

  /// Leading icon for the category.
  final IconData icon;

  /// Whether this notification category is currently enabled.
  final bool enabled;

  /// Callback when the toggle switch is changed.
  final ValueChanged<bool> onToggled;

  /// Additional configuration widgets shown when [enabled] is true.
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  icon,
                  color: enabled
                      ? context.colorScheme.primary
                      : context.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: context.textTheme.titleMedium),
                      Text(
                        subtitle,
                        style: context.textTheme.bodySmall?.copyWith(
                          color: context.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: enabled,
                  onChanged: onToggled,
                ),
              ],
            ),
            AnimatedCrossFade(
              firstChild: const SizedBox.shrink(),
              secondChild: children.isNotEmpty
                  ? Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: children,
                      ),
                    )
                  : const SizedBox.shrink(),
              crossFadeState: enabled
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              duration: const Duration(milliseconds: 250),
            ),
          ],
        ),
      ),
    );
  }
}
