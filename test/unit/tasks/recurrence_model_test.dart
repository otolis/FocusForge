import 'package:flutter_test/flutter_test.dart';
import 'package:focusforge/features/tasks/domain/recurrence_model.dart';

void main() {
  group('RecurrenceRule', () {
    test('fromJson parses daily recurrence', () {
      final json = {
        'id': 'rule-1',
        'task_id': 'task-1',
        'type': 'daily',
        'interval_days': null,
        'days_of_week': null,
        'day_of_month': null,
        'created_at': '2026-03-17T10:00:00.000Z',
      };
      final rule = RecurrenceRule.fromJson(json);

      expect(rule.id, 'rule-1');
      expect(rule.taskId, 'task-1');
      expect(rule.type, RecurrenceType.daily);
    });

    test('fromJson parses weekly recurrence with days_of_week', () {
      final json = {
        'id': 'rule-2',
        'task_id': 'task-1',
        'type': 'weekly',
        'interval_days': null,
        'days_of_week': [1, 3, 5],
        'day_of_month': null,
        'created_at': '2026-03-17T10:00:00.000Z',
      };
      final rule = RecurrenceRule.fromJson(json);

      expect(rule.type, RecurrenceType.weekly);
      expect(rule.daysOfWeek, [1, 3, 5]);
    });

    test('fromJson parses monthly recurrence with day_of_month', () {
      final json = {
        'id': 'rule-3',
        'task_id': 'task-1',
        'type': 'monthly',
        'interval_days': null,
        'days_of_week': null,
        'day_of_month': 15,
        'created_at': '2026-03-17T10:00:00.000Z',
      };
      final rule = RecurrenceRule.fromJson(json);

      expect(rule.type, RecurrenceType.monthly);
      expect(rule.dayOfMonth, 15);
    });

    test('fromJson parses custom recurrence with interval_days', () {
      final json = {
        'id': 'rule-4',
        'task_id': 'task-1',
        'type': 'custom',
        'interval_days': 3,
        'days_of_week': null,
        'day_of_month': null,
        'created_at': '2026-03-17T10:00:00.000Z',
      };
      final rule = RecurrenceRule.fromJson(json);

      expect(rule.type, RecurrenceType.custom);
      expect(rule.intervalDays, 3);
    });

    test('toJson serializes type as string', () {
      final rule = RecurrenceRule(
        id: 'rule-1',
        taskId: 'task-1',
        type: RecurrenceType.weekly,
        daysOfWeek: [1, 3, 5],
        createdAt: DateTime(2026, 3, 17),
      );
      final output = rule.toJson();

      expect(output['type'], 'weekly');
      expect(output['days_of_week'], [1, 3, 5]);
    });

    test('displayLabel returns "Daily" for daily type', () {
      final rule = RecurrenceRule(
        id: 'r1',
        taskId: 't1',
        type: RecurrenceType.daily,
        createdAt: DateTime(2026),
      );
      expect(rule.displayLabel, 'Daily');
    });

    test('displayLabel returns "Mon/Wed/Fri" for weekly [1,3,5]', () {
      final rule = RecurrenceRule(
        id: 'r2',
        taskId: 't1',
        type: RecurrenceType.weekly,
        daysOfWeek: [1, 3, 5],
        createdAt: DateTime(2026),
      );
      expect(rule.displayLabel, 'Mon/Wed/Fri');
    });

    test('displayLabel returns "Monthly (15th)" for monthly with dayOfMonth=15', () {
      final rule = RecurrenceRule(
        id: 'r3',
        taskId: 't1',
        type: RecurrenceType.monthly,
        dayOfMonth: 15,
        createdAt: DateTime(2026),
      );
      expect(rule.displayLabel, 'Monthly (15th)');
    });

    test('displayLabel returns "Every 3 days" for custom with intervalDays=3', () {
      final rule = RecurrenceRule(
        id: 'r4',
        taskId: 't1',
        type: RecurrenceType.custom,
        intervalDays: 3,
        createdAt: DateTime(2026),
      );
      expect(rule.displayLabel, 'Every 3 days');
    });
  });
}
