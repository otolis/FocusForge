import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/task_repository.dart';
import '../../domain/task_model.dart';

final taskRepositoryProvider = Provider<TaskRepository>(
  (ref) => TaskRepository(),
);

final taskListProvider = AsyncNotifierProvider<TaskListNotifier, List<Task>>(
  TaskListNotifier.new,
);

class TaskListNotifier extends AsyncNotifier<List<Task>> {
  @override
  FutureOr<List<Task>> build() async {
    final userId = _getCurrentUserId();
    final repo = ref.read(taskRepositoryProvider);
    return repo.getTasks(userId);
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final userId = _getCurrentUserId();
      final repo = ref.read(taskRepositoryProvider);
      return repo.getTasks(userId);
    });
  }

  Future<void> addTask(Task task) async {
    final repo = ref.read(taskRepositoryProvider);
    final created = await repo.createTask(task);
    state = AsyncData([...state.value ?? [], created]);
  }

  Future<void> updateTask(Task task) async {
    final repo = ref.read(taskRepositoryProvider);
    final updated = await repo.updateTask(task);
    final tasks = [...state.value ?? []];
    final index = tasks.indexWhere((t) => t.id == task.id);
    if (index != -1) {
      tasks[index] = updated;
      state = AsyncData(tasks);
    }
  }

  Future<void> toggleComplete(String taskId) async {
    final tasks = [...state.value ?? []];
    final index = tasks.indexWhere((t) => t.id == taskId);
    if (index == -1) return;
    final previous = tasks[index];
    final toggled = previous.copyWith(
      isCompleted: !previous.isCompleted,
      completedAt: !previous.isCompleted ? DateTime.now() : null,
      clearCompletedAt: previous.isCompleted,
    );
    tasks[index] = toggled;
    state = AsyncData(tasks);
    try {
      final repo = ref.read(taskRepositoryProvider);
      await repo.updateTask(toggled);
    } catch (e) {
      tasks[index] = previous;
      state = AsyncData(tasks);
      rethrow;
    }
  }

  Future<void> deleteTask(String taskId) async {
    final tasks = [...state.value ?? []];
    final previous = tasks.toList();
    tasks.removeWhere((t) => t.id == taskId);
    state = AsyncData(tasks);
    try {
      final repo = ref.read(taskRepositoryProvider);
      await repo.deleteTask(taskId);
    } catch (e) {
      state = AsyncData(previous);
      rethrow;
    }
  }

  String _getCurrentUserId() {
    return Supabase.instance.client.auth.currentUser!.id;
  }
}
