/// Represents a user's peak and low energy hours for AI scheduling.
///
/// Default values match the database default:
/// `{"peak_hours": [9,10,11], "low_hours": [14,15]}`.
class EnergyPattern {
  final List<int> peakHours;
  final List<int> lowHours;

  const EnergyPattern({
    this.peakHours = const [9, 10, 11],
    this.lowHours = const [14, 15],
  });

  /// Parses from the `energy_pattern` JSONB column.
  ///
  /// Returns defaults if [json] is null (e.g., a freshly created profile).
  factory EnergyPattern.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const EnergyPattern();
    return EnergyPattern(
      peakHours: (json['peak_hours'] as List?)?.cast<int>() ?? [9, 10, 11],
      lowHours: (json['low_hours'] as List?)?.cast<int>() ?? [14, 15],
    );
  }

  Map<String, dynamic> toJson() => {
        'peak_hours': peakHours,
        'low_hours': lowHours,
      };

  EnergyPattern copyWith({List<int>? peakHours, List<int>? lowHours}) {
    return EnergyPattern(
      peakHours: peakHours ?? this.peakHours,
      lowHours: lowHours ?? this.lowHours,
    );
  }
}

/// A user's profile stored in the `public.profiles` Supabase table.
///
/// Created automatically by a database trigger when a new user signs up.
/// Contains display info (name, avatar), energy scheduling preferences,
/// and an onboarding flag.
class Profile {
  final String id;
  final String? displayName;
  final String? avatarUrl;
  final EnergyPattern energyPattern;
  final bool onboardingCompleted;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Profile({
    required this.id,
    this.displayName,
    this.avatarUrl,
    this.energyPattern = const EnergyPattern(),
    this.onboardingCompleted = false,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Parses a profile row returned from `supabase.from('profiles').select()`.
  factory Profile.fromJson(Map<String, dynamic> json) {
    return Profile(
      id: json['id'] as String,
      displayName: json['display_name'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      energyPattern: EnergyPattern.fromJson(
        json['energy_pattern'] as Map<String, dynamic>?,
      ),
      onboardingCompleted: json['onboarding_completed'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  /// Produces a JSON map for `supabase.from('profiles').update(...)`.
  ///
  /// Excludes `id` and `created_at` because those are server-managed.
  Map<String, dynamic> toJson() => {
        'display_name': displayName,
        'avatar_url': avatarUrl,
        'energy_pattern': energyPattern.toJson(),
        'onboarding_completed': onboardingCompleted,
        'updated_at': DateTime.now().toIso8601String(),
      };

  Profile copyWith({
    String? displayName,
    String? avatarUrl,
    EnergyPattern? energyPattern,
    bool? onboardingCompleted,
  }) {
    return Profile(
      id: id,
      displayName: displayName ?? this.displayName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      energyPattern: energyPattern ?? this.energyPattern,
      onboardingCompleted: onboardingCompleted ?? this.onboardingCompleted,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }

  /// Returns initials derived from [displayName].
  ///
  /// - "John Doe" -> "JD"
  /// - "John" -> "J"
  /// - null or empty -> "?"
  String get initials {
    if (displayName == null || displayName!.isEmpty) return '?';
    final parts = displayName!.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    }
    return parts.first[0].toUpperCase();
  }
}
