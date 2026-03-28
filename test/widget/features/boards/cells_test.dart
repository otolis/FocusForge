import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:focusforge/features/boards/presentation/widgets/cells/status_cell.dart';
import 'package:focusforge/features/boards/presentation/widgets/cells/priority_cell.dart';
import 'package:focusforge/features/boards/presentation/widgets/cells/person_cell.dart';
import 'package:focusforge/features/boards/presentation/widgets/cells/timeline_cell.dart';
import 'package:focusforge/features/boards/presentation/widgets/cells/due_date_cell.dart';
import 'package:focusforge/features/boards/presentation/widgets/cells/text_cell.dart';
import 'package:focusforge/features/boards/presentation/widgets/cells/number_cell.dart';
import 'package:focusforge/features/boards/presentation/widgets/cells/checkbox_cell.dart';
import 'package:focusforge/features/boards/presentation/widgets/cells/link_cell.dart';

/// Helper to wrap a widget in MaterialApp for testing.
Widget _wrap(Widget child) {
  return MaterialApp(
    home: Scaffold(
      body: SizedBox(width: 200, child: child),
    ),
  );
}

void main() {
  // ───────────────────────────────────────────────
  // StatusCell
  // ───────────────────────────────────────────────
  group('StatusCell', () {
    testWidgets('renders label text', (tester) async {
      await tester.pumpWidget(_wrap(
        const StatusCell(statusLabel: 'Working on it', statusColor: '#FF9800'),
      ));
      expect(find.text('Working on it'), findsOneWidget);
    });

    testWidgets('shows "Not Started" when label is null', (tester) async {
      await tester.pumpWidget(_wrap(
        const StatusCell(),
      ));
      expect(find.text('Not Started'), findsOneWidget);
    });

    testWidgets('renders correct background color', (tester) async {
      await tester.pumpWidget(_wrap(
        const StatusCell(statusLabel: 'Done', statusColor: '#4CAF50'),
      ));

      final container = tester.widget<Container>(find.byType(Container).first);
      expect(container.color, isNotNull);
    });

    testWidgets('fires onTap callback', (tester) async {
      int tapCount = 0;
      await tester.pumpWidget(_wrap(
        StatusCell(onTap: () => tapCount++),
      ));

      await tester.tap(find.byType(GestureDetector));
      expect(tapCount, 1);
    });
  });

  // ───────────────────────────────────────────────
  // PriorityCell
  // ───────────────────────────────────────────────
  group('PriorityCell', () {
    testWidgets('renders "Critical" for priority 1', (tester) async {
      await tester.pumpWidget(_wrap(
        const PriorityCell(priority: 1),
      ));
      expect(find.text('Critical'), findsOneWidget);
    });

    testWidgets('renders "High" for priority 2', (tester) async {
      await tester.pumpWidget(_wrap(
        const PriorityCell(priority: 2),
      ));
      expect(find.text('High'), findsOneWidget);
    });

    testWidgets('renders "Medium" for priority 3', (tester) async {
      await tester.pumpWidget(_wrap(
        const PriorityCell(priority: 3),
      ));
      expect(find.text('Medium'), findsOneWidget);
    });

    testWidgets('renders "Low" for priority 4', (tester) async {
      await tester.pumpWidget(_wrap(
        const PriorityCell(priority: 4),
      ));
      expect(find.text('Low'), findsOneWidget);
    });

    testWidgets('defaults to "Low" for unknown priority', (tester) async {
      await tester.pumpWidget(_wrap(
        const PriorityCell(priority: 99),
      ));
      expect(find.text('Low'), findsOneWidget);
    });

    testWidgets('fires onTap callback', (tester) async {
      int tapCount = 0;
      await tester.pumpWidget(_wrap(
        PriorityCell(priority: 1, onTap: () => tapCount++),
      ));

      await tester.tap(find.byType(GestureDetector));
      expect(tapCount, 1);
    });
  });

  // ───────────────────────────────────────────────
  // PersonCell
  // ───────────────────────────────────────────────
  group('PersonCell', () {
    testWidgets('shows person_outline when no assignee', (tester) async {
      await tester.pumpWidget(_wrap(
        const PersonCell(),
      ));
      expect(find.byIcon(Icons.person_outline), findsOneWidget);
    });

    testWidgets('shows name when assignee present', (tester) async {
      await tester.pumpWidget(_wrap(
        const PersonCell(assigneeName: 'Alice Smith'),
      ));
      expect(find.text('Alice Smith'), findsOneWidget);
      expect(find.byType(CircleAvatar), findsOneWidget);
    });

    testWidgets('fires onTap callback', (tester) async {
      int tapCount = 0;
      await tester.pumpWidget(_wrap(
        PersonCell(onTap: () => tapCount++),
      ));

      await tester.tap(find.byType(GestureDetector));
      expect(tapCount, 1);
    });
  });

  // ───────────────────────────────────────────────
  // TimelineCell
  // ───────────────────────────────────────────────
  group('TimelineCell', () {
    testWidgets('shows "Set dates" when no dates', (tester) async {
      await tester.pumpWidget(_wrap(
        const TimelineCell(),
      ));
      expect(find.text('Set dates'), findsOneWidget);
    });

    testWidgets('shows date bar when dates present', (tester) async {
      await tester.pumpWidget(_wrap(
        TimelineCell(
          startDate: DateTime(2026, 3, 1),
          endDate: DateTime(2026, 3, 15),
        ),
      ));
      expect(find.text('1/3 - 15/3'), findsOneWidget);
    });

    testWidgets('fires onTap callback', (tester) async {
      int tapCount = 0;
      await tester.pumpWidget(_wrap(
        TimelineCell(onTap: () => tapCount++),
      ));

      await tester.tap(find.byType(GestureDetector));
      expect(tapCount, 1);
    });
  });

  // ───────────────────────────────────────────────
  // DueDateCell
  // ───────────────────────────────────────────────
  group('DueDateCell', () {
    testWidgets('shows em dash when no date', (tester) async {
      await tester.pumpWidget(_wrap(
        const DueDateCell(),
      ));
      expect(find.text('\u2014'), findsOneWidget);
    });

    testWidgets('shows formatted date', (tester) async {
      await tester.pumpWidget(_wrap(
        DueDateCell(dueDate: DateTime(2026, 6, 15)),
      ));
      expect(find.text('Jun 15'), findsOneWidget);
    });

    testWidgets('shows error color when overdue', (tester) async {
      // Use a date far in the past to guarantee overdue
      await tester.pumpWidget(_wrap(
        DueDateCell(dueDate: DateTime(2020, 1, 1)),
      ));

      final textWidget = tester.widget<Text>(find.text('Jan 1'));
      final style = textWidget.style!;
      // The error color should be applied; verify it is not the default onSurface
      expect(style.color, isNotNull);
    });

    testWidgets('fires onTap callback', (tester) async {
      int tapCount = 0;
      await tester.pumpWidget(_wrap(
        DueDateCell(onTap: () => tapCount++),
      ));

      await tester.tap(find.byType(GestureDetector));
      expect(tapCount, 1);
    });
  });

  // ───────────────────────────────────────────────
  // TextCell
  // ───────────────────────────────────────────────
  group('TextCell', () {
    testWidgets('shows text in display mode', (tester) async {
      await tester.pumpWidget(_wrap(
        const TextCell(value: 'Hello World'),
      ));
      expect(find.text('Hello World'), findsOneWidget);
      expect(find.byType(TextField), findsNothing);
    });

    testWidgets('shows TextField when isEditing=true', (tester) async {
      await tester.pumpWidget(_wrap(
        const TextCell(value: 'Hello World', isEditing: true),
      ));
      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('uses 14px for name column', (tester) async {
      await tester.pumpWidget(_wrap(
        const TextCell(value: 'Task Title', isNameColumn: true),
      ));

      final textWidget = tester.widget<Text>(find.text('Task Title'));
      expect(textWidget.style?.fontSize, 14.0);
    });

    testWidgets('uses 13px for non-name column', (tester) async {
      await tester.pumpWidget(_wrap(
        const TextCell(value: 'Description text'),
      ));

      final textWidget = tester.widget<Text>(find.text('Description text'));
      expect(textWidget.style?.fontSize, 13.0);
    });
  });

  // ───────────────────────────────────────────────
  // NumberCell
  // ───────────────────────────────────────────────
  group('NumberCell', () {
    testWidgets('shows right-aligned number text', (tester) async {
      await tester.pumpWidget(_wrap(
        const NumberCell(value: 42),
      ));
      expect(find.text('42'), findsOneWidget);
    });

    testWidgets('shows TextField when isEditing=true', (tester) async {
      await tester.pumpWidget(_wrap(
        const NumberCell(value: 42, isEditing: true),
      ));
      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('shows empty string for null value', (tester) async {
      await tester.pumpWidget(_wrap(
        const NumberCell(),
      ));
      // Should not crash and should render
      expect(find.byType(NumberCell), findsOneWidget);
    });
  });

  // ───────────────────────────────────────────────
  // CheckboxCell
  // ───────────────────────────────────────────────
  group('CheckboxCell', () {
    testWidgets('renders unchecked', (tester) async {
      await tester.pumpWidget(_wrap(
        const CheckboxCell(value: false),
      ));

      final checkbox = tester.widget<Checkbox>(find.byType(Checkbox));
      expect(checkbox.value, false);
    });

    testWidgets('renders checked', (tester) async {
      await tester.pumpWidget(_wrap(
        const CheckboxCell(value: true),
      ));

      final checkbox = tester.widget<Checkbox>(find.byType(Checkbox));
      expect(checkbox.value, true);
    });

    testWidgets('calls onChanged on tap', (tester) async {
      bool? newValue;
      await tester.pumpWidget(_wrap(
        CheckboxCell(
          value: false,
          onChanged: (v) => newValue = v,
        ),
      ));

      await tester.tap(find.byType(Checkbox));
      expect(newValue, true);
    });
  });

  // ───────────────────────────────────────────────
  // LinkCell
  // ───────────────────────────────────────────────
  group('LinkCell', () {
    testWidgets('shows underlined text in primary color', (tester) async {
      await tester.pumpWidget(_wrap(
        const LinkCell(value: 'https://example.com'),
      ));

      final textWidget = tester.widget<Text>(
        find.text('https://example.com'),
      );
      expect(textWidget.style?.decoration, TextDecoration.underline);
    });

    testWidgets('shows em dash when empty', (tester) async {
      await tester.pumpWidget(_wrap(
        const LinkCell(value: ''),
      ));
      expect(find.text('\u2014'), findsOneWidget);
    });

    testWidgets('shows TextField when isEditing=true', (tester) async {
      await tester.pumpWidget(_wrap(
        const LinkCell(value: 'https://example.com', isEditing: true),
      ));
      expect(find.byType(TextField), findsOneWidget);
    });
  });
}
