import 'category_model.dart';

enum Priority { p1, p2, p3, p4 }

enum TaskStatus { pending, completed }

class Task {
  final String id;
  final String userId;
  final String title;
  final String? description;
  final Priority priority;
  final String? categoryId;
  final DateTime? deadline;
  final bool isCompleted;
  final DateTime? completedAt;
  final String? recurrenceRuleId;
  final String? parentTaskId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Category? category; // Joined from select('*, categories(*)')

  const Task({
    required this.id,
    required this.userId,
    required this.title,
    this.description,
    this.priority = Priority.p3,
    this.categoryId,
    this.deadline,
    this.isCompleted = false,
    this.completedAt,
    this.recurrenceRuleId,
    this.parentTaskId,
    required this.createdAt,
    required this.updatedAt,
    this.category,
  });

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      priority: Priority.values[(json['priority'] as int?) ?? 2],
      categoryId: json['category_id'] as String?,
      deadline: json['deadline'] != null
          ? DateTime.parse(json['deadline'] as String)
          : null,
      isCompleted: json['is_completed'] as bool? ?? false,
      completedAt: json['completed_at'] != null
          ? DateTime.parse(json['completed_at'] as String)
          : null,
      recurrenceRuleId: json['recurrence_rule_id'] as String?,
      parentTaskId: json['parent_task_id'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      category: json['categories'] != null
          ? Category.fromJson(json['categories'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'user_id': userId,
        'title': title,
        'description': description,
        'priority': priority.index,
        'category_id': categoryId,
        'deadline': deadline?.toIso8601String(),
        'is_completed': isCompleted,
        'completed_at': completedAt?.toIso8601String(),
        'recurrence_rule_id': recurrenceRuleId,
        'parent_task_id': parentTaskId,
        'updated_at': DateTime.now().toIso8601String(),
      };

  Task copyWith({
    String? title,
    String? description,
    Priority? priority,
    String? categoryId,
    bool clearCategory = false,
    DateTime? deadline,
    bool clearDeadline = false,
    bool? isCompleted,
    DateTime? completedAt,
    bool clearCompletedAt = false,
    String? recurrenceRuleId,
    bool clearRecurrenceRuleId = false,
    String? parentTaskId,
    Category? category,
    bool clearCategoryObj = false,
  }) {
    return Task(
      id: id,
      userId: userId,
      title: title ?? this.title,
      description: description ?? this.description,
      priority: priority ?? this.priority,
      categoryId: clearCategory ? null : (categoryId ?? this.categoryId),
      deadline: clearDeadline ? null : (deadline ?? this.deadline),
      isCompleted: isCompleted ?? this.isCompleted,
      completedAt: clearCompletedAt ? null : (completedAt ?? this.completedAt),
      recurrenceRuleId: clearRecurrenceRuleId
          ? null
          : (recurrenceRuleId ?? this.recurrenceRuleId),
      parentTaskId: parentTaskId ?? this.parentTaskId,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
      category: clearCategoryObj ? null : (category ?? this.category),
    );
  }

  TaskStatus get status =>
      isCompleted ? TaskStatus.completed : TaskStatus.pending;
}
