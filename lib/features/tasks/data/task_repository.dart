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
    return Task.fromJson(data);
  }

  Future<Task> updateTask(Task task) async {
    final data = await _client.from('tasks').update(task.toJson()).eq('id', task.id).select('*, categories(*)').single();
    return Task.fromJson(data);
  }

  Future<void> deleteTask(String taskId) async {
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
}
