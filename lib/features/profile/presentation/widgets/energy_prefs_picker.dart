import 'package:flutter/material.dart';

import '../../../../core/utils/extensions.dart';
import '../../domain/profile_model.dart';

/// A picker widget for selecting peak and low energy hours.
///
/// Displays two horizontally scrollable rows of [FilterChip] widgets
/// for hours 6 AM through 10 PM. Peak hours use [primary] color when
/// selected; low hours use [tertiary] color. Validates that no hour
/// can be both peak and low simultaneously.
class EnergyPrefsPicker extends StatelessWidget {
  const EnergyPrefsPicker({
    super.key,
    required this.energyPattern,
    required this.onChanged,
  });

  /// The current energy pattern state.
  final EnergyPattern energyPattern;

  /// Called with the updated [EnergyPattern] whenever the user toggles a chip.
  final ValueChanged<EnergyPattern> onChanged;

  /// Formats an hour (0-23) as a 12-hour string like "6 AM" or "1 PM".
  String _formatHour(int hour) {
    if (hour == 0 || hour == 24) return '12 AM';
    if (hour == 12) return '12 PM';
    if (hour < 12) return '$hour AM';
    return '${hour - 12} PM';
  }

  void _togglePeakHour(int hour) {
    final peak = List<int>.from(energyPattern.peakHours);
    final low = List<int>.from(energyPattern.lowHours);

    if (peak.contains(hour)) {
      peak.remove(hour);
    } else {
      peak.add(hour);
      // Validation: remove from low if it was there
      low.remove(hour);
    }

    onChanged(energyPattern.copyWith(peakHours: peak, lowHours: low));
  }

  void _toggleLowHour(int hour) {
    final peak = List<int>.from(energyPattern.peakHours);
    final low = List<int>.from(energyPattern.lowHours);

    if (low.contains(hour)) {
      low.remove(hour);
    } else {
      low.add(hour);
      // Validation: remove from peak if it was there
      peak.remove(hour);
    }

    onChanged(energyPattern.copyWith(peakHours: peak, lowHours: low));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Peak Energy Hours
        Text(
          'Peak Energy Hours',
          style: context.textTheme.labelLarge?.copyWith(
            color: context.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: List.generate(17, (index) {
              final hour = index + 6; // 6 AM to 10 PM
              final isSelected = energyPattern.peakHours.contains(hour);
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  label: Text(_formatHour(hour)),
                  selected: isSelected,
                  onSelected: (_) => _togglePeakHour(hour),
                  selectedColor: context.colorScheme.primary,
                  labelStyle: TextStyle(
                    color: isSelected
                        ? context.colorScheme.onPrimary
                        : context.colorScheme.onSurface,
                  ),
                  checkmarkColor:
                      isSelected ? context.colorScheme.onPrimary : null,
                ),
              );
            }),
          ),
        ),
        const SizedBox(height: 16),
        // Low Energy Hours
        Text(
          'Low Energy Hours',
          style: context.textTheme.labelLarge?.copyWith(
            color: context.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: List.generate(17, (index) {
              final hour = index + 6; // 6 AM to 10 PM
              final isSelected = energyPattern.lowHours.contains(hour);
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  label: Text(_formatHour(hour)),
                  selected: isSelected,
                  onSelected: (_) => _toggleLowHour(hour),
                  selectedColor: context.colorScheme.tertiary,
                  labelStyle: TextStyle(
                    color: isSelected
                        ? context.colorScheme.onTertiary
                        : context.colorScheme.onSurface,
                  ),
                  checkmarkColor:
                      isSelected ? context.colorScheme.onTertiary : null,
                ),
              );
            }),
          ),
        ),
        const SizedBox(height: 12),
        // Helper text
        Text(
          'AI planner uses this to schedule your day optimally.',
          style: context.textTheme.labelLarge?.copyWith(
            color: context.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
