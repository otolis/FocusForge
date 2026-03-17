/// A single completion entry for a habit, stored in `public.habit_logs`.
///
/// Each log represents a completion on a specific [completedDate] with a
/// [count] (1 for binary habits, variable for count-based habits like
/// "drink 8 glasses of water").
///
/// The database enforces a `UNIQUE (habit_id, completed_date)` constraint,
/// so there is at most one log per habit per day. Count-based habits
/// increment the [count] field via upsert.
class HabitLog {
  final String id;
  final String habitId;
  final DateTime completedDate;
  final int count;
  final DateTime createdAt;

  const HabitLog({
    required this.id,
    required this.habitId,
    required this.completedDate,
    this.count = 1,
    required this.createdAt,
  });

  /// Parses a habit_log row returned from Supabase.
  ///
  /// [completed_date] is stored as a `DATE` type (yyyy-MM-dd string).
  factory HabitLog.fromJson(Map<String, dynamic> json) {
    return HabitLog(
      id: json['id'] as String,
      habitId: json['habit_id'] as String,
      completedDate: DateTime.parse(json['completed_date'] as String),
      count: json['count'] as int? ?? 1,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  /// Produces a JSON map for inserting into `habit_logs`.
  ///
  /// Excludes `id` and `created_at` (server-managed).
  /// Formats [completedDate] as `yyyy-MM-dd` string for the `DATE` column.
  Map<String, dynamic> toJson() => {
        'habit_id': habitId,
        'completed_date':
            '${completedDate.year}-${completedDate.month.toString().padLeft(2, '0')}-${completedDate.day.toString().padLeft(2, '0')}',
        'count': count,
      };
}
