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
import '../providers/task_provider.dart';
import '../providers/category_provider.dart';
import '../widgets/priority_badge.dart';
import '../widgets/recurrence_picker.dart';
import '../../../smart_input/presentation/widgets/smart_input_field.dart';
import '../../../smart_input/domain/parsed_task_input.dart';
import '../../../smart_input/presentation/providers/smart_input_provider.dart';
import '../../../../shared/widgets/ai_rewrite_button.dart';

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
  bool _isFetchingTask = false;
  String? _fetchError;

  bool get _isEditMode => widget.taskId != null;

  Task? _existingTask;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _descriptionController = TextEditingController();

    if (!_isEditMode) {
      // Initialize TFLite model for smart input in create mode.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(smartInputInitProvider);
      });
    }

    if (_isEditMode) {
      // Load existing task data after the first frame.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadExistingTask();
      });
    }
  }

  Future<void> _loadExistingTask() async {
    // Fast path: try the in-memory list first.
    final tasks = ref.read(taskListProvider).valueOrNull ?? [];
    final memTask = tasks.where((t) => t.id == widget.taskId).firstOrNull;
    if (memTask != null) {
      _populateForm(memTask);
      await _loadRecurrenceRule(memTask);
      return;
    }

    // Slow path: fetch from Supabase (deep-link / direct navigation).
    setState(() => _isFetchingTask = true);
    try {
      final task = await ref.read(taskRepositoryProvider).getTaskById(widget.taskId!);
      if (!mounted) return;
      if (task == null) {
        setState(() => _fetchError = 'Task not found');
      } else {
        _populateForm(task);
        await _loadRecurrenceRule(task);
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _fetchError = 'Could not load task. Please try again.');
    } finally {
      if (mounted) setState(() => _isFetchingTask = false);
    }
  }

  void _populateForm(Task task) {
    setState(() {
      _existingTask = task;
      _titleController.text = task.title;
      _descriptionController.text = task.description ?? '';
      _selectedPriority = task.priority;
      _selectedCategoryId = task.categoryId;
      _selectedDeadline = task.deadline;
    });
  }

  /// Loads the existing recurrence rule from Supabase and populates
  /// [_recurrenceConfig] so the [RecurrencePicker] shows the current pattern.
  Future<void> _loadRecurrenceRule(Task task) async {
    if (task.recurrenceRuleId == null) return;
    try {
      final ruleData = await Supabase.instance.client
          .from('recurrence_rules')
          .select()
          .eq('id', task.recurrenceRuleId!)
          .maybeSingle();
      if (ruleData != null && mounted) {
        final rule = RecurrenceRule.fromJson(ruleData);
        setState(() {
          _recurrenceConfig = RecurrenceConfig(
            type: rule.type,
            intervalDays: rule.intervalDays,
            daysOfWeek: rule.daysOfWeek,
            dayOfMonth: rule.dayOfMonth,
          );
        });
      }
    } catch (_) {
      // Non-critical: picker will default to None if rule fetch fails
    }
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

  /// Maps ParsedTaskInput priority string ('P1'-'P4') to [Priority] enum.
  Priority _mapSmartPriority(String priorityStr) {
    return switch (priorityStr.toUpperCase()) {
      'P1' => Priority.p1,
      'P2' => Priority.p2,
      'P3' => Priority.p3,
      'P4' => Priority.p4,
      _ => Priority.p3,
    };
  }

  /// Searches user categories for a match against the suggested category name.
  String? _matchCategoryByName(String suggestedName, List<Category> categories) {
    for (final cat in categories) {
      if (cat.name.toLowerCase() == suggestedName.toLowerCase()) return cat.id;
    }
    for (final cat in categories) {
      if (cat.name.toLowerCase().contains(suggestedName.toLowerCase()) ||
          suggestedName.toLowerCase().contains(cat.name.toLowerCase())) {
        return cat.id;
      }
    }
    return null;
  }

  /// Applies NLP-parsed results to form fields (priority, deadline, category).
  void _onSmartInputParsed(ParsedTaskInput parsed) {
    if (!mounted) return;
    setState(() {
      if (parsed.suggestedPriority != null) {
        _selectedPriority = _mapSmartPriority(parsed.suggestedPriority!);
      }
      if (parsed.suggestedDeadline != null) {
        _selectedDeadline = parsed.suggestedDeadline;
      }
      if (parsed.suggestedCategory != null) {
        final categories = ref.read(categoryListProvider).valueOrNull ?? [];
        final matchedId = _matchCategoryByName(
          parsed.suggestedCategory!.displayName,
          categories,
        );
        if (matchedId != null) _selectedCategoryId = matchedId;
      }
    });
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
              tooltip: 'Delete task',
              onPressed: _handleDelete,
            ),
        ],
      ),
      body: _isFetchingTask
          ? const Center(child: CircularProgressIndicator())
          : _fetchError != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.error_outline, size: 48, color: Theme.of(context).colorScheme.error),
                      const SizedBox(height: 16),
                      Text(_fetchError!, style: Theme.of(context).textTheme.bodyLarge),
                      const SizedBox(height: 16),
                      TextButton(
                        onPressed: () => context.pop(),
                        child: const Text('Go Back'),
                      ),
                    ],
                  ),
                )
              : Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title field -- SmartInputField in create mode, plain field in edit mode
              if (!_isEditMode) ...[
                Row(
                  children: [
                    Expanded(
                      child: SmartInputField(
                        controller: _titleController,
                        hintText: 'e.g., "Buy groceries tomorrow high priority"',
                        onParsed: _onSmartInputParsed,
                      ),
                    ),
                    const SizedBox(width: 4),
                    AiRewriteButton(controller: _titleController),
                  ],
                ),
              ] else ...[
                AppTextField(
                  label: 'Title',
                  controller: _titleController,
                  suffixIcon: AiRewriteButton(controller: _titleController),
                  validator: (v) =>
                      v?.isEmpty ?? true ? 'Title is required' : null,
                  textInputAction: TextInputAction.next,
                ),
              ],
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
                key: ValueKey('recurrence_${_recurrenceConfig?.type?.name ?? "none"}'),
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
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: Priority.values.map((priority) {
            final isSelected = _selectedPriority == priority;
            final color = PriorityBadge.colorFor(priority, context.colorScheme);
            final label = switch (priority) {
              Priority.p1 => 'P1 Urgent',
              Priority.p2 => 'P2 High',
              Priority.p3 => 'P3 Normal',
              Priority.p4 => 'P4 Low',
            };
            return ChoiceChip(
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
          error: (err, _) => const Text('Could not load categories.'),
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        ListTile(
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
        ),
        if (_recurrenceConfig != null && _selectedDeadline == null)
          Padding(
            padding: const EdgeInsets.only(left: 16, top: 4),
            child: Text(
              'Required for recurring tasks',
              style: TextStyle(
                color: Theme.of(context).colorScheme.error,
                fontSize: 12,
              ),
            ),
          ),
      ],
    );
  }

  Future<void> _handleSave() async {
    // Require deadline when recurrence is configured.
    if (_recurrenceConfig != null && _selectedDeadline == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('A deadline is required for recurring tasks.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

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
          const SnackBar(content: Text('Could not save task. Please try again.')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _createTask() async {
    final now = DateTime.now();
    final taskId = const Uuid().v4();
    final currentUser = Supabase.instance.client.auth.currentUser;
    if (currentUser == null) return;
    final userId = currentUser.id;

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
    if (_existingTask == null) return;
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
    if (_existingTask == null) return;
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

          // RECTASK-01: Upsert recurrence rule with current picker config
          if (_recurrenceConfig != null && parent.recurrenceRuleId != null) {
            await Supabase.instance.client
                .from('recurrence_rules')
                .update({
                  'type': _recurrenceConfig!.type.name,
                  'interval_days': _recurrenceConfig!.type == RecurrenceType.custom
                      ? _recurrenceConfig!.intervalDays
                      : null,
                  'days_of_week': _recurrenceConfig!.type == RecurrenceType.weekly
                      ? _recurrenceConfig!.daysOfWeek
                      : null,
                  'day_of_month': _recurrenceConfig!.type == RecurrenceType.monthly
                      ? _recurrenceConfig!.dayOfMonth
                      : null,
                })
                .eq('id', parent.recurrenceRuleId!);
          }

          // Delete incomplete future child instances so generate_recurring_instances
          // can re-insert them with the updated pattern. The SQL function has a
          // NOT EXISTS guard that would skip dates already occupied by old instances.
          await Supabase.instance.client
              .from('tasks')
              .delete()
              .eq('parent_task_id', parentId)
              .eq('is_completed', false)
              .gt('deadline', DateTime.now().toIso8601String());

          final repo = ref.read(taskRepositoryProvider);
          await repo.generateRecurringInstances(parentId);
        }
      }
      if (mounted) context.pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not save task. Please try again.')),
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
          const SnackBar(content: Text('Could not delete task. Please try again.')),
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
    if (_existingTask == null) return;
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
          const SnackBar(content: Text('Could not delete task. Please try again.')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}
