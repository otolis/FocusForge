import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/habit_model.dart';
import '../domain/habit_log_model.dart';

/// Repository for habit CRUD operations and completion logging against the
/// Supabase `habits` and `habit_logs` tables.
///
/// Accepts an optional [SupabaseClient] for dependency injection in tests.
class HabitRepository {
  HabitRepository([SupabaseClient? client])
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  /// The currently authenticated user's ID.
  String get _userId => _client.auth.currentUser!.id;

  /// Fetches all habits for the current user, ordered by creation date.
  Future<List<Habit>> getHabits() async {
    final data = await _client
        .from('habits')
        .select()
        .eq('user_id', _userId)
        .order('created_at');
    return data.map((json) => Habit.fromJson(json)).toList();
  }

  /// Fetches a single habit by [habitId].
  Future<Habit> getHabit(String habitId) async {
    final data = await _client
        .from('habits')
        .select()
        .eq('id', habitId)
        .single();
    return Habit.fromJson(data);
  }

  /// Creates a new habit from the given [habit] model.
  Future<void> createHabit(Habit habit) async {
    await _client.from('habits').insert(habit.toJson());
    await _scheduleHabitReminder(habit);
  }

  /// Updates an existing habit matching [habit.id].
  Future<void> updateHabit(Habit habit) async {
    await _client
        .from('habits')
        .update(habit.toJson())
        .eq('id', habit.id);
  }

  /// Deletes the habit with the given [habitId].
  Future<void> deleteHabit(String habitId) async {
    // Clean up any unsent reminders for this habit
    try {
      await _client
          .from('scheduled_reminders')
          .delete()
          .eq('item_id', habitId)
          .eq('sent', false);
    } catch (_) {}
    await _client.from('habits').delete().eq('id', habitId);
  }

  /// Logs a completion for [habitId] for today.
  ///
  /// If a log entry already exists for today, increments the count.
  /// Otherwise, inserts a new log entry. Uses the user's local date
  /// to avoid timezone issues with the `DATE` column.
  Future<void> logCompletion(String habitId, {int count = 1}) async {
    final today = DateTime.now().toLocal();
    final dateStr =
        '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

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

  /// Fetches logs for a habit within a date range (inclusive).
  ///
  /// Used for heat map display and analytics charts.
  Future<List<HabitLog>> getLogs(
    String habitId, {
    required DateTime from,
    required DateTime to,
  }) async {
    final fromStr =
        '${from.year}-${from.month.toString().padLeft(2, '0')}-${from.day.toString().padLeft(2, '0')}';
    final toStr =
        '${to.year}-${to.month.toString().padLeft(2, '0')}-${to.day.toString().padLeft(2, '0')}';

    final data = await _client
        .from('habit_logs')
        .select()
        .eq('habit_id', habitId)
        .gte('completed_date', fromStr)
        .lte('completed_date', toStr)
        .order('completed_date');
    return data.map((json) => HabitLog.fromJson(json)).toList();
  }

  /// Fetches today's progress (count) for a specific habit.
  ///
  /// Returns 0 if no log entry exists for today.
  Future<int> getTodayProgress(String habitId) async {
    final today = DateTime.now().toLocal();
    final dateStr =
        '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

    final data = await _client
        .from('habit_logs')
        .select()
        .eq('habit_id', habitId)
        .eq('completed_date', dateStr)
        .maybeSingle();

    if (data != null) {
      return data['count'] as int;
    }
    return 0;
  }

  /// Inserts an initial habit reminder for daily check-in.
  ///
  /// Reads the user's habit_daily_summary_time from notification_preferences
  /// and inserts a single reminder for today (or tomorrow if past). The
  /// send-reminders Edge Function handles recurring delivery by re-inserting
  /// after each send.
  Future<void> _scheduleHabitReminder(Habit habit) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return;

      // Read user's preferred reminder time
      final prefsData = await _client
          .from('notification_preferences')
          .select('habit_daily_summary_time')
          .eq('user_id', userId)
          .maybeSingle();

      final summaryTime =
          prefsData?['habit_daily_summary_time'] as String? ?? '08:00';
      final parts = summaryTime.split(':');
      final hour = int.parse(parts[0]);
      final minute = int.parse(parts[1]);

      // Schedule for today at the user's preferred time, or tomorrow if past
      final now = DateTime.now();
      var remindAt = DateTime(now.year, now.month, now.day, hour, minute);
      if (remindAt.isBefore(now)) {
        remindAt = remindAt.add(const Duration(days: 1));
      }

      await _client.from('scheduled_reminders').insert({
        'user_id': userId,
        'reminder_type': 'habit_reminder',
        'item_id': habit.id,
        'remind_at': remindAt.toUtc().toIso8601String(),
        'title': 'Habit reminder',
        'body': habit.name,
        'deep_link_route': '/habits/${habit.id}',
      });
    } catch (e) {
      // Non-critical: don't fail habit creation if scheduling fails
    }
  }
}
