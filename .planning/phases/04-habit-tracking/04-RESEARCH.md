# Phase 4: Habit Tracking - Research

**Researched:** 2026-03-18
**Domain:** Flutter habit tracking (CRUD, streak logic, heat map visualization, bar charts, haptic feedback)
**Confidence:** HIGH

## Summary

Phase 4 implements a complete habit tracking vertical slice: Supabase schema (habits + habit_logs tables), data layer (repository), domain logic (streak calculation), and presentation (list, detail, analytics, heat map, check-in animation). The phase depends only on Phase 1 (auth, theme, app shell, Supabase client) which is complete.

The standard stack for this phase is well-established: `fl_chart` 1.2.0 for bar charts (already specified in CLAUDE.md tech stack), `contribution_heatmap` 0.5.3 for the GitHub-style heat map calendar (supports amber/orange palettes natively), and Flutter's built-in `HapticFeedback` API for tactile feedback. The existing codebase already uses Riverpod 3.x with `Notifier`/`AsyncNotifier` patterns and Clean Architecture (`data/domain/presentation` per feature), so the habits feature follows the same conventions established in the auth and profile features.

**Primary recommendation:** Follow the existing Clean Architecture pattern from `features/profile/` exactly. Use `contribution_heatmap` for the heat map (it has built-in `HeatmapColor.amber`), `fl_chart` `BarChart` for analytics, Flutter's `HapticFeedback.lightImpact()` / `mediumImpact()` for feedback, and a custom `ScaleTransition` for the bounce animation. Build the Supabase migration with `habits` and `habit_logs` tables plus RLS policies matching the `profiles` table pattern.

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
- Calendar heat map (GitHub-style contribution grid) showing the last 3 months
- Color intensity mapped to completion (empty, partial, full) using the amber/orange palette
- Heat map appears on the habit detail screen (not the list -- too large)
- Current streak displayed as fire icon + "X day streak" badge below the heat map
- Streak counter (compact) also visible on the habit list card for quick reference
- Binary habits (yes/no): one-tap on the habit card in the list view -- tap the check circle to complete
- Count-based habits (e.g., "drink 8 glasses"): tap to increment by 1, long-press for custom entry dialog
- Completion animation: scale bounce + color fill on the card/circle (subtle, satisfying)
- Lottie/confetti animations deferred to Phase 8 integration
- Haptic feedback: light haptic on every check-in tap, medium haptic on streak milestones (7, 30, 100 days)
- Primary chart: bar chart showing daily completion rate for the selected period, rendered via fl_chart
- Time period selector: Material 3 SegmentedButton with Week / Month / Year options
- Summary stats: four stat cards above the chart -- best streak, current streak, total completions, completion rate %
- Analytics is a dedicated section within the habit detail screen (scrollable below the heat map)

### Claude's Discretion
- Habit list layout (cards vs tiles), grouping strategy, and sort order
- Empty state design for no habits yet
- Habit creation/edit form layout and field arrangement
- Heat map color gradient exact values (stay within amber/orange family)
- Streak calculation algorithm (handling timezone, partial completions)
- Database schema design (habits table, habit_logs table, indexes)
- Bar chart styling (colors, labels, grid lines)

