import 'package:flutter_test/flutter_test.dart';

/// Dart port of the quiet hours logic from the send-reminders Edge Function.
/// Handles midnight wrap-around (e.g., 22:00 -- 07:00).
class QuietHoursChecker {
  /// Determine if [now] falls within the quiet hours window defined by
  /// [quietStart] and [quietEnd] (both in "HH:MM" 24-hour format).
  ///
  /// Returns `false` if either parameter is null.
  /// Handles midnight wrap-around correctly (e.g., 22:00 to 07:00).
  static bool isInQuietHours(
    DateTime now,
    String? quietStart,
    String? quietEnd,
  ) {
    if (quietStart == null || quietEnd == null) return false;

    final currentMinutes = now.hour * 60 + now.minute;

    final startParts = quietStart.split(':').map(int.parse).toList();
    final endParts = quietEnd.split(':').map(int.parse).toList();

    final start = startParts[0] * 60 + startParts[1];
    final end = endParts[0] * 60 + endParts[1];

    if (start <= end) {
      // Non-wrapping range (e.g., 13:00 -- 17:00)
      return currentMinutes >= start && currentMinutes < end;
    }

    // Wraps midnight (e.g., 22:00 -- 07:00)
    return currentMinutes >= start || currentMinutes < end;
  }
}

void main() {
  group('QuietHoursChecker', () {
    test('returns false when quietStart is null', () {
      final now = DateTime(2026, 3, 20, 23, 0);
      expect(QuietHoursChecker.isInQuietHours(now, null, '07:00'), isFalse);
    });

    test('returns false when quietEnd is null', () {
      final now = DateTime(2026, 3, 20, 23, 0);
      expect(QuietHoursChecker.isInQuietHours(now, '22:00', null), isFalse);
    });

    test('returns false when both are null', () {
      final now = DateTime(2026, 3, 20, 23, 0);
      expect(QuietHoursChecker.isInQuietHours(now, null, null), isFalse);
    });

    test(
        'returns true when current time is within non-wrapping range (14:00 in 13:00-17:00)',
        () {
      final now = DateTime(2026, 3, 20, 14, 0);
      expect(
          QuietHoursChecker.isInQuietHours(now, '13:00', '17:00'), isTrue);
    });

    test(
        'returns false when current time is outside non-wrapping range (18:00 in 13:00-17:00)',
        () {
      final now = DateTime(2026, 3, 20, 18, 0);
      expect(
          QuietHoursChecker.isInQuietHours(now, '13:00', '17:00'), isFalse);
    });

    test(
        'returns false when current time is before non-wrapping range (10:00 in 13:00-17:00)',
        () {
      final now = DateTime(2026, 3, 20, 10, 0);
      expect(
          QuietHoursChecker.isInQuietHours(now, '13:00', '17:00'), isFalse);
    });

    test(
        'returns true when current time is within wrapping range late night (23:00 in 22:00-07:00)',
        () {
      final now = DateTime(2026, 3, 20, 23, 0);
      expect(
          QuietHoursChecker.isInQuietHours(now, '22:00', '07:00'), isTrue);
    });

    test(
        'returns true when current time is within wrapping range early morning (05:00 in 22:00-07:00)',
        () {
      final now = DateTime(2026, 3, 21, 5, 0);
      expect(
          QuietHoursChecker.isInQuietHours(now, '22:00', '07:00'), isTrue);
    });

    test(
        'returns false when current time is outside wrapping range (12:00 in 22:00-07:00)',
        () {
      final now = DateTime(2026, 3, 20, 12, 0);
      expect(
          QuietHoursChecker.isInQuietHours(now, '22:00', '07:00'), isFalse);
    });

    test(
        'returns false when current time is just outside wrapping range (15:00 in 22:00-07:00)',
        () {
      final now = DateTime(2026, 3, 20, 15, 0);
      expect(
          QuietHoursChecker.isInQuietHours(now, '22:00', '07:00'), isFalse);
    });

    test('handles edge case: current time equals quiet start (should be in quiet hours)',
        () {
      final now = DateTime(2026, 3, 20, 22, 0);
      expect(
          QuietHoursChecker.isInQuietHours(now, '22:00', '07:00'), isTrue);
    });

    test(
        'handles edge case: current time equals quiet end (should NOT be in quiet hours)',
        () {
      final now = DateTime(2026, 3, 21, 7, 0);
      expect(
          QuietHoursChecker.isInQuietHours(now, '22:00', '07:00'), isFalse);
    });

    test('handles midnight exactly in wrapping range (00:00 in 22:00-07:00)',
        () {
      final now = DateTime(2026, 3, 21, 0, 0);
      expect(
          QuietHoursChecker.isInQuietHours(now, '22:00', '07:00'), isTrue);
    });

    test(
        'handles non-wrapping range edge: current time equals start (13:00 in 13:00-17:00)',
        () {
      final now = DateTime(2026, 3, 20, 13, 0);
      expect(
          QuietHoursChecker.isInQuietHours(now, '13:00', '17:00'), isTrue);
    });

    test(
        'handles non-wrapping range edge: current time equals end (17:00 in 13:00-17:00)',
        () {
      final now = DateTime(2026, 3, 20, 17, 0);
      expect(
          QuietHoursChecker.isInQuietHours(now, '13:00', '17:00'), isFalse);
    });
  });
}
