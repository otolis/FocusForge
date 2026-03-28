import 'package:flutter/material.dart';

import '../../domain/timeline_constants.dart';

/// A background color band indicating the energy zone for a time slot.
///
/// - [EnergyZone.peak]: warm amber tint (light) or low-opacity amber (dark).
/// - [EnergyZone.low]: muted sage tint (light) or low-opacity sage (dark).
/// - [EnergyZone.regular]: fully transparent (no decoration).
class EnergyZoneBand extends StatelessWidget {
  /// The energy zone classification for this band.
  final EnergyZone zone;

  /// The height in pixels for this band (typically one hour).
  final double height;

  const EnergyZoneBand({
    super.key,
    required this.zone,
    required this.height,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      height: height,
      color: _zoneColor(isDark),
    );
  }

  Color _zoneColor(bool isDark) {
    switch (zone) {
      case EnergyZone.peak:
        return isDark
            ? const Color(0xFFFF8F00).withValues(alpha:0.08)
            : const Color(0xFFFFF3E0).withValues(alpha:0.4);
      case EnergyZone.low:
        return isDark
            ? const Color(0xFF81C784).withValues(alpha:0.08)
            : const Color(0xFFE8F5E9).withValues(alpha:0.4);
      case EnergyZone.regular:
        return Colors.transparent;
    }
  }
}
