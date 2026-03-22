/// Records when a user completed a task or habit relative to a reminder.
///
/// Stored in the `completion_patterns` Supabase table and used by the
/// adaptive timing algorithm to learn the user's optimal reminder timing.
class CompletionPattern {
  final String id;
  final String userId;

  /// Either 'task' or 'habit'.
  final String itemType;

  /// The UUID of the task or habit that was completed.
  final String itemId;

  /// The original deadline (for tasks). Null for habits.
  final DateTime? deadlineAt;

  /// When the item was actually completed.
  final DateTime completedAt;

  /// When the most recent reminder was sent for this item.
  final DateTime? reminderSentAt;

  /// Minutes between reminder sent and completion.
  ///
  /// Used to measure responsiveness and optimize future reminder timing.
  final int? responseDelayMinutes;

  final DateTime createdAt;

  const CompletionPattern({
    required this.id,
    required this.userId,
    required this.itemType,
    required this.itemId,
    this.deadlineAt,
    required this.completedAt,
    this.reminderSentAt,
    this.responseDelayMinutes,
    required this.createdAt,
  });

  /// Parses a completion_patterns row from Supabase.
  factory CompletionPattern.fromJson(Map<String, dynamic> json) {
    return CompletionPattern(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      itemType: json['item_type'] as String,
      itemId: json['item_id'] as String,
      deadlineAt: json['deadline_at'] != null
          ? DateTime.parse(json['deadline_at'] as String)
          : null,
      completedAt: DateTime.parse(json['completed_at'] as String),
      reminderSentAt: json['reminder_sent_at'] != null
          ? DateTime.parse(json['reminder_sent_at'] as String)
          : null,
      responseDelayMinutes: json['response_delay_minutes'] as int?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  /// Produces a JSON map for Supabase insert operations.
  ///
  /// Excludes `id` and `created_at` because those are server-managed.
  Map<String, dynamic> toJson() => {
        'user_id': userId,
        'item_type': itemType,
        'item_id': itemId,
        'deadline_at': deadlineAt?.toIso8601String(),
        'completed_at': completedAt.toIso8601String(),
        'reminder_sent_at': reminderSentAt?.toIso8601String(),
        'response_delay_minutes': responseDelayMinutes,
      };

  CompletionPattern copyWith({
    String? itemType,
    String? itemId,
    DateTime? deadlineAt,
    DateTime? completedAt,
    DateTime? reminderSentAt,
    int? responseDelayMinutes,
  }) {
    return CompletionPattern(
      id: id,
      userId: userId,
      itemType: itemType ?? this.itemType,
      itemId: itemId ?? this.itemId,
      deadlineAt: deadlineAt ?? this.deadlineAt,
      completedAt: completedAt ?? this.completedAt,
      reminderSentAt: reminderSentAt ?? this.reminderSentAt,
      responseDelayMinutes: responseDelayMinutes ?? this.responseDelayMinutes,
      createdAt: createdAt,
    );
  }
}
