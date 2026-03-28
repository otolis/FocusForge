import 'package:flutter/material.dart';

import '../../../../../core/utils/contrast_color.dart';

/// A full-width colored pill cell displaying a status label.
///
/// Renders the status color as background with centered label text.
/// Text color switches between white and dark based on background luminance
/// for WCAG AA compliance.
class StatusCell extends StatelessWidget {
  /// The status label text. Defaults to 'Not Started' when null.
  final String? statusLabel;

  /// Hex color string (e.g. '#FF9800'). Defaults to gray when null.
  final String? statusColor;

  /// Called when the cell is tapped (opens status picker).
  final VoidCallback? onTap;

  const StatusCell({
    super.key,
    this.statusLabel,
    this.statusColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final label = statusLabel ?? 'Not Started';
    final bgColor = _parseColor(statusColor) ?? const Color(0xFF9E9E9E);
    final textColor = contrastTextColor(
      bgColor,
      brightness: Theme.of(context).brightness,
    );

    return Semantics(
      label: 'Status: $label',
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 36,
          alignment: Alignment.center,
          color: bgColor.withValues(alpha: 0.85),
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

  /// Parses a hex color string like '#FF9800' into a [Color].
  static Color? _parseColor(String? hex) {
    if (hex == null || hex.isEmpty) return null;
    try {
      return Color(int.parse(hex.replaceFirst('#', '0xFF')));
    } catch (_) {
      return null;
    }
  }
}
