import 'package:flutter_test/flutter_test.dart';
import 'package:focusforge/features/habits/domain/habit_frequency.dart';
import 'package:focusforge/features/habits/domain/habit_model.dart';
import 'package:focusforge/features/habits/domain/habit_log_model.dart';

void main() {
  group('HabitFrequency', () {
    test('enum has daily, weekly, custom values', () {
      expect(HabitFrequency.values, [
        HabitFrequency.daily,
        HabitFrequency.weekly,
        HabitFrequency.custom,
      ]);
    });

    test('byName parses string values correctly', () {
      expect(HabitFrequency.values.byName('daily'), HabitFrequency.daily);
      expect(HabitFrequency.values.byName('weekly'), HabitFrequency.weekly);
      expect(HabitFrequency.values.byName('custom'), HabitFrequency.custom);
    });
  });

  group('Habit', () {
    final fullJson = {
      'id': 'habit-123',
      'user_id': 'user-456',
      'name': 'Drink Water',
      'description': 'Drink 8 glasses of water daily',
      'frequency': 'daily',
      'target_count': 8,
      'custom_days': [1, 3, 5],
      'icon': 'water_drop',
      'created_at': '2026-01-15T10:30:00Z',
      'updated_at': '2026-03-17T14:00:00Z',
    };

    test('fromJson parses all fields correctly', () {
      final habit = Habit.fromJson(fullJson);

      expect(habit.id, 'habit-123');
      expect(habit.userId, 'user-456');
      expect(habit.name, 'Drink Water');
      expect(habit.description, 'Drink 8 glasses of water daily');
      expect(habit.frequency, HabitFrequency.daily);
      expect(habit.targetCount, 8);
      expect(habit.customDays, [1, 3, 5]);
      expect(habit.icon, 'water_drop');
      expect(habit.createdAt, DateTime.parse('2026-01-15T10:30:00Z'));
      expect(habit.updatedAt, DateTime.parse('2026-03-17T14:00:00Z'));
    });

    test('fromJson handles null optional fields gracefully', () {
      final json = {
        'id': 'habit-789',
        'user_id': 'user-456',
        'name': 'Meditate',
        'description': null,
        'frequency': 'weekly',
        'target_count': null,
        'custom_days': null,
        'icon': null,
        'created_at': '2026-03-17T12:00:00Z',
        'updated_at': '2026-03-17T12:00:00Z',
      };

      final habit = Habit.fromJson(json);

      expect(habit.id, 'habit-789');
      expect(habit.name, 'Meditate');
      expect(habit.description, isNull);
      expect(habit.frequency, HabitFrequency.weekly);
      expect(habit.targetCount, 1); // default fallback
      expect(habit.customDays, isNull);
      expect(habit.icon, isNull);
    });

    test('toJson excludes id and created_at, includes updated_at', () {
      final habit = Habit(
        id: 'habit-123',
        userId: 'user-456',
        name: 'Exercise',
        description: 'Morning run',
        frequency: HabitFrequency.daily,
        targetCount: 1,
        customDays: null,
        icon: 'directions_run',
        createdAt: DateTime.parse('2026-01-01T00:00:00Z'),
        updatedAt: DateTime.parse('2026-03-17T00:00:00Z'),
      );

      final json = habit.toJson();

      expect(json['user_id'], 'user-456');
      expect(json['name'], 'Exercise');
      expect(json['description'], 'Morning run');
      expect(json['frequency'], 'daily');
      expect(json['target_count'], 1);
      expect(json['custom_days'], isNull);
      expect(json['icon'], 'directions_run');
      expect(json.containsKey('updated_at'), true);
      // Server-managed fields must be excluded
      expect(json.containsKey('id'), false);
      expect(json.containsKey('created_at'), false);
    });

    test('toJson includes frequency as string name', () {
      final habit = Habit(
        id: 'h-1',
        userId: 'u-1',
        name: 'Weekly Review',
        frequency: HabitFrequency.weekly,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final json = habit.toJson();
      expect(json['frequency'], 'weekly');
    });

    test('isBinary returns true when targetCount == 1', () {
      final habit = Habit(
        id: 'h-1',
        userId: 'u-1',
        name: 'Meditate',
        targetCount: 1,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(habit.isBinary, true);
    });

    test('isBinary returns false when targetCount > 1', () {
      final habit = Habit(
        id: 'h-2',
        userId: 'u-1',
        name: 'Drink Water',
        targetCount: 8,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(habit.isBinary, false);
    });

    test('isCompletedToday returns true when todayProgress >= targetCount', () {
      final habit = Habit(
        id: 'h-1',
        userId: 'u-1',
        name: 'Drink Water',
        targetCount: 8,
        todayProgress: 8,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(habit.isCompletedToday, true);
    });

    test('isCompletedToday returns true when todayProgress exceeds targetCount',
        () {
      final habit = Habit(
        id: 'h-1',
        userId: 'u-1',
        name: 'Drink Water',
        targetCount: 8,
        todayProgress: 10,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(habit.isCompletedToday, true);
    });

    test('isCompletedToday returns false when todayProgress < targetCount', () {
      final habit = Habit(
        id: 'h-1',
        userId: 'u-1',
        name: 'Drink Water',
        targetCount: 8,
        todayProgress: 5,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(habit.isCompletedToday, false);
    });

    test('copyWith creates new instance preserving unchanged fields', () {
      final original = Habit(
        id: 'h-1',
        userId: 'u-1',
        name: 'Original Habit',
        description: 'Original description',
        frequency: HabitFrequency.daily,
        targetCount: 3,
        customDays: [1, 2, 3],
        icon: 'star',
        currentStreak: 5,
        todayProgress: 2,
        createdAt: DateTime.parse('2026-01-01T00:00:00Z'),
        updatedAt: DateTime.parse('2026-03-17T00:00:00Z'),
      );

      final updated = original.copyWith(
        name: 'Updated Habit',
        targetCount: 5,
      );

      expect(updated.id, 'h-1'); // unchanged
      expect(updated.userId, 'u-1'); // unchanged
      expect(updated.name, 'Updated Habit'); // changed
      expect(updated.description, 'Original description'); // unchanged
      expect(updated.frequency, HabitFrequency.daily); // unchanged
      expect(updated.targetCount, 5); // changed
      expect(updated.customDays, [1, 2, 3]); // unchanged
      expect(updated.icon, 'star'); // unchanged
      expect(updated.createdAt, DateTime.parse('2026-01-01T00:00:00Z'));
    });
  });

  group('HabitLog', () {
    test('fromJson parses all fields correctly', () {
      final json = {
        'id': 'log-123',
        'habit_id': 'habit-456',
        'completed_date': '2026-03-17',
        'count': 3,
        'created_at': '2026-03-17T14:30:00Z',
      };

      final log = HabitLog.fromJson(json);

      expect(log.id, 'log-123');
      expect(log.habitId, 'habit-456');
      expect(log.completedDate, DateTime.parse('2026-03-17'));
      expect(log.count, 3);
      expect(log.createdAt, DateTime.parse('2026-03-17T14:30:00Z'));
    });

    test('fromJson handles null count with default of 1', () {
      final json = {
        'id': 'log-456',
        'habit_id': 'habit-789',
        'completed_date': '2026-03-17',
        'count': null,
        'created_at': '2026-03-17T12:00:00Z',
      };

      final log = HabitLog.fromJson(json);

      expect(log.count, 1); // default fallback
    });

    test('toJson produces habit_id, completed_date as yyyy-MM-dd, count', () {
      final log = HabitLog(
        id: 'log-123',
        habitId: 'habit-456',
        completedDate: DateTime(2026, 3, 7), // single-digit day
        count: 5,
        createdAt: DateTime.parse('2026-03-07T10:00:00Z'),
      );

      final json = log.toJson();

      expect(json['habit_id'], 'habit-456');
      expect(json['completed_date'], '2026-03-07'); // padded
      expect(json['count'], 5);
      // Server-managed fields must be excluded
      expect(json.containsKey('id'), false);
      expect(json.containsKey('created_at'), false);
    });

    test('toJson pads single-digit months correctly', () {
      final log = HabitLog(
        id: 'log-789',
        habitId: 'habit-123',
        completedDate: DateTime(2026, 1, 15),
        count: 1,
        createdAt: DateTime.now(),
      );

      final json = log.toJson();

      expect(json['completed_date'], '2026-01-15');
    });
  });
}