### Deferred Ideas (OUT OF SCOPE)
- Streak freeze (prevent anxiety from breaks) -- tracked as HABIT-05 in v2 requirements
- Lottie/confetti animations on completion -- Phase 8 integration
- Habit reminders/notifications -- Phase 7
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|-----------------|
| HABIT-01 | User can create, edit, and delete habits with daily/weekly/custom frequency and target counts | Supabase schema design (habits table with frequency/target_count columns), Clean Architecture CRUD pattern from profile feature, Riverpod Notifier pattern |
| HABIT-02 | User can see visual streak tracking with consecutive-day counter and chain display | `contribution_heatmap` package for GitHub-style heat map, streak calculation algorithm with date-difference logic, amber/orange HeatmapColor |
| HABIT-03 | User can view habit analytics with completion rate charts (weekly/monthly/yearly) via fl_chart | `fl_chart` 1.2.0 BarChart API with BarChartData/BarChartGroupData, Material 3 SegmentedButton for period selection, stat card layout |
| HABIT-04 | User can check in habits with one-tap completion and satisfying feedback animations | ScaleTransition bounce animation, Flutter HapticFeedback API (lightImpact/mediumImpact), tap/long-press gesture handling for binary vs count-based habits |
</phase_requirements>

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| fl_chart | ^1.2.0 | Bar charts for habit analytics | Specified in project tech stack (CLAUDE.md). Most popular Flutter charting library (3k+ GitHub stars). Supports bar, line, pie. Latest version (1.2.0, published March 2026) adds label support on bar rods. |
| contribution_heatmap | ^0.5.3 | GitHub-style heat map calendar for streak visualization | Custom RenderBox for high performance. Built-in `HeatmapColor.amber` matches project palette. Interactive tap support. Published Jan 2026, actively maintained. |
| flutter_riverpod | ^3.3.1 | State management (already in project) | Already installed. Project uses Notifier/AsyncNotifier patterns. |
| supabase_flutter | ^2.12.0 | Backend (already in project) | Already installed. Habits feature uses same Supabase client for CRUD + RLS. |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| Flutter HapticFeedback | built-in | Tactile feedback on check-in | `import 'package:flutter/services.dart'` -- no additional dependency. Use `HapticFeedback.lightImpact()` for every check-in, `HapticFeedback.mediumImpact()` for milestone streaks. |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| contribution_heatmap | flutter_heatmap_calendar | flutter_heatmap_calendar is older, less maintained, and lacks built-in amber color support. contribution_heatmap uses custom RenderBox (better performance) and has amber/orange presets. |
| contribution_heatmap | Custom-built heat map widget | Full control over styling but 200-300 lines of custom painting code. Package already supports amber palette and tap callbacks. Use package unless customization needs exceed its API. |
| fl_chart | syncfusion_flutter_charts | Syncfusion requires license attribution and is much heavier. fl_chart is already in the project tech stack. |

**Installation:**
```bash
flutter pub add fl_chart contribution_heatmap
```

**Version verification:**
- fl_chart 1.2.0: Published March 14, 2026. Requires Dart >=3.6.2, Flutter >=3.27.4. Compatible with project (Dart ^3.7.0, Flutter >=3.29.0). [Source: pub.dev]
- contribution_heatmap 0.5.3: Published January 2, 2026. Requires Dart >=3.0.0, Flutter >=3.0.0. Compatible. BSD-3-Clause license. [Source: pub.dev]

## Architecture Patterns

### Recommended Project Structure
```
lib/features/habits/
├── data/
│   └── habit_repository.dart        # Supabase CRUD for habits + habit_logs
├── domain/
│   ├── habit_model.dart             # Habit model with fromJson/toJson
│   ├── habit_log_model.dart         # HabitLog model (completion entries)
│   ├── habit_frequency.dart         # Frequency enum (daily/weekly/custom)
│   └── streak_calculator.dart       # Pure streak calculation logic
├── presentation/
│   ├── providers/
│   │   └── habit_provider.dart      # Riverpod providers (Notifier, FutureProvider)
│   ├── screens/
│   │   ├── habit_list_screen.dart   # Main list with check-in circles
│   │   ├── habit_detail_screen.dart # Heat map + analytics + stats
│   │   └── habit_form_screen.dart   # Create/edit form
│   └── widgets/
│       ├── habit_card.dart          # List item with streak badge + check circle
│       ├── habit_heat_map.dart      # Wraps ContributionHeatmap
│       ├── habit_bar_chart.dart     # Wraps fl_chart BarChart
│       ├── stat_card.dart           # Summary stat card (streak, rate, etc.)
│       ├── check_in_button.dart     # Animated check-in circle with bounce
│       └── period_selector.dart     # SegmentedButton for Week/Month/Year
```

