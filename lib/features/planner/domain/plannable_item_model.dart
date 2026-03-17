/// Energy level classification for plannable items.
///
/// Used by the AI scheduler to match items to appropriate time slots
/// based on the user's energy pattern (peak, low, regular hours).
enum EnergyLevel { high, medium, low }

/// A single item the user wants scheduled into their day.
///
/// Maps to the `public.plannable_items` Supabase table. Each item has a
/// duration (constrained to 15/30/45/60/90/120 minutes), an energy level,
/// and a target date.
class PlannableItem {
  final String id;
  final String userId;
  final String title;
  final int durationMinutes;
  final EnergyLevel energyLevel;
  final DateTime planDate;
  final DateTime createdAt;

  const PlannableItem({
    required this.id,
    required this.userId,
    required this.title,
    required this.durationMinutes,
    required this.energyLevel,
    required this.planDate,
    required this.createdAt,
  });

  /// Parses a row returned from `supabase.from('plannable_items').select()`.
  factory PlannableItem.fromJson(Map<String, dynamic> json) {
    return PlannableItem(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      title: json['title'] as String,
      durationMinutes: json['duration_minutes'] as int,
      energyLevel: EnergyLevel.values.byName(json['energy_level'] as String),
      planDate: DateTime.parse(json['plan_date'] as String),
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  /// Produces an insert-ready map for the `plannable_items` table.
  ///
  /// Excludes `id` and `created_at` (server-managed).
  Map<String, dynamic> toJson() => {
        'title': title,
        'duration_minutes': durationMinutes,
        'energy_level': energyLevel.name,
        'plan_date': planDate.toIso8601String().split('T').first,
      };

  /// Produces a compact map for sending to the generate-schedule Edge Function.
  ///
  /// Only includes the fields the AI scheduler needs: id, title, duration, energy.
  Map<String, dynamic> toEdgeFunctionJson() => {
        'id': id,
        'title': title,
        'duration_minutes': durationMinutes,
        'energy_level': energyLevel.name,
      };

  PlannableItem copyWith({
    String? title,
    int? durationMinutes,
    EnergyLevel? energyLevel,
    DateTime? planDate,
  }) {
    return PlannableItem(
      id: id,
      userId: userId,
      title: title ?? this.title,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      energyLevel: energyLevel ?? this.energyLevel,
      planDate: planDate ?? this.planDate,
      createdAt: createdAt,
    );
  }
}
