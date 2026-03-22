import 'package:flutter/material.dart';

/// Returns the theme-aware display color for a priority level (1-4).
///
/// Uses [ColorScheme] tokens so colors adapt to light/dark mode:
/// - P1 (urgent): [ColorScheme.error]
/// - P2 (high): [ColorScheme.tertiary]
/// - P3 (normal): [ColorScheme.primary]
/// - P4 (low): [ColorScheme.outlineVariant]
Color priorityColor(int priority, ColorScheme cs) {
  return switch (priority) {
    1 => cs.error,
    2 => cs.tertiary,
    3 => cs.primary,
    4 => cs.outlineVariant,
    _ => cs.outlineVariant,
  };
}

/// Presence indicator color constant.
///
/// Used for online status dots in user avatars.
const kPresenceGreen = Color(0xFF4CAF50);