### Pattern 1: Notifier + Repository (CRUD State Management)
**What:** Use Riverpod `Notifier` or `AsyncNotifier` to manage habit list state, with a repository for Supabase operations. Matches the `AuthStateNotifier` + `AuthRepository` pattern already in the codebase.
**When to use:** For the main habit list and CRUD operations.
**Example:**
```dart
// Source: Existing pattern from auth_provider.dart, adapted for habits

// Repository provider
final habitRepositoryProvider = Provider<HabitRepository>(
  (ref) => HabitRepository(),
);

// Habit list provider (async, fetches from Supabase)
final habitListProvider = AsyncNotifierProvider<HabitListNotifier, List<Habit>>(
  HabitListNotifier.new,
);

class HabitListNotifier extends AsyncNotifier<List<Habit>> {
  late final HabitRepository _repository;

  @override
  Future<List<Habit>> build() async {
    _repository = ref.read(habitRepositoryProvider);
    return _repository.getHabits();
  }

  Future<void> createHabit(Habit habit) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await _repository.createHabit(habit);
      return _repository.getHabits();
    });
  }

  Future<void> deleteHabit(String habitId) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await _repository.deleteHabit(habitId);
      return _repository.getHabits();
    });
  }

  Future<void> checkIn(String habitId, {int count = 1}) async {
    await _repository.logCompletion(habitId, count: count);
    ref.invalidateSelf(); // Refresh list to show updated streak
  }
}
```

### Pattern 2: Model with fromJson/toJson (Supabase Serialization)
**What:** Follow the exact `Profile.fromJson()` / `toJson()` pattern for Habit and HabitLog models. Server-managed fields (id, created_at) excluded from toJson.
**When to use:** All domain models that map to Supabase tables.
**Example:**
```dart
// Source: Adapted from profile_model.dart pattern

enum HabitFrequency { daily, weekly, custom }

class Habit {
  final String id;
  final String userId;
  final String name;
  final String? description;
  final HabitFrequency frequency;
  final int targetCount;        // 1 for binary, >1 for count-based
  final List<int>? customDays;  // For weekly/custom: [1,3,5] = Mon/Wed/Fri
  final String? icon;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Transient (not stored in DB, computed client-side)
  final int currentStreak;
  final int todayProgress;

  const Habit({
    required this.id,
    required this.userId,
    required this.name,
    this.description,
    this.frequency = HabitFrequency.daily,
    this.targetCount = 1,
    this.customDays,
    this.icon,
    required this.createdAt,
    required this.updatedAt,
    this.currentStreak = 0,
    this.todayProgress = 0,
  });

  bool get isBinary => targetCount == 1;
  bool get isCompletedToday => todayProgress >= targetCount;

  factory Habit.fromJson(Map<String, dynamic> json) {
    return Habit(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      frequency: HabitFrequency.values.byName(json['frequency'] as String),
      targetCount: json['target_count'] as int? ?? 1,
      customDays: (json['custom_days'] as List?)?.cast<int>(),
      icon: json['icon'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
    'user_id': userId,
    'name': name,
    'description': description,
    'frequency': frequency.name,
    'target_count': targetCount,
    'custom_days': customDays,
    'icon': icon,
    'updated_at': DateTime.now().toIso8601String(),
  };
}
```

### Pattern 3: ScaleTransition Bounce Animation for Check-In
**What:** Use explicit `AnimationController` + `ScaleTransition` for a snappy bounce effect on habit check-in, combined with color fill transition.
**When to use:** The check-in circle/button on habit cards.
**Example:**
```dart
// Source: Flutter API docs (ScaleTransition, AnimationController)

class CheckInButton extends StatefulWidget {
  final bool isCompleted;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  const CheckInButton({
    super.key,
    required this.isCompleted,
    required this.onTap,
    this.onLongPress,
  });

  @override
  State<CheckInButton> createState() => _CheckInButtonState();
}

class _CheckInButtonState extends State<CheckInButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.3).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );
  }

  void _handleTap() {
    _controller.forward().then((_) => _controller.reverse());
    HapticFeedback.lightImpact();
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _handleTap,
      onLongPress: widget.onLongPress,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: widget.isCompleted
                ? context.colorScheme.primary
                : Colors.transparent,
            border: Border.all(
              color: context.colorScheme.primary,
              width: 2,
            ),
          ),
          child: Icon(
            widget.isCompleted ? Icons.check : null,
            color: widget.isCompleted
                ? context.colorScheme.onPrimary
                : null,
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
```

