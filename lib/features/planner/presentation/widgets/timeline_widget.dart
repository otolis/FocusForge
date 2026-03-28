import 'package:flutter/material.dart';

import '../../../../core/utils/extensions.dart';
import '../../../profile/domain/profile_model.dart';
import '../../domain/schedule_block_model.dart';
import '../../domain/timeline_constants.dart';
import 'empty_slot.dart';
import 'energy_zone_band.dart';
import 'hour_marker.dart';
import 'time_block_card.dart';

/// Vertical scrollable timeline container for the daily planner.
///
/// Layers (back to front):
/// 1. Energy zone background bands (amber for peak, sage for low)
/// 2. Faint 15-minute guide lines (brighter during drag)
/// 3. Hour markers with AM/PM labels
/// 4. Empty slots (dotted placeholders for unoccupied hours)
/// 5. Draggable schedule block cards (proportionally sized by duration)
///
/// Supports drag-to-reschedule: blocks can be long-pressed and dragged
/// vertically to new time slots with 15-minute snap alignment.
class TimelineWidget extends StatefulWidget {
  /// The generated schedule blocks to render on the timeline.
  final List<ScheduleBlock> blocks;

  /// The user's energy pattern for zone coloring.
  final EnergyPattern energyPattern;

  /// Called when the user taps an empty slot's "+" icon.
  final VoidCallback onEmptySlotTap;

  /// Called when a block is dragged to a new time position.
  ///
  /// Parameters: item ID and the new start minute (snapped to 15-minute grid).
  final Function(String itemId, int newStartMinute) onBlockMoved;

  /// Called when the user taps a schedule block to navigate to its source.
  final Function(String itemId)? onBlockTap;

  /// Called when the user taps a block's completion checkmark.
  final Function(String itemId)? onBlockComplete;

  const TimelineWidget({
    super.key,
    required this.blocks,
    required this.energyPattern,
    required this.onEmptySlotTap,
    required this.onBlockMoved,
    this.onBlockTap,
    this.onBlockComplete,
  });

  @override
  State<TimelineWidget> createState() => _TimelineWidgetState();
}

class _TimelineWidgetState extends State<TimelineWidget> {
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _timelineKey = GlobalKey();

  /// Whether a drag operation is currently active over the timeline.
  bool _isDragActive = false;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DragTarget<ScheduleBlock>(
      onWillAcceptWithDetails: (details) {
        setState(() => _isDragActive = true);
        return true;
      },
      onLeave: (_) {
        setState(() => _isDragActive = false);
      },
      onAcceptWithDetails: (details) {
        setState(() => _isDragActive = false);
        final RenderBox renderBox =
            _timelineKey.currentContext!.findRenderObject() as RenderBox;
        final localOffset = renderBox.globalToLocal(details.offset);
        final scrollOffset = _scrollController.offset;
        final adjustedY = localOffset.dy + scrollOffset;
        final snappedMinute = TimelineConstants.yToSnappedMinute(adjustedY);
        final clampedMinute = snappedMinute.clamp(
          TimelineConstants.startHour * 60,
          TimelineConstants.endHour * 60 - details.data.durationMinutes,
        );
        widget.onBlockMoved(details.data.itemId, clampedMinute);
      },
      builder: (context, candidateData, rejectedData) {
        return SingleChildScrollView(
          controller: _scrollController,
          physics: const ClampingScrollPhysics(),
          child: SizedBox(
            key: _timelineKey,
            height: TimelineConstants.totalHeight,
            child: Stack(
              children: [
                // Layer 1: Energy zone bands
                ..._buildEnergyZones(),

                // Layer 2: 15-minute guide lines
                ..._buildGuideLines(context),

                // Layer 3: Hour markers
                ..._buildHourMarkers(),

                // Layer 4: Empty slots (only for unoccupied hours)
                ..._buildEmptySlots(),

                // Layer 5: Draggable schedule blocks
                ..._buildBlocks(),
              ],
            ),
          ),
        );
      },
    );
  }

  List<Widget> _buildEnergyZones() {
    final zones = <Widget>[];
    for (var hour = TimelineConstants.startHour;
        hour < TimelineConstants.endHour;
        hour++) {
      final zone = TimelineConstants.getZone(hour, widget.energyPattern);
      zones.add(
        Positioned(
          top: TimelineConstants.minuteToY(hour * 60),
          left: 0,
          right: 0,
          height: TimelineConstants.hourHeight,
          child: EnergyZoneBand(
            zone: zone,
            height: TimelineConstants.hourHeight,
          ),
        ),
      );
    }
    return zones;
  }

  List<Widget> _buildGuideLines(BuildContext context) {
    final lines = <Widget>[];
    final guideOpacity = _isDragActive ? 0.4 : 0.15;
    final lineColor =
        context.colorScheme.outlineVariant.withValues(alpha:guideOpacity);

    for (var hour = TimelineConstants.startHour;
        hour < TimelineConstants.endHour;
        hour++) {
      for (final quarterOffset in [15, 30, 45]) {
        final minute = hour * 60 + quarterOffset;
        lines.add(
          Positioned(
            top: TimelineConstants.minuteToY(minute),
            left: 56,
            right: 0,
            child: Container(height: 0.5, color: lineColor),
          ),
        );
      }
    }
    return lines;
  }

  List<Widget> _buildHourMarkers() {
    final markers = <Widget>[];
    for (var hour = TimelineConstants.startHour;
        hour <= TimelineConstants.endHour;
        hour++) {
      markers.add(
        Positioned(
          top: TimelineConstants.minuteToY(hour * 60),
          left: 0,
          right: 0,
          child: HourMarker(hour: hour),
        ),
      );
    }
    return markers;
  }

  List<Widget> _buildEmptySlots() {
    final slots = <Widget>[];
    for (var hour = TimelineConstants.startHour;
        hour < TimelineConstants.endHour;
        hour++) {
      final hourStart = hour * 60;
      final hourEnd = (hour + 1) * 60;

      // Check if any block overlaps this hour
      final isOccupied = widget.blocks.any(
        (b) => b.startMinute < hourEnd && b.endMinute > hourStart,
      );

      if (!isOccupied) {
        slots.add(
          Positioned(
            top: TimelineConstants.minuteToY(hourStart),
            left: 0,
            right: 0,
            child: EmptySlot(hour: hour, onTap: widget.onEmptySlotTap),
          ),
        );
      }
    }
    return slots;
  }

  List<Widget> _buildBlocks() {
    return widget.blocks
        .map(
          (block) => Positioned(
            top: block.topOffset,
            left: 0,
            right: 0,
            child: LayoutBuilder(
              builder: (context, constraints) {
                return DraggableTimeBlockCard(
                  block: block,
                  cardWidth: constraints.maxWidth - 64,
                  onTap: widget.onBlockTap != null
                      ? () => widget.onBlockTap!(block.itemId)
                      : null,
                  onComplete: widget.onBlockComplete != null
                      ? () => widget.onBlockComplete!(block.itemId)
                      : null,
                );
              },
            ),
          ),
        )
        .toList();
  }
}
