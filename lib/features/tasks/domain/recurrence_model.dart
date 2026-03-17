enum RecurrenceType { daily, weekly, monthly, custom }

class RecurrenceRule {
  final String id;
  final String taskId;
  final RecurrenceType type;
  final int? intervalDays;
  final List<int>? daysOfWeek; // ISO weekday: 1=Mon, 7=Sun
  final int? dayOfMonth;
  final DateTime createdAt;

  const RecurrenceRule({
    required this.id,
    required this.taskId,
    required this.type,
    this.intervalDays,
    this.daysOfWeek,
    this.dayOfMonth,
    required this.createdAt,
  });

  factory RecurrenceRule.fromJson(Map<String, dynamic> json) {
    return RecurrenceRule(
      id: json['id'] as String,
      taskId: json['task_id'] as String,
      type: RecurrenceType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => RecurrenceType.daily,
      ),
      intervalDays: json['interval_days'] as int?,
      daysOfWeek: (json['days_of_week'] as List?)?.cast<int>(),
      dayOfMonth: json['day_of_month'] as int?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'task_id': taskId,
        'type': type.name,
        'interval_days': intervalDays,
        'days_of_week': daysOfWeek,
        'day_of_month': dayOfMonth,
      };

  String get displayLabel {
    switch (type) {
      case RecurrenceType.daily:
        return 'Daily';
      case RecurrenceType.weekly:
        if (daysOfWeek == null || daysOfWeek!.isEmpty) return 'Weekly';
        const dayNames = ['', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
        final names = daysOfWeek!.map((d) => dayNames[d.clamp(1, 7)]).toList();
        return names.join('/');
      case RecurrenceType.monthly:
        if (dayOfMonth != null) return 'Monthly (${_ordinal(dayOfMonth!)})';
        return 'Monthly';
      case RecurrenceType.custom:
        if (intervalDays != null) return 'Every $intervalDays days';
        return 'Custom';
    }
  }

  static String _ordinal(int day) {
    if (day >= 11 && day <= 13) return '${day}th';
    switch (day % 10) {
      case 1: return '${day}st';
      case 2: return '${day}nd';
      case 3: return '${day}rd';
      default: return '${day}th';
    }
  }
}
