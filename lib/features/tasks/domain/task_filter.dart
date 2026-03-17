import 'task_model.dart';

class TaskFilter {
  final Priority? priority;
  final String? categoryId;
  final DateTime? dateFrom;
  final DateTime? dateTo;
  final String? searchQuery;

  const TaskFilter({
    this.priority,
    this.categoryId,
    this.dateFrom,
    this.dateTo,
    this.searchQuery,
  });

  bool get isEmpty =>
      priority == null &&
      categoryId == null &&
      dateFrom == null &&
      dateTo == null &&
      (searchQuery == null || searchQuery!.isEmpty);

  TaskFilter copyWith({
    Priority? priority,
    bool clearPriority = false,
    String? categoryId,
    bool clearCategory = false,
    DateTime? dateFrom,
    bool clearDateFrom = false,
    DateTime? dateTo,
    bool clearDateTo = false,
    String? searchQuery,
    bool clearSearch = false,
  }) {
    return TaskFilter(
      priority: clearPriority ? null : (priority ?? this.priority),
      categoryId: clearCategory ? null : (categoryId ?? this.categoryId),
      dateFrom: clearDateFrom ? null : (dateFrom ?? this.dateFrom),
      dateTo: clearDateTo ? null : (dateTo ?? this.dateTo),
      searchQuery: clearSearch ? null : (searchQuery ?? this.searchQuery),
    );
  }

  static const TaskFilter empty = TaskFilter();

  TaskFilter clear() => empty;
}
