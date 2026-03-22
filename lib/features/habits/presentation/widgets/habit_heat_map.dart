import 'package:contribution_heatmap/contribution_heatmap.dart';
import 'package:flutter/material.dart';

import '../../domain/habit_log_model.dart';

/// A GitHub-style contribution heat map showing habit completion over the
/// last 3 months.
///
/// Uses the `contribution_heatmap` package with an amber/orange color palette.
/// Each cell's intensity is mapped to the completion count, capped at
/// [targetCount] for consistent color scaling.
class HabitHeatMap extends StatelessWidget {
  const HabitHeatMap({
    super.key,
    required this.logs,
    required this.targetCount,
  });

  /// The habit completion logs to visualize.
  final List<HabitLog> logs;

  /// The target count for the habit (used to cap intensity mapping).
  final int targetCount;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final threeMonthsAgo = DateTime(now.year, now.month - 3, now.day);

    // Map habit logs to ContributionEntry list
    final entries = logs.map((log) {
      final level = log.count >= targetCount ? targetCount : log.count;
      return ContributionEntry(log.completedDate, level);
    }).toList();

    return ContributionHeatmap(
      entries: entries,
      minDate: threeMonthsAgo,
      maxDate: now,
      heatmapColor: HeatmapColor.amber,
      cellSize: 14,
      cellSpacing: 3,
      cellRadius: 3,
      showMonthLabels: true,
      weekdayLabel: WeekdayLabel.githubLike,
      startWeekday: DateTime.monday,
      onCellTap: (date, count) {
        final dateStr =
            '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$dateStr: $count completion${count == 1 ? '' : 's'}'),
            duration: const Duration(seconds: 2),
          ),
        );
      },
    );
  }
}
