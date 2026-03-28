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
  ///
  /// Numeric fields use `(value as num).toInt()` instead of `as int` because
  /// Dart's [jsonDecode] produces [double] for JSON numbers that include a
  /// decimal point (e.g. `540.0`). LLM output is non-deterministic, so the
  /// Edge Function may occasionally return floats even though the prompt
  /// requests integers.
  ///
  /// The [energyLevel] lookup is case-insensitive to tolerate LLM
  /// capitalisation variations (e.g. "High" instead of "high").
  factory ScheduleBlock.fromJson(Map<String, dynamic> json) {
    final rawEnergy = (json['energy_level'] as String).toLowerCase();
    return ScheduleBlock(
      itemId: json['item_id'] as String,
      title: json['title'] as String,
      startMinute: (json['start_minute'] as num).toInt(),
      durationMinutes: (json['duration_minutes'] as num).toInt(),
      energyLevel: EnergyLevel.values.byName(rawEnergy),
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
