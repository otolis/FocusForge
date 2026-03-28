import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/utils/extensions.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../providers/board_list_provider.dart';
import '../widgets/board_grid_card.dart';

/// Converts a raw error into a user-readable message.
///
/// For [PostgrestException]s the Supabase error code / message is surfaced so
/// the developer (or savvy user) can tell what went wrong. Network and
/// socket errors get a generic connectivity hint.
String _userFriendlyError(Object error) {
  if (error is PostgrestException) {
    final code = error.code ?? '';
    final msg = error.message;
    // Table / function missing => migration not applied
    if (code == '42P01' || code == '42883' || msg.contains('does not exist')) {
      return 'The boards database tables have not been created yet.\n\n'
          'Run migration 00003_create_boards.sql in your Supabase SQL editor.';
    }
    return 'Database error ($code): $msg';
  }
  final s = error.toString().toLowerCase();
  if (s.contains('socket') || s.contains('network') || s.contains('timeout')) {
    return 'Could not reach the server. Check your connection and try again.';
  }
  // In debug builds show the raw error; in release keep it terse.
  if (kDebugMode) {
    return 'Unexpected error:\n$error';
  }
  return 'Something went wrong. Please try again.';
}

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
        error: (error, stack) {
          debugPrint('[BoardListScreen] Error loading boards: $error');
          debugPrint('[BoardListScreen] Stack: $stack');
          // Show actual error context so the user can act on it.
          final message = _userFriendlyError(error);
          return Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 48,
                    color: context.colorScheme.error,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    message,
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
          );
        },
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
        tooltip: 'Create board',
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
      debugPrint('[BoardListScreen] Create board failed: $e');
      if (parentContext.mounted) {
        ScaffoldMessenger.of(parentContext).showSnackBar(
          SnackBar(content: Text(_userFriendlyError(e))),
        );
      }
    }
  }
}
