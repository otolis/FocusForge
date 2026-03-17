import 'package:flutter/material.dart';

/// Amber seed color used for Material 3 palette generation.
const Color seedColor = Color(0xFFFF8F00);

/// Light color scheme generated from the amber seed with cream surface
/// and teal tertiary accent.
final ColorScheme lightColorScheme = ColorScheme.fromSeed(
  seedColor: seedColor,
  brightness: Brightness.light,
  tertiary: const Color(0xFF2E7D6F),
  surface: const Color(0xFFFFFBF5),
);

/// Dark color scheme generated from the amber seed with warm charcoal
/// surface and sage green tertiary accent.
final ColorScheme darkColorScheme = ColorScheme.fromSeed(
  seedColor: seedColor,
  brightness: Brightness.dark,
  tertiary: const Color(0xFF81C784),
  surface: const Color(0xFF1E1B16),
);
