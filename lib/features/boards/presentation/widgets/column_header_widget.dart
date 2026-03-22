import 'package:flutter/material.dart';

import '../../../../core/utils/extensions.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../domain/board_role.dart';

/// Header widget for a Kanban column in the board detail screen.
///
/// Displays the column name, a card count badge, and (for editors/owners)
/// a popup menu with rename, add card, and delete options.
class ColumnHeaderWidget extends StatelessWidget {
  const ColumnHeaderWidget({
    super.key,
    required this.columnName,
    required this.cardCount,
    required this.userRole,
    this.onRename,
    this.onDelete,
    this.onAddCard,
  });

  /// The display name of the column.
  final String columnName;

  /// Number of cards currently in this column.
  final int cardCount;

  /// The current user's role on this board, used to show/hide edit controls.
  final BoardRole userRole;

  /// Called with the new name when the user renames the column.
  final ValueChanged<String>? onRename;

  /// Called when the user confirms column deletion.
  final VoidCallback? onDelete;

  /// Called when the user selects "Add card" from the menu.
  final VoidCallback? onAddCard;

  bool get _canEdit =>
      userRole == BoardRole.owner || userRole == BoardRole.editor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              columnName,
              style: context.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: context.colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '$cardCount',
              style: context.textTheme.labelSmall?.copyWith(
                color: context.colorScheme.onPrimaryContainer,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (_canEdit) ...[
            const SizedBox(width: 4),
            PopupMenuButton<String>(
              icon: Icon(
                Icons.more_vert,
                size: 18,
                color: context.colorScheme.onSurfaceVariant,
              ),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              onSelected: (value) {
                switch (value) {
                  case 'rename':
                    _showRenameDialog(context);
                  case 'add_card':
                    onAddCard?.call();
                  case 'delete':
                    _showDeleteConfirmation(context);
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'rename',
                  child: Text('Rename'),
                ),
                const PopupMenuItem(
                  value: 'add_card',
                  child: Text('Add card'),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Text('Delete column'),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  void _showRenameDialog(BuildContext context) {
    final controller = TextEditingController(text: columnName);

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Rename Column'),
          content: AppTextField(
            label: 'Column name',
            controller: controller,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) {
              final newName = controller.text.trim();
              if (newName.isNotEmpty && newName != columnName) {
                onRename?.call(newName);
              }
              Navigator.of(dialogContext).pop();
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                final newName = controller.text.trim();
                if (newName.isNotEmpty && newName != columnName) {
                  onRename?.call(newName);
                }
                Navigator.of(dialogContext).pop();
              },
              child: const Text('Rename'),
            ),
          ],
        );
      },
    );
  }

  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Delete Column'),
          content: Text(
            'Delete "$columnName" and all its cards? This cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: Theme.of(dialogContext).colorScheme.error,
                foregroundColor: Theme.of(dialogContext).colorScheme.onError,
              ),
              onPressed: () {
                Navigator.of(dialogContext).pop();
                onDelete?.call();
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }
}
