import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/utils/date_helpers.dart';
import '../../../../core/utils/extensions.dart';
import '../../domain/task_model.dart';
import '../providers/task_filter_provider.dart';
import '../providers/task_provider.dart';
import '../widgets/date_section_header.dart';
import '../widgets/task_card.dart';
import '../widgets/task_filter_bar.dart';
import '../widgets/task_quick_create_sheet.dart';

/// The main task list screen with date-grouped cards, filter/search bar,
/// quick-create FAB, pull-to-refresh, collapsible completed section, delete
/// undo snackbar, and empty state.
class TaskListScreen extends ConsumerWidget {
  const TaskListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filteredAsync = ref.watch(filteredTaskListProvider);
    final completedAsync = ref.watch(completedTaskListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tasks'),
        automaticallyImplyLeading: false,
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: context.colorScheme.primary,
        foregroundColor: context.colorScheme.onPrimary,
        onPressed: () => TaskQuickCreateSheet.show(context),
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          const TaskFilterBar(),
          Expanded(
            child: filteredAsync.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (error, _) => _ErrorView(
                onRetry: () =>
                    ref.read(taskListProvider.notifier).refresh(),
              ),
              data: (filteredTasks) {
                final completedTasks =
                    completedAsync.valueOrNull ?? <Task>[];

                // Empty state
                if (filteredTasks.isEmpty && completedTasks.isEmpty) {
                  return _EmptyState();
                }

                return RefreshIndicator(
                  onRefresh: () =>
                      ref.read(taskListProvider.notifier).refresh(),
                  child: _TaskListBody(
                    filteredTasks: filteredTasks,
                    completedTasks: completedTasks,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Internal widgets
// ---------------------------------------------------------------------------

class _TaskListBody extends ConsumerWidget {
  const _TaskListBody({
    required this.filteredTasks,
    required this.completedTasks,
  });

  final List<Task> filteredTasks;
  final List<Task> completedTasks;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Group tasks by date section
    final grouped = <String, List<Task>>{};
    for (final task in filteredTasks) {
      final section = getDateSection(task.deadline);
      (grouped[section] ??= []).add(task);
    }

    // Sort sections by dateSectionOrder
    final sortedSections = grouped.keys.toList()
      ..sort((a, b) =>
          dateSectionOrder.indexOf(a).compareTo(dateSectionOrder.indexOf(b)));

    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        // Date-grouped pending tasks
        for (final section in sortedSections) ...[
          SliverToBoxAdapter(
            child: DateSectionHeader(title: section),
          ),
          SliverList.builder(
            itemCount: grouped[section]!.length,
            itemBuilder: (context, index) {
              final task = grouped[section]![index];
              return Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 2,
                ),
                child: TaskCard(
                  task: task,
                  onTap: () => context.push('/tasks/${task.id}'),
                  onToggleComplete: (id) =>
                      ref.read(taskListProvider.notifier).toggleComplete(id),
                  onDelete: (id) {
                    ref.read(taskListProvider.notifier).deleteTask(id);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('Task deleted'),
                        action: SnackBarAction(
                          label: 'Undo',
                          onPressed: () =>
                              ref.read(taskListProvider.notifier).refresh(),
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ],

        // Completed section (collapsible)
        if (completedTasks.isNotEmpty)
          SliverToBoxAdapter(
            child: _CompletedSection(tasks: completedTasks),
          ),

        // Bottom padding so FAB doesn't overlap the last card
        const SliverPadding(padding: EdgeInsets.only(bottom: 80)),
      ],
    );
  }
}

/// Collapsible completed tasks section.
class _CompletedSection extends ConsumerWidget {
  const _CompletedSection({required this.tasks});

  final List<Task> tasks;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ExpansionTile(
      initiallyExpanded: false,
      title: Text(
        'Completed (${tasks.length})',
        style: context.textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.w600,
          color: context.colorScheme.onSurfaceVariant,
        ),
      ),
      children: tasks.map((task) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
          child: TaskCard(
            task: task,
            onTap: () => context.push('/tasks/${task.id}'),
            onToggleComplete: (id) =>
                ref.read(taskListProvider.notifier).toggleComplete(id),
            onDelete: (id) {
              ref.read(taskListProvider.notifier).deleteTask(id);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Task deleted'),
                  action: SnackBarAction(
                    label: 'Undo',
                    onPressed: () =>
                        ref.read(taskListProvider.notifier).refresh(),
                  ),
                ),
              );
            },
          ),
        );
      }).toList(),
    );
  }
}

/// Friendly empty state when no tasks exist.
class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.task_alt,
            size: 64,
            color:
                context.colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
          ),
          const SizedBox(height: 16),
          Text(
            'No tasks yet',
            style: context.textTheme.titleLarge?.copyWith(
              color: context.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap + to add your first task',
            style: context.textTheme.bodyMedium?.copyWith(
              color: context.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

/// Error view with retry button.
class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Failed to load tasks'),
          const SizedBox(height: 12),
          FilledButton.tonal(
            onPressed: onRetry,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}
