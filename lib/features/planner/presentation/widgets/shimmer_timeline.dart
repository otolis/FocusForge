import 'package:flutter/material.dart';

import '../../../../core/utils/extensions.dart';

/// Shimmer skeleton displayed while the AI generates a schedule.
///
/// Shows 7 placeholder blocks at varying heights that pulse between
/// 30% and 70% opacity using a repeating animation.
class ShimmerTimeline extends StatefulWidget {
  const ShimmerTimeline({super.key});

  @override
  State<ShimmerTimeline> createState() => _ShimmerTimelineState();
}

class _ShimmerTimelineState extends State<ShimmerTimeline>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  /// Heights for the placeholder blocks (simulating 30m, 60m, 45m, 75m, 30m, 60m, 45m).
  static const List<double> _blockHeights = [40, 80, 60, 100, 40, 80, 60];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fillColor = context.colorScheme.surfaceContainerHighest;

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        final opacity = 0.3 + (_animation.value * 0.4);
        return Padding(
          padding: const EdgeInsets.only(top: 16),
          child: Column(
            children: [
              for (final height in _blockHeights)
                Opacity(
                  opacity: opacity,
                  child: Container(
                    height: height,
                    margin: const EdgeInsets.only(
                      left: 56,
                      right: 8,
                      bottom: 8,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: fillColor.withValues(alpha:0.5),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
