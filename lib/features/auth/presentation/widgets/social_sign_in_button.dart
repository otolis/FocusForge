import 'package:flutter/material.dart';

import '../../../../core/utils/extensions.dart';

/// A full-width outlined button for social sign-in (Google).
///
/// Displays the Google "G" logo on the left and a text label. Shows a
/// [CircularProgressIndicator] when [isLoading] is true.
///
/// Height: 48dp, border radius: 12dp (inherited from theme's
/// [OutlinedButtonThemeData]).
class SocialSignInButton extends StatelessWidget {
  const SocialSignInButton({
    super.key,
    required this.onPressed,
    this.isLoading = false,
  });

  /// Callback when the button is pressed.
  final VoidCallback? onPressed;

  /// When true, shows a loading indicator and disables the button.
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: isLoading ? null : onPressed,
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(double.infinity, 48),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        side: BorderSide(color: context.colorScheme.outline),
      ),
      child: isLoading
          ? SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: context.colorScheme.onSurface,
              ),
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Google "G" logo as styled text (no external asset required).
                Text(
                  'G',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: context.colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Continue with Google',
                  style: TextStyle(
                    color: context.colorScheme.onSurface,
                  ),
                ),
              ],
            ),
    );
  }
}
