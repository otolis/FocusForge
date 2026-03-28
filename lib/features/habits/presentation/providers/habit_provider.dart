import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/habit_repository.dart';
import '../../domain/habit_model.dart';

/// Provides the [HabitRepository] instance.
final habitRepositoryProvider = Provider<HabitRepository>(
  (ref) => HabitRepository(),
);

/// Provides the user's habit list as an async value with CRUD operations.
///
/// Fetches all habits on build, populates transient fields (todayProgress),
/// and exposes create/update/delete/checkIn methods.
final habitListProvider =
    AsyncNotifierProvider<HabitListNotifier, List<Habit>>(
  HabitListNotifier.new,
);

/// Manages the habit list state with full CRUD and check-in support.
///
/// Uses [AsyncNotifier] because habit data is fetched asynchronously from
/// Supabase. Each mutation re-fetches the full list to ensure consistency.
class HabitListNotifier extends AsyncNotifier<List<Habit>> {
  late HabitRepository _repository;

  @override
  Future<List<Habit>> build() async {
    _repository = ref.read(habitRepositoryProvider);
    final habits = await _repository.getHabits();

    // Populate transient todayProgress for each habit
    final enriched = <Habit>[];
    for (final habit in habits) {
      final progress = await _repository.getTodayProgress(habit.id);
      enriched.add(habit.copyWith(todayProgress: progress));
    }
    return enriched;
  }

  /// Creates a new habit and refreshes the list.
  Future<void> createHabit(Habit habit) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await _repository.createHabit(habit);
      return build();
    });
  }

  /// Updates an existing habit and refreshes the list.
  Future<void> updateHabit(Habit habit) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await _repository.updateHabit(habit);
      return build();
    });
  }

  /// Deletes a habit and refreshes the list.
  Future<void> deleteHabit(String habitId) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await _repository.deleteHabit(habitId);
      return build();
    });
  }

  /// Logs a completion for [habitId] and refreshes the list.
  ///
  /// For binary habits, [count] defaults to 1. For count-based habits,
  /// pass the increment amount.
  Future<void> checkIn(String habitId, {int count = 1}) async {
    await _repository.logCompletion(habitId, count: count);
    ref.invalidateSelf();
  }
}

/// Provides a single habit by [habitId] with today's progress populated.
final habitDetailProvider =
    FutureProvider.family<Habit, String>((ref, habitId) async {
  final repository = ref.read(habitRepositoryProvider);
  final habit = await repository.getHabit(habitId);
  final progress = await repository.getTodayProgress(habitId);
  return habit.copyWith(todayProgress: progress);
});
