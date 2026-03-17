import 'package:flutter_test/flutter_test.dart';
import 'package:focusforge/features/tasks/domain/task_model.dart';
import 'package:focusforge/features/tasks/domain/category_model.dart';

void main() {
  group('Task', () {
    final now = DateTime(2026, 3, 17, 10, 0);
    final json = {
      'id': 'task-1',
      'user_id': 'user-1',
      'title': 'Buy groceries',
      'description': 'Milk, eggs, bread',
      'priority': 1,
      'category_id': 'cat-1',
      'deadline': '2026-03-20T09:00:00.000Z',
      'is_completed': false,
      'completed_at': null,
      'recurrence_rule_id': null,
      'parent_task_id': null,
      'created_at': '2026-03-17T10:00:00.000Z',
      'updated_at': '2026-03-17T10:00:00.000Z',
      'categories': {
        'id': 'cat-1',
        'user_id': 'user-1',
        'name': 'Shopping',
        'color_index': 2,
        'created_at': '2026-03-17T10:00:00.000Z',
        'updated_at': '2026-03-17T10:00:00.000Z',
      },
    };

    test('fromJson parses all fields including nested Category', () {
      final task = Task.fromJson(json);

      expect(task.id, 'task-1');
      expect(task.userId, 'user-1');
      expect(task.title, 'Buy groceries');
      expect(task.description, 'Milk, eggs, bread');
      expect(task.priority, Priority.p2);
      expect(task.categoryId, 'cat-1');
      expect(task.deadline, DateTime.utc(2026, 3, 20, 9));
      expect(task.isCompleted, false);
      expect(task.completedAt, isNull);
      expect(task.recurrenceRuleId, isNull);
      expect(task.parentTaskId, isNull);
      expect(task.category, isNotNull);
      expect(task.category!.name, 'Shopping');
    });

    test('fromJson handles null optionals', () {
      final minJson = {
        'id': 'task-2',
        'user_id': 'user-1',
        'title': 'Simple task',
        'created_at': '2026-03-17T10:00:00.000Z',
        'updated_at': '2026-03-17T10:00:00.000Z',
      };
      final task = Task.fromJson(minJson);

      expect(task.description, isNull);
      expect(task.priority, Priority.p3); // default index 2
      expect(task.categoryId, isNull);
      expect(task.deadline, isNull);
      expect(task.category, isNull);
    });

    test('toJson excludes id, created_at, fts, and category', () {
      final task = Task.fromJson(json);
      final output = task.toJson();

      expect(output.containsKey('id'), false);
      expect(output.containsKey('created_at'), false);
      expect(output.containsKey('fts'), false);
      expect(output.containsKey('categories'), false);
      expect(output['user_id'], 'user-1');
      expect(output['title'], 'Buy groceries');
      expect(output['priority'], 1); // Priority.p2.index == 1
      expect(output['is_completed'], false);
    });

    test('copyWith changes specific fields', () {
      final task = Task.fromJson(json);
      final updated = task.copyWith(title: 'Updated title', priority: Priority.p1);

      expect(updated.title, 'Updated title');
      expect(updated.priority, Priority.p1);
      expect(updated.id, task.id); // unchanged
      expect(updated.userId, task.userId); // unchanged
    });

    test('copyWith clear flags work', () {
      final task = Task.fromJson(json);
      final cleared = task.copyWith(clearCategory: true, clearDeadline: true);

      expect(cleared.categoryId, isNull);
      expect(cleared.deadline, isNull);
    });

    test('Priority enum indexing maps correctly to DB int', () {
      expect(Priority.p1.index, 0);
      expect(Priority.p2.index, 1);
      expect(Priority.p3.index, 2);
      expect(Priority.p4.index, 3);
    });

    test('TaskStatus getter returns correct status', () {
      final pending = Task.fromJson(json);
      expect(pending.status, TaskStatus.pending);

      final completed = pending.copyWith(isCompleted: true);
      expect(completed.status, TaskStatus.completed);
    });
  });
}
