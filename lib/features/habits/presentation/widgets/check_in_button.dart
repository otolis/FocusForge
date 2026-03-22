import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// An animated circular check-in button for habit completion.
///
/// For binary habits (target == 1), displays a check icon when completed.
/// For count-based habits (target > 1), displays progress text "X/Y".
///
/// Tapping triggers a scale bounce animation (200ms, elasticOut curve) with
/// light haptic feedback. Supports long-press for count-based habits to
/// allow custom count entry.
class CheckInButton extends StatefulWidget {
  const CheckInButton({
    super.key,
    required this.isCompleted,
    required this.onTap,
    this.onLongPress,
    this.progress = 0,
    this.target = 1,
  });

  /// Whether the habit is fully completed for today.
  final bool isCompleted;

  /// Callback invoked on tap (single increment).
  final VoidCallback onTap;

  /// Optional callback invoked on long press (custom count entry).
  final VoidCallback? onLongPress;

  /// Current progress count for today.
  final int progress;

  /// Target count to complete the habit (1 for binary).
  final int target;

  @override
  State<CheckInButton> createState() => _CheckInButtonState();
}

class _CheckInButtonState extends State<CheckInButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.3).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.elasticOut,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handleTap() async {
    _controller.forward().then((_) => _controller.reverse());
    HapticFeedback.lightImpact();
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isCountBased = widget.target > 1;

    return GestureDetector(
      onTap: _handleTap,
      onLongPress: widget.onLongPress,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: widget.isCompleted
                ? colorScheme.primary
                : Colors.transparent,
            border: widget.isCompleted
                ? null
                : Border.all(
                    color: colorScheme.primary,
                    width: 2,
                  ),
          ),
          child: Center(
            child: isCountBased
                ? Text(
                    '${widget.progress}/${widget.target}',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: widget.isCompleted
                          ? colorScheme.onPrimary
                          : colorScheme.primary,
                    ),
                  )
                : widget.isCompleted
                    ? Icon(
                        Icons.check,
                        size: 20,
                        color: colorScheme.onPrimary,
                      )
                    : null,
          ),
        ),
      ),
    );
  }
}
