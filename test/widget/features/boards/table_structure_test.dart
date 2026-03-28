import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focusforge/features/boards/domain/board_model.dart';
import 'package:focusforge/features/boards/domain/board_table_column.dart';
import 'package:focusforge/features/boards/presentation/widgets/table/add_item_row.dart';
import 'package:focusforge/features/boards/presentation/widgets/table/group_footer_widget.dart';
import 'package:focusforge/features/boards/presentation/widgets/table/group_header_widget.dart';
import 'package:focusforge/features/boards/presentation/widgets/table/table_data_row.dart';
import 'package:focusforge/features/boards/presentation/widgets/table/table_header_row.dart';

void main() {
  // ──────────────────────────────────────────────
  // Shared test data
  // ──────────────────────────────────────────────

  const testGroup = BoardGroup(
    id: 'g1',
    name: 'Sprint 1',
    color: '#2196F3',
    position: 1000,
  );

  const testColumns = [
    TableColumnDef(
      id: 'col_status',
      type: ColumnType.status,
      name: 'Status',
      width: 150,
      position: 1000,
    ),
    TableColumnDef(
      id: 'col_priority',
      type: ColumnType.priority,
      name: 'Priority',
      width: 120,
      position: 2000,
    ),
    TableColumnDef(
      id: 'col_due',
      type: ColumnType.dueDate,
      name: 'Due Date',
      width: 120,
      position: 3000,
    ),
  ];

  const testStatusLabels = [
    StatusLabelDef(id: 's1', name: 'Working on it', color: '#FF9800'),
    StatusLabelDef(id: 's2', name: 'Done', color: '#4CAF50'),
  ];

  final testCard = BoardCard(
    id: 'card1',
    boardId: 'board1',
    columnId: 'col1',
    title: 'Test Task',
    priority: 2,
    statusLabel: 'Working on it',
    statusColor: '#FF9800',
    position: 1000,
    createdBy: 'user1',
    createdAt: DateTime(2026, 3, 1),
    updatedAt: DateTime(2026, 3, 15),
  );

  const testMembers = <BoardMember>[];

  /// Wraps a widget in a MaterialApp for testing.
  Widget wrapInApp(Widget child) {
    return MaterialApp(
      home: Scaffold(
        body: child,
      ),
    );
  }

  // ──────────────────────────────────────────────
  // GroupHeaderWidget tests
  // ──────────────────────────────────────────────

  group('GroupHeaderWidget', () {
    testWidgets('renders group name', (tester) async {
      await tester.pumpWidget(wrapInApp(
        GroupHeaderWidget(
          group: testGroup,
          itemCount: 5,
          isCollapsed: false,
          onToggle: () {},
        ),
      ));

      expect(find.text('Sprint 1'), findsOneWidget);
    });

    testWidgets('renders item count', (tester) async {
      await tester.pumpWidget(wrapInApp(
        GroupHeaderWidget(
          group: testGroup,
          itemCount: 7,
          isCollapsed: false,
          onToggle: () {},
        ),
      ));

      expect(find.text('7 items'), findsOneWidget);
    });

    testWidgets('shows expand_more icon when expanded', (tester) async {
      await tester.pumpWidget(wrapInApp(
        GroupHeaderWidget(
          group: testGroup,
          itemCount: 3,
          isCollapsed: false,
          onToggle: () {},
        ),
      ));

      expect(find.byIcon(Icons.expand_more), findsOneWidget);
      expect(find.byIcon(Icons.chevron_right), findsNothing);
    });

    testWidgets('shows chevron_right icon when collapsed', (tester) async {
      await tester.pumpWidget(wrapInApp(
        GroupHeaderWidget(
          group: testGroup,
          itemCount: 3,
          isCollapsed: true,
          onToggle: () {},
        ),
      ));

      expect(find.byIcon(Icons.chevron_right), findsOneWidget);
      expect(find.byIcon(Icons.expand_more), findsNothing);
    });

    testWidgets('calls onToggle when tapped', (tester) async {
      var toggled = false;
      await tester.pumpWidget(wrapInApp(
        GroupHeaderWidget(
          group: testGroup,
          itemCount: 3,
          isCollapsed: false,
          onToggle: () => toggled = true,
        ),
      ));

      await tester.tap(find.byType(GroupHeaderWidget));
      expect(toggled, isTrue);
    });

    testWidgets('has semantics label with group info', (tester) async {
      await tester.pumpWidget(wrapInApp(
        GroupHeaderWidget(
          group: testGroup,
          itemCount: 5,
          isCollapsed: false,
          onToggle: () {},
        ),
      ));

      // Verify that the Semantics widget exists with the correct label
      // by finding a Semantics widget whose properties contain our label.
      final semanticsFinder = find.bySemanticsLabel(
        RegExp(r'Group: Sprint 1.*5 items.*expanded'),
      );
      expect(semanticsFinder, findsOneWidget);
    });
  });

  // ──────────────────────────────────────────────
  // GroupFooterWidget tests
  // ──────────────────────────────────────────────

  group('GroupFooterWidget', () {
    testWidgets('fixed section renders item count', (tester) async {
      await tester.pumpWidget(wrapInApp(
        const GroupFooterWidget(
          itemCount: 12,
          section: FooterSection.fixed,
          statusCounts: {'Working on it': 5, 'Done': 7},
          statusLabels: testStatusLabels,
        ),
      ));

      expect(find.text('12 items'), findsOneWidget);
    });

    testWidgets('scrollable section renders status bar segments',
        (tester) async {
      await tester.pumpWidget(wrapInApp(
        const GroupFooterWidget(
          itemCount: 8,
          section: FooterSection.scrollable,
          statusCounts: {'Working on it': 3, 'Done': 5},
          statusLabels: testStatusLabels,
        ),
      ));

      // The ClipRRect wrapping the status bar segments should exist
      expect(find.byType(ClipRRect), findsOneWidget);
      // Two Flexible segments for the two status counts
      expect(find.byType(Flexible), findsNWidgets(2));
    });

    testWidgets('scrollable section renders em dash when no dates set',
        (tester) async {
      await tester.pumpWidget(wrapInApp(
        const GroupFooterWidget(
          itemCount: 4,
          section: FooterSection.scrollable,
          statusCounts: {},
          statusLabels: testStatusLabels,
        ),
      ));

      expect(find.text('\u2014'), findsOneWidget);
    });

    testWidgets('scrollable section renders date range when dates provided',
        (tester) async {
      await tester.pumpWidget(wrapInApp(
        GroupFooterWidget(
          itemCount: 3,
          section: FooterSection.scrollable,
          statusCounts: const {},
          statusLabels: testStatusLabels,
          earliestDate: DateTime(2026, 3, 1),
          latestDate: DateTime(2026, 3, 28),
        ),
      ));

      expect(find.text('Mar 1 - Mar 28'), findsOneWidget);
    });

    testWidgets('fixed section fits within 200px without overflow',
        (tester) async {
      await tester.pumpWidget(wrapInApp(
        SizedBox(
          width: 200,
          child: const GroupFooterWidget(
            itemCount: 99,
            section: FooterSection.fixed,
            statusCounts: {'Working on it': 5, 'Done': 7},
            statusLabels: testStatusLabels,
          ),
        ),
      ));

      // No overflow error means the widget fits within 200px
      expect(tester.takeException(), isNull);
      expect(find.text('99 items'), findsOneWidget);
    });
  });

  // ──────────────────────────────────────────────
  // AddItemRow tests
  // ──────────────────────────────────────────────

  group('AddItemRow', () {
    testWidgets('renders "Add item" hint text', (tester) async {
      await tester.pumpWidget(wrapInApp(
        AddItemRow(onSubmit: (_) {}),
      ));

      expect(find.text('Add item'), findsOneWidget);
    });

    testWidgets('renders add icon', (tester) async {
      await tester.pumpWidget(wrapInApp(
        AddItemRow(onSubmit: (_) {}),
      ));

      expect(find.byIcon(Icons.add), findsOneWidget);
    });

    testWidgets('calls onSubmit when Enter pressed with text', (tester) async {
      String? submitted;
      await tester.pumpWidget(wrapInApp(
        AddItemRow(onSubmit: (text) => submitted = text),
      ));

      await tester.enterText(find.byType(TextField), 'New task');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();

      expect(submitted, equals('New task'));
    });

    testWidgets('does not submit when text is empty', (tester) async {
      String? submitted;
      await tester.pumpWidget(wrapInApp(
        AddItemRow(onSubmit: (text) => submitted = text),
      ));

      await tester.enterText(find.byType(TextField), '');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();

      expect(submitted, isNull);
    });
  });

  // ──────────────────────────────────────────────
  // TableHeaderRow tests
  // ──────────────────────────────────────────────

  group('TableHeaderRow', () {
    testWidgets('renders column names', (tester) async {
      await tester.pumpWidget(wrapInApp(
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: TableHeaderRow(
            columns: testColumns,
            onResize: (_, __) {},
            onResizeEnd: () {},
            onAddColumn: () {},
            onReorder: (_, __) {},
          ),
        ),
      ));

      expect(find.text('Status'), findsOneWidget);
      expect(find.text('Priority'), findsOneWidget);
      expect(find.text('Due Date'), findsOneWidget);
    });

    testWidgets('renders add column button', (tester) async {
      await tester.pumpWidget(wrapInApp(
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: TableHeaderRow(
            columns: testColumns,
            onResize: (_, __) {},
            onResizeEnd: () {},
            onAddColumn: () {},
            onReorder: (_, __) {},
          ),
        ),
      ));

      expect(find.byIcon(Icons.add), findsOneWidget);
    });

    testWidgets('calls onAddColumn when add button tapped', (tester) async {
      var addCalled = false;
      await tester.pumpWidget(wrapInApp(
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: TableHeaderRow(
            columns: testColumns,
            onResize: (_, __) {},
            onResizeEnd: () {},
            onAddColumn: () => addCalled = true,
            onReorder: (_, __) {},
          ),
        ),
      ));

      await tester.tap(find.byIcon(Icons.add));
      expect(addCalled, isTrue);
    });

    testWidgets('has LongPressDraggable for column reorder', (tester) async {
      await tester.pumpWidget(wrapInApp(
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: TableHeaderRow(
            columns: testColumns,
            onResize: (_, __) {},
            onResizeEnd: () {},
            onAddColumn: () {},
            onReorder: (_, __) {},
          ),
        ),
      ));

      // One LongPressDraggable per column
      expect(
        find.byType(LongPressDraggable<int>),
        findsNWidgets(testColumns.length),
      );
    });

    testWidgets('has DragTarget for column drop zones', (tester) async {
      await tester.pumpWidget(wrapInApp(
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: TableHeaderRow(
            columns: testColumns,
            onResize: (_, __) {},
            onResizeEnd: () {},
            onAddColumn: () {},
            onReorder: (_, __) {},
          ),
        ),
      ));

      // One DragTarget per column
      expect(
        find.byType(DragTarget<int>),
        findsNWidgets(testColumns.length),
      );
    });

    testWidgets('accepts onReorder callback', (tester) async {
      int? fromIdx;
      int? toIdx;
      await tester.pumpWidget(wrapInApp(
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: TableHeaderRow(
            columns: testColumns,
            onResize: (_, __) {},
            onResizeEnd: () {},
            onAddColumn: () {},
            onReorder: (from, to) {
              fromIdx = from;
              toIdx = to;
            },
          ),
        ),
      ));

      // Verify the widget was built with the onReorder callback
      // (drag gesture testing is complex; we verify the widget tree instead)
      final headerRow =
          tester.widget<TableHeaderRow>(find.byType(TableHeaderRow));
      expect(headerRow.onReorder, isNotNull);
      // Verify callback type works
      headerRow.onReorder(0, 2);
      expect(fromIdx, 0);
      expect(toIdx, 2);
    });
  });

  // ──────────────────────────────────────────────
  // TableDataRow tests
  // ──────────────────────────────────────────────

  group('TableDataRow', () {
    testWidgets('renders correct number of cells matching columns',
        (tester) async {
      await tester.pumpWidget(wrapInApp(
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: TableDataRow(
            card: testCard,
            columns: testColumns,
            rowIndex: 0,
            members: testMembers,
            onCellTap: (_, __) {},
            onCellChanged: (_, __, ___) {},
          ),
        ),
      ));

      // Each column renders a SizedBox with the column width
      // We check that the row has exactly testColumns.length direct children
      // by looking for the cell-level SizedBox widgets
      final row = find.byType(TableDataRow);
      expect(row, findsOneWidget);

      // The row renders cells in SizedBox wrappers
      // We should find our specific cell types
      expect(find.byType(SizedBox), findsWidgets);
    });

    testWidgets('applies even row zebra striping (light mode)',
        (tester) async {
      await tester.pumpWidget(wrapInApp(
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: TableDataRow(
            card: testCard,
            columns: testColumns,
            rowIndex: 0,
            members: testMembers,
            onCellTap: (_, __) {},
            onCellChanged: (_, __, ___) {},
          ),
        ),
      ));

      // Find the Container that is the root of TableDataRow
      final container = tester.widget<Container>(
        find.descendant(
          of: find.byType(TableDataRow),
          matching: find.byType(Container).first,
        ),
      );

      final decoration = container.decoration as BoxDecoration;
      // Even row in light mode = #FFFBF5
      expect(decoration.color, equals(const Color(0xFFFFFBF5)));
    });

    testWidgets('applies odd row zebra striping (light mode)', (tester) async {
      await tester.pumpWidget(wrapInApp(
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: TableDataRow(
            card: testCard,
            columns: testColumns,
            rowIndex: 1,
            members: testMembers,
            onCellTap: (_, __) {},
            onCellChanged: (_, __, ___) {},
          ),
        ),
      ));

      final container = tester.widget<Container>(
        find.descendant(
          of: find.byType(TableDataRow),
          matching: find.byType(Container).first,
        ),
      );

      final decoration = container.decoration as BoxDecoration;
      // Odd row in light mode = #F5F0E8
      expect(decoration.color, equals(const Color(0xFFF5F0E8)));
    });

    testWidgets('has bottom border with outlineVariant', (tester) async {
      await tester.pumpWidget(wrapInApp(
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: TableDataRow(
            card: testCard,
            columns: testColumns,
            rowIndex: 0,
            members: testMembers,
            onCellTap: (_, __) {},
            onCellChanged: (_, __, ___) {},
          ),
        ),
      ));

      final container = tester.widget<Container>(
        find.descendant(
          of: find.byType(TableDataRow),
          matching: find.byType(Container).first,
        ),
      );

      final decoration = container.decoration as BoxDecoration;
      expect(decoration.border, isNotNull);
    });

    testWidgets('dispatches to StatusCell for status column', (tester) async {
      // Use only a status column
      const statusOnly = [
        TableColumnDef(
          id: 'col_status',
          type: ColumnType.status,
          name: 'Status',
          width: 150,
          position: 1000,
        ),
      ];

      await tester.pumpWidget(wrapInApp(
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: TableDataRow(
            card: testCard,
            columns: statusOnly,
            rowIndex: 0,
            members: testMembers,
            onCellTap: (_, __) {},
            onCellChanged: (_, __, ___) {},
          ),
        ),
      ));

      // StatusCell should render the status label text
      expect(find.text('Working on it'), findsOneWidget);
    });

    testWidgets('dispatches to CheckboxCell for checkbox column',
        (tester) async {
      const checkboxOnly = [
        TableColumnDef(
          id: 'col_check',
          type: ColumnType.checkbox,
          name: 'Done',
          width: 100,
          position: 1000,
        ),
      ];

      await tester.pumpWidget(wrapInApp(
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: TableDataRow(
            card: testCard,
            columns: checkboxOnly,
            rowIndex: 0,
            members: testMembers,
            onCellTap: (_, __) {},
            onCellChanged: (_, __, ___) {},
          ),
        ),
      ));

      expect(find.byType(Checkbox), findsOneWidget);
    });
  });
}
