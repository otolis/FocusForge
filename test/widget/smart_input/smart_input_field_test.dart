import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:focusforge/features/smart_input/domain/parsed_task_input.dart';
import 'package:focusforge/features/smart_input/presentation/providers/smart_input_provider.dart';
import 'package:focusforge/features/smart_input/presentation/widgets/smart_input_field.dart';

import '../../helpers/test_helpers.dart';

void main() {
  group('SmartInputField', () {
    /// Wraps [SmartInputField] with provider overrides so that
    /// NlpParserService and TfliteClassifierService don't need native
    /// bindings during testing.
    Widget buildTestWidget({String? hintText}) {
      return createTestApp(
        SmartInputField(hintText: hintText),
        overrides: [
          smartInputProvider.overrideWith(
            (ref, text) => ParsedTaskInput(
              rawText: text,
              extractedTitle: text,
            ),
          ),
        ],
      );
    }

    testWidgets('renders TextField with hint text', (tester) async {
      await tester.pumpWidget(buildTestWidget(hintText: 'Type a task'));
      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('Type a task'), findsOneWidget);
    });

    testWidgets('renders with default hint when none provided',
        (tester) async {
      await tester.pumpWidget(buildTestWidget());
      expect(find.byType(TextField), findsOneWidget);
      expect(find.textContaining('Buy groceries'), findsOneWidget);
    });

    testWidgets('has auto_awesome prefix icon', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      expect(find.byIcon(Icons.auto_awesome), findsOneWidget);
    });

    testWidgets('accepts text input', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.enterText(find.byType(TextField), 'buy milk');
      expect(find.text('buy milk'), findsOneWidget);
    });
  });
}
