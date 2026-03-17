import 'plannable_item_model.dart';
import 'timeline_constants.dart';

/// A scheduled time block produced by the AI scheduler.
///
/// Represents one item placed on the daily timeline. Contains position
/// information (start minute from midnight), duration, and computed pixel
/// offsets for timeline rendering.
class ScheduleBlock {
  final String itemId;
  final String title;
  final int startMinute;
  final int durationMinutes;
  final EnergyLevel energyLevel;

  const ScheduleBlock({
    required this.itemId,
    required this.title,
    required this.startMinute,
    required this.durationMinutes,
    required this.energyLevel,
  });

  /// Minutes-from-midnight when this block ends.
  int get endMinute => startMinute + durationMinutes;

  /// Y pixel offset from the top of the timeline widget.
  double get topOffset => TimelineConstants.minuteToY(startMinute);

  /// Height in pixels on the timeline widget.
  double get height => durationMinutes * TimelineConstants.pixelsPerMinute;

  /// Parses a schedule block from the Groq API / Edge Function response.
  factory ScheduleBlock.fromJson(Map<String, dynamic> json) {
    return ScheduleBlock(
      itemId: json['item_id'] as String,
      title: json['title'] as String,
      startMinute: json['start_minute'] as int,
      durationMinutes: json['duration_minutes'] as int,
      energyLevel: EnergyLevel.values.byName(json['energy_level'] as String),
    );
  }

  /// Produces a JSON map matching the Edge Function response format.
  Map<String, dynamic> toJson() => {
        'item_id': itemId,
        'title': title,
        'start_minute': startMinute,
        'duration_minutes': durationMinutes,
        'energy_level': energyLevel.name,
      };

  ScheduleBlock copyWith({int? startMinute}) {
    return ScheduleBlock(
      itemId: itemId,
      title: title,
      startMinute: startMinute ?? this.startMinute,
      durationMinutes: durationMinutes,
      energyLevel: energyLevel,
    );
  }
}
