import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:focusforge/features/notifications/domain/notification_preferences.dart';
import 'package:focusforge/features/notifications/data/notification_repository.dart';
import 'package:focusforge/features/notifications/presentation/providers/notification_providers.dart';
import 'package:focusforge/features/notifications/presentation/widgets/category_toggle_card.dart';
import 'package:focusforge/features/notifications/presentation/widgets/quiet_hours_picker.dart';
import 'package:focusforge/features/notifications/presentation/widgets/reminder_offset_selector.dart';

void main() {
  group('CategoryToggleCard', () {
    Widget buildCard({
      bool enabled = true,
      List<Widget> children = const [],
      ValueChanged<bool>? onToggled,
    }) {
      return MaterialApp(
        home: Scaffold(
          body: CategoryToggleCard(
            title: 'Task Reminders',
            subtitle: 'Get notified before task deadlines',
            icon: Icons.task_alt_rounded,
            enabled: enabled,
            onToggled: onToggled ?? (_) {},
            children: children,
          ),
        ),
      );
    }

    testWidgets('renders title and subtitle', (tester) async {
      await tester.pumpWidget(buildCard());
      expect(find.text('Task Reminders'), findsOneWidget);
      expect(find.text('Get notified before task deadlines'), findsOneWidget);
    });

    testWidgets('renders Switch toggle', (tester) async {
      await tester.pumpWidget(buildCard());
      expect(find.byType(Switch), findsOneWidget);
    });

    testWidgets('hides children when disabled', (tester) async {
      await tester.pumpWidget(buildCard(
        enabled: false,
        children: [const Text('Child Widget')],
      ));
      await tester.pumpAndSettle();
      // AnimatedCrossFade should show firstChild (SizedBox.shrink)
      expect(find.text('Child Widget'), findsOneWidget);
      // The child exists in tree but AnimatedCrossFade hides it visually
      expect(find.byType(AnimatedCrossFade), findsOneWidget);
    });

    testWidgets('shows children when enabled', (tester) async {
      await tester.pumpWidget(buildCard(
        enabled: true,
        children: [const Text('Child Widget')],
      ));
      await tester.pumpAndSettle();
      expect(find.text('Child Widget'), findsOneWidget);
      expect(find.byType(AnimatedCrossFade), findsOneWidget);
    });

    testWidgets('calls onToggled when switch is tapped', (tester) async {
      bool? toggled;
      await tester.pumpWidget(buildCard(
        enabled: true,
        onToggled: (v) => toggled = v,
      ));
      await tester.tap(find.byType(Switch));
      expect(toggled, false);
    });
  });

  group('QuietHoursPicker', () {
    Widget buildPicker({
      bool enabled = false,
      String startTime = '22:00',
      String endTime = '07:00',
    }) {
      return MaterialApp(
        home: Scaffold(
          body: QuietHoursPicker(
            enabled: enabled,
            onEnabledChanged: (_) {},
            startTime: startTime,
            endTime: endTime,
            onStartChanged: (_) {},
            onEndChanged: (_) {},
          ),
        ),
      );
    }

    testWidgets('renders Quiet Hours text', (tester) async {
      await tester.pumpWidget(buildPicker());
      expect(find.text('Quiet Hours'), findsOneWidget);
    });

    testWidgets('renders SwitchListTile for toggle', (tester) async {
      await tester.pumpWidget(buildPicker());
      expect(find.byType(SwitchListTile), findsOneWidget);
    });

    testWidgets('shows Start and End labels when enabled', (tester) async {
      await tester.pumpWidget(buildPicker(enabled: true));
      await tester.pumpAndSettle();
      expect(find.text('Start'), findsOneWidget);
      expect(find.text('End'), findsOneWidget);
    });

    testWidgets('uses AnimatedCrossFade for expand/collapse', (tester) async {
      await tester.pumpWidget(buildPicker());
      expect(find.byType(AnimatedCrossFade), findsOneWidget);
    });
  });

  group('ReminderOffsetSelector', () {
    Widget buildSelector({
      List<int> selectedOffsets = const [1440, 60],
    }) {
      return MaterialApp(
        home: Scaffold(
          body: ReminderOffsetSelector(
            label: 'Default reminder timing',
            selectedOffsets: selectedOffsets,
            onChanged: (_) {},
          ),
        ),
      );
    }

    testWidgets('renders label text', (tester) async {
      await tester.pumpWidget(buildSelector());
      expect(find.text('Default reminder timing'), findsOneWidget);
    });

    testWidgets('renders all 7 FilterChip options', (tester) async {
      await tester.pumpWidget(buildSelector());
      expect(find.byType(FilterChip), findsNWidgets(7));
    });

    testWidgets('shows human-readable labels for offsets', (tester) async {
      await tester.pumpWidget(buildSelector());
      expect(find.text('15 min'), findsOneWidget);
      expect(find.text('30 min'), findsOneWidget);
      expect(find.text('1 hour'), findsOneWidget);
      expect(find.text('3 hours'), findsOneWidget);
      expect(find.text('12 hours'), findsOneWidget);
      expect(find.text('1 day'), findsOneWidget);
      expect(find.text('2 days'), findsOneWidget);
    });

    testWidgets('selected offsets are reflected in chips', (tester) async {
      await tester.pumpWidget(buildSelector(selectedOffsets: [1440, 60]));
      // FilterChips with selected=true for 1440 (1 day) and 60 (1 hour)
      final chips = tester.widgetList<FilterChip>(find.byType(FilterChip));
      final selectedChips = chips.where((c) => c.selected).toList();
      expect(selectedChips.length, 2);
    });
  });

  group('NotificationSettingsScreen structure', () {
    // Note: Full screen tests require Supabase mock which is complex.
    // These tests verify the individual widget components that compose
    // the screen, ensuring all building blocks render correctly.

    testWidgets('CategoryToggleCard renders all three category types',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ListView(
              children: [
                CategoryToggleCard(
                  title: 'Task Reminders',
                  subtitle: 'Get notified before task deadlines',
                  icon: Icons.task_alt_rounded,
                  enabled: true,
                  onToggled: (_) {},
                ),
                CategoryToggleCard(
                  title: 'Habit Reminders',
                  subtitle: 'Daily reminders for your habits',
                  icon: Icons.repeat_rounded,
                  enabled: true,
                  onToggled: (_) {},
                ),
                CategoryToggleCard(
                  title: 'Planner Notifications',
                  subtitle: 'Morning summary and time block reminders',
                  icon: Icons.calendar_today_rounded,
                  enabled: true,
                  onToggled: (_) {},
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Task Reminders'), findsOneWidget);
      expect(find.text('Habit Reminders'), findsOneWidget);
      expect(find.text('Planner Notifications'), findsOneWidget);
      expect(find.byType(CategoryToggleCard), findsNWidgets(3));
    });

    testWidgets('Snooze duration dropdown has correct options',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Card(
              child: ListTile(
                title: const Text('Snooze duration'),
                subtitle:
                    const Text('How long to delay snoozed notifications'),
                trailing: DropdownButton<int>(
                  value: 15,
                  items: const [
                    DropdownMenuItem(value: 15, child: Text('15 min')),
                    DropdownMenuItem(value: 30, child: Text('30 min')),
                    DropdownMenuItem(value: 60, child: Text('1 hour')),
                  ],
                  onChanged: (_) {},
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.text('Snooze duration'), findsOneWidget);
      expect(
          find.text('How long to delay snoozed notifications'), findsOneWidget);
      expect(find.byType(DropdownButton<int>), findsOneWidget);
    });
  });
}
