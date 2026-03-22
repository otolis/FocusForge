import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/utils/extensions.dart';
import '../../../../core/utils/priority_color.dart' as pc;
import '../../../../shared/widgets/app_button.dart';
import '../../domain/board_model.dart';
import '../providers/board_detail_provider.dart';

/// Shows a modal bottom sheet for viewing and editing a board card's
/// details, including title, description, priority, due date, and
/// assignee.
///
/// The sheet is scrollable via [DraggableScrollableSheet] and includes
/// save and delete actions that update the card via [boardDetailProvider].
void showCardDetailSheet(
  BuildContext context,
  WidgetRef ref,
  BoardCard card,
  String boardId,
) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (sheetContext) {
      return _CardDetailContent(
        card: card,
        boardId: boardId,
      );
    },
  );
}

class _CardDetailContent extends ConsumerStatefulWidget {
  const _CardDetailContent({
    required this.card,
    required this.boardId,
  });

  final BoardCard card;
  final String boardId;

  @override
  ConsumerState<_CardDetailContent> createState() => _CardDetailContentState();
}

class _CardDetailContentState extends ConsumerState<_CardDetailContent> {
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late int _priority;
  DateTime? _dueDate;
  bool _isSaving = false;

  /// Priority labels.
  static const _priorityLabels = ['P1', 'P2', 'P3', 'P4'];

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.card.title);
    _descriptionController =
        TextEditingController(text: widget.card.description ?? '');
    _priority = widget.card.priority;
    _dueDate = widget.card.dueDate;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  /// Resolves the assignee ID to a display name from the board's member list.
  String? _resolveAssigneeName() {
    final assigneeId = widget.card.assigneeId;
    if (assigneeId == null) return null;
    final state = ref.read(boardDetailProvider(widget.boardId));
    final member = state.members
        .where((m) => m.userId == assigneeId)
        .firstOrNull;
    return member?.displayName ?? 'Unknown member';
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) {
        return SingleChildScrollView(
          controller: scrollController,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Drag handle
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: context.colorScheme.onSurfaceVariant
                          .withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Title field
                TextFormField(
                  controller: _titleController,
                  style: context.textTheme.titleMedium,
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    hintText: 'Card title',
                  ),
                ),
                const SizedBox(height: 8),

                // Description field
                TextFormField(
                  controller: _descriptionController,
                  style: context.textTheme.bodyMedium,
                  maxLines: null,
                  minLines: 3,
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    hintText: 'Add description...',
                    hintStyle: context.textTheme.bodyMedium?.copyWith(
                      color: context.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Priority selector
                Text(
                  'Priority',
                  style: context.textTheme.labelMedium?.copyWith(
                    color: context.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: List.generate(_priorityLabels.length, (index) {
                    final label = _priorityLabels[index];
                    final priorityValue = index + 1;
                    final isSelected = _priority == priorityValue;
                    final color = pc.priorityColor(priorityValue, context.colorScheme);
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(label),
                        selected: isSelected,
                        selectedColor: color.withValues(alpha: 0.2),
                        labelStyle: TextStyle(
                          color: isSelected ? color : null,
                          fontWeight:
                              isSelected ? FontWeight.w600 : FontWeight.normal,
                        ),
                        side: isSelected
                            ? BorderSide(color: color)
                            : null,
                        onSelected: (_) {
                          setState(() => _priority = priorityValue);
                        },
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 16),

                // Due date
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    Icons.schedule,
                    color: context.colorScheme.onSurfaceVariant,
                  ),
                  title: Text(
                    _dueDate != null
                        ? DateFormat('MMMM d, y').format(_dueDate!)
                        : 'Set due date',
                    style: context.textTheme.bodyMedium?.copyWith(
                      color: _dueDate != null
                          ? null
                          : context.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  trailing: _dueDate != null
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 18),
                          onPressed: () => setState(() => _dueDate = null),
                        )
                      : null,
                  onTap: _pickDueDate,
                ),

                // Assignee
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    Icons.person_outline,
                    color: context.colorScheme.onSurfaceVariant,
                  ),
                  title: Text(
                    _resolveAssigneeName() ?? 'Assign member',
                    style: context.textTheme.bodyMedium?.copyWith(
                      color: widget.card.assigneeId != null
                          ? null
                          : context.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Save button
                SizedBox(
                  width: double.infinity,
                  child: AppButton(
                    onPressed: _isSaving ? null : _save,
                    label: 'Save',
                    isLoading: _isSaving,
                  ),
                ),
                const SizedBox(height: 8),

                // Delete button
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: _isSaving ? null : _delete,
                    style: TextButton.styleFrom(
                      foregroundColor: context.colorScheme.error,
                    ),
                    child: const Text('Delete card'),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _pickDueDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 3)),
    );
    if (picked != null) {
      setState(() => _dueDate = picked);
    }
  }

  Future<void> _save() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) return;

    setState(() => _isSaving = true);

    try {
      await ref
          .read(boardDetailProvider(widget.boardId).notifier)
          .updateCard(
            widget.card.id,
            title: title,
            description: _descriptionController.text.trim(),
            priority: _priority,
            dueDate: _dueDate,
          );
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not save card. Please try again.')),
        );
      }
    }
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Card'),
        content: const Text(
          'Are you sure you want to delete this card? This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(dialogContext).colorScheme.error,
              foregroundColor: Theme.of(dialogContext).colorScheme.onError,
            ),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await ref
            .read(boardDetailProvider(widget.boardId).notifier)
            .deleteCard(widget.card.id, widget.card.columnId);
        if (mounted) {
          Navigator.of(context).pop();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not delete card. Please try again.')),
          );
        }
      }
    }
  }
}
