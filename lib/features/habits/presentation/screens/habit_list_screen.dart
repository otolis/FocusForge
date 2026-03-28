import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/utils/extensions.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/celebration_overlay.dart';
import '../../domain/habit_model.dart';
import '../providers/habit_provider.dart';
import '../widgets/habit_card.dart';

/// The main habits tab screen displaying all user habits with check-in support.
///
/// Uses [habitListProvider] to fetch and display habits via [AsyncValue.when].
/// Supports:
/// - Empty state with prompt to create first habit
/// - One-tap check-in for binary habits
/// - Tap-to-increment and long-press-for-custom-amount for count-based habits
/// - Milestone haptic feedback at 7, 30, and 100 day streaks
/// - FAB to navigate to habit creation form
class HabitListScreen extends ConsumerWidget {
  const HabitListScreen({super.key});

  /// Shows a dialog for entering a custom count for count-based habits.
  Future<void> _showCustomCountDialog(
    BuildContext context,
    WidgetRef ref,
    Habit habit,
  ) async {
    final controller = TextEditingController();
    final result = await showDialog<int>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Log ${habit.name}'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          autofocus: true,
          decoration: InputDecoration(
            labelText: 'Count',
            hintText: 'Enter amount (current: ${habit.todayProgress}/${habit.targetCount})',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final value = int.tryParse(controller.text);
              if (value != null && value > 0) {
                Navigator.pop(dialogContext, value);
              }
            },
            child: const Text('Log'),
          ),
        ],
      ),
    );

    if (result != null) {
      await ref.read(habitListProvider.notifier).checkIn(habit.id, count: result);
      if (!context.mounted) return;
      _checkMilestoneHaptic(context, ref, habit.id);
    }
  }

  /// Checks if the habit just hit a streak milestone and fires medium haptic
  /// with a confetti celebration overlay.
  void _checkMilestoneHaptic(BuildContext context, WidgetRef ref, String habitId) {
    // Read the updated state to check the streak after check-in
    final habitsAsync = ref.read(habitListProvider);
    habitsAsync.whenData((habits) {
      final updated = habits.where((h) => h.id == habitId).firstOrNull;
      if (updated != null) {
        final streak = updated.currentStreak;
        if (streak == 7 || streak == 30 || streak == 100) {
          HapticFeedback.mediumImpact();
          CelebrationOverlay.show(
            context,
            animationAsset: CelebrationAssets.streakMilestone,
            size: 250,
          );
        }
      }
    });
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final habitsAsync = ref.watch(habitListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Habits'),
      ),
      body: habitsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Failed to load habits',
                style: context.textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => ref.invalidate(habitListProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (habits) {
          if (habits.isEmpty) {
            return _buildEmptyState(context);
          }
          return _buildHabitList(context, ref, habits);
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/habits/new'),
        child: const Icon(Icons.add),
      ),
    );
  }

  /// Empty state shown when the user has no habits yet.
  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.local_fire_department_rounded,
              size: 64,
              color: context.colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text(
              'No habits yet',
              style: context.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Tap + to create your first habit',
              style: context.textTheme.bodyMedium?.copyWith(
                color: context.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            AppButton(
              label: 'Create Habit',
              onPressed: () => context.push('/habits/new'),
            ),
          ],
        ),
      ),
    );
  }

  /// Habit list with HabitCard for each habit.
  Widget _buildHabitList(
    BuildContext context,
    WidgetRef ref,
    List<Habit> habits,
  ) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: habits.length,
      itemBuilder: (context, index) {
        final habit = habits[index];
        return HabitCard(
          habit: habit,
          onCheckIn: () async {
            try {
              await ref
                  .read(habitListProvider.notifier)
                  .checkIn(habit.id, count: 1);
              if (!context.mounted) return;
              _checkMilestoneHaptic(context, ref, habit.id);
            } catch (e) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Could not check in. Please try again.'),
                  ),
                );
              }
            }
          },
          onLongPress: () => _showCustomCountDialog(context, ref, habit),
          onTap: () => context.push('/habits/${habit.id}'),
        );
      },
    );
  }
}