### Anti-Patterns to Avoid
- **Storing streak count in the habits table:** Streak is a derived value from habit_logs. Calculate it on-the-fly from log entries rather than maintaining a separate counter that can become stale. Cache the computed value in the model's transient field.
- **Fetching all logs for streak calculation:** Only fetch logs from today backwards until a gap is found, not the entire log history. Use a Supabase query with `.order('completed_date', ascending: false).limit(N)`.
- **Using StatefulWidget for list-level state:** The habit list state belongs in Riverpod, not in StatefulWidget. Only use StatefulWidget for animation controllers (like the bounce effect).
- **Mixing UTC and local dates:** All date comparisons for streaks must use the user's local date (midnight-to-midnight), not UTC timestamps. Store `completed_date` as `DATE` (not `TIMESTAMPTZ`) in the habit_logs table to avoid timezone ambiguity.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| GitHub-style heat map calendar | Custom GridView/Table with day cells | `contribution_heatmap` package | Handles month boundaries, week alignment, scrolling, and has built-in amber/orange color schemes. 200+ lines of custom painting avoided. |
| Bar chart with axis labels | Custom CustomPainter chart | `fl_chart` BarChart | Touch handling, axis titles, grid lines, animations, responsive sizing all built-in. Custom charts take 500+ lines and miss edge cases. |
| Haptic feedback | Custom platform channel vibrations | `HapticFeedback.lightImpact()` / `mediumImpact()` | Built into Flutter SDK. Works on both iOS and Android with platform-appropriate feedback levels. |
| Date calculations (week-of-year, day-of-week) | Manual DateTime arithmetic | Dart's built-in `DateTime` API (`weekday`, `difference()`) | Edge cases with DST, leap years, month boundaries. Dart handles these correctly. |

**Key insight:** The heat map is the riskiest custom component to build. The `contribution_heatmap` package's `HeatmapColor.amber` enum value directly matches the design requirement and saves significant implementation time. If the amber preset doesn't exactly match the theme, the fallback is to fork or wrap the widget -- but try the preset first.

## Common Pitfalls

### Pitfall 1: Streak Calculation Across Timezones
**What goes wrong:** Streaks break or double-count because the app uses UTC midnight instead of the user's local midnight for day boundaries.
**Why it happens:** Supabase stores timestamps in UTC. If a user in UTC-8 completes a habit at 11pm local time, that's 7am UTC the next day.
**How to avoid:** Store `completed_date` as a `DATE` type (not `TIMESTAMPTZ`) in the habit_logs table, and always convert `DateTime.now()` to the user's local date before comparing. Use `DateTime.now().toLocal()` and compare `.year`, `.month`, `.day` properties, not raw timestamps.
**Warning signs:** Users reporting broken streaks, or streaks incrementing twice in one day.

### Pitfall 2: Weekly/Custom Frequency Streak Logic
**What goes wrong:** A habit set to "3 times per week" shows a broken streak on non-scheduled days.
**Why it happens:** Naive streak logic checks every consecutive day. For weekly habits, "consecutive" means consecutive scheduled periods, not consecutive calendar days.
**How to avoid:** For daily habits: check consecutive calendar days. For weekly habits: check consecutive weeks where the target was met. For custom habits (e.g., Mon/Wed/Fri): check that the last N scheduled days were all completed. Ignore non-scheduled days entirely.
**Warning signs:** Users with weekly habits always seeing "0 day streak".

### Pitfall 3: Heat Map Data Volume
**What goes wrong:** Loading 90 days of habit logs for the heat map causes slow rendering or excessive Supabase reads.
**Why it happens:** Fetching all logs individually instead of aggregating.
**How to avoid:** Use a single Supabase query with `.gte('completed_date', threeMonthsAgo)` and group by date client-side. The result set for 90 days is at most 90 rows -- manageable. Consider caching the result in the provider.
**Warning signs:** Slow detail screen load, excessive Supabase API calls in dashboard.

### Pitfall 4: fl_chart Bar Chart Not Animating on Data Change
**What goes wrong:** The bar chart appears static when switching between Week/Month/Year periods.
**Why it happens:** Not passing `duration` and `curve` to the `BarChart` widget, or rebuilding the widget with a new key.
**How to avoid:** Always pass `BarChart(data, duration: Duration(milliseconds: 300), curve: Curves.easeInOut)` to enable implicit animations. The fl_chart library handles transitions between data states automatically when these are set.
**Warning signs:** Abrupt chart redraws, no smooth transition.

