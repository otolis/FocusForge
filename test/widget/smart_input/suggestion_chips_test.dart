import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:focusforge/features/smart_input/domain/parsed_task_input.dart';
import 'package:focusforge/features/smart_input/domain/smart_input_category.dart';
import 'package:focusforge/features/smart_input/presentation/widgets/suggestion_chips.dart';

import '../../helpers/test_helpers.dart';

void main() {
  group('SuggestionChips', () {
    testWidgets('shows no chips when all fields are null', (tester) async {
      const parsed = ParsedTaskInput(rawText: 'test', extractedTitle: 'test');
      await tester.pumpWidget(
        createTestApp(const SuggestionChips(parsed: parsed)),
      );
      // SizedBox.shrink should be rendered -- no InputChip visible
      expect(find.byType(InputChip), findsNothing);
    });

    testWidgets('shows deadline chip when suggestedDeadline is set',
        (tester) async {
      final tomorrow = DateTime.now().add(const Duration(days: 1));
      final parsed = ParsedTaskInput(
        rawText: 'test tomorrow',
        extractedTitle: 'test',
        suggestedDeadline: tomorrow,
      );
      await tester.pumpWidget(
        createTestApp(SuggestionChips(parsed: parsed)),
      );
      expect(find.byType(InputChip), findsOneWidget);
      expect(find.text('Tomorrow'), findsOneWidget);
    });

    testWidgets('shows priority chip with correct icon for P1',
        (tester) async {
      const parsed = ParsedTaskInput(
        rawText: 'urgent task',
        extractedTitle: 'task',
        suggestedPriority: 'P1',
      );
      await tester.pumpWidget(
        createTestApp(const SuggestionChips(parsed: parsed)),
      );
      expect(find.text('P1'), findsOneWidget);
      expect(find.byIcon(Icons.priority_high), findsOneWidget);
    });

    testWidgets('shows category chip with displayName', (tester) async {
      const parsed = ParsedTaskInput(
        rawText: 'buy groceries',
        extractedTitle: 'buy groceries',
        suggestedCategory: SmartInputCategory.shopping,
      );
      await tester.pumpWidget(
        createTestApp(const SuggestionChips(parsed: parsed)),
      );
      expect(find.textContaining('Shopping'), findsOneWidget);
    });

    testWidgets('shows all three chips when all fields present',
        (tester) async {
      final parsed = ParsedTaskInput(
        rawText: 'urgent buy groceries tomorrow',
        extractedTitle: 'buy groceries',
        suggestedDeadline: DateTime.now().add(const Duration(days: 1)),
        suggestedPriority: 'P1',
        suggestedCategory: SmartInputCategory.shopping,
      );
      await tester.pumpWidget(
        createTestApp(SuggestionChips(parsed: parsed)),
      );
      expect(find.byType(InputChip), findsNWidgets(3));
    });

    testWidgets('shows confidence percentage for ML-classified category',
        (tester) async {
      const parsed = ParsedTaskInput(
        rawText: 'do something',
        extractedTitle: 'do something',
        suggestedCategory: SmartInputCategory.work,
        categoryConfidence: 0.85,
      );
      await tester.pumpWidget(
        createTestApp(const SuggestionChips(parsed: parsed)),
      );
      expect(find.textContaining('85%'), findsOneWidget);
    });
  });
}
