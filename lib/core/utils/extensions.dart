import 'package:flutter/material.dart';

/// Convenience extensions on [BuildContext] for quick access to theme data.
extension BuildContextX on BuildContext {
  /// Shorthand for `Theme.of(this).colorScheme`.
  ColorScheme get colorScheme => Theme.of(this).colorScheme;

  /// Shorthand for `Theme.of(this).textTheme`.
  TextTheme get textTheme => Theme.of(this).textTheme;
}
