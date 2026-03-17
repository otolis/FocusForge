import '../../profile/domain/profile_model.dart';
import 'schedule_block_model.dart';

/// Classifies a time slot based on the user's energy pattern.
enum EnergyZone { peak, low, regular }

/// Constants and utility methods for the daily planner timeline widget.
///
/// The timeline spans from [startHour] (6 AM) to [endHour] (10 PM),
/// rendering each hour as [hourHeight] pixels. All time calculations use
/// minutes-from-midnight internally and convert to pixel offsets for display.
class TimelineConstants {
  TimelineConstants._();

  /// First visible hour on the timeline (6 AM).
  static const int startHour = 6;

  /// Last visible hour on the timeline (10 PM).
  static const int endHour = 22;

  /// Number of hours displayed on the timeline.
  static const int totalHours = endHour - startHour;

  /// Height in pixels for one hour on the timeline.
  static const double hourHeight = 80.0;

  /// Total height of the scrollable timeline in pixels.
  static const double totalHeight = totalHours * hourHeight;

  /// Pixels per minute (hourHeight / 60).
  static const double pixelsPerMinute = hourHeight / 60.0;

  /// Snap interval in minutes for drag-to-reschedule.
  static const int snapMinutes = 15;

  /// Pixel height of one snap interval.
  static const double snapHeight = snapMinutes * pixelsPerMinute;

  /// Converts a time in minutes-from-midnight to a Y pixel offset.
  ///
  /// Example: 540 (9 AM) -> (540 - 360) * pixelsPerMinute = 240.0
  static double minuteToY(int minute) {
    return (minute - startHour * 60) * pixelsPerMinute;
  }

  /// Converts a Y pixel offset to the nearest snapped minute value.
  ///
  /// Snaps to [snapMinutes]-minute intervals and clamps to the visible
  /// timeline range.
  static int yToSnappedMinute(double y) {
    final rawMinutes = (y / pixelsPerMinute).round() + startHour * 60;
    final snapped = (rawMinutes / snapMinutes).round() * snapMinutes;
    return snapped.clamp(startHour * 60, endHour * 60);
  }

  /// Returns the energy zone for the given [hour] based on [pattern].
  ///
  /// - [EnergyZone.peak] if the hour is in the user's peak hours
  /// - [EnergyZone.low] if the hour is in the user's low hours
  /// - [EnergyZone.regular] otherwise
  static EnergyZone getZone(int hour, EnergyPattern pattern) {
    if (pattern.peakHours.contains(hour)) return EnergyZone.peak;
    if (pattern.lowHours.contains(hour)) return EnergyZone.low;
    return EnergyZone.regular;
  }

  /// Resolves overlapping blocks by pushing later blocks forward.
  ///
  /// Sorts blocks by [ScheduleBlock.startMinute], then walks sequentially:
  /// if a block overlaps the previous one, its start is pushed to the end
  /// of the previous block. End times are clamped to [endHour] * 60.
  static List<ScheduleBlock> resolveOverlaps(List<ScheduleBlock> blocks) {
    if (blocks.isEmpty) return blocks;

    final sorted = List<ScheduleBlock>.from(blocks)
      ..sort((a, b) => a.startMinute.compareTo(b.startMinute));

    final resolved = <ScheduleBlock>[sorted.first];

    for (var i = 1; i < sorted.length; i++) {
      final prev = resolved.last;
      var current = sorted[i];

      if (current.startMinute < prev.endMinute) {
        // Push this block to start after the previous one ends.
        final newStart = prev.endMinute;
        current = current.copyWith(startMinute: newStart);
      }

      // Clamp: ensure block doesn't extend past the timeline.
      final maxStart = endHour * 60 - current.durationMinutes;
      if (current.startMinute > maxStart) {
        current = current.copyWith(startMinute: maxStart.clamp(startHour * 60, endHour * 60));
      }

      resolved.add(current);
    }

    return resolved;
  }
}
