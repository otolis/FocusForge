import 'package:flutter/material.dart';

/// Tab switcher for Table and Kanban views.
///
/// Displays two tabs ("Table" and "Kanban") with icons. The active tab
/// has a primary color underline and semibold text. Tapping a tab
/// calls [onTabChanged] with 0 for Table or 1 for Kanban.
class ViewSwitcher extends StatelessWidget {
  /// Currently active tab: 0 = Table, 1 = Kanban.
  final int activeIndex;

  /// Called when a tab is tapped.
  final ValueChanged<int> onTabChanged;

  const ViewSwitcher({
    super.key,
    required this.activeIndex,
    required this.onTabChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      height: 48,
      color: colorScheme.surface,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          _buildTab(
            context,
            index: 0,
            icon: Icons.grid_view,
            label: 'Table',
            colorScheme: colorScheme,
          ),
          const SizedBox(width: 16),
          _buildTab(
            context,
            index: 1,
            icon: Icons.view_column,
            label: 'Kanban',
            colorScheme: colorScheme,
          ),
        ],
      ),
    );
  }

  Widget _buildTab(
    BuildContext context, {
    required int index,
    required IconData icon,
    required String label,
    required ColorScheme colorScheme,
  }) {
    final isActive = activeIndex == index;
    final color =
        isActive ? colorScheme.primary : colorScheme.onSurfaceVariant;

    return GestureDetector(
      onTap: () => onTabChanged(index),
      behavior: HitTestBehavior.opaque,
      child: Container(
        height: 48,
        decoration: isActive
            ? BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: colorScheme.primary,
                    width: 2,
                  ),
                ),
              )
            : null,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
