import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/utils/extensions.dart';
import '../../domain/board_model.dart';

/// A card widget for the board list grid, displaying board name,
/// column count, and creation date.
///
/// Tapping navigates to the full-screen Kanban board detail view.
class BoardGridCard extends StatelessWidget {
  const BoardGridCard({
    super.key,
    required this.board,
    this.columnCount,
    this.memberCount,
  });

  /// The board to display.
  final Board board;

  /// Optional column count to display (e.g., "3 columns").
  final int? columnCount;

  /// Optional member count (reserved for future use).
  final int? memberCount;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      color: context.colorScheme.surfaceContainerLow,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => context.push('/boards/${board.id}'),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                board.name,
                style: context.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.view_column_rounded,
                    size: 16,
                    color: context.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${columnCount ?? 3} columns',
                    style: context.textTheme.bodySmall?.copyWith(
                      color: context.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Text(
                DateFormat('MMM d').format(board.createdAt),
                style: context.textTheme.bodySmall?.copyWith(
                  color: context.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
