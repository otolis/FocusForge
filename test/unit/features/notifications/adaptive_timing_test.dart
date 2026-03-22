import 'package:flutter_test/flutter_test.dart';

/// Dart port of the adaptive timing algorithm from the send-reminders
/// Edge Function. Mirrors the TypeScript logic so the algorithm can be
/// validated with deterministic unit tests.
class AdaptiveTimingCalculator {
  /// Analyze completion patterns and return an adaptive insight.
  ///
  /// [completions] -- list of completion records, each containing:
  ///   - `deadline_at` (DateTime?) -- the task's deadline
  ///   - `completed_at` (DateTime) -- when the task was completed
  ///   - `response_delay_minutes` (int?) -- minutes between reminder and completion
  ///
  /// [defaultOffsetMinutes] -- the user's current default reminder offset
  ///
  /// Returns a record with:
  ///   - `adjustedOffsetMinutes` (int?) -- new suggested offset (null if no change)
  ///   - `insight` (String?) -- human-readable insight message (null if insufficient data)
  static ({int? adjustedOffsetMinutes, String? insight}) calculate(
    List<Map<String, dynamic>> completions,
    int defaultOffsetMinutes,
  ) {
    // Need at least 3 completions to detect a pattern
    if (completions.length < 3) {
      return (adjustedOffsetMinutes: null, insight: null);
    }

    // Signal 1: Deadline proximity (minutes before deadline they complete)
    final proximities = completions
        .where((c) => c['deadline_at'] != null)
        .map((c) {
      final deadline = (c['deadline_at'] as DateTime).millisecondsSinceEpoch;
      final completed =
          (c['completed_at'] as DateTime).millisecondsSinceEpoch;
      return (deadline - completed) / (1000 * 60);
    }).toList();

    final double? avgProximity = proximities.isNotEmpty
        ? proximities.reduce((a, b) => a + b) / proximities.length
        : null;

    // Signal 2: Response delay (minutes between reminder and completion)
    final delays = completions
        .where((c) => c['response_delay_minutes'] != null)
        .map((c) => (c['response_delay_minutes'] as num).toDouble())
        .toList();

    final double avgDelay = delays.isNotEmpty
        ? delays.reduce((a, b) => a + b) / delays.length
        : 30.0;

    String? insight;

    // Procrastination detection: completing < 30 min before deadline on average
    if (avgProximity != null && avgProximity < 30) {
      insight =
          'Reminder moved earlier -- you tend to complete tasks ${avgProximity.round()} min before deadline';
    }
    // Fast responder detection: acting on reminders within 15 min on average
    else if (avgDelay < 15 && delays.length >= 3) {
      insight =
          'You typically act on reminders within ${avgDelay.round()} minutes';
    }

    return (adjustedOffsetMinutes: null, insight: insight);
  }
}

