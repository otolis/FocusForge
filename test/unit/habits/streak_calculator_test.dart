import 'package:flutter_test/flutter_test.dart';
import 'package:focusforge/features/habits/domain/habit_log_model.dart';
import 'package:focusforge/features/habits/domain/streak_calculator.dart';

/// Helper to create a [HabitLog] for a given date and count.
HabitLog makeLog(DateTime date, int count) {
  return HabitLog(
    id: 'log-${date.toIso8601String()}',
    habitId: 'habit-test',
    completedDate: DateTime(date.year, date.month, date.day),
    count: count,
    createdAt: date,
  );
}

void main() {
  group('calculateDailyStreak', () {
    test('5 consecutive days ending today returns 5', () {
      final now = DateTime.now();
      final logs = List.generate(
        5,
        (i) => makeLog(now.subtract(Duration(days: i)), 1),
      );

      expect(StreakCalculator.calculateDailyStreak(logs, 1), 5);
    });

    test('5 consecutive days ending yesterday returns 5 (grace for today)', () {
      final now = DateTime.now();
      final logs = List.generate(
        5,
        (i) => makeLog(now.subtract(Duration(days: i + 1)), 1),
      );

      expect(StreakCalculator.calculateDailyStreak(logs, 1), 5);
    });

    test('gap 2 days ago returns 2 (yesterday + today)', () {
      final now = DateTime.now();
      final logs = [
        makeLog(now, 1),
        makeLog(now.subtract(const Duration(days: 1)), 1),
        // gap at day 2
        makeLog(now.subtract(const Duration(days: 3)), 1),
        makeLog(now.subtract(const Duration(days: 4)), 1),
      ];

      expect(StreakCalculator.calculateDailyStreak(logs, 1), 2);
    });

    test('no completions returns 0', () {
      expect(StreakCalculator.calculateDailyStreak([], 1), 0);
    });

    test('only today returns 1', () {
      final now = DateTime.now();
      final logs = [makeLog(now, 1)];

      expect(StreakCalculator.calculateDailyStreak(logs, 1), 1);
    });

    test('partial completion day (count < targetCount) is NOT counted', () {
      final now = DateTime.now();
      final logs = [
        makeLog(now, 2), // meets target
        makeLog(now.subtract(const Duration(days: 1)), 1), // partial (< 2)
        makeLog(now.subtract(const Duration(days: 2)), 2), // meets target
      ];

      // Day 1 (yesterday) is partial so streak breaks -> only today counts
      expect(StreakCalculator.calculateDailyStreak(logs, 2), 1);
    });
  });

  group('calculateWeeklyStreak', () {
    test('3 consecutive weeks with 3/3 completions returns 3', () {
      final now = DateTime.now();
      // Current week: 3 days completed
      // Previous week: 3 days completed
      // Week before: 3 days completed
      // Build logs for each week
      final logs = <HabitLog>[];

      // Find Monday of current week
      final monday = now.subtract(Duration(days: now.weekday - 1));

      for (var week = 0; week < 3; week++) {
        final weekStart = monday.subtract(Duration(days: week * 7));
        for (var day = 0; day < 3; day++) {
          logs.add(makeLog(weekStart.add(Duration(days: day)), 1));
        }
      }

      expect(StreakCalculator.calculateWeeklyStreak(logs, 1, 3), 3);
    });

    test('current week incomplete, 2 previous met returns 2', () {
      final now = DateTime.now();
      final monday = now.subtract(Duration(days: now.weekday - 1));

      final logs = <HabitLog>[];

      // Current week: only 1 day (not meeting 3/week target)
      logs.add(makeLog(monday, 1));

      // Previous week: 3 days
      final prevMonday = monday.subtract(const Duration(days: 7));
      for (var day = 0; day < 3; day++) {
        logs.add(makeLog(prevMonday.add(Duration(days: day)), 1));
      }

      // Week before: 3 days
      final prevPrevMonday = monday.subtract(const Duration(days: 14));
      for (var day = 0; day < 3; day++) {
        logs.add(makeLog(prevPrevMonday.add(Duration(days: day)), 1));
      }

      expect(StreakCalculator.calculateWeeklyStreak(logs, 1, 3), 2);
    });
  });

  group('calculateCustomStreak', () {
    test('Mon/Wed/Fri schedule, all completed for 2 weeks returns 6', () {
      final now = DateTime.now();
      // Find the most recent Friday (or today if it's Friday)
      final scheduledDays = [
        DateTime.monday,
        DateTime.wednesday,
        DateTime.friday,
      ];

      // Walk backwards to find the 6 most recent scheduled days and mark them complete
      final logs = <HabitLog>[];
      var checkDate = now;
      var scheduledCount = 0;
      while (scheduledCount < 6) {
        if (scheduledDays.contains(checkDate.weekday)) {
          logs.add(makeLog(checkDate, 1));
          scheduledCount++;
        }
        checkDate = checkDate.subtract(const Duration(days: 1));
      }

      expect(
        StreakCalculator.calculateCustomStreak(logs, 1, scheduledDays),
        6,
      );
    });

    test('non-scheduled days are ignored', () {
      final now = DateTime.now();
      final scheduledDays = [
        DateTime.monday,
        DateTime.wednesday,
        DateTime.friday,
      ];

      // Create logs: complete all scheduled days for 1 week + some non-scheduled days
      final logs = <HabitLog>[];
      var checkDate = now;
      var scheduledCount = 0;
      while (scheduledCount < 3) {
        if (scheduledDays.contains(checkDate.weekday)) {
          logs.add(makeLog(checkDate, 1));
          scheduledCount++;
        }
        checkDate = checkDate.subtract(const Duration(days: 1));
      }

      // Add a non-scheduled day log (e.g., Tuesday) -- should be ignored
      final tuesday = now.subtract(
        Duration(days: (now.weekday - DateTime.tuesday) % 7),
      );
      logs.add(makeLog(tuesday, 1));

      // Streak should still be 3 (only scheduled days count)
      expect(
        StreakCalculator.calculateCustomStreak(logs, 1, scheduledDays),
        3,
      );
    });
  });

  group('bestStreak', () {
    test('finds longest streak in scattered logs', () {
      // Build two streaks: 3 days and 5 days, separated by a gap
      final now = DateTime.now();
      final logs = [
        // Recent streak of 3
        makeLog(now, 1),
        makeLog(now.subtract(const Duration(days: 1)), 1),
        makeLog(now.subtract(const Duration(days: 2)), 1),
        // Gap at day 3
        // Older streak of 5
        makeLog(now.subtract(const Duration(days: 10)), 1),
        makeLog(now.subtract(const Duration(days: 11)), 1),
        makeLog(now.subtract(const Duration(days: 12)), 1),
        makeLog(now.subtract(const Duration(days: 13)), 1),
        makeLog(now.subtract(const Duration(days: 14)), 1),
      ];

      expect(StreakCalculator.bestStreak(logs, 1), 5);
    });
  });

  group('completionRate', () {
    test('7 of 10 days returns 70.0', () {
      final now = DateTime.now();
      final from = now.subtract(const Duration(days: 9));
      final logs = List.generate(
        7,
        (i) => makeLog(from.add(Duration(days: i)), 1),
      );

      expect(StreakCalculator.completionRate(logs, 1, from, now), 70.0);
    });

    test('0 days returns 0.0', () {
      final now = DateTime.now();
      final from = now.subtract(const Duration(days: 9));

      expect(StreakCalculator.completionRate([], 1, from, now), 0.0);
    });
  });

  group('totalCompletions', () {
    test('sums all log counts', () {
      final now = DateTime.now();
      final logs = [
        makeLog(now, 3),
        makeLog(now.subtract(const Duration(days: 1)), 2),
        makeLog(now.subtract(const Duration(days: 2)), 5),
      ];

      expect(StreakCalculator.totalCompletions(logs), 10);
    });
  });
}
