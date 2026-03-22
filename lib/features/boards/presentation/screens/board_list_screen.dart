import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/utils/extensions.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../domain/board_model.dart';
import '../providers/board_list_provider.dart';
import '../widgets/board_grid_card.dart';

/// Displays the user's boards in a 2-column card grid with a FAB to
/// create new boards.
///
/// Watches [boardListProvider] for the board list and handles loading,
/// error, and empty states. Creating a board navigates to its Kanban view.
class BoardListScreen extends ConsumerWidget {
  const BoardListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final boardsAsync = ref.watch(boardListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Boards'),
      ),
      body: boardsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                error.toString(),
                style: context.textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () => ref.invalidate(boardListProvider),
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (boards) {
          if (boards.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.dashboard_outlined,
                    size: 64,
                    color: context.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No boards yet',
                    style: context.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Create your first board',
                    style: context.textTheme.bodyMedium?.copyWith(
                      color: context.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            );
          }

          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.1,
            ),
            itemCount: boards.length,
            itemBuilder: (context, index) {
              return BoardGridCard(board: boards[index]);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreateBoardDialog(context, ref),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showCreateBoardDialog(BuildContext context, WidgetRef ref) {
    final nameController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('New Board'),
          content: AppTextField(
            label: 'Board name',
            controller: nameController,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) {
              _createBoard(dialogContext, context, ref, nameController);
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                _createBoard(dialogContext, context, ref, nameController);
              },
              child: const Text('Create'),
            ),
          ],
        );
      },
    );
  }

  void _createBoard(
    BuildContext dialogContext,
    BuildContext parentContext,
    WidgetRef ref,
    TextEditingController nameController,
  ) async {
    final name = nameController.text.trim();
    if (name.isEmpty) return;

    Navigator.of(dialogContext).pop();

    try {
      final boardId = await ref
          .read(boardListProvider.notifier)
          .createBoard(name);
      if (parentContext.mounted) {
        parentContext.push('/boards/$boardId');
      }
    } catch (e) {
      if (parentContext.mounted) {
        ScaffoldMessenger.of(parentContext).showSnackBar(
          SnackBar(content: Text('Failed to create board: $e')),
        );
      }
    }
  }
}
