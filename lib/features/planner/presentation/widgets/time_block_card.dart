import 'package:flutter/material.dart';

import '../../../../core/utils/extensions.dart';
import '../../domain/plannable_item_model.dart';
import '../../domain/schedule_block_model.dart';

/// Renders a single scheduled time block on the timeline.
///
/// Proportionally sized based on [block.height] (duration * pixelsPerMinute).
/// Background color reflects the block's [EnergyLevel]:
/// - high -> primaryContainer
/// - medium -> secondaryContainer
/// - low -> tertiaryContainer
///
/// Supports [isDragging] (elevated shadow) and [isGhost] (translucent dashed
/// outline) visual states for drag-and-drop interactions.
class TimeBlockCard extends StatelessWidget {
  final ScheduleBlock block;
  final bool isDragging;
  final bool isGhost;

  const TimeBlockCard({
    super.key,
    required this.block,
    this.isDragging = false,
    this.isGhost = false,
  });

  @override
  Widget build(BuildContext context) {
    final cardColor = _colorForEnergy(context, block.energyLevel);

    if (isGhost) {
      return Opacity(
        opacity: 0.3,
        child: Container(
          width: double.infinity,
          height: block.height,
          margin: const EdgeInsets.only(left: 56, right: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: context.colorScheme.outline,
              width: 1,
            ),
          ),
        ),
      );
    }

    return Container(
      width: double.infinity,
      height: block.height,
      margin: const EdgeInsets.only(left: 56, right: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: cardColor,
        boxShadow: isDragging
            ? [
                BoxShadow(
                  color: context.colorScheme.shadow.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              block.title,
              style: context.textTheme.bodyMedium,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (block.height > 40) ...[
              const SizedBox(height: 2),
              Text(
                '${_formatMinute(block.startMinute)} - ${_formatMinute(block.endMinute)}',
                style: context.textTheme.labelSmall?.copyWith(
                  color: context.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
            if (block.height > 60) ...[
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                  color: context.colorScheme.surface.withOpacity(0.6),
                ),
                child: Text(
                  '${block.durationMinutes} min',
                  style: context.textTheme.labelSmall,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Returns the background color for the given energy level.
  Color _colorForEnergy(BuildContext context, EnergyLevel level) {
    switch (level) {
      case EnergyLevel.high:
        return context.colorScheme.primaryContainer;
      case EnergyLevel.medium:
        return context.colorScheme.secondaryContainer;
      case EnergyLevel.low:
        return context.colorScheme.tertiaryContainer;
    }
  }

  /// Formats a minute-from-midnight value into "H:MM AM/PM".
  String _formatMinute(int minute) {
    final h = minute ~/ 60;
    final m = minute % 60;
    final period = h >= 12 ? 'PM' : 'AM';
    final displayH = h > 12 ? h - 12 : (h == 0 ? 12 : h);
    return '$displayH:${m.toString().padLeft(2, '0')} $period';
  }
}

/// Wraps [TimeBlockCard] in a [LongPressDraggable] for drag-to-reschedule.
///
/// Long-press initiates a vertical-axis drag. The feedback widget shows the
/// card with Material elevation 8 shadow. The original position displays a
/// translucent ghost outline via [TimeBlockCard.isGhost].
class DraggableTimeBlockCard extends StatelessWidget {
  const DraggableTimeBlockCard({
    super.key,
    required this.block,
    required this.cardWidth,
  });

  /// The schedule block data for this card.
  final ScheduleBlock block;

  /// The width to use for the drag feedback widget.
  final double cardWidth;

  @override
  Widget build(BuildContext context) {
    return LongPressDraggable<ScheduleBlock>(
      axis: Axis.vertical,
      data: block,
      feedback: Material(
        elevation: 8,
        borderRadius: BorderRadius.circular(12),
        shadowColor: context.colorScheme.shadow.withOpacity(0.3),
        child: SizedBox(
          width: cardWidth,
          height: block.height,
          child: TimeBlockCard(block: block, isDragging: true),
        ),
      ),
      childWhenDragging: Opacity(
        opacity: 0.3,
        child: TimeBlockCard(block: block, isGhost: true),
      ),
      child: TimeBlockCard(block: block),
    );
  }
}
