import 'package:flutter/material.dart';

import '../../../../core/utils/extensions.dart';
import '../../domain/timeline_constants.dart';

/// Displays an hour label on the left axis of the timeline.
///
/// Shows the hour in 12-hour AM/PM format with a thin divider line
/// extending to the right edge.
class HourMarker extends StatelessWidget {
  /// The hour in 24-hour format (0-23).
  final int hour;

  const HourMarker({super.key, required this.hour});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: TimelineConstants.hourHeight,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 48,
            child: Padding(
              padding: const EdgeInsets.only(top: 0, right: 4),
              child: Text(
                _formatHour(hour),
                textAlign: TextAlign.right,
                style: context.textTheme.labelSmall?.copyWith(
                  color: context.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
          Expanded(
            child: Divider(
              height: 1,
              thickness: 0.5,
              color: context.colorScheme.outlineVariant.withValues(alpha:0.3),
            ),
          ),
        ],
      ),
    );
  }

  /// Formats a 24-hour value into a 12-hour AM/PM string.
  String _formatHour(int h) {
    if (h == 0) return '12 AM';
    if (h < 12) return '$h AM';
    if (h == 12) return '12 PM';
    return '${h - 12} PM';
  }
}