### Pitfall 5: Check-In Race Conditions
**What goes wrong:** Rapid tapping on the check-in button sends multiple Supabase insert requests, creating duplicate log entries.
**Why it happens:** No debounce or optimistic UI update.
**How to avoid:** Use a `UNIQUE` constraint on `(habit_id, completed_date)` in the database (for binary habits). For count-based habits, use `UPSERT` (Supabase `.upsert()`) to increment the count rather than inserting a new row. Also debounce the tap handler (disable button while request is in-flight).
**Warning signs:** Duplicate rows in habit_logs, count jumping by 2+ on single tap.

## Code Examples

### Supabase Migration: habits + habit_logs Tables
```sql
-- Source: Pattern from 00001_create_profiles.sql, adapted for habits

-- habits table: stores habit definitions
create table public.habits (
  id uuid default gen_random_uuid() primary key,
  user_id uuid not null references auth.users on delete cascade,
  name text not null,
  description text,
  frequency text not null default 'daily' check (frequency in ('daily', 'weekly', 'custom')),
  target_count integer not null default 1 check (target_count >= 1),
  custom_days integer[] default null,  -- e.g., {1,3,5} for Mon/Wed/Fri
  icon text,
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

alter table public.habits enable row level security;

create policy "Users can view own habits"
  on public.habits for select
  using ((select auth.uid()) = user_id);

create policy "Users can insert own habits"
  on public.habits for insert
  with check ((select auth.uid()) = user_id);

create policy "Users can update own habits"
  on public.habits for update
  using ((select auth.uid()) = user_id)
  with check ((select auth.uid()) = user_id);

create policy "Users can delete own habits"
  on public.habits for delete
  using ((select auth.uid()) = user_id);

-- habit_logs table: stores completion entries
create table public.habit_logs (
  id uuid default gen_random_uuid() primary key,
  habit_id uuid not null references public.habits on delete cascade,
  completed_date date not null default current_date,
  count integer not null default 1 check (count >= 1),
  created_at timestamptz default now(),
  unique (habit_id, completed_date)
);

alter table public.habit_logs enable row level security;

-- Users can view logs for their own habits
create policy "Users can view own habit logs"
  on public.habit_logs for select
  using (
    exists (
      select 1 from public.habits
      where habits.id = habit_logs.habit_id
      and habits.user_id = (select auth.uid())
    )
  );

-- Users can insert logs for their own habits
create policy "Users can insert own habit logs"
  on public.habit_logs for insert
  with check (
    exists (
      select 1 from public.habits
      where habits.id = habit_logs.habit_id
      and habits.user_id = (select auth.uid())
    )
  );

-- Users can update logs for their own habits
create policy "Users can update own habit logs"
  on public.habit_logs for update
  using (
    exists (
      select 1 from public.habits
      where habits.id = habit_logs.habit_id
      and habits.user_id = (select auth.uid())
    )
  );

-- Users can delete logs for their own habits
create policy "Users can delete own habit logs"
  on public.habit_logs for delete
  using (
    exists (
      select 1 from public.habits
      where habits.id = habit_logs.habit_id
      and habits.user_id = (select auth.uid())
    )
  );

-- Indexes for common queries
create index idx_habits_user_id on public.habits(user_id);
create index idx_habit_logs_habit_id on public.habit_logs(habit_id);
create index idx_habit_logs_completed_date on public.habit_logs(completed_date);
create index idx_habit_logs_habit_date on public.habit_logs(habit_id, completed_date);
```

