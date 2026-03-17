import 'package:flutter_test/flutter_test.dart';
import 'package:focusforge/features/tasks/domain/task_filter.dart';
import 'package:focusforge/features/tasks/domain/task_model.dart';

void main() {
  group('TaskFilter', () {
    test('isEmpty returns true when all fields are null', () {
      const filter = TaskFilter();
      expect(filter.isEmpty, true);
    });

    test('isEmpty returns true when searchQuery is empty string', () {
      const filter = TaskFilter(searchQuery: '');
      expect(filter.isEmpty, true);
    });

    test('isEmpty returns false when priority is set', () {
      const filter = TaskFilter(priority: Priority.p1);
      expect(filter.isEmpty, false);
    });

    test('isEmpty returns false when categoryId is set', () {
      const filter = TaskFilter(categoryId: 'cat-1');
      expect(filter.isEmpty, false);
    });

    test('isEmpty returns false when searchQuery is non-empty', () {
      const filter = TaskFilter(searchQuery: 'hello');
      expect(filter.isEmpty, false);
    });

    test('copyWith changes specified fields', () {
      const filter = TaskFilter(priority: Priority.p1, categoryId: 'cat-1');
      final updated = filter.copyWith(priority: Priority.p4);

      expect(updated.priority, Priority.p4);
      expect(updated.categoryId, 'cat-1'); // unchanged
    });

    test('copyWith clear flags reset fields to null', () {
      const filter = TaskFilter(
        priority: Priority.p1,
        categoryId: 'cat-1',
        searchQuery: 'test',
      );
      final cleared = filter.copyWith(
        clearPriority: true,
        clearCategory: true,
        clearSearch: true,
      );

      expect(cleared.priority, isNull);
      expect(cleared.categoryId, isNull);
      expect(cleared.searchQuery, isNull);
    });

    test('clear() returns empty filter', () {
      const filter = TaskFilter(
        priority: Priority.p2,
        categoryId: 'cat-1',
        searchQuery: 'hello',
      );
      final cleared = filter.clear();

      expect(cleared.isEmpty, true);
      expect(cleared.priority, isNull);
      expect(cleared.categoryId, isNull);
    });

    test('TaskFilter.empty is a const empty filter', () {
      expect(TaskFilter.empty.isEmpty, true);
    });
  });
}
