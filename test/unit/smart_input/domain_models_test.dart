import 'package:flutter_test/flutter_test.dart';

import 'package:focusforge/features/smart_input/domain/parsed_task_input.dart';
import 'package:focusforge/features/smart_input/domain/smart_input_category.dart';

void main() {
  group('SmartInputCategory', () {
    test('has exactly 8 values', () {
      expect(SmartInputCategory.values.length, equals(8));
    });

    test('contains all expected categories', () {
      expect(SmartInputCategory.values, containsAll([
        SmartInputCategory.work,
        SmartInputCategory.personal,
        SmartInputCategory.health,
        SmartInputCategory.shopping,
        SmartInputCategory.finance,
        SmartInputCategory.education,
        SmartInputCategory.errands,
        SmartInputCategory.social,
      ]));
    });

    test('displayName returns capitalized string', () {
      expect(SmartInputCategory.work.displayName, equals('Work'));
      expect(SmartInputCategory.personal.displayName, equals('Personal'));
      expect(SmartInputCategory.health.displayName, equals('Health'));
      expect(SmartInputCategory.shopping.displayName, equals('Shopping'));
      expect(SmartInputCategory.finance.displayName, equals('Finance'));
      expect(SmartInputCategory.education.displayName, equals('Education'));
      expect(SmartInputCategory.errands.displayName, equals('Errands'));
      expect(SmartInputCategory.social.displayName, equals('Social'));
    });

    test('categoryKeywords contains all categories as keys', () {
      for (final category in SmartInputCategory.values) {
        expect(
          SmartInputCategory.categoryKeywords.containsKey(category),
          isTrue,
          reason: '${category.name} should have keywords',
        );
      }
    });

    test('categoryKeywords values are non-empty lists', () {
      for (final entry in SmartInputCategory.categoryKeywords.entries) {
        expect(
          entry.value,
          isNotEmpty,
          reason: '${entry.key.name} keywords should not be empty',
        );
      }
    });

    test('work category contains expected keywords', () {
      final keywords = SmartInputCategory.categoryKeywords[SmartInputCategory.work]!;
      expect(keywords, containsAll(['work', 'meeting', 'office']));
    });

    test('shopping category contains expected keywords', () {
      final keywords = SmartInputCategory.categoryKeywords[SmartInputCategory.shopping]!;
      expect(keywords, containsAll(['buy', 'shop', 'groceries']));
    });
  });

  group('ParsedTaskInput', () {
    test('can be created with required fields only', () {
      const input = ParsedTaskInput(
        rawText: 'Buy groceries',
        extractedTitle: 'Buy groceries',
      );
      expect(input.rawText, equals('Buy groceries'));
      expect(input.extractedTitle, equals('Buy groceries'));
      expect(input.suggestedDeadline, isNull);
      expect(input.suggestedPriority, isNull);
      expect(input.suggestedCategory, isNull);
      expect(input.categoryConfidence, equals(0.0));
      expect(input.priorityConfidence, equals(0.0));
    });

    test('can be created with all fields', () {
      final deadline = DateTime(2026, 3, 20);
      final input = ParsedTaskInput(
        rawText: 'Buy groceries tomorrow high priority',
        extractedTitle: 'Buy groceries',
        suggestedDeadline: deadline,
        suggestedPriority: 'P2',
        suggestedCategory: SmartInputCategory.shopping,
        categoryConfidence: 0.85,
        priorityConfidence: 0.95,
      );
      expect(input.rawText, equals('Buy groceries tomorrow high priority'));
      expect(input.extractedTitle, equals('Buy groceries'));
      expect(input.suggestedDeadline, equals(deadline));
      expect(input.suggestedPriority, equals('P2'));
      expect(input.suggestedCategory, equals(SmartInputCategory.shopping));
      expect(input.categoryConfidence, equals(0.85));
      expect(input.priorityConfidence, equals(0.95));
    });

    test('copyWith returns new instance with overridden fields', () {
      const original = ParsedTaskInput(
        rawText: 'Buy groceries',
        extractedTitle: 'Buy groceries',
      );

      final modified = original.copyWith(
        suggestedPriority: 'P1',
        suggestedCategory: SmartInputCategory.shopping,
        categoryConfidence: 0.9,
      );

      expect(modified.rawText, equals('Buy groceries'));
      expect(modified.extractedTitle, equals('Buy groceries'));
      expect(modified.suggestedPriority, equals('P1'));
      expect(modified.suggestedCategory, equals(SmartInputCategory.shopping));
      expect(modified.categoryConfidence, equals(0.9));
      // Original should be unchanged
      expect(original.suggestedPriority, isNull);
      expect(original.suggestedCategory, isNull);
    });

    test('copyWith preserves existing values when not overridden', () {
      final original = ParsedTaskInput(
        rawText: 'Test',
        extractedTitle: 'Test',
        suggestedPriority: 'P1',
        suggestedDeadline: DateTime(2026, 4, 1),
        priorityConfidence: 0.8,
      );

      final modified = original.copyWith(
        suggestedCategory: SmartInputCategory.work,
      );

      expect(modified.suggestedPriority, equals('P1'));
      expect(modified.suggestedDeadline, equals(DateTime(2026, 4, 1)));
      expect(modified.priorityConfidence, equals(0.8));
      expect(modified.suggestedCategory, equals(SmartInputCategory.work));
    });

    test('equality works for identical instances', () {
      const a = ParsedTaskInput(
        rawText: 'Test',
        extractedTitle: 'Test',
        suggestedPriority: 'P1',
      );
      const b = ParsedTaskInput(
        rawText: 'Test',
        extractedTitle: 'Test',
        suggestedPriority: 'P1',
      );
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('equality fails for different instances', () {
      const a = ParsedTaskInput(
        rawText: 'Test A',
        extractedTitle: 'Test A',
      );
      const b = ParsedTaskInput(
        rawText: 'Test B',
        extractedTitle: 'Test B',
      );
      expect(a, isNot(equals(b)));
    });

    test('toString contains extractedTitle', () {
      const input = ParsedTaskInput(
        rawText: 'Buy groceries',
        extractedTitle: 'Buy groceries',
      );
      expect(input.toString(), contains('Buy groceries'));
    });
  });
}
