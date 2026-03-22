import 'package:flutter/material.dart';

import '../../../../core/utils/extensions.dart';

/// A widget for configuring quiet hours (do-not-disturb window).
///
/// Provides a toggle to enable/disable quiet hours and two time pickers
/// for start and end times. Times are stored as "HH:mm" strings and
/// displayed using [MaterialLocalizations.formatTimeOfDay].
///
/// When disabled, the time pickers are hidden with [AnimatedCrossFade].
class QuietHoursPicker extends StatelessWidget {
  const QuietHoursPicker({
    super.key,
    required this.enabled,
    required this.onEnabledChanged,
    required this.startTime,
    required this.endTime,
    required this.onStartChanged,
    required this.onEndChanged,
  });

  /// Whether quiet hours are currently enabled.
  final bool enabled;

  /// Callback when the quiet hours toggle is changed.
  final ValueChanged<bool> onEnabledChanged;

  /// Start of the quiet hours window (e.g. "22:00").
  final String startTime;

  /// End of the quiet hours window (e.g. "07:00").
  final String endTime;

  /// Callback when the start time is changed.
  final ValueChanged<String> onStartChanged;

  /// Callback when the end time is changed.
  final ValueChanged<String> onEndChanged;

  /// Converts an "HH:mm" string to a [TimeOfDay].
  static TimeOfDay _parseTime(String time) {
    final parts = time.split(':');
    return TimeOfDay(
      hour: int.parse(parts[0]),
      minute: int.parse(parts[1]),
    );
  }

  /// Converts a [TimeOfDay] to an "HH:mm" string.
  static String _formatTime(TimeOfDay time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _pickTime(
    BuildContext context,
    String currentTime,
    ValueChanged<String> onChanged,
  ) async {
    final initial = _parseTime(currentTime);
    final picked = await showTimePicker(
      context: context,
      initialTime: initial,
    );
    if (picked != null) {
      onChanged(_formatTime(picked));
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = MaterialLocalizations.of(context);

    return Card(
      child: Column(
        children: [
          SwitchListTile(
            secondary: Icon(
              Icons.do_not_disturb_on_rounded,
              color: enabled
                  ? context.colorScheme.primary
                  : context.colorScheme.onSurfaceVariant,
            ),
            title: const Text('Quiet Hours'),
            subtitle: const Text('Suppress notifications during this window'),
            value: enabled,
            onChanged: onEnabledChanged,
          ),
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: Column(
              children: [
                const Divider(height: 1),
                ListTile(
                  title: const Text('Start'),
                  trailing: Text(
                    localizations
                        .formatTimeOfDay(_parseTime(startTime)),
                    style: context.textTheme.bodyLarge?.copyWith(
                      color: context.colorScheme.primary,
                    ),
                  ),
                  onTap: () => _pickTime(context, startTime, onStartChanged),
                ),
                ListTile(
                  title: const Text('End'),
                  trailing: Text(
                    localizations
                        .formatTimeOfDay(_parseTime(endTime)),
                    style: context.textTheme.bodyLarge?.copyWith(
                      color: context.colorScheme.primary,
                    ),
                  ),
                  onTap: () => _pickTime(context, endTime, onEndChanged),
                ),
              ],
            ),
            crossFadeState: enabled
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 250),
          ),
        ],
      ),
    );
  }
}
