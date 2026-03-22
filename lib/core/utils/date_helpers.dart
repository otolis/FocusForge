import 'package:intl/intl.dart';

/// Ordered list of date section names for consistent sorting of task groups.
const dateSectionOrder = [
  'Overdue',
  'Today',
  'Tomorrow',
  'This Week',
  'Later',
  'No Deadline',
];

/// Returns the date section label for a given [deadline].
///
/// Possible return values: 'Overdue', 'Today', 'Tomorrow', 'This Week',
/// 'Later', or 'No Deadline' (when [deadline] is null).
String getDateSection(DateTime? deadline) {
  if (deadline == null) return 'No Deadline';

  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final tomorrow = today.add(const Duration(days: 1));
  final endOfWeek = today.add(Duration(days: 7 - today.weekday % 7));

  final deadlineDate = DateTime(deadline.year, deadline.month, deadline.day);

  if (deadlineDate.isBefore(today)) return 'Overdue';
  if (deadlineDate.isBefore(tomorrow)) return 'Today';
  if (deadlineDate.isBefore(tomorrow.add(const Duration(days: 1)))) {
    return 'Tomorrow';
  }
  if (deadlineDate.isBefore(endOfWeek.add(const Duration(days: 1)))) {
    return 'This Week';
  }
  return 'Later';
}

/// Formats a [deadline] into a human-readable short label.
///
/// Returns 'Today', 'Tomorrow', or a date string like 'Mar 15' (same year)
/// or 'Mar 15, 2025' (different year).
String formatDeadline(DateTime deadline) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final deadlineDate = DateTime(deadline.year, deadline.month, deadline.day);

  if (deadlineDate == today) return 'Today';
  if (deadlineDate == today.add(const Duration(days: 1))) return 'Tomorrow';
  if (deadlineDate.year == now.year) return DateFormat('MMM d').format(deadline);
  return DateFormat('MMM d, y').format(deadline);
}