### Repository: Habit CRUD + Log Operations
```dart
// Source: Pattern from profile_repository.dart

class HabitRepository {
  HabitRepository([SupabaseClient? client])
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  String get _userId => _client.auth.currentUser!.id;

  Future<List<Habit>> getHabits() async {
    final data = await _client
        .from('habits')
        .select()
        .eq('user_id', _userId)
        .order('created_at');
    return data.map((json) => Habit.fromJson(json)).toList();
  }

  Future<void> createHabit(Habit habit) async {
    await _client.from('habits').insert(habit.toJson());
  }

  Future<void> updateHabit(Habit habit) async {
    await _client
        .from('habits')
        .update(habit.toJson())
        .eq('id', habit.id);
  }

  Future<void> deleteHabit(String habitId) async {
    await _client.from('habits').delete().eq('id', habitId);
  }

  /// Logs a completion for today. Uses upsert to handle count-based habits.
  Future<void> logCompletion(String habitId, {int count = 1}) async {
    final today = DateTime.now().toLocal();
    final dateStr = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

    // Check if entry exists for today
    final existing = await _client
        .from('habit_logs')
        .select()
        .eq('habit_id', habitId)
        .eq('completed_date', dateStr)
        .maybeSingle();

    if (existing != null) {
      // Update count (increment)
      final currentCount = existing['count'] as int;
      await _client
          .from('habit_logs')
          .update({'count': currentCount + count})
          .eq('id', existing['id']);
    } else {
      // Insert new entry
      await _client.from('habit_logs').insert({
        'habit_id': habitId,
        'completed_date': dateStr,
        'count': count,
      });
    }
  }

  /// Fetches logs for a habit within a date range (for heat map and analytics).
  Future<List<HabitLog>> getLogs(String habitId, {
    required DateTime from,
    required DateTime to,
  }) async {
    final data = await _client
        .from('habit_logs')
        .select()
        .eq('habit_id', habitId)
        .gte('completed_date', from.toIso8601String().split('T').first)
        .lte('completed_date', to.toIso8601String().split('T').first)
        .order('completed_date');
    return data.map((json) => HabitLog.fromJson(json)).toList();
  }
}
```

### Streak Calculation Algorithm
```dart
// Source: Community best practices + adapted for frequency types

class StreakCalculator {
  /// Calculates the current streak for a daily habit.
  ///
  /// Works backwards from today: if today is completed, count it.
  /// Then check yesterday, day before, etc. Stop at the first gap.
  static int calculateDailyStreak(List<HabitLog> logs, int targetCount) {
    if (logs.isEmpty) return 0;

    // Build a set of completed dates for O(1) lookup
    final completedDates = <String>{};
    for (final log in logs) {
      if (log.count >= targetCount) {
        completedDates.add(_dateKey(log.completedDate));
      }
    }

    final today = DateTime.now().toLocal();
    var current = today;
    var streak = 0;

    // If today is not completed, start checking from yesterday
    if (!completedDates.contains(_dateKey(current))) {
      current = current.subtract(const Duration(days: 1));
      // If yesterday also not completed, streak is 0
      if (!completedDates.contains(_dateKey(current))) return 0;
    }

    // Count backwards from current date
    while (completedDates.contains(_dateKey(current))) {
      streak++;
      current = current.subtract(const Duration(days: 1));
    }

    return streak;
  }

  /// Calculates streak for weekly habits (consecutive weeks meeting target).
  static int calculateWeeklyStreak(
    List<HabitLog> logs,
    int targetCount,
    int targetDaysPerWeek,
  ) {
    if (logs.isEmpty) return 0;

    // Group logs by ISO week
    final weekMap = <String, int>{};
    for (final log in logs) {
      final weekKey = _weekKey(log.completedDate);
      weekMap[weekKey] = (weekMap[weekKey] ?? 0) + (log.count >= targetCount ? 1 : 0);
    }

    final today = DateTime.now().toLocal();
    var currentWeek = today;
    var streak = 0;

    // Check current week first
    final thisWeekKey = _weekKey(currentWeek);
    final thisWeekCount = weekMap[thisWeekKey] ?? 0;

    // If current week not yet met target, check previous week
    if (thisWeekCount < targetDaysPerWeek) {
      currentWeek = currentWeek.subtract(const Duration(days: 7));
    }

    while (true) {
      final key = _weekKey(currentWeek);
      final count = weekMap[key] ?? 0;
      if (count >= targetDaysPerWeek) {
        streak++;
        currentWeek = currentWeek.subtract(const Duration(days: 7));
      } else {
        break;
      }
    }

    return streak;
  }

  static String _dateKey(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  static String _weekKey(DateTime date) {
    // ISO week number calculation
    final dayOfYear = date.difference(DateTime(date.year, 1, 1)).inDays;
    final weekNumber = ((dayOfYear - date.weekday + 10) / 7).floor();
    return '${date.year}-W$weekNumber';
  }
}
```

### fl_chart Bar Chart for Analytics
```dart
// Source: fl_chart 1.2.0 API (pub.dev/packages/fl_chart)

Widget buildCompletionBarChart(
  List<DailyCompletion> data,
  BuildContext context,
) {
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
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(4),
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
                if (index < data.length) {
                  return Text(
                    data[index].label, // "Mon", "Jan", etc.
                    style: context.textTheme.bodySmall,
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 32,
              getTitlesWidget: (value, meta) {
                return Text(
                  '${value.toInt()}%',
                  style: context.textTheme.bodySmall,
                );
              },
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
```

