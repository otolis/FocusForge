import 'habit_log_model.dart';

/// Pure streak calculation engine for habit tracking analytics.
///
/// All methods are static — no instance state. Works with [HabitLog] data
/// to compute daily/weekly/custom streaks, best streaks, completion rates,
/// and total completions.
class StreakCalculator {
  StreakCalculator._();

  /// Calculates the current daily streak (consecutive days with completions
  /// meeting [targetCount]).
  ///
  /// Grace period: if today is not yet completed but yesterday is, the streak
  /// starts counting from yesterday backwards.
  ///
  /// Returns 0 if neither today nor yesterday are completed.
  static int calculateDailyStreak(List<HabitLog> logs, int targetCount) {
    if (logs.isEmpty) return 0;

    final completed = _buildCompletedDateSet(logs, targetCount);
    if (completed.isEmpty) return 0;

    final today = DateTime.now();
    final todayKey = _dateKey(today);
    final yesterday = today.subtract(const Duration(days: 1));
    final yesterdayKey = _dateKey(yesterday);

    // Determine starting point
    DateTime startDate;
    if (completed.contains(todayKey)) {
      startDate = today;
    } else if (completed.contains(yesterdayKey)) {
      startDate = yesterday;
    } else {
      return 0;
    }

    // Count backwards while date is in the completed set
    var streak = 0;
    var checkDate = startDate;
    while (completed.contains(_dateKey(checkDate))) {
      streak++;
      checkDate = checkDate.subtract(const Duration(days: 1));
    }

    return streak;
  }

  /// Calculates the current weekly streak (consecutive weeks where at least
  /// [targetDaysPerWeek] days met [targetCount]).
  ///
  /// Weeks are ISO weeks (Monday–Sunday). If the current week doesn't meet
  /// the target, counting starts from the previous week.
  static int calculateWeeklyStreak(
    List<HabitLog> logs,
    int targetCount,
    int targetDaysPerWeek,
  ) {
    if (logs.isEmpty) return 0;

    final completed = _buildCompletedDateSet(logs, targetCount);
    if (completed.isEmpty) return 0;

    // Group completed dates by ISO week
    final weekCounts = <String, int>{};
    for (final dateKey in completed) {
      final parts = dateKey.split('-');
      final date = DateTime(
        int.parse(parts[0]),
        int.parse(parts[1]),
        int.parse(parts[2]),
      );
      final wk = _weekKey(date);
      weekCounts[wk] = (weekCounts[wk] ?? 0) + 1;
    }

    // Start from current week, check backwards
    final now = DateTime.now();
    var checkDate = now;
    var currentWeekKey = _weekKey(checkDate);

    // Check if current week meets the target
    final currentWeekMet =
        (weekCounts[currentWeekKey] ?? 0) >= targetDaysPerWeek;

    if (!currentWeekMet) {
      // Move to previous week
      checkDate = _previousMonday(checkDate);
      currentWeekKey = _weekKey(checkDate);
    }

    var streak = 0;
    while ((weekCounts[currentWeekKey] ?? 0) >= targetDaysPerWeek) {
      streak++;
      checkDate = checkDate.subtract(const Duration(days: 7));
      currentWeekKey = _weekKey(checkDate);
    }

    return streak;
  }

  /// Calculates the current custom streak for habits scheduled on specific
  /// [scheduledDays] (1=Monday ... 7=Sunday).
  ///
  /// Only scheduled days are considered. Non-scheduled days are skipped.
  /// If today is not a scheduled day, starts from the most recent scheduled day.
  static int calculateCustomStreak(
    List<HabitLog> logs,
    int targetCount,
    List<int> scheduledDays,
  ) {
    if (logs.isEmpty || scheduledDays.isEmpty) return 0;

    final completed = _buildCompletedDateSet(logs, targetCount);
    if (completed.isEmpty) return 0;

    final now = DateTime.now();

    // Find the most recent scheduled day (today or earlier)
    var checkDate = now;
    while (!scheduledDays.contains(checkDate.weekday)) {
      checkDate = checkDate.subtract(const Duration(days: 1));
    }

    // If the most recent scheduled day is not completed, try the one before
    if (!completed.contains(_dateKey(checkDate))) {
      checkDate = checkDate.subtract(const Duration(days: 1));
      while (!scheduledDays.contains(checkDate.weekday)) {
        checkDate = checkDate.subtract(const Duration(days: 1));
      }
      if (!completed.contains(_dateKey(checkDate))) {
        return 0;
      }
    }

    // Count consecutive scheduled days that are completed
    var streak = 0;
    while (completed.contains(_dateKey(checkDate))) {
      streak++;
      // Move to previous scheduled day
      checkDate = checkDate.subtract(const Duration(days: 1));
      while (!scheduledDays.contains(checkDate.weekday)) {
        checkDate = checkDate.subtract(const Duration(days: 1));
      }
    }

    return streak;
  }

