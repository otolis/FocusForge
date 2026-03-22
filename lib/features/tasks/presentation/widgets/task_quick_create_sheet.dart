import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/utils/extensions.dart';
import '../../domain/task_model.dart';
import '../providers/task_provider.dart';
import 'priority_badge.dart';
import '../../../smart_input/presentation/widgets/smart_input_field.dart';
import '../../../smart_input/domain/parsed_task_input.dart';
import '../../../smart_input/presentation/providers/smart_input_provider.dart';

/// A bottom sheet for quick task creation with title, priority, and deadline.
///
/// Supports keyboard avoidance via [isScrollControlled] and [viewInsets].
/// "More details" navigates to the full create form and closes this sheet.
class TaskQuickCreateSheet extends ConsumerStatefulWidget {
  const TaskQuickCreateSheet({super.key});

  /// Convenience method to show the quick-create sheet as a modal.
  static void show(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => const TaskQuickCreateSheet(),
    );
  }

  @override
  ConsumerState<TaskQuickCreateSheet> createState() =>
      _TaskQuickCreateSheetState();
}

class _TaskQuickCreateSheetState extends ConsumerState<TaskQuickCreateSheet> {
  final _titleController = TextEditingController();
  Priority _priority = Priority.p3;
  DateTime? _deadline;
  bool _titleError = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(smartInputInitProvider);
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  static const _priorityLabels = {
    Priority.p1: 'P1 Urgent',
    Priority.p2: 'P2 High',
    Priority.p3: 'P3 Normal',
    Priority.p4: 'P4 Low',
  };

  Future<void> _pickDeadline() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _deadline ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() => _deadline = picked);
    }
  }

  void _submit() {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      setState(() => _titleError = true);
      return;
    }

    final now = DateTime.now();
    final task = Task(
      id: const Uuid().v4(),
      userId: Supabase.instance.client.auth.currentUser!.id,
      title: title,
      priority: _priority,
      deadline: _deadline,
      createdAt: now,
      updatedAt: now,
    );

    ref.read(taskListProvider.notifier).addTask(task);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 8,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          Text(
            'Quick Add Task',
            style: context.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),

          // Title input with NLP smart parsing
          SmartInputField(
            controller: _titleController,
            hintText: 'e.g., "Buy groceries tomorrow high priority"',
            onParsed: (parsed) {
              if (!mounted) return;
              setState(() {
                if (_titleError) _titleError = false;
                if (parsed.suggestedPriority != null) {
                  _priority = switch (parsed.suggestedPriority!.toUpperCase()) {
                    'P1' => Priority.p1,
                    'P2' => Priority.p2,
                    'P3' => Priority.p3,
                    'P4' => Priority.p4,
                    _ => Priority.p3,
                  };
                }
                if (parsed.suggestedDeadline != null) {
                  _deadline = parsed.suggestedDeadline;
                }
              });
            },
          ),
          if (_titleError)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                'Title cannot be empty',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.error,
                  fontSize: 12,
                ),
              ),
            ),
          const SizedBox(height: 12),

          // Priority selector
          Wrap(
            spacing: 8,
            children: Priority.values.map((p) {
              final isSelected = _priority == p;
              return ChoiceChip(
                label: Text(_priorityLabels[p]!),
                selected: isSelected,
                onSelected: (selected) {
                  if (selected) setState(() => _priority = p);
                },
                selectedColor:
                    PriorityBadge.priorityColors[p]?.withValues(alpha: 0.25),
                checkmarkColor: PriorityBadge.priorityColors[p],
              );
            }).toList(),
          ),
          const SizedBox(height: 12),

          // Deadline picker
          Row(
            children: [
              ActionChip(
                avatar: const Icon(Icons.calendar_today, size: 16),
                label: Text(
                  _deadline != null
                      ? '${_deadline!.month}/${_deadline!.day}/${_deadline!.year}'
                      : 'Add deadline',
                ),
                onPressed: _pickDeadline,
              ),
              if (_deadline != null) ...[
                const SizedBox(width: 4),
                IconButton(
                  icon: const Icon(Icons.close, size: 18),
                  onPressed: () => setState(() => _deadline = null),
                  style: IconButton.styleFrom(
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 16),

          // Action row
          Row(
            children: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  context.push('/tasks/create');
                },
                child: const Text('More details'),
              ),
              const Spacer(),
              FilledButton(
                onPressed: _submit,
                child: const Text('Add'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
