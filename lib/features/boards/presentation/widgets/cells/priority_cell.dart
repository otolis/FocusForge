import 'package:flutter/material.dart';

import '../../../../../core/utils/contrast_color.dart';

/// A full-width colored pill cell displaying a priority level.
///
/// Uses Monday.com branded colors:
/// - Critical (1): red #E2445C
/// - High (2): orange #FDAB3D
/// - Medium (3): blue #579BFC
/// - Low (4): gray #C4C4C4
///
/// Text color switches between white and dark based on background luminance
/// for WCAG AA compliance.
class PriorityCell extends StatelessWidget {
  /// Priority level (1-4). Values outside range default to Low.
  final int priority;

  /// Called when the cell is tapped (opens priority picker).
  final VoidCallback? onTap;

  const PriorityCell({
    super.key,
    required this.priority,
    this.onTap,
  });

  static const _labels = {
    1: 'Critical',
    2: 'High',
    3: 'Medium',
    4: 'Low',
  };

  static const _colors = {
    1: Color(0xFFE2445C),
    2: Color(0xFFFDAB3D),
    3: Color(0xFF579BFC),
    4: Color(0xFFC4C4C4),
  };

  @override
  Widget build(BuildContext context) {
    final label = _labels[priority] ?? 'Low';
    final bgColor = _colors[priority] ?? _colors[4]!;
    final textColor = contrastTextColor(
      bgColor,
      brightness: Theme.of(context).brightness,
    );

    return Semantics(
      label: 'Priority: $label',
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 36,
          alignment: Alignment.center,
          color: bgColor,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w400,
              color: textColor,
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ),
      ),
    );
  }
}