void main() {
  group('AdaptiveTimingCalculator', () {
    test('returns null insight when fewer than 3 completions', () {
      final result = AdaptiveTimingCalculator.calculate([
        {
          'deadline_at': DateTime(2026, 3, 20, 14, 0),
          'completed_at': DateTime(2026, 3, 20, 13, 30),
          'response_delay_minutes': 10,
        },
        {
          'deadline_at': DateTime(2026, 3, 21, 14, 0),
          'completed_at': DateTime(2026, 3, 21, 13, 45),
          'response_delay_minutes': 8,
        },
      ], 60);

      expect(result.adjustedOffsetMinutes, isNull);
      expect(result.insight, isNull);
    });

    test('returns null insight for empty completions', () {
      final result = AdaptiveTimingCalculator.calculate([], 60);

      expect(result.adjustedOffsetMinutes, isNull);
      expect(result.insight, isNull);
    });

    test('detects procrastination pattern when avg proximity < 30 min', () {
      final result = AdaptiveTimingCalculator.calculate([
        {
          'deadline_at': DateTime(2026, 3, 18, 17, 0),
          'completed_at': DateTime(2026, 3, 18, 16, 45), // 15 min before
          'response_delay_minutes': 20,
        },
        {
          'deadline_at': DateTime(2026, 3, 19, 12, 0),
          'completed_at': DateTime(2026, 3, 19, 11, 50), // 10 min before
          'response_delay_minutes': 25,
        },
        {
          'deadline_at': DateTime(2026, 3, 20, 9, 0),
          'completed_at': DateTime(2026, 3, 20, 8, 40), // 20 min before
          'response_delay_minutes': 30,
        },
      ], 60);

      expect(result.insight, isNotNull);
      expect(result.insight, contains('Reminder moved earlier'));
      expect(result.insight, contains('min before deadline'));
    });

    test(
        'generates insight message with correct proximity value for procrastination',
        () {
      // All complete exactly 10 min before deadline
      final result = AdaptiveTimingCalculator.calculate([
        {
          'deadline_at': DateTime(2026, 3, 18, 17, 0),
          'completed_at': DateTime(2026, 3, 18, 16, 50), // 10 min
          'response_delay_minutes': 30,
        },
        {
          'deadline_at': DateTime(2026, 3, 19, 12, 0),
          'completed_at': DateTime(2026, 3, 19, 11, 50), // 10 min
          'response_delay_minutes': 30,
        },
        {
          'deadline_at': DateTime(2026, 3, 20, 9, 0),
          'completed_at': DateTime(2026, 3, 20, 8, 50), // 10 min
          'response_delay_minutes': 30,
        },
      ], 60);

      expect(result.insight, contains('10 min before deadline'));
    });

    test('detects fast responder pattern when avg delay < 15 min', () {
      // Complete well before deadline (not procrastinating) but respond fast
      final result = AdaptiveTimingCalculator.calculate([
        {
          'deadline_at': DateTime(2026, 3, 18, 17, 0),
          'completed_at': DateTime(2026, 3, 18, 12, 0), // 300 min before
          'response_delay_minutes': 5,
        },
        {
          'deadline_at': DateTime(2026, 3, 19, 12, 0),
          'completed_at': DateTime(2026, 3, 19, 8, 0), // 240 min before
          'response_delay_minutes': 8,
        },
        {
          'deadline_at': DateTime(2026, 3, 20, 9, 0),
          'completed_at': DateTime(2026, 3, 20, 5, 0), // 240 min before
          'response_delay_minutes': 10,
        },
      ], 60);

      expect(result.insight, isNotNull);
      expect(result.insight, contains('act on reminders within'));
      expect(result.insight, contains('minutes'));
    });

    test('returns no insight for normal completion patterns', () {
      // Completes >30 min before deadline, response delay >15 min
      final result = AdaptiveTimingCalculator.calculate([
        {
          'deadline_at': DateTime(2026, 3, 18, 17, 0),
          'completed_at': DateTime(2026, 3, 18, 14, 0), // 180 min before
          'response_delay_minutes': 45,
        },
        {
          'deadline_at': DateTime(2026, 3, 19, 12, 0),
          'completed_at': DateTime(2026, 3, 19, 9, 0), // 180 min before
          'response_delay_minutes': 30,
        },
        {
          'deadline_at': DateTime(2026, 3, 20, 9, 0),
          'completed_at': DateTime(2026, 3, 20, 7, 0), // 120 min before
          'response_delay_minutes': 60,
        },
      ], 60);

      expect(result.insight, isNull);
    });

    test('handles completions without deadlines gracefully', () {
      // No deadline_at means proximity can't be calculated
      final result = AdaptiveTimingCalculator.calculate([
        {
          'deadline_at': null,
          'completed_at': DateTime(2026, 3, 18, 14, 0),
          'response_delay_minutes': 45,
        },
        {
          'deadline_at': null,
          'completed_at': DateTime(2026, 3, 19, 9, 0),
          'response_delay_minutes': 30,
        },
        {
          'deadline_at': null,
          'completed_at': DateTime(2026, 3, 20, 7, 0),
          'response_delay_minutes': 60,
        },
      ], 60);

      // No proximity data, delay > 15 -- no insight
      expect(result.insight, isNull);
    });

    test('procrastination takes priority over fast responder', () {
      // Both signals present: avg proximity < 30 AND avg delay < 15
      // Procrastination pattern should take priority
      final result = AdaptiveTimingCalculator.calculate([
        {
          'deadline_at': DateTime(2026, 3, 18, 17, 0),
          'completed_at': DateTime(2026, 3, 18, 16, 50), // 10 min before
          'response_delay_minutes': 5,
        },
        {
          'deadline_at': DateTime(2026, 3, 19, 12, 0),
          'completed_at': DateTime(2026, 3, 19, 11, 48), // 12 min before
          'response_delay_minutes': 8,
        },
        {
          'deadline_at': DateTime(2026, 3, 20, 9, 0),
          'completed_at': DateTime(2026, 3, 20, 8, 52), // 8 min before
          'response_delay_minutes': 3,
        },
      ], 60);

      expect(result.insight, isNotNull);
      expect(result.insight, contains('Reminder moved earlier'));
    });
  });
}
