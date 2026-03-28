import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/task_filter.dart';
import '../../domain/task_model.dart';
import 'task_provider.dart';

final taskFilterProvider = StateProvider<TaskFilter>(
  (ref) => const TaskFilter(),
);

/// Derived provider that filters and groups the task list based on active filters.
/// For search queries, falls back to client-side title matching (server FTS runs separately).
final filteredTaskListProvider = Provider<AsyncValue<List<Task>>>((ref) {
  final tasksAsync = ref.watch(taskListProvider);
  final filter = ref.watch(taskFilterProvider);

  return tasksAsync.whenData((tasks) {
    var filtered = tasks.where((t) => !t.isCompleted).toList();

    if (filter.priority != null) {
      filtered = filtered.where((t) => t.priority == filter.priority).toList();
    }
    if (filter.categoryId != null) {
      filtered = filtered.where((t) => t.categoryId == filter.categoryId).toList();
    }
    if (filter.dateFrom != null) {
      filtered = filtered
          .where((t) => t.deadline != null && !t.deadline!.isBefore(filter.dateFrom!))
          .toList();
    }
    // FILTER-01: Add 1 day to make end date inclusive of all times on that day
    if (filter.dateTo != null) {
      final inclusiveEnd = filter.dateTo!.add(const Duration(days: 1));
      filtered = filtered
          .where((t) => t.deadline != null && t.deadline!.isBefore(inclusiveEnd))
          .toList();
    }
    if (filter.searchQuery != null && filter.searchQuery!.isNotEmpty) {
      final query = filter.searchQuery!.toLowerCase();
      filtered = filtered
          .where((t) => t.title.toLowerCase().contains(query) ||
              (t.description?.toLowerCase().contains(query) ?? false))
          .toList();
    }

    return filtered;
  });
});

/// Provider for completed tasks (separate from filtered list).
final completedTaskListProvider = Provider<AsyncValue<List<Task>>>((ref) {
  final tasksAsync = ref.watch(taskListProvider);
  return tasksAsync.whenData(
    (tasks) => tasks.where((t) => t.isCompleted).toList(),
  );
});
