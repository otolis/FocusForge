import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/utils/extensions.dart';
import '../../domain/habit_frequency.dart';
import '../../domain/habit_log_model.dart';
import '../../domain/habit_model.dart';
import '../../domain/streak_calculator.dart';
import '../providers/habit_provider.dart';
import '../widgets/habit_bar_chart.dart';
import '../widgets/habit_heat_map.dart';
import '../widgets/period_selector.dart';
import '../widgets/stat_card.dart';

/// Full habit detail screen with GitHub-style heat map, streak badge,
/// summary statistics, and analytics bar chart.
///
/// Receives a [habitId] from the route parameter and fetches the habit
/// and its logs from the repository. Computes streak and analytics stats
/// using [StreakCalculator].
class HabitDetailScreen extends ConsumerStatefulWidget {
  const HabitDetailScreen({super.key, required this.habitId});

  /// The ID of the habit to display.
  final String habitId;

  @override
  ConsumerState<HabitDetailScreen> createState() => _HabitDetailScreenState();
}

class _HabitDetailScreenState extends ConsumerState<HabitDetailScreen> {
  AnalyticsPeriod _selectedPeriod = AnalyticsPeriod.month;
  Habit? _habit;
  List<HabitLog> _logs = [];
  bool _isLoading = true;
  String? _errorMessage;

  // Computed stats
  int _currentStreak = 0;
  int _bestStreak = 0;
  int _totalCompletions = 0;
  double _completionRate = 0.0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      final repository = ref.read(habitRepositoryProvider);
      final now = DateTime.now();
      final oneYearAgo = DateTime(now.year - 1, now.month, now.day);

      final habit = await repository.getHabit(widget.habitId);
      final logs = await repository.getLogs(
        widget.habitId,
        from: oneYearAgo,
        to: now,
      );
      final todayProgress = await repository.getTodayProgress(widget.habitId);

      // Compute streaks based on frequency
      int currentStreak;
      switch (habit.frequency) {
        case HabitFrequency.daily:
          currentStreak =
              StreakCalculator.calculateDailyStreak(logs, habit.targetCount);
          break;
        case HabitFrequency.weekly:
          currentStreak = StreakCalculator.calculateWeeklyStreak(
            logs,
            habit.targetCount,
            habit.targetCount, // target days per week
          );
          break;
        case HabitFrequency.custom:
          currentStreak = StreakCalculator.calculateCustomStreak(
            logs,
            habit.targetCount,
            habit.customDays ?? [],
          );
          break;
      }

      final bestStreak =
          StreakCalculator.bestStreak(logs, habit.targetCount);
      final totalCompletions = StreakCalculator.totalCompletions(logs);

      // Completion rate for last 30 days
      final thirtyDaysAgo = now.subtract(const Duration(days: 30));
      final completionRate = StreakCalculator.completionRate(
        logs,
        habit.targetCount,
        thirtyDaysAgo,
        now,
      );

