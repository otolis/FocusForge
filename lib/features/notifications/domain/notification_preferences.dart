/// User notification preferences stored in the `notification_preferences`
/// Supabase table.
///
/// Controls which types of notifications the user receives, quiet hours,
/// default reminder offsets, and snooze duration. Created automatically
/// by a database trigger when a new user signs up.
class NotificationPreferences {
  final String id;
  final String userId;

  /// Master toggle -- when false, all notifications are suppressed.
  final bool enabled;

  /// Whether task deadline reminders are enabled.
  final bool taskRemindersEnabled;

  /// Default reminder offsets in minutes before a task deadline.
  ///
  /// Example: `[1440, 60]` means reminders at 24 hours and 1 hour before.
  final List<int> taskDefaultOffsets;

  /// Whether habit reminders are enabled.
  final bool habitRemindersEnabled;

  /// Time of day for the daily habit summary notification (e.g. "08:00").
  final String habitDailySummaryTime;

  /// Whether the AI planner daily summary notification is enabled.
  final bool plannerSummaryEnabled;

  /// Whether time-block start reminders are enabled.
  final bool plannerBlockRemindersEnabled;

  /// Minutes before a time block starts to send the reminder.
  final int plannerBlockOffset;

  /// Whether quiet hours are enabled (suppress notifications during window).
  final bool quietHoursEnabled;

  /// Start of the quiet hours window (e.g. "22:00").
  final String quietStart;

  /// End of the quiet hours window (e.g. "07:00").
  final String quietEnd;

  /// Duration in minutes for the snooze action on notifications.
  final int snoozeDuration;

  final DateTime createdAt;
  final DateTime updatedAt;

  const NotificationPreferences({
    required this.id,
    required this.userId,
    this.enabled = true,
    this.taskRemindersEnabled = true,
    this.taskDefaultOffsets = const [1440, 60],
    this.habitRemindersEnabled = true,
    this.habitDailySummaryTime = '08:00',
    this.plannerSummaryEnabled = true,
    this.plannerBlockRemindersEnabled = true,
    this.plannerBlockOffset = 15,
    this.quietHoursEnabled = false,
    this.quietStart = '22:00',
    this.quietEnd = '07:00',
    this.snoozeDuration = 15,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Creates default preferences for a user before the DB trigger has run.
  ///
  /// Useful for optimistic UI display while the server-side record is created.
  factory NotificationPreferences.defaults({required String userId}) {
    final now = DateTime.now();
    return NotificationPreferences(
      id: '',
      userId: userId,
      createdAt: now,
      updatedAt: now,
    );
  }

  /// Parses a notification_preferences row from Supabase.
  factory NotificationPreferences.fromJson(Map<String, dynamic> json) {
    return NotificationPreferences(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      enabled: json['enabled'] as bool? ?? true,
      taskRemindersEnabled: json['task_reminders_enabled'] as bool? ?? true,
      taskDefaultOffsets:
          (json['task_default_offsets'] as List?)?.cast<int>() ?? [1440, 60],
      habitRemindersEnabled:
          json['habit_reminders_enabled'] as bool? ?? true,
      habitDailySummaryTime:
          json['habit_daily_summary_time'] as String? ?? '08:00',
      plannerSummaryEnabled:
          json['planner_summary_enabled'] as bool? ?? true,
      plannerBlockRemindersEnabled:
          json['planner_block_reminders_enabled'] as bool? ?? true,
      plannerBlockOffset: json['planner_block_offset'] as int? ?? 15,
      quietHoursEnabled: json['quiet_hours_enabled'] as bool? ?? false,
      quietStart: json['quiet_start'] as String? ?? '22:00',
      quietEnd: json['quiet_end'] as String? ?? '07:00',
      snoozeDuration: json['snooze_duration'] as int? ?? 15,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  /// Produces a JSON map for Supabase update operations.
  ///
  /// Excludes `id` and `created_at` because those are server-managed.
  Map<String, dynamic> toJson() => {
        'user_id': userId,
        'enabled': enabled,
        'task_reminders_enabled': taskRemindersEnabled,
        'task_default_offsets': taskDefaultOffsets,
        'habit_reminders_enabled': habitRemindersEnabled,
        'habit_daily_summary_time': habitDailySummaryTime,
        'planner_summary_enabled': plannerSummaryEnabled,
        'planner_block_reminders_enabled': plannerBlockRemindersEnabled,
        'planner_block_offset': plannerBlockOffset,
        'quiet_hours_enabled': quietHoursEnabled,
        'quiet_start': quietStart,
        'quiet_end': quietEnd,
        'snooze_duration': snoozeDuration,
        'updated_at': DateTime.now().toIso8601String(),
      };

  NotificationPreferences copyWith({
    bool? enabled,
    bool? taskRemindersEnabled,
    List<int>? taskDefaultOffsets,
    bool? habitRemindersEnabled,
    String? habitDailySummaryTime,
    bool? plannerSummaryEnabled,
    bool? plannerBlockRemindersEnabled,
    int? plannerBlockOffset,
    bool? quietHoursEnabled,
    String? quietStart,
    String? quietEnd,
    int? snoozeDuration,
  }) {
    return NotificationPreferences(
      id: id,
      userId: userId,
      enabled: enabled ?? this.enabled,
      taskRemindersEnabled: taskRemindersEnabled ?? this.taskRemindersEnabled,
      taskDefaultOffsets: taskDefaultOffsets ?? this.taskDefaultOffsets,
      habitRemindersEnabled:
          habitRemindersEnabled ?? this.habitRemindersEnabled,
      habitDailySummaryTime:
          habitDailySummaryTime ?? this.habitDailySummaryTime,
      plannerSummaryEnabled:
          plannerSummaryEnabled ?? this.plannerSummaryEnabled,
      plannerBlockRemindersEnabled:
          plannerBlockRemindersEnabled ?? this.plannerBlockRemindersEnabled,
      plannerBlockOffset: plannerBlockOffset ?? this.plannerBlockOffset,
      quietHoursEnabled: quietHoursEnabled ?? this.quietHoursEnabled,
      quietStart: quietStart ?? this.quietStart,
      quietEnd: quietEnd ?? this.quietEnd,
      snoozeDuration: snoozeDuration ?? this.snoozeDuration,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}
