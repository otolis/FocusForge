import 'package:flutter_test/flutter_test.dart';
import 'package:focusforge/features/profile/domain/profile_model.dart';

void main() {
  group('EnergyPattern', () {
    test('fromJson parses peak_hours and low_hours arrays', () {
      final json = {
        'peak_hours': [8, 9, 10],
        'low_hours': [13, 14],
      };

      final pattern = EnergyPattern.fromJson(json);

      expect(pattern.peakHours, [8, 9, 10]);
      expect(pattern.lowHours, [13, 14]);
    });

    test('fromJson with null returns defaults (peak: [9,10,11], low: [14,15])',
        () {
      final pattern = EnergyPattern.fromJson(null);

      expect(pattern.peakHours, [9, 10, 11]);
      expect(pattern.lowHours, [14, 15]);
    });

    test('toJson produces correct JSON', () {
      const pattern = EnergyPattern(
        peakHours: [7, 8, 9],
        lowHours: [15, 16],
      );

      final json = pattern.toJson();

      expect(json['peak_hours'], [7, 8, 9]);
      expect(json['low_hours'], [15, 16]);
    });

    test('copyWith creates a new instance with updated fields', () {
      const original = EnergyPattern(
        peakHours: [9, 10, 11],
        lowHours: [14, 15],
      );

      final updated = original.copyWith(peakHours: [8, 9]);

      expect(updated.peakHours, [8, 9]);
      expect(updated.lowHours, [14, 15]); // unchanged
    });
  });

  group('Profile', () {
    test('fromJson correctly parses all fields including energy_pattern', () {
      final json = {
        'id': 'user-123',
        'display_name': 'John Doe',
        'avatar_url': 'https://example.com/avatar.png',
        'energy_pattern': {
          'peak_hours': [8, 9, 10],
          'low_hours': [13, 14],
        },
        'onboarding_completed': true,
        'created_at': '2026-01-15T10:30:00Z',
        'updated_at': '2026-03-17T14:00:00Z',
      };

      final profile = Profile.fromJson(json);

      expect(profile.id, 'user-123');
      expect(profile.displayName, 'John Doe');
      expect(profile.avatarUrl, 'https://example.com/avatar.png');
      expect(profile.energyPattern.peakHours, [8, 9, 10]);
      expect(profile.energyPattern.lowHours, [13, 14]);
      expect(profile.onboardingCompleted, true);
      expect(profile.createdAt, DateTime.parse('2026-01-15T10:30:00Z'));
      expect(profile.updatedAt, DateTime.parse('2026-03-17T14:00:00Z'));
    });

    test('fromJson handles null optional fields gracefully', () {
      final json = {
        'id': 'user-456',
        'display_name': null,
        'avatar_url': null,
        'energy_pattern': null,
        'onboarding_completed': null,
        'created_at': '2026-03-17T12:00:00Z',
        'updated_at': '2026-03-17T12:00:00Z',
      };

      final profile = Profile.fromJson(json);

      expect(profile.id, 'user-456');
      expect(profile.displayName, isNull);
      expect(profile.avatarUrl, isNull);
      expect(profile.energyPattern.peakHours, [9, 10, 11]); // defaults
      expect(profile.energyPattern.lowHours, [14, 15]); // defaults
      expect(profile.onboardingCompleted, false); // default
    });

    test('toJson produces correct JSON with energy_pattern', () {
      final profile = Profile(
        id: 'user-789',
        displayName: 'Jane Smith',
        avatarUrl: 'https://example.com/jane.png',
        energyPattern: const EnergyPattern(
          peakHours: [10, 11, 12],
          lowHours: [15, 16],
        ),
        onboardingCompleted: true,
        createdAt: DateTime.parse('2026-01-01T00:00:00Z'),
        updatedAt: DateTime.parse('2026-03-17T00:00:00Z'),
      );

      final json = profile.toJson();

      expect(json['display_name'], 'Jane Smith');
      expect(json['avatar_url'], 'https://example.com/jane.png');
      expect(json['energy_pattern']['peak_hours'], [10, 11, 12]);
      expect(json['energy_pattern']['low_hours'], [15, 16]);
      expect(json['onboarding_completed'], true);
      expect(json.containsKey('updated_at'), true);
      // toJson should NOT include 'id' or 'created_at' (server-managed fields)
      expect(json.containsKey('id'), false);
      expect(json.containsKey('created_at'), false);
    });

    test('initials returns "JD" for "John Doe"', () {
      final profile = Profile(
        id: 'user-1',
        displayName: 'John Doe',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(profile.initials, 'JD');
    });

    test('initials returns "J" for "John"', () {
      final profile = Profile(
        id: 'user-2',
        displayName: 'John',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(profile.initials, 'J');
    });

    test('initials returns "?" for null displayName', () {
      final profile = Profile(
        id: 'user-3',
        displayName: null,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(profile.initials, '?');
    });

    test('initials returns "?" for empty displayName', () {
      final profile = Profile(
        id: 'user-4',
        displayName: '',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(profile.initials, '?');
    });

    test('copyWith creates new instance with updated fields', () {
      final original = Profile(
        id: 'user-5',
        displayName: 'Original Name',
        onboardingCompleted: false,
        createdAt: DateTime.parse('2026-01-01T00:00:00Z'),
        updatedAt: DateTime.parse('2026-01-01T00:00:00Z'),
      );

      final updated = original.copyWith(
        displayName: 'Updated Name',
        onboardingCompleted: true,
      );

      expect(updated.id, 'user-5'); // unchanged
      expect(updated.displayName, 'Updated Name');
      expect(updated.onboardingCompleted, true);
      expect(updated.createdAt, DateTime.parse('2026-01-01T00:00:00Z')); // unchanged
    });
  });
}
