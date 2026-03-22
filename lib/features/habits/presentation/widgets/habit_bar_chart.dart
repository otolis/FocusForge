import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../../core/utils/extensions.dart';

/// A single data point for the habit analytics bar chart.
class DailyCompletion {
  /// The display label for this bar (e.g. "Mon", "W1", "Jan").
  final String label;

  /// The completion rate as a percentage (0–100).
  final double completionRate;

  const DailyCompletion({
    required this.label,
    required this.completionRate,
  });
}

/// An animated bar chart showing habit completion rates over time.
///
/// Each bar represents a time period's completion rate (0–100%).
/// Animates with a 300ms easeInOut transition when data changes.
class HabitBarChart extends StatelessWidget {
  const HabitBarChart({
    super.key,
    required this.data,
  });

  /// The completion data to display as bars.
  final List<DailyCompletion> data;

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return const AspectRatio(
        aspectRatio: 1.7,
        child: Center(child: Text('Check in to see your progress')),
      );
    }

    return AspectRatio(
      aspectRatio: 1.7,
      child: BarChart(
        BarChartData(
          maxY: 100,
          barGroups: data.asMap().entries.map((entry) {
            return BarChartGroupData(
              x: entry.key,
              barRods: [
                BarChartRodData(
                  toY: entry.value.completionRate,
                  width: 12,
                  color: context.colorScheme.primary,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(4),
                    topRight: Radius.circular(4),
                  ),
                ),
              ],
            );
          }).toList(),
          borderData: FlBorderData(show: false),
          gridData: const FlGridData(
            show: true,
            drawVerticalLine: false,
          ),
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index < 0 || index >= data.length) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      data[index].label,
                      style: context.textTheme.bodySmall,
                    ),
                  );
                },
                reservedSize: 24,
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  return Text(
                    '${value.toInt()}%',
                    style: context.textTheme.bodySmall,
                  );
                },
                reservedSize: 32,
                interval: 25,
              ),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
          ),
        ),
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      ),
    );
  }
}
