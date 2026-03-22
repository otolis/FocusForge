import 'package:flutter/material.dart';

/// Time period for habit analytics chart grouping.
enum AnalyticsPeriod { week, month, year }

/// Extension providing a human-readable label for [AnalyticsPeriod].
extension AnalyticsPeriodLabel on AnalyticsPeriod {
  /// Returns the display label: "Week", "Month", or "Year".
  String get label {
    switch (this) {
      case AnalyticsPeriod.week:
        return 'Week';
      case AnalyticsPeriod.month:
        return 'Month';
      case AnalyticsPeriod.year:
        return 'Year';
    }
  }
}

/// A Material 3 [SegmentedButton] for selecting analytics time period.
///
/// Allows switching between [AnalyticsPeriod.week], [AnalyticsPeriod.month],
/// and [AnalyticsPeriod.year] for the analytics bar chart.
class PeriodSelector extends StatelessWidget {
  const PeriodSelector({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  /// The currently selected period.
  final AnalyticsPeriod selected;

  /// Called when the user selects a new period.
  final ValueChanged<AnalyticsPeriod> onChanged;

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<AnalyticsPeriod>(
      segments: AnalyticsPeriod.values
          .map(
            (period) => ButtonSegment<AnalyticsPeriod>(
              value: period,
              label: Text(period.label),
            ),
          )
          .toList(),
      selected: {selected},
      onSelectionChanged: (selection) => onChanged(selection.first),
    );
  }
}
