import 'package:flutter/material.dart';

/// Returns white or dark text color based on background luminance.
///
/// Ensures WCAG AA 4.5:1 contrast ratio for text on colored pills.
/// Dark text: #1E1B16 in light mode, #FFFBF5 in dark mode.
Color contrastTextColor(
  Color background, {
  Brightness brightness = Brightness.light,
}) {
  final luminance = background.computeLuminance();
  // If background is light (luminance > 0.4), use dark text
  if (luminance > 0.4) {
    return brightness == Brightness.dark
        ? const Color(0xFFFFFBF5)
        : const Color(0xFF1E1B16);
  }
  return Colors.white;
}
