import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

/// Asset paths for celebration animations.
class CelebrationAssets {
  static const String taskComplete = 'assets/animations/task_complete.json';
  static const String habitCheckin = 'assets/animations/habit_checkin.json';
  static const String streakMilestone = 'assets/animations/streak_milestone.json';
}

/// A reusable overlay that plays a Lottie animation on top of the current
/// screen and auto-dismisses after the animation completes.
///
/// The overlay uses [IgnorePointer] so it does not block user interaction
/// while playing. Call [CelebrationOverlay.show] to trigger.
class CelebrationOverlay {
  /// Shows a Lottie animation overlay centered on screen.
  ///
  /// [context] must have an active [Overlay] ancestor.
  /// [animationAsset] is the asset path (use [CelebrationAssets] constants).
  /// [size] controls the animation widget dimensions (default 200x200).
  static void show(
    BuildContext context, {
    required String animationAsset,
    double size = 200,
  }) {
    final overlay = Overlay.of(context);
    late OverlayEntry entry;

    entry = OverlayEntry(
      builder: (context) => Positioned.fill(
        child: IgnorePointer(
          child: Center(
            child: SizedBox(
              width: size,
              height: size,
              child: Lottie.asset(
                animationAsset,
                repeat: false,
                onLoaded: (composition) {
                  Future.delayed(composition.duration, () {
                    if (entry.mounted) entry.remove();
                  });
                },
              ),
            ),
          ),
        ),
      ),
    );

    overlay.insert(entry);

    // Safety timeout: remove after 3 seconds max in case onLoaded doesn't fire
    Future.delayed(const Duration(seconds: 3), () {
      if (entry.mounted) entry.remove();
    });
  }
}
