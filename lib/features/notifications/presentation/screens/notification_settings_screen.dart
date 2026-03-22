import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/utils/extensions.dart';
import '../../domain/notification_preferences.dart';
import '../providers/notification_providers.dart';
import '../widgets/category_toggle_card.dart';
import '../widgets/quiet_hours_picker.dart';
import '../widgets/reminder_offset_selector.dart';

/// Dedicated notification preferences screen with master toggle, category
/// sections, quiet hours picker, and snooze duration selector.
///
/// Loads preferences via [notificationPreferencesProvider] and persists
/// changes via [NotificationRepository.updatePreferences]. Each preference
/// change is saved immediately to Supabase.
class NotificationSettingsScreen extends ConsumerStatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  ConsumerState<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends ConsumerState<NotificationSettingsScreen> {
  /// Local copy of preferences for immediate UI updates while saving.
  NotificationPreferences? _prefs;

  /// The current user's ID, obtained from Supabase Auth.
  String get _userId => Supabase.instance.client.auth.currentUser!.id;

  /// Updates local state and persists to Supabase.
  Future<void> _updatePrefs(NotificationPreferences updated) async {
    setState(() => _prefs = updated);
    try {
      await ref
          .read(notificationRepositoryProvider)
          .updatePreferences(updated);
      ref.invalidate(notificationPreferencesProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Preferences saved'),
            duration: Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save: $e')),
        );
      }
    }
  }

  /// Opens a time picker and returns the selected time as "HH:mm" string.
  Future<void> _pickHabitSummaryTime() async {
    if (_prefs == null) return;
    final parts = _prefs!.habitDailySummaryTime.split(':');
    final initial = TimeOfDay(
      hour: int.parse(parts[0]),
      minute: int.parse(parts[1]),
    );
    final picked = await showTimePicker(
      context: context,
      initialTime: initial,
    );
    if (picked != null) {
      final formatted =
          '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
      _updatePrefs(_prefs!.copyWith(habitDailySummaryTime: formatted));
    }
  }

  @override
  Widget build(BuildContext context) {
    final prefsAsync = ref.watch(notificationPreferencesProvider(_userId));

    return Scaffold(
      appBar: AppBar(title: const Text('Notification Settings')),
      body: prefsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Failed to load preferences',
                style: context.textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () =>
                    ref.invalidate(notificationPreferencesProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (serverPrefs) {
          // Use local copy if available, otherwise use server data.
          final prefs = _prefs ?? serverPrefs;

          return ListView(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            children: [
              // 1. Master Toggle
              Card(
                child: SwitchListTile(
                  secondary: Icon(
                    Icons.notifications_rounded,
                    color: prefs.enabled
                        ? context.colorScheme.primary
                        : context.colorScheme.onSurfaceVariant,
                  ),
                  title: const Text('Notifications'),
                  subtitle: const Text(
                      'Enable or disable all notifications'),
                  value: prefs.enabled,
                  onChanged: (value) =>
                      _updatePrefs(prefs.copyWith(enabled: value)),
                ),
              ),
              const SizedBox(height: 24),

              // 2. Section Header: Categories
              Padding(
                padding: const EdgeInsets.only(left: 4, bottom: 8),
                child: Text(
                  'Categories',
                  style: context.textTheme.labelLarge?.copyWith(
                    color: context.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),

              // 3. Task Reminders
              IgnorePointer(
                ignoring: !prefs.enabled,
                child: Opacity(
                  opacity: prefs.enabled ? 1.0 : 0.5,
                  child: CategoryToggleCard(
                    title: 'Task Reminders',
                    subtitle: 'Get notified before task deadlines',
                    icon: Icons.task_alt_rounded,
                    enabled: prefs.taskRemindersEnabled,
                    onToggled: (value) => _updatePrefs(
                        prefs.copyWith(taskRemindersEnabled: value)),
                    children: [
                      ReminderOffsetSelector(
                        label: 'Default reminder timing',
                        selectedOffsets: prefs.taskDefaultOffsets,
                        onChanged: (offsets) => _updatePrefs(
                            prefs.copyWith(taskDefaultOffsets: offsets)),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),

              // 4. Habit Reminders
              IgnorePointer(
                ignoring: !prefs.enabled,
                child: Opacity(
                  opacity: prefs.enabled ? 1.0 : 0.5,
                  child: CategoryToggleCard(
                    title: 'Habit Reminders',
                    subtitle: 'Daily reminders for your habits',
                    icon: Icons.repeat_rounded,
                    enabled: prefs.habitRemindersEnabled,
                    onToggled: (value) => _updatePrefs(
                        prefs.copyWith(habitRemindersEnabled: value)),
                    children: [
                      Builder(builder: (context) {
                        final localizations =
                            MaterialLocalizations.of(context);
                        final parts =
                            prefs.habitDailySummaryTime.split(':');
                        final tod = TimeOfDay(
                          hour: int.parse(parts[0]),
                          minute: int.parse(parts[1]),
                        );
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Daily summary time'),
                          trailing: Text(
                            localizations.formatTimeOfDay(tod),
                            style: context.textTheme.bodyLarge?.copyWith(
                              color: context.colorScheme.primary,
                            ),
                          ),
                          onTap: _pickHabitSummaryTime,
                        );
                      }),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),

              // 5. Planner Notifications
              IgnorePointer(
                ignoring: !prefs.enabled,
                child: Opacity(
                  opacity: prefs.enabled ? 1.0 : 0.5,
                  child: CategoryToggleCard(
                    title: 'Planner Notifications',
                    subtitle:
                        'Morning summary and time block reminders',
                    icon: Icons.calendar_today_rounded,
                    enabled: prefs.plannerSummaryEnabled ||
                        prefs.plannerBlockRemindersEnabled,
                    onToggled: (value) => _updatePrefs(prefs.copyWith(
                      plannerSummaryEnabled: value,
                      plannerBlockRemindersEnabled: value,
                    )),
                    children: [
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Morning summary'),
                        value: prefs.plannerSummaryEnabled,
                        onChanged: (value) => _updatePrefs(
                            prefs.copyWith(plannerSummaryEnabled: value)),
                      ),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Time block reminders'),
                        value: prefs.plannerBlockRemindersEnabled,
                        onChanged: (value) => _updatePrefs(prefs.copyWith(
                            plannerBlockRemindersEnabled: value)),
                      ),
                      if (prefs.plannerBlockRemindersEnabled)
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Remind before block'),
                          trailing: DropdownButton<int>(
                            value: prefs.plannerBlockOffset,
                            underline: const SizedBox.shrink(),
                            items: const [
                              DropdownMenuItem(
                                  value: 5, child: Text('5 min')),
                              DropdownMenuItem(
                                  value: 10, child: Text('10 min')),
                              DropdownMenuItem(
                                  value: 15, child: Text('15 min')),
                              DropdownMenuItem(
                                  value: 30, child: Text('30 min')),
                            ],
                            onChanged: (value) {
                              if (value != null) {
                                _updatePrefs(prefs.copyWith(
                                    plannerBlockOffset: value));
                              }
                            },
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // 6. Section Header: Schedule
              Padding(
                padding: const EdgeInsets.only(left: 4, bottom: 8),
                child: Text(
                  'Schedule',
                  style: context.textTheme.labelLarge?.copyWith(
                    color: context.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),

              // 7. Quiet Hours
              IgnorePointer(
                ignoring: !prefs.enabled,
                child: Opacity(
                  opacity: prefs.enabled ? 1.0 : 0.5,
                  child: QuietHoursPicker(
                    enabled: prefs.quietHoursEnabled,
                    onEnabledChanged: (value) => _updatePrefs(
                        prefs.copyWith(quietHoursEnabled: value)),
                    startTime: prefs.quietStart,
                    endTime: prefs.quietEnd,
                    onStartChanged: (time) =>
                        _updatePrefs(prefs.copyWith(quietStart: time)),
                    onEndChanged: (time) =>
                        _updatePrefs(prefs.copyWith(quietEnd: time)),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // 8. Section Header: Actions
              Padding(
                padding: const EdgeInsets.only(left: 4, bottom: 8),
                child: Text(
                  'Actions',
                  style: context.textTheme.labelLarge?.copyWith(
                    color: context.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),

              // 9. Snooze Duration
              IgnorePointer(
                ignoring: !prefs.enabled,
                child: Opacity(
                  opacity: prefs.enabled ? 1.0 : 0.5,
                  child: Card(
                    child: ListTile(
                      leading: Icon(
                        Icons.snooze_rounded,
                        color: context.colorScheme.onSurfaceVariant,
                      ),
                      title: const Text('Snooze duration'),
                      subtitle: const Text(
                          'How long to delay snoozed notifications'),
                      trailing: DropdownButton<int>(
                        value: prefs.snoozeDuration,
                        underline: const SizedBox.shrink(),
                        items: const [
                          DropdownMenuItem(
                              value: 15, child: Text('15 min')),
                          DropdownMenuItem(
                              value: 30, child: Text('30 min')),
                          DropdownMenuItem(
                              value: 60, child: Text('1 hour')),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            _updatePrefs(
                                prefs.copyWith(snoozeDuration: value));
                          }
                        },
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          );
        },
      ),
    );
  }
}
