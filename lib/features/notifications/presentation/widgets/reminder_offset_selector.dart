import 'package:flutter/material.dart';

import '../../../../core/utils/extensions.dart';

/// A chip-based multi-selector for task reminder timing offsets.
///
/// Displays a row of [FilterChip] widgets, each representing a time
/// duration before a task deadline. Multiple chips can be selected
/// simultaneously (e.g. user wants both a 1-day and 1-hour reminder).
///
/// Offset values are in minutes. Common presets are provided with
/// human-readable labels.
class ReminderOffsetSelector extends StatelessWidget {
  const ReminderOffsetSelector({
    super.key,
    required this.label,
    required this.selectedOffsets,
    required this.onChanged,
  });

  /// Descriptive label shown above the chips (e.g. "Default reminder timing").
  final String label;

  /// Currently selected offset values in minutes.
  final List<int> selectedOffsets;

  /// Callback with the updated list of selected offsets.
  final ValueChanged<List<int>> onChanged;

  /// Available offset options in minutes, with human-readable labels.
  static const List<_OffsetOption> _options = [
    _OffsetOption(15, '15 min'),
    _OffsetOption(30, '30 min'),
    _OffsetOption(60, '1 hour'),
    _OffsetOption(180, '3 hours'),
    _OffsetOption(720, '12 hours'),
    _OffsetOption(1440, '1 day'),
    _OffsetOption(2880, '2 days'),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: context.textTheme.bodyMedium),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: _options.map((option) {
            final isSelected = selectedOffsets.contains(option.minutes);
            return FilterChip(
              label: Text(option.label),
              selected: isSelected,
              selectedColor: context.colorScheme.primaryContainer,
              onSelected: (selected) {
                final updated = List<int>.from(selectedOffsets);
                if (selected) {
                  updated.add(option.minutes);
                } else {
                  updated.remove(option.minutes);
                }
                onChanged(updated);
              },
            );
          }).toList(),
        ),
      ],
    );
  }
}

/// Internal model pairing a minute value with its display label.
class _OffsetOption {
  const _OffsetOption(this.minutes, this.label);
  final int minutes;
  final String label;
}
