import 'package:flutter_test/flutter_test.dart';

import 'package:focusforge/features/smart_input/data/nlp_parser_service.dart';
import 'package:focusforge/features/smart_input/domain/parsed_task_input.dart';
import 'package:focusforge/features/smart_input/domain/smart_input_category.dart';

void main() {
  late NlpParserService parser;

  setUp(() {
    parser = NlpParserService();
  });

  group('NlpParserService', () {
    group('priority extraction', () {
      test('extracts P1 from "urgent fix server"', () {
        final result = parser.parse('urgent fix server');
        expect(result.suggestedPriority, equals('P1'));
      });

      test('extracts P1 from "critical bug in production"', () {
        final result = parser.parse('critical bug in production');
        expect(result.suggestedPriority, equals('P1'));
      });

      test('extracts P1 from "asap deploy hotfix"', () {
        final result = parser.parse('asap deploy hotfix');
        expect(result.suggestedPriority, equals('P1'));
      });

      test('extracts P1 from "p1 server outage"', () {
        final result = parser.parse('p1 server outage');
        expect(result.suggestedPriority, equals('P1'));
      });

      test('extracts P2 from "high priority task"', () {
        final result = parser.parse('high priority task');
        expect(result.suggestedPriority, equals('P2'));
      });

      test('extracts P2 from "important review code"', () {
        final result = parser.parse('important review code');
        expect(result.suggestedPriority, equals('P2'));
      });

      test('extracts P3 from "medium priority review"', () {
        final result = parser.parse('medium priority review');
        expect(result.suggestedPriority, equals('P3'));
      });

      test('extracts P3 from "normal update docs"', () {
        final result = parser.parse('normal update docs');
        expect(result.suggestedPriority, equals('P3'));
      });

      test('extracts P4 from "low priority cleanup"', () {
        final result = parser.parse('low priority cleanup');
        expect(result.suggestedPriority, equals('P4'));
      });

      test('extracts P4 from "no rush refactor utils"', () {
        final result = parser.parse('no rush refactor utils');
        expect(result.suggestedPriority, equals('P4'));
      });

      test('returns null priority for plain task', () {
        final result = parser.parse('just a plain task');
        expect(result.suggestedPriority, isNull);
      });
    });

    group('date extraction', () {
      test('"tomorrow" yields a date one day from now', () {
        final result = parser.parse('buy groceries tomorrow');
        expect(result.suggestedDeadline, isNotNull);
        final now = DateTime.now();
        final tomorrow = DateTime(now.year, now.month, now.day + 1);
        expect(result.suggestedDeadline!.year, equals(tomorrow.year));
        expect(result.suggestedDeadline!.month, equals(tomorrow.month));
        expect(result.suggestedDeadline!.day, equals(tomorrow.day));
      });

      test('"next Friday" yields a future Friday', () {
        final result = parser.parse('review docs next Friday');
        expect(result.suggestedDeadline, isNotNull);
        // The parsed date should be a Friday (weekday == 5)
        expect(result.suggestedDeadline!.weekday, equals(DateTime.friday));
        // And it should be in the future
        expect(
          result.suggestedDeadline!.isAfter(DateTime.now().subtract(const Duration(days: 1))),
          isTrue,
        );
      });

      test('"by March 30" yields March 30', () {
        final result = parser.parse('pay rent by March 30');
        expect(result.suggestedDeadline, isNotNull);
        expect(result.suggestedDeadline!.month, equals(3));
        expect(result.suggestedDeadline!.day, equals(30));
      });

      test('returns null deadline for plain task', () {
        final result = parser.parse('just a plain task');
        expect(result.suggestedDeadline, isNull);
      });
    });

    group('category extraction', () {
      test('"buy groceries" maps to shopping', () {
        final result = parser.parse('buy groceries');
        expect(result.suggestedCategory, equals(SmartInputCategory.shopping));
      });

      test('"study for exam" maps to education', () {
        final result = parser.parse('study for exam');
        expect(result.suggestedCategory, equals(SmartInputCategory.education));
      });

      test('"pay rent" maps to finance', () {
        final result = parser.parse('pay rent');
        expect(result.suggestedCategory, equals(SmartInputCategory.finance));
      });

      test('"doctor appointment" maps to health', () {
        final result = parser.parse('doctor appointment');
        expect(result.suggestedCategory, equals(SmartInputCategory.health));
      });

      test('"fix leaky faucet" maps to errands', () {
        final result = parser.parse('fix leaky faucet');
        expect(result.suggestedCategory, equals(SmartInputCategory.errands));
      });

      test('"office meeting with client" maps to work', () {
        final result = parser.parse('office meeting with client');
        expect(result.suggestedCategory, equals(SmartInputCategory.work));
      });

      test('"dinner with friends" maps to personal', () {
        // "friends" matches personal keywords before "dinner" matches social
        final result = parser.parse('dinner with friends');
        expect(result.suggestedCategory, equals(SmartInputCategory.personal));
      });

      test('returns null category for ambiguous input', () {
        final result = parser.parse('do the thing');
        expect(result.suggestedCategory, isNull);
      });
    });

    group('title cleanup', () {
      test('priority keywords are stripped from title', () {
        final result = parser.parse('urgent fix server crash');
        expect(result.extractedTitle, isNot(contains('urgent')));
        expect(result.extractedTitle.toLowerCase(), contains('fix server crash'));
      });

      test('date tokens are stripped from title', () {
        final result = parser.parse('buy groceries tomorrow');
        expect(result.extractedTitle.toLowerCase(), isNot(contains('tomorrow')));
        expect(result.extractedTitle.toLowerCase(), contains('buy groceries'));
      });

      test('multiple extractions leave a clean title', () {
        final result = parser.parse('urgent buy groceries tomorrow');
        expect(result.extractedTitle.toLowerCase(), isNot(contains('urgent')));
        expect(result.extractedTitle.toLowerCase(), isNot(contains('tomorrow')));
        expect(result.extractedTitle.toLowerCase(), contains('buy groceries'));
      });

      test('category keywords are NOT stripped from title', () {
        final result = parser.parse('buy groceries at the store');
        expect(result.extractedTitle.toLowerCase(), contains('buy'));
        expect(result.extractedTitle.toLowerCase(), contains('groceries'));
        expect(result.extractedTitle.toLowerCase(), contains('store'));
      });

      test('title does not have leading/trailing whitespace or punctuation', () {
        final result = parser.parse('urgent: fix the bug');
        expect(result.extractedTitle, isNot(startsWith(':')));
        expect(result.extractedTitle, isNot(startsWith(' ')));
        expect(result.extractedTitle, isNot(endsWith(' ')));
      });
    });

    group('edge cases', () {
      test('empty string returns empty ParsedTaskInput', () {
        final result = parser.parse('');
        expect(result.rawText, equals(''));
        expect(result.extractedTitle, equals(''));
        expect(result.suggestedDeadline, isNull);
        expect(result.suggestedPriority, isNull);
        expect(result.suggestedCategory, isNull);
      });

      test('whitespace-only string returns empty ParsedTaskInput', () {
        final result = parser.parse('   ');
        expect(result.rawText, equals('   '));
        expect(result.extractedTitle, equals(''));
        expect(result.suggestedDeadline, isNull);
        expect(result.suggestedPriority, isNull);
        expect(result.suggestedCategory, isNull);
      });

      test('very long input (500+ chars) does not crash', () {
        final longText = 'a ' * 300; // 600 chars
        expect(() => parser.parse(longText), returnsNormally);
        final result = parser.parse(longText);
        expect(result, isA<ParsedTaskInput>());
      });

      test('rawText is always preserved', () {
        const original = 'Buy groceries tomorrow high priority';
        final result = parser.parse(original);
        expect(result.rawText, equals(original));
      });

      test('combined priority + date + category extraction', () {
        final result = parser.parse('Buy groceries tomorrow high priority');
        expect(result.suggestedPriority, equals('P2'));
        expect(result.suggestedDeadline, isNotNull);
        expect(result.suggestedCategory, equals(SmartInputCategory.shopping));
        expect(result.extractedTitle.toLowerCase(), contains('buy groceries'));
      });
    });
  });
}
