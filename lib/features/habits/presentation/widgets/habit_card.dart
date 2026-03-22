import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/utils/extensions.dart';
import '../../domain/habit_model.dart';
import '../../domain/habit_frequency.dart';
import 'check_in_button.dart';

/// A card widget displaying a single habit with check-in circle, streak badge,
/// and frequency chip.
///
/// Tapping the card navigates to the habit detail screen.
/// The leading [CheckInButton] handles tap (single increment) and
/// long-press (custom count entry for count-based habits).
class HabitCard extends StatelessWidget {
  const HabitCard({
    super.key,
    required this.habit,
    required this.onCheckIn,
    this.onLongPress,
    this.onTap,
  });

  /// The habit to display.
  final Habit habit;

  /// Called when the check-in button is tapped (single increment).
  final VoidCallback onCheckIn;

  /// Called when the check-in button is long-pressed (custom count).
  final VoidCallback? onLongPress;

  /// Called when the card itself is tapped. Defaults to navigating
  /// to `/habits/{id}`.
  final VoidCallback? onTap;

  String _frequencyLabel(HabitFrequency frequency) {
    switch (frequency) {
      case HabitFrequency.daily:
        return 'Daily';
      case HabitFrequency.weekly:
        return 'Weekly';
      case HabitFrequency.custom:
        return 'Custom';
    }
  }

  @override
  Widget build(BuildContext context) {
    final completedTint = habit.isCompletedToday
        ? context.colorScheme.primary.withOpacity(0.05)
        : null;

    return Card(
      color: completedTint,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap ?? () => context.push('/habits/${habit.id}'),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              // Leading check-in button
              CheckInButton(
                isCompleted: habit.isCompletedToday,
                onTap: onCheckIn,
                onLongPress: habit.isBinary ? null : onLongPress,
                progress: habit.todayProgress,
                target: habit.targetCount,
              ),
              const SizedBox(width: 12),

              // Habit info column
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      habit.name,
                      style: context.textTheme.titleMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        // Streak badge
                        if (habit.currentStreak > 0) ...[
                          Icon(
                            Icons.local_fire_department,
                            color: Colors.orange,
                            size: 16,
                          ),
                          const SizedBox(width: 2),
                          Text(
                            '${habit.currentStreak} day streak',
                            style: context.textTheme.bodySmall,
                          ),
                          const SizedBox(width: 8),
                        ],
                        // Frequency chip
                        Chip(
                          label: Text(
                            _frequencyLabel(habit.frequency),
                            style: context.textTheme.labelSmall,
                          ),
                          visualDensity: VisualDensity.compact,
                          padding: EdgeInsets.zero,
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Trailing icon
              if (habit.icon != null)
                Icon(
                  Icons.circle,
                  size: 24,
                  color: context.colorScheme.onSurfaceVariant,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