  /// Scans all [logs] and finds the longest consecutive daily streak
  /// where each day meets [targetCount].
  static int bestStreak(List<HabitLog> logs, int targetCount) {
    if (logs.isEmpty) return 0;

    final completed = _buildCompletedDateSet(logs, targetCount);
    if (completed.isEmpty) return 0;

    // Sort the unique dates
    final sortedDates = completed.toList()..sort();

    var best = 1;
    var current = 1;

    for (var i = 1; i < sortedDates.length; i++) {
      final prevParts = sortedDates[i - 1].split('-');
      final currParts = sortedDates[i].split('-');
      final prevDate = DateTime(
        int.parse(prevParts[0]),
        int.parse(prevParts[1]),
        int.parse(prevParts[2]),
      );
      final currDate = DateTime(
        int.parse(currParts[0]),
        int.parse(currParts[1]),
        int.parse(currParts[2]),
      );

      final diff = currDate.difference(prevDate).inDays;
      if (diff == 1) {
        current++;
        if (current > best) best = current;
      } else {
        current = 1;
      }
    }

    return best;
  }

  /// Calculates the completion rate as a percentage for the given date range.
  ///
  /// Returns (days meeting target / total days in range) * 100.
  static double completionRate(
    List<HabitLog> logs,
    int targetCount,
    DateTime from,
    DateTime to,
  ) {
    final totalDays = to.difference(from).inDays + 1;
    if (totalDays <= 0) return 0.0;

    final completed = _buildCompletedDateSet(logs, targetCount);
    if (completed.isEmpty) return 0.0;

    var count = 0;
    var checkDate = DateTime(from.year, from.month, from.day);
    final endDate = DateTime(to.year, to.month, to.day);

    while (!checkDate.isAfter(endDate)) {
      if (completed.contains(_dateKey(checkDate))) {
        count++;
      }
      checkDate = checkDate.add(const Duration(days: 1));
    }

    return (count / totalDays) * 100;
  }

  /// Sums all [HabitLog.count] values across all logs.
  static int totalCompletions(List<HabitLog> logs) {
    return logs.fold(0, (sum, log) => sum + log.count);
  }

  // ---- Helpers ----

  /// Builds a set of date keys ("yyyy-MM-dd") for dates where the total
  /// log count meets or exceeds [targetCount].
  static Set<String> _buildCompletedDateSet(
    List<HabitLog> logs,
    int targetCount,
  ) {
    // Group logs by date and sum counts (in case multiple logs per day)
    final dayCounts = <String, int>{};
    for (final log in logs) {
      final key = _dateKey(log.completedDate);
      dayCounts[key] = (dayCounts[key] ?? 0) + log.count;
    }

    return dayCounts.entries
        .where((e) => e.value >= targetCount)
        .map((e) => e.key)
        .toSet();
  }

  /// Returns a date key in "yyyy-MM-dd" format.
  static String _dateKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  /// Returns an ISO week key in "yyyy-Www" format.
  static String _weekKey(DateTime date) {
    // ISO week: week containing Thursday defines the year
    final thursday = date.add(Duration(days: DateTime.thursday - date.weekday));
    final jan1 = DateTime(thursday.year, 1, 1);
    final weekNumber =
        ((thursday.difference(jan1).inDays) / 7).ceil() + 1;
    return '${thursday.year}-W${weekNumber.toString().padLeft(2, '0')}';
  }

  /// Finds the Monday of the previous week from [date].
  static DateTime _previousMonday(DateTime date) {
    // Go to Monday of current week, then subtract 7 days
    final currentMonday = date.subtract(Duration(days: date.weekday - 1));
    return currentMonday.subtract(const Duration(days: 7));
  }
}
