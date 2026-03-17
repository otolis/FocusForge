import 'package:flutter_test/flutter_test.dart';
import 'package:focusforge/features/tasks/domain/category_model.dart';

void main() {
  group('Category', () {
    final json = {
      'id': 'cat-1',
      'user_id': 'user-1',
      'name': 'Work',
      'color_index': 3,
      'created_at': '2026-03-17T10:00:00.000Z',
      'updated_at': '2026-03-17T10:00:00.000Z',
    };

    test('fromJson parses all fields correctly', () {
      final category = Category.fromJson(json);

      expect(category.id, 'cat-1');
      expect(category.userId, 'user-1');
      expect(category.name, 'Work');
      expect(category.colorIndex, 3);
      expect(category.createdAt, DateTime.utc(2026, 3, 17, 10));
      expect(category.updatedAt, DateTime.utc(2026, 3, 17, 10));
    });

    test('toJson excludes id and created_at', () {
      final category = Category.fromJson(json);
      final output = category.toJson();

      expect(output.containsKey('id'), false);
      expect(output.containsKey('created_at'), false);
      expect(output['user_id'], 'user-1');
      expect(output['name'], 'Work');
      expect(output['color_index'], 3);
    });

    test('presetColors has exactly 10 entries', () {
      expect(Category.presetColors.length, 10);
    });

    test('color getter returns correct color from presetColors', () {
      final category = Category.fromJson(json);
      expect(category.color, Category.presetColors[3]);
    });

    test('color getter clamps out-of-range colorIndex', () {
      final outOfRange = Category.fromJson({
        ...json,
        'color_index': 99,
      });
      expect(outOfRange.color, Category.presetColors[9]);
    });

    test('copyWith creates new instance with changed fields', () {
      final category = Category.fromJson(json);
      final updated = category.copyWith(name: 'Personal', colorIndex: 5);

      expect(updated.name, 'Personal');
      expect(updated.colorIndex, 5);
      expect(updated.id, category.id); // unchanged
    });
  });
}
