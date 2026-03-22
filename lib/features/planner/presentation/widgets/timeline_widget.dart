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
/// 2. Faint 15-minute guide lines
/// 3. Hour markers with AM/PM labels
/// 4. Empty slots (dotted placeholders for unoccupied hours)
/// 5. Schedule block cards (proportionally sized by duration)
class TimelineWidget extends StatelessWidget {
  /// The generated schedule blocks to render on the timeline.
  final List<ScheduleBlock> blocks;

  /// The user's energy pattern for zone coloring.
  final EnergyPattern energyPattern;

  /// Called when the user taps an empty slot's "+" icon.
  final VoidCallback onEmptySlotTap;

  const TimelineWidget({
    super.key,
    required this.blocks,
    required this.energyPattern,
    required this.onEmptySlotTap,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const ClampingScrollPhysics(),
      child: SizedBox(
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

            // Layer 5: Schedule blocks
            ..._buildBlocks(),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildEnergyZones() {
    final zones = <Widget>[];
    for (var hour = TimelineConstants.startHour;
        hour < TimelineConstants.endHour;
        hour++) {
      final zone = TimelineConstants.getZone(hour, energyPattern);
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
    final lineColor = context.colorScheme.outlineVariant.withOpacity(0.15);

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
      final isOccupied = blocks.any(
        (b) => b.startMinute < hourEnd && b.endMinute > hourStart,
      );

      if (!isOccupied) {
        slots.add(
          Positioned(
            top: TimelineConstants.minuteToY(hourStart),
            left: 0,
            right: 0,
            child: EmptySlot(hour: hour, onTap: onEmptySlotTap),
          ),
        );
      }
    }
    return slots;
  }

  List<Widget> _buildBlocks() {
    return blocks
        .map(
          (block) => Positioned(
            top: block.topOffset,
            left: 0,
            right: 0,
            child: TimeBlockCard(block: block),
          ),
        )
        .toList();
  }
}
