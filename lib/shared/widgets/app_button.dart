import 'package:flutter/material.dart';

import '../../core/utils/extensions.dart';

/// A reusable button widget that supports filled, outlined, and destructive
/// variants with built-in loading state.
///
/// Full width by default (double.infinity), 48dp height, 12dp border radius.
class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.onPressed,
    required this.label,
    this.isLoading = false,
    this.isOutlined = false,
    this.isDestructive = false,
  });

  /// Callback when the button is pressed. Disabled when [isLoading] is true.
  final VoidCallback? onPressed;

  /// Text label displayed on the button.
  final String label;

  /// When true, shows a [CircularProgressIndicator] and disables the button.
  final bool isLoading;

  /// When true, uses [OutlinedButton] style instead of [FilledButton].
  final bool isOutlined;

  /// When true, uses [colorScheme.error] for the button background.
  final bool isDestructive;

  @override
  Widget build(BuildContext context) {
    final effectiveOnPressed = isLoading ? null : onPressed;

    final child = isLoading
        ? const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Colors.white,
            ),
          )
        : Text(label);

    if (isOutlined) {
      return OutlinedButton(
        onPressed: effectiveOnPressed,
        style: isDestructive
            ? OutlinedButton.styleFrom(
                foregroundColor: context.colorScheme.error,
                side: BorderSide(color: context.colorScheme.error),
              )
            : null,
        child: child,
      );
    }

    return FilledButton(
      onPressed: effectiveOnPressed,
      style: isDestructive
          ? FilledButton.styleFrom(
              backgroundColor: context.colorScheme.error,
              foregroundColor: context.colorScheme.onError,
            )
          : null,
      child: child,
    );
  }
}
