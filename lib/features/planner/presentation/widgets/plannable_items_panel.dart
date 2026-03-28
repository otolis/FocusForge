import 'package:flutter/material.dart';

import '../../../../core/utils/extensions.dart';
import '../../domain/plannable_item_model.dart';

/// Displays the user's plannable items as dismissible cards in a
/// collapsible panel above the timeline.
///
/// Each card shows the item title, duration chip, and energy level icon.
/// Items can be dismissed (deleted) with a left swipe. The panel header
/// shows the count and collapses/expands on tap.
class PlannableItemsPanel extends StatefulWidget {
  /// The list of plannable items to display.
  final List<PlannableItem> items;

  /// Called when the user dismisses (deletes) an item.
  final ValueChanged<String> onDelete;

  /// Called when the user taps "Add Item".
  final VoidCallback onAddItem;

  const PlannableItemsPanel({
    super.key,
    required this.items,
    required this.onDelete,
    required this.onAddItem,
  });

  @override
  State<PlannableItemsPanel> createState() => _PlannableItemsPanelState();
}

class _PlannableItemsPanelState extends State<PlannableItemsPanel> {
  bool _isExpanded = true;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Header row: count + expand/collapse toggle + add button
        InkWell(
          onTap: () => setState(() => _isExpanded = !_isExpanded),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Icon(
                  Icons.checklist_rounded,
                  size: 18,
                  color: context.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  '${widget.items.length} item${widget.items.length == 1 ? '' : 's'} to schedule',
                  style: context.textTheme.titleSmall?.copyWith(
                    color: context.colorScheme.onSurface,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.add_rounded, size: 20),
                  tooltip: 'Add item',
                  onPressed: widget.onAddItem,
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 32,
                    minHeight: 32,
                  ),
                ),
                Icon(
                  _isExpanded
                      ? Icons.expand_less_rounded
                      : Icons.expand_more_rounded,
                  size: 20,
                  color: context.colorScheme.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),

        // Expandable items list
        AnimatedCrossFade(
          firstChild: _buildItemsList(context),
          secondChild: const SizedBox.shrink(),
          crossFadeState: _isExpanded
              ? CrossFadeState.showFirst
              : CrossFadeState.showSecond,
          duration: const Duration(milliseconds: 200),
        ),

        // Divider
        Divider(
          height: 1,
          color: context.colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ],
    );
  }

  Widget _buildItemsList(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, right: 16, bottom: 8),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: widget.items.map((item) {
          return _PlannableItemCard(
            item: item,
            onDelete: () => widget.onDelete(item.id),
          );
        }).toList(),
      ),
    );
  }
}

/// A compact card representing a single plannable item.
///
/// Shows the item title, a duration badge, and an energy level indicator.
/// Can be dismissed with a swipe to delete.
class _PlannableItemCard extends StatelessWidget {
  final PlannableItem item;
  final VoidCallback onDelete;

  const _PlannableItemCard({
    required this.item,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final energyColor = _energyColor(context, item.energyLevel);

    return Dismissible(
      key: ValueKey(item.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDelete(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: context.colorScheme.error.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          Icons.delete_outline_rounded,
          color: context.colorScheme.error,
          size: 18,
        ),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: energyColor.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: energyColor.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Energy level indicator dot
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: energyColor,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),

            // Title (constrained width for wrapping in Wrap layout)
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 160),
              child: Text(
                item.title,
                style: context.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),

            // Duration badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: context.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                _formatDuration(item.durationMinutes),
                style: context.textTheme.labelSmall?.copyWith(
                  color: context.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _energyColor(BuildContext context, EnergyLevel level) {
    return switch (level) {
      EnergyLevel.high => Colors.deepOrange,
      EnergyLevel.medium => Colors.amber.shade700,
      EnergyLevel.low => Colors.teal,
    };
  }

  String _formatDuration(int minutes) {
    if (minutes < 60) return '${minutes}m';
    final h = minutes ~/ 60;
    final m = minutes % 60;
    return m == 0 ? '${h}h' : '${h}h${m}m';
  }
}