### Heat Map Integration
```dart
// Source: contribution_heatmap 0.5.3 API (pub.dev)

Widget buildHabitHeatMap(List<HabitLog> logs, int targetCount) {
  final entries = logs.map((log) {
    // Map completion level: 0 = none, partial = 1-targetCount, full = targetCount
    final level = log.count >= targetCount ? targetCount : log.count;
    return ContributionEntry(log.completedDate, level);
  }).toList();

  final now = DateTime.now().toLocal();
  final threeMonthsAgo = DateTime(now.year, now.month - 3, now.day);

  return SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    child: ContributionHeatmap(
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
        // Show tooltip or detail for that day
      },
    ),
  );
}
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| StateNotifier + StateNotifierProvider | Notifier + NotifierProvider (or AsyncNotifier) | Riverpod 2.0 (2023), refined in 3.0 (Sep 2025) | This project already uses Notifier pattern (auth_provider.dart). Continue using it for habits. |
| fl_chart 0.x (`y:`, `colors:`) | fl_chart 1.x (`toY:`, `color:`, labels on rods) | fl_chart 1.0.0 (May 2025), 1.2.0 (Mar 2026) | Breaking API changes from 0.x to 1.x. Use `toY` not `y`, `color` not `colors`. |
| Custom-painted heat maps | `contribution_heatmap` package | Published 2025, v0.5.3 Jan 2026 | Eliminates 200+ lines of custom painting code. Built-in amber/orange support. |
| flutter_heatmap_calendar | contribution_heatmap | 2025-2026 | contribution_heatmap uses custom RenderBox (better perf), actively maintained, has built-in amber preset. |

**Deprecated/outdated:**
- `StateNotifier`: Still works in Riverpod 3.x but is legacy. Use `Notifier` or `AsyncNotifier` instead.
- fl_chart `colors:` parameter: Removed in 1.x. Use `color:` (singular) or `gradient:` property.
- fl_chart `y:` parameter in `BarChartRodData`: Renamed to `toY:` in 0.55+.

## Open Questions

1. **Heat map `HeatmapColor.amber` exact appearance**
   - What we know: The `contribution_heatmap` package has an `amber` enum value in HeatmapColor.
   - What's unclear: The exact color gradient values (light-to-dark amber range). May need visual testing to confirm it matches the project's amber seed color (#FF8F00).
   - Recommendation: Install the package and test visually. If the preset doesn't match, the alternative is a custom-built heat map using CustomPainter or wrapping with ColorFiltered.

2. **Count-based habit log upsert strategy**
   - What we know: The unique constraint on `(habit_id, completed_date)` prevents duplicate binary entries. For count-based habits, we need to increment the count.
   - What's unclear: Whether Supabase's `.upsert()` with `onConflict` can atomically increment a column, or if a read-then-update is needed.
   - Recommendation: Use a read-then-update pattern (shown in code example above). If performance becomes an issue, consider a PostgreSQL function with `INSERT ... ON CONFLICT DO UPDATE SET count = habit_logs.count + $1`.

3. **Custom-days frequency streak behavior**
   - What we know: Daily and weekly streaks have clear semantics. Custom frequency (e.g., Mon/Wed/Fri) needs careful logic.
   - What's unclear: Should a "custom" habit's streak reset if the user misses a non-scheduled day? (Answer: No -- only scheduled days count.)
   - Recommendation: For custom frequency, track consecutive *scheduled* days that were completed. If today is not a scheduled day, the streak remains unchanged.

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | flutter_test + mockito 5.4.4 |
| Config file | None (Flutter default) |
| Quick run command | `flutter test test/unit/habits/` |
| Full suite command | `flutter test` |

### Phase Requirements to Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| HABIT-01 | Habit CRUD (create, read, update, delete) with frequency and target_count | unit | `flutter test test/unit/habits/habit_model_test.dart -x` | No -- Wave 0 |
| HABIT-01 | HabitRepository CRUD operations | unit | `flutter test test/unit/habits/habit_repository_test.dart -x` | No -- Wave 0 |
| HABIT-02 | Streak calculation (daily, weekly, custom) | unit | `flutter test test/unit/habits/streak_calculator_test.dart -x` | No -- Wave 0 |
| HABIT-02 | Heat map renders with correct entries | widget | `flutter test test/widget/habits/habit_heat_map_test.dart -x` | No -- Wave 0 |
| HABIT-03 | Analytics data aggregation (completion rates) | unit | `flutter test test/unit/habits/habit_analytics_test.dart -x` | No -- Wave 0 |
| HABIT-03 | Bar chart renders with correct data | widget | `flutter test test/widget/habits/habit_bar_chart_test.dart -x` | No -- Wave 0 |
| HABIT-04 | Check-in increments count and triggers animation | widget | `flutter test test/widget/habits/check_in_button_test.dart -x` | No -- Wave 0 |
| HABIT-04 | Haptic feedback calls on check-in | unit | `flutter test test/unit/habits/habit_check_in_test.dart -x` | No -- Wave 0 |

### Sampling Rate
- **Per task commit:** `flutter test test/unit/habits/`
- **Per wave merge:** `flutter test`
- **Phase gate:** Full suite green before `/gsd:verify-work`

### Wave 0 Gaps
- [ ] `test/unit/habits/habit_model_test.dart` -- covers HABIT-01 (model serialization, frequency enum, isBinary/isCompletedToday)
- [ ] `test/unit/habits/habit_repository_test.dart` -- covers HABIT-01 (mock Supabase CRUD)
- [ ] `test/unit/habits/streak_calculator_test.dart` -- covers HABIT-02 (daily, weekly, custom streaks, edge cases)
- [ ] `test/unit/habits/habit_analytics_test.dart` -- covers HABIT-03 (completion rate aggregation)
- [ ] `test/widget/habits/check_in_button_test.dart` -- covers HABIT-04 (tap handler, animation trigger)
- [ ] Test helper extensions for habit fixtures in `test/helpers/test_helpers.dart`

## Sources

### Primary (HIGH confidence)
- [fl_chart pub.dev](https://pub.dev/packages/fl_chart) -- version 1.2.0 confirmed, API verified
- [fl_chart bar_chart documentation](https://github.com/imaNNeo/fl_chart/blob/main/repo_files/documentations/bar_chart.md) -- BarChartData, BarChartGroupData, BarChartRodData API
- [fl_chart changelog](https://pub.dev/packages/fl_chart/changelog) -- breaking changes from 0.x to 1.x confirmed
- [contribution_heatmap pub.dev](https://pub.dev/packages/contribution_heatmap) -- version 0.5.3, HeatmapColor enum with amber/orange values
- [Flutter HapticFeedback API](https://api.flutter.dev/flutter/services/HapticFeedback-class.html) -- lightImpact, mediumImpact methods
- [Flutter ScaleTransition API](https://api.flutter.dev/flutter/widgets/ScaleTransition-class.html) -- bounce animation pattern
- Existing codebase: `lib/features/profile/` -- established Clean Architecture + Riverpod pattern

### Secondary (MEDIUM confidence)
- [Supabase RLS documentation](https://supabase.com/docs/guides/database/tables) -- RLS policy patterns
- [fl_chart BarChartGroupData API docs](https://pub.dev/documentation/fl_chart/latest/fl_chart/BarChartGroupData-class.html) -- full property list
- [Building a Habit Tracker in Flutter (C# Corner)](https://www.c-sharpcorner.com/article/building-a-habit-tracker-app-in-flutter-part-4-advanced-tracking-notificati/) -- streak algorithm patterns

### Tertiary (LOW confidence)
- Heat map `HeatmapColor.amber` exact color values -- needs visual verification after install
- `contribution_heatmap` custom color API -- enum only, no custom Color() support documented

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH -- fl_chart is the project's declared charting library, contribution_heatmap verified on pub.dev with amber support
- Architecture: HIGH -- follows exact patterns already established in the codebase (profile feature, auth feature)
- Pitfalls: HIGH -- streak calculation gotchas well-documented in community, timezone issues universally acknowledged
- Heat map package: MEDIUM -- HeatmapColor.amber exists but exact gradient not verified visually

**Research date:** 2026-03-18
**Valid until:** 2026-04-18 (30 days -- stable libraries, unlikely to change)
