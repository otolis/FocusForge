import 'habit_frequency.dart';

/// A habit tracked by the user, stored in the `public.habits` Supabase table.
///
/// Each habit has a [frequency] (daily, weekly, or custom), a [targetCount]
/// for count-based habits (1 for binary yes/no habits), and optional
/// [customDays] for specifying which days of the week the habit applies.
///
/// [currentStreak] and [todayProgress] are transient fields computed
/// client-side from habit_logs, not stored in the database.
class Habit {
  final String id;
  final String userId;
  final String name;
  final String? description;
  final HabitFrequency frequency;
  final int targetCount;
  final List<int>? customDays;
  final String? icon;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Transient (computed client-side from habit_logs, not stored in DB)
  final int currentStreak;
  final int todayProgress;

  const Habit({
    required this.id,
    required this.userId,
    required this.name,
    this.description,
    this.frequency = HabitFrequency.daily,
    this.targetCount = 1,
    this.customDays,
    this.icon,
    required this.createdAt,
    required this.updatedAt,
    this.currentStreak = 0,
    this.todayProgress = 0,
  });

  /// Whether this habit is binary (yes/no) or count-based.
  bool get isBinary => targetCount == 1;

  /// Whether today's progress meets or exceeds the target.
  bool get isCompletedToday => todayProgress >= targetCount;

  /// Parses a habit row returned from `supabase.from('habits').select()`.
  factory Habit.fromJson(Map<String, dynamic> json) {
    return Habit(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      frequency: HabitFrequency.values.byName(json['frequency'] as String),
      targetCount: json['target_count'] as int? ?? 1,
      customDays: (json['custom_days'] as List?)?.cast<int>(),
      icon: json['icon'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  /// Produces a JSON map for `supabase.from('habits').insert(...)` or
  /// `supabase.from('habits').update(...)`.
  ///
  /// Excludes `id` and `created_at` because those are server-managed.
  Map<String, dynamic> toJson() => {
        'user_id': userId,
        'name': name,
        'description': description,
        'frequency': frequency.name,
        'target_count': targetCount,
        'custom_days': customDays,
        'icon': icon,
        'updated_at': DateTime.now().toIso8601String(),
      };

  /// Creates a copy of this habit with the given fields replaced.
  Habit copyWith({
    String? name,
    String? description,
    HabitFrequency? frequency,
    int? targetCount,
    List<int>? customDays,
    String? icon,
    int? currentStreak,
    int? todayProgress,
  }) {
    return Habit(
      id: id,
      userId: userId,
      name: name ?? this.name,
      description: description ?? this.description,
      frequency: frequency ?? this.frequency,
      targetCount: targetCount ?? this.targetCount,
      customDays: customDays ?? this.customDays,
      icon: icon ?? this.icon,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
      currentStreak: currentStreak ?? this.currentStreak,
      todayProgress: todayProgress ?? this.todayProgress,
    );
  }
}
