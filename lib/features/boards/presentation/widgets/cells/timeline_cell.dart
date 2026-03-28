import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../../core/utils/contrast_color.dart';

/// A cell displaying a colored timeline bar with date range labels.
///
/// When both [startDate] and [endDate] are set, renders a colored bar
/// (at 70% opacity) with centered "d/M - d/M" date range text.
/// When either date is null, shows a "Set dates" placeholder.
class TimelineCell extends StatelessWidget {
  /// Start date of the timeline range.
  final DateTime? startDate;

  /// End date of the timeline range.
  final DateTime? endDate;

  /// Color for the timeline bar. Defaults to primary if not provided.
  final Color barColor;

  /// Called when the cell is tapped (opens date range picker).
  final VoidCallback? onTap;

  const TimelineCell({
    super.key,
    this.startDate,
    this.endDate,
    this.barColor = const Color(0xFF579BFC),
    this.onTap,
  });

  static final _dateFormat = DateFormat('d/M');

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final hasDates = startDate != null && endDate != null;

    final semanticLabel = hasDates
        ? 'Timeline: ${_dateFormat.format(startDate!)} to ${_dateFormat.format(endDate!)}'
        : 'Timeline: not set';

    return Semantics(
      label: semanticLabel,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 36,
          padding: const EdgeInsets.symmetric(vertical: 8),
          alignment: Alignment.center,
          child: hasDates ? _buildBar(context) : _buildPlaceholder(cs),
        ),
      ),
    );
  }

  Widget _buildBar(BuildContext context) {
    final effectiveColor = barColor.withValues(alpha: 0.7);
    final textColor = contrastTextColor(
      effectiveColor,
      brightness: Theme.of(context).brightness,
    );
    final label = '${_dateFormat.format(startDate!)} - ${_dateFormat.format(endDate!)}';

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: effectiveColor,
        borderRadius: BorderRadius.circular(4),
      ),
      alignment: Alignment.center,
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w400,
          color: textColor,
        ),
        overflow: TextOverflow.ellipsis,
        maxLines: 1,
      ),
    );
  }

  Widget _buildPlaceholder(ColorScheme cs) {
    return Text(
      'Set dates',
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: cs.onSurfaceVariant,
      ),
    );
  }
}
