import 'package:flutter/material.dart';

import '../../../../core/utils/extensions.dart';

/// Placeholder widget shown in empty Kanban columns, prompting the
/// user to add their first card.
///
/// Renders a subtle outlined container with an add icon and "Add card"
/// text. The entire widget is tappable via [onAddCard].
class EmptyColumnPlaceholder extends StatelessWidget {
  const EmptyColumnPlaceholder({
    super.key,
    required this.onAddCard,
  });

  /// Called when the user taps the placeholder to add a new card.
  final VoidCallback onAddCard;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onAddCard,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        height: 80,
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          border: Border.all(
            color: context.colorScheme.outlineVariant.withValues(alpha: 0.5),
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.add_rounded,
                color: context.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(height: 4),
              Text(
                'Add card',
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
