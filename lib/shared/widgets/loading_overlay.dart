import 'package:flutter/material.dart';

/// A widget that overlays a semi-transparent barrier with a centered
/// [CircularProgressIndicator] when [isLoading] is true.
///
/// When [isLoading] is false, only the [child] is displayed.
class LoadingOverlay extends StatelessWidget {
  const LoadingOverlay({
    super.key,
    required this.isLoading,
    required this.child,
  });

  /// Whether the loading overlay is currently visible.
  final bool isLoading;

  /// The content beneath the overlay.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        if (isLoading)
          Positioned.fill(
            child: AbsorbPointer(
              child: ColoredBox(
                color: Colors.black.withValues(alpha: 0.3),
                child: const Center(
                  child: CircularProgressIndicator(),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
