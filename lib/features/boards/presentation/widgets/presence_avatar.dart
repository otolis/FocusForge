import 'package:flutter/material.dart';

import '../../../../core/utils/extensions.dart';
import '../../../../features/profile/presentation/widgets/avatar_widget.dart';

/// Displays a circular avatar with an online presence indicator.
///
/// When [isOnline] is true, a green dot appears at bottom-right and the
/// avatar is fully opaque. When false, the avatar is dimmed to 50% opacity
/// and no dot is shown.
class PresenceAvatar extends StatelessWidget {
  final String? displayName;
  final String? avatarUrl;
  final bool isOnline;
  final double radius;

  const PresenceAvatar({
    super.key,
    this.displayName,
    this.avatarUrl,
    this.isOnline = false,
    this.radius = 16,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Opacity(
          opacity: isOnline ? 1.0 : 0.5,
          child: AvatarWidget(
            displayName: displayName,
            avatarUrl: avatarUrl,
            radius: radius,
          ),
        ),
        if (isOnline)
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: Colors.green,
                shape: BoxShape.circle,
                border: Border.all(
                  color: context.colorScheme.surface,
                  width: 1.5,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