      if (mounted) {
        setState(() {
          _habit = habit.copyWith(todayProgress: todayProgress);
          _logs = logs;
          _currentStreak = currentStreak;
          _bestStreak = bestStreak;
          _totalCompletions = totalCompletions;
          _completionRate = completionRate;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Could not load habit details. Please try again.';
        });
      }
    }
  }

  /// Computes bar chart data from logs based on the selected period.
  List<DailyCompletion> _computeChartData() {
    if (_habit == null || _logs.isEmpty) return [];

    final now = DateTime.now();
    final targetCount = _habit!.targetCount;

    switch (_selectedPeriod) {
      case AnalyticsPeriod.week:
        return _computeWeekData(now, targetCount);
      case AnalyticsPeriod.month:
        return _computeMonthData(now, targetCount);
      case AnalyticsPeriod.year:
        return _computeYearData(now, targetCount);
    }
  }

  List<DailyCompletion> _computeWeekData(DateTime now, int targetCount) {
    const dayLabels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final results = <DailyCompletion>[];

    // Find Monday of current week
    final monday = now.subtract(Duration(days: now.weekday - 1));

    for (var i = 0; i < 7; i++) {
      final day = monday.add(Duration(days: i));
      final dayKey =
          '${day.year}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';

      final dayLogs = _logs.where((log) {
        final logKey =
            '${log.completedDate.year}-${log.completedDate.month.toString().padLeft(2, '0')}-${log.completedDate.day.toString().padLeft(2, '0')}';
        return logKey == dayKey;
      });

      final totalCount =
          dayLogs.fold<int>(0, (sum, log) => sum + log.count);
      final rate = totalCount >= targetCount ? 100.0 : (totalCount / targetCount) * 100;

      results.add(DailyCompletion(
        label: dayLabels[i],
        completionRate: day.isAfter(now) ? 0 : rate,
      ));
    }

    return results;
  }

  List<DailyCompletion> _computeMonthData(DateTime now, int targetCount) {
    final results = <DailyCompletion>[];
    final thirtyDaysAgo = now.subtract(const Duration(days: 29));

    // Group into 4 weeks (roughly)
    for (var week = 0; week < 4; week++) {
      final weekStart = thirtyDaysAgo.add(Duration(days: week * 7));
      final weekEnd = week < 3
          ? thirtyDaysAgo.add(Duration(days: (week + 1) * 7 - 1))
          : now;

      var completedDays = 0;
      var totalDays = 0;

      var checkDay = weekStart;
      while (!checkDay.isAfter(weekEnd) && !checkDay.isAfter(now)) {
        totalDays++;
        final dayKey =
            '${checkDay.year}-${checkDay.month.toString().padLeft(2, '0')}-${checkDay.day.toString().padLeft(2, '0')}';

        final dayTotal = _logs
            .where((log) {
              final logKey =
                  '${log.completedDate.year}-${log.completedDate.month.toString().padLeft(2, '0')}-${log.completedDate.day.toString().padLeft(2, '0')}';
              return logKey == dayKey;
            })
            .fold<int>(0, (sum, log) => sum + log.count);

        if (dayTotal >= targetCount) completedDays++;
        checkDay = checkDay.add(const Duration(days: 1));
      }

      final rate = totalDays > 0 ? (completedDays / totalDays) * 100 : 0.0;
      results.add(DailyCompletion(
        label: 'W${week + 1}',
        completionRate: rate,
      ));
    }

    return results;
  }

  List<DailyCompletion> _computeYearData(DateTime now, int targetCount) {
    const monthLabels = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    final results = <DailyCompletion>[];

    for (var i = 11; i >= 0; i--) {
      final monthDate = DateTime(now.year, now.month - i, 1);
      final monthEnd = DateTime(monthDate.year, monthDate.month + 1, 0);
      final effectiveEnd = monthEnd.isAfter(now) ? now : monthEnd;

      final totalDays = effectiveEnd.difference(monthDate).inDays + 1;
      var completedDays = 0;

      var checkDay = monthDate;
      while (!checkDay.isAfter(effectiveEnd)) {
        final dayKey =
            '${checkDay.year}-${checkDay.month.toString().padLeft(2, '0')}-${checkDay.day.toString().padLeft(2, '0')}';

        final dayTotal = _logs
            .where((log) {
              final logKey =
                  '${log.completedDate.year}-${log.completedDate.month.toString().padLeft(2, '0')}-${log.completedDate.day.toString().padLeft(2, '0')}';
              return logKey == dayKey;
            })
            .fold<int>(0, (sum, log) => sum + log.count);

        if (dayTotal >= targetCount) completedDays++;
        checkDay = checkDay.add(const Duration(days: 1));
      }

      final rate = totalDays > 0 ? (completedDays / totalDays) * 100 : 0.0;
      results.add(DailyCompletion(
        label: monthLabels[(monthDate.month - 1) % 12],
        completionRate: rate,
      ));
    }

    return results;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text(_habit?.name ?? 'Loading...')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final habit = _habit;
    if (habit == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Habit')),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _errorMessage ?? 'Habit not found',
                style: context.textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              if (_errorMessage != null) ...[
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: _loadData,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                ),
              ],
            ],
          ),
        ),
      );
    }

    // Filter logs to last 3 months for heat map
    final now = DateTime.now();
    final threeMonthsAgo = DateTime(now.year, now.month - 3, now.day);
    final heatMapLogs = _logs
        .where((log) => log.completedDate.isAfter(threeMonthsAgo))
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(habit.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            tooltip: 'Edit habit',
            onPressed: () => context.push('/habits/${widget.habitId}/edit'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section 1: Heat Map
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Text('Activity', style: context.textTheme.titleMedium),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 8),
              child: HabitHeatMap(
                logs: heatMapLogs,
                targetCount: habit.targetCount,
              ),
            ),
            // Streak badge
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Icon(
                    Icons.local_fire_department,
                    color: context.colorScheme.tertiary,
                    size: 24,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '$_currentStreak day streak',
                    style: context.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (_currentStreak >= 7) ...[
                    const SizedBox(width: 8),
                    Text(
                      'Keep it up!',
                      style: context.textTheme.bodySmall?.copyWith(
                        color: context.colorScheme.tertiary,
                      ),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Section 2: Summary Stats
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text('Statistics', style: context.textTheme.titleMedium),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: GridView.count(
                crossAxisCount: 2,
                childAspectRatio: 2.5,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  StatCard(
                    label: 'Best Streak',
                    value: '$_bestStreak days',
                    icon: Icons.emoji_events,
                    iconColor: context.colorScheme.tertiary,
                  ),
                  StatCard(
                    label: 'Current Streak',
                    value: '$_currentStreak days',
                    icon: Icons.local_fire_department,
                    iconColor: context.colorScheme.tertiary,
                  ),
                  StatCard(
                    label: 'Total Check-ins',
                    value: '$_totalCompletions',
                  ),
                  StatCard(
                    label: 'Completion Rate',
                    value: '${_completionRate.toStringAsFixed(0)}%',
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Section 3: Analytics Chart
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Text(
                    'Completion Rate',
                    style: context.textTheme.titleMedium,
                  ),
                  const Spacer(),
                  PeriodSelector(
                    selected: _selectedPeriod,
                    onChanged: (period) {
                      setState(() => _selectedPeriod = period);
                    },
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: HabitBarChart(data: _computeChartData()),
            ),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
