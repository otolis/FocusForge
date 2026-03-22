import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/utils/extensions.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../domain/task_model.dart';
import '../../domain/category_model.dart';
import '../../domain/recurrence_model.dart';
import '../../data/task_repository.dart';
import '../providers/task_provider.dart';
import '../providers/category_provider.dart';
import '../widgets/priority_badge.dart';
import '../widgets/recurrence_picker.dart';

/// Full-screen form for creating and editing tasks.
///
/// When [taskId] is null, operates in create mode.
/// When [taskId] is provided, operates in edit mode with pre-filled fields.
class TaskFormScreen extends ConsumerStatefulWidget {
  const TaskFormScreen({super.key, this.taskId});

  /// The ID of the task to edit, or null for create mode.
  final String? taskId;

  @override
  ConsumerState<TaskFormScreen> createState() => _TaskFormScreenState();
}

class _TaskFormScreenState extends ConsumerState<TaskFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  Priority _selectedPriority = Priority.p3;
  String? _selectedCategoryId;
  DateTime? _selectedDeadline;
  RecurrenceConfig? _recurrenceConfig;
  bool _isLoading = false;

  bool get _isEditMode => widget.taskId != null;

  Task? _existingTask;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _descriptionController = TextEditingController();

    if (_isEditMode) {
      // Load existing task data after the first frame.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadExistingTask();
      });
    }
  }

  void _loadExistingTask() {
    final tasks = ref.read(taskListProvider).valueOrNull ?? [];
    final task = tasks.where((t) => t.id == widget.taskId).firstOrNull;
    if (task == null) return;

    setState(() {
      _existingTask = task;
      _titleController.text = task.title;
      _descriptionController.text = task.description ?? '';
      _selectedPriority = task.priority;
      _selectedCategoryId = task.categoryId;
      _selectedDeadline = task.deadline;
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  bool get _isRecurringTask {
    if (_existingTask == null) return false;
    return _existingTask!.recurrenceRuleId != null ||
        _existingTask!.parentTaskId != null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditMode ? 'Edit Task' : 'New Task'),
        actions: [
          if (_isEditMode)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: _handleDelete,
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title field
              AppTextField(
                label: 'Title',
                controller: _titleController,
                validator: (v) =>
                    v?.isEmpty ?? true ? 'Title is required' : null,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 16),

              // Description field
              AppTextField(
                label: 'Description',
                controller: _descriptionController,
                maxLines: 4,
                textInputAction: TextInputAction.newline,
              ),
              const SizedBox(height: 16),

              // Priority selector
              _buildPrioritySelector(),
              const SizedBox(height: 16),

              // Category selector
              _buildCategorySelector(),
              const SizedBox(height: 16),

              // Deadline picker
              _buildDeadlinePicker(),
              const SizedBox(height: 16),

              // Recurrence picker
              RecurrencePicker(
                initialType: _recurrenceConfig?.type,
                initialIntervalDays: _recurrenceConfig?.intervalDays,
                initialDaysOfWeek: _recurrenceConfig?.daysOfWeek,
                initialDayOfMonth: _recurrenceConfig?.dayOfMonth,
                onChanged: (config) {
                  setState(() => _recurrenceConfig = config);
                },
              ),
              const SizedBox(height: 24),

              // Save button
              SizedBox(
                width: double.infinity,
                child: AppButton(
                  label: _isEditMode ? 'Save Changes' : 'Create Task',
                  isLoading: _isLoading,
                  onPressed: _isLoading ? null : _handleSave,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPrioritySelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Priority', style: context.textTheme.titleSmall),
        const SizedBox(height: 8),
        Row(
          children: Priority.values.map((priority) {
            final isSelected = _selectedPriority == priority;
            final color = PriorityBadge.priorityColors[priority]!;
            final label = switch (priority) {
              Priority.p1 => 'P1 Urgent',
              Priority.p2 => 'P2 High',
              Priority.p3 => 'P3 Normal',
              Priority.p4 => 'P4 Low',
            };
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(label),
                selected: isSelected,
                selectedColor: color.withValues(alpha: 0.25),
                avatar: isSelected
                    ? Icon(Icons.check, size: 18, color: color)
                    : null,
                onSelected: (selected) {
                  if (selected) {
                    setState(() => _selectedPriority = priority);
                  }
                },
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildCategorySelector() {
    final categoriesAsync = ref.watch(categoryListProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Category', style: context.textTheme.titleSmall),
        const SizedBox(height: 8),
        categoriesAsync.when(
          loading: () =>
              const Center(child: CircularProgressIndicator()),
          error: (err, _) => Text('Error loading categories: $err'),
          data: (categories) => Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ...categories.map((cat) {
                final isSelected = _selectedCategoryId == cat.id;
                return ChoiceChip(
                  label: Text(cat.name),
                  selected: isSelected,
                  avatar: CircleAvatar(
                    backgroundColor: cat.color,
                    radius: 10,
                  ),
                  onSelected: (selected) {
                    setState(() {
                      // Allow deselect by tapping the already-selected chip.
                      _selectedCategoryId = selected ? cat.id : null;
                    });
                  },
                );
              }),
              ActionChip(
                avatar: const Icon(Icons.settings, size: 18),
                label: const Text('Manage categories'),
                onPressed: () => context.push('/tasks/categories'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDeadlinePicker() {
    final formatted = _selectedDeadline != null
        ? '${_selectedDeadline!.day}/${_selectedDeadline!.month}/${_selectedDeadline!.year}'
        : 'No deadline';

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.calendar_today),
      title: Text(formatted),
      trailing: _selectedDeadline != null
          ? IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () {
                setState(() => _selectedDeadline = null);
              },
            )
          : null,
      onTap: () async {
        final now = DateTime.now();
        final picked = await showDatePicker(
          context: context,
          initialDate: _selectedDeadline ?? now,
          firstDate: now,
          lastDate: now.add(const Duration(days: 365)),
        );
        if (picked != null) {
          setState(() => _selectedDeadline = picked);
        }
      },
    );
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    // Recurring task edit dialog.
    if (_isEditMode && _isRecurringTask) {
      final result = await _showRecurringEditDialog();
      if (result == null) return; // cancelled
      await _saveRecurringTask(result);
      return;
    }

    setState(() => _isLoading = true);
    try {
      if (_isEditMode) {
        await _updateTask();
      } else {
        await _createTask();
      }
      if (mounted) context.pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _createTask() async {
    final now = DateTime.now();
    final taskId = const Uuid().v4();
    final userId = Supabase.instance.client.auth.currentUser!.id;

    final task = Task(
      id: taskId,
      userId: userId,
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim().isEmpty
          ? null
          : _descriptionController.text.trim(),
      priority: _selectedPriority,
      categoryId: _selectedCategoryId,
      deadline: _selectedDeadline,
      createdAt: now,
      updatedAt: now,
    );

    await ref.read(taskListProvider.notifier).addTask(task);

    // If recurrence configured, create recurrence rule and generate instances.
    if (_recurrenceConfig != null) {
      final ruleId = const Uuid().v4();
      final rule = RecurrenceRule(
        id: ruleId,
        taskId: taskId,
        type: _recurrenceConfig!.type,
        intervalDays: _recurrenceConfig!.intervalDays,
        daysOfWeek: _recurrenceConfig!.daysOfWeek,
        dayOfMonth: _recurrenceConfig!.dayOfMonth,
        createdAt: now,
      );

      // Insert recurrence rule via Supabase.
      await Supabase.instance.client
          .from('recurrence_rules')
          .insert(rule.toJson());

      // Update the task to reference the rule.
      final updatedTask = task.copyWith(recurrenceRuleId: ruleId);
      await ref.read(taskListProvider.notifier).updateTask(updatedTask);

      // Generate recurring instances.
      final repo = ref.read(taskRepositoryProvider);
      await repo.generateRecurringInstances(taskId);
    }
  }

  Future<void> _updateTask() async {
    final task = _existingTask!.copyWith(
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim().isEmpty
          ? null
          : _descriptionController.text.trim(),
      priority: _selectedPriority,
      categoryId: _selectedCategoryId,
      clearCategory: _selectedCategoryId == null,
      deadline: _selectedDeadline,
      clearDeadline: _selectedDeadline == null,
    );
    await ref.read(taskListProvider.notifier).updateTask(task);
  }

  Future<String?> _showRecurringEditDialog() async {
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Apply changes to:'),
        content: const Text(
          'This task is part of a recurring series.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(null),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop('this'),
            child: const Text('This instance only'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop('all'),
            child: const Text('All future instances'),
          ),
        ],
      ),
    );
  }

  Future<void> _saveRecurringTask(String scope) async {
    setState(() => _isLoading = true);
    try {
      if (scope == 'this') {
        // Update only this instance.
        await _updateTask();
      } else if (scope == 'all') {
        // Update the parent task template and regenerate instances.
        final parentId =
            _existingTask!.parentTaskId ?? _existingTask!.id;
        final tasks = ref.read(taskListProvider).valueOrNull ?? [];
        final parent =
            tasks.where((t) => t.id == parentId).firstOrNull;
        if (parent != null) {
          final updatedParent = parent.copyWith(
            title: _titleController.text.trim(),
            description: _descriptionController.text.trim().isEmpty
                ? null
                : _descriptionController.text.trim(),
            priority: _selectedPriority,
            categoryId: _selectedCategoryId,
            clearCategory: _selectedCategoryId == null,
            deadline: _selectedDeadline,
            clearDeadline: _selectedDeadline == null,
          );
          await ref
              .read(taskListProvider.notifier)
              .updateTask(updatedParent);
          final repo = ref.read(taskRepositoryProvider);
          await repo.generateRecurringInstances(parentId);
        }
      }
      if (mounted) context.pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleDelete() async {
    if (_isRecurringTask) {
      final result = await _showRecurringDeleteDialog();
      if (result == null) return;
      await _deleteRecurringTask(result);
      return;
    }

    final confirmed = await _showDeleteConfirmation();
    if (confirmed != true) return;

    setState(() => _isLoading = true);
    try {
      await ref
          .read(taskListProvider.notifier)
          .deleteTask(widget.taskId!);
      if (mounted) context.pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<bool?> _showDeleteConfirmation() {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete task?'),
        content: const Text('This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(
              'Delete',
              style: TextStyle(color: context.colorScheme.error),
            ),
          ),
        ],
      ),
    );
  }

  Future<String?> _showRecurringDeleteDialog() {
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete recurring task?'),
        content: const Text(
          'This task is part of a recurring series.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(null),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop('this'),
            child: const Text('This instance only'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop('series'),
            child: Text(
              'Entire series',
              style: TextStyle(color: context.colorScheme.error),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteRecurringTask(String scope) async {
    setState(() => _isLoading = true);
    try {
      if (scope == 'this') {
        // Delete only this instance.
        await ref
            .read(taskListProvider.notifier)
            .deleteTask(widget.taskId!);
      } else if (scope == 'series') {
        // Delete the parent task — FK cascade deletes all instances.
        final parentId =
            _existingTask!.parentTaskId ?? _existingTask!.id;
        await ref
            .read(taskListProvider.notifier)
            .deleteTask(parentId);
      }
      if (mounted) context.pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}
