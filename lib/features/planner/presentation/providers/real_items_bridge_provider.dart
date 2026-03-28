import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../tasks/presentation/providers/task_provider.dart';
import '../../../tasks/domain/task_model.dart';
import '../../../habits/presentation/providers/habit_provider.dart';
import '../../domain/plannable_item_model.dart';

/// Bridges real tasks and habits into [PlannableItem] objects for the AI planner.
///
/// Watches [taskListProvider] and [habitListProvider] reactively. Converts:
/// - Uncompleted tasks into PlannableItems with duration mapped from priority
/// - Habits not yet completed today into PlannableItems with duration 15 min
///   and medium energy
///
/// The manual AddItemSheet flow continues to work alongside this bridge.
final realPlannableItemsProvider = Provider<List<PlannableItem>>((ref) {
  final tasks = ref.watch(taskListProvider).valueOrNull ?? [];
  final habits = ref.watch(habitListProvider).valueOrNull ?? [];

  final items = <PlannableItem>[];
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);

  // Convert uncompleted tasks into plannable items
  for (final task in tasks.where((t) => !t.isCompleted)) {
    items.add(PlannableItem(
      id: task.id,
      userId: task.userId,
      title: task.title,
      durationMinutes: _estimateDuration(task.priority),
      energyLevel: _mapPriorityToEnergy(task.priority),
      planDate: today,
      createdAt: task.createdAt,
      sourceType: 'task',
      sourceId: task.id,
    ));
  }

  // Convert habits not completed today into plannable items
  for (final habit in habits.where((h) => !h.isCompletedToday)) {
    items.add(PlannableItem(
      id: habit.id,
      userId: habit.userId,
      title: habit.name,
      durationMinutes: 15,
      energyLevel: EnergyLevel.medium,
      planDate: today,
      createdAt: habit.createdAt,
      sourceType: 'habit',
      sourceId: habit.id,
    ));
  }

  return items;
});

/// Maps task priority to planner energy level.
/// P1 (urgent) and P2 (high) require deep focus = high energy.
/// P3 (normal) = medium energy.
/// P4 (low) = low energy.
EnergyLevel _mapPriorityToEnergy(Priority priority) {
  return switch (priority) {
    Priority.p1 => EnergyLevel.high,
    Priority.p2 => EnergyLevel.high,
    Priority.p3 => EnergyLevel.medium,
    Priority.p4 => EnergyLevel.low,
  };
}

/// Estimates task duration based on priority.
/// Higher priority tasks tend to be more involved.
int _estimateDuration(Priority priority) {
  return switch (priority) {
    Priority.p1 => 60,
    Priority.p2 => 45,
    Priority.p3 => 30,
    Priority.p4 => 15,
  };
}
