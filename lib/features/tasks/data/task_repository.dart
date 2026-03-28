import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/task_model.dart';
import '../domain/task_filter.dart';

class TaskRepository {
  TaskRepository([SupabaseClient? client])
      : _client = client ?? Supabase.instance.client;
  final SupabaseClient _client;

  Future<List<Task>> getTasks(String userId, {TaskFilter? filter}) async {
    var query = _client.from('tasks').select('*, categories(*)').eq('user_id', userId);

    if (filter != null) {
      if (filter.priority != null) {
        query = query.eq('priority', filter.priority!.index);
      }
      if (filter.categoryId != null) {
        query = query.eq('category_id', filter.categoryId!);
      }
      if (filter.dateFrom != null) {
        query = query.gte('deadline', filter.dateFrom!.toIso8601String());
      }
      if (filter.dateTo != null) {
        query = query.lte('deadline', filter.dateTo!.toIso8601String());
      }
    }

    final data = await query.order('deadline', ascending: true);
    return data.map((json) => Task.fromJson(json)).toList();
  }

  /// Fetches a single task by ID. Returns null if not found.
  Future<Task?> getTaskById(String taskId) async {
    final data = await _client
        .from('tasks')
        .select('*, categories(*)')
        .eq('id', taskId)
        .maybeSingle();
    if (data == null) return null;
    return Task.fromJson(data);
  }

  Future<Task> createTask(Task task) async {
    final data = await _client.from('tasks').insert(task.toJson()).select('*, categories(*)').single();
    final created = Task.fromJson(data);
    await _scheduleReminders(created);
    return created;
  }

  Future<Task> updateTask(Task task) async {
    final data = await _client.from('tasks').update(task.toJson()).eq('id', task.id).select('*, categories(*)').single();
    final updated = Task.fromJson(data);
    await _scheduleReminders(updated);
    return updated;
  }

  Future<void> deleteTask(String taskId) async {
    // Clean up any unsent reminders for this task
    try {
      await _client
          .from('scheduled_reminders')
          .delete()
          .eq('item_id', taskId)
          .eq('sent', false);
    } catch (_) {}
    await _client.from('tasks').delete().eq('id', taskId);
  }

  Future<List<Task>> searchTasks(String query) async {
    final data = await _client.rpc('search_tasks', params: {
      'p_query': query,
    });
    return (data as List).map((json) => Task.fromJson(json as Map<String, dynamic>)).toList();
  }

  Future<void> generateRecurringInstances(String taskId) async {
    await _client.rpc('generate_recurring_instances', params: {
      'p_task_id': taskId,
    });
  }

  /// Inserts initial scheduled_reminders rows for a task with a deadline.
  ///
  /// Reads the user's task_default_offsets from notification_preferences,
  /// deletes any existing unsent reminders for this task, then inserts
  /// new reminders at each offset before the deadline. Skips remind_at
  /// times that are in the past.
  Future<void> _scheduleReminders(Task task) async {
    if (task.deadline == null || task.isCompleted) return;
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;

    try {
      // Read user's default offsets from notification_preferences
      final prefsData = await _client
          .from('notification_preferences')
          .select('task_default_offsets')
          .eq('user_id', userId)
          .maybeSingle();

      final offsets = prefsData != null
          ? (prefsData['task_default_offsets'] as List?)?.cast<int>() ??
              [1440, 60]
          : [1440, 60];

      // Delete existing unsent reminders for this task (idempotent on update)
      await _client
          .from('scheduled_reminders')
          .delete()
          .eq('item_id', task.id)
          .eq('sent', false);

      // Insert new reminders at each offset
      final now = DateTime.now();
      for (final offsetMinutes in offsets) {
        final remindAt =
            task.deadline!.subtract(Duration(minutes: offsetMinutes));
        if (remindAt.isAfter(now)) {
          await _client.from('scheduled_reminders').insert({
            'user_id': userId,
            'reminder_type': 'task_deadline',
            'item_id': task.id,
            'remind_at': remindAt.toUtc().toIso8601String(),
            'title': 'Task deadline approaching',
            'body': task.title,
            'deep_link_route': '/tasks/${task.id}',
          });
        }
      }
    } catch (e) {
      // Non-critical: don't fail the task create/update if scheduling fails
      // The task is already saved at this point
    }
  }
}
