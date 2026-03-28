import 'package:flutter/material.dart';

import '../../../../core/utils/extensions.dart';
import '../../domain/timeline_constants.dart';

/// A dotted placeholder slot in the timeline with a "+" button.
///
/// Shown for empty hours that have no scheduled block. Tapping the slot
/// triggers [onTap] to open the add-item bottom sheet.
class EmptySlot extends StatelessWidget {
  /// The hour this slot represents (24-hour format).
  final int hour;

  /// Called when the user taps the "+" icon.
  final VoidCallback onTap;

  const EmptySlot({
    super.key,
    required this.hour,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: TimelineConstants.hourHeight,
        margin: const EdgeInsets.only(left: 56, right: 8),
        decoration: BoxDecoration(
          border: Border.all(
            color: context.colorScheme.outlineVariant.withValues(alpha:0.3),
            width: 1,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Icon(
            Icons.add_rounded,
            size: 20,
            color: context.colorScheme.onSurfaceVariant.withValues(alpha:0.4),
          ),
        ),
      ),
    );
  }
}
