import 'package:flutter/material.dart';

import '../../../../core/utils/extensions.dart';

/// Displays a circular avatar with either a network image or initials.
///
/// If [avatarUrl] is non-null and non-empty, shows the image with initials
/// as a loading placeholder. Otherwise shows initials on a
/// [primaryContainer] background, or a fallback person icon.
///
/// When [onEdit] is provided, a small camera icon button is overlaid at
/// the bottom-right corner.
class AvatarWidget extends StatelessWidget {
  const AvatarWidget({
    super.key,
    this.displayName,
    this.avatarUrl,
    this.onEdit,
    this.radius = 48,
  });

  /// The user's display name, used to derive initials.
  final String? displayName;

  /// Optional avatar image URL from Supabase Storage.
  final String? avatarUrl;

  /// Called when the edit overlay icon is tapped.
  final VoidCallback? onEdit;

  /// Radius of the CircleAvatar. Defaults to 48dp.
  final double radius;

  /// Derives initials from [displayName].
  String get _initials {
    if (displayName == null || displayName!.isEmpty) return '?';
    final parts = displayName!.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    }
    return parts.first[0].toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final hasAvatar = avatarUrl != null && avatarUrl!.isNotEmpty;

    final avatar = CircleAvatar(
      radius: radius,
      backgroundColor: context.colorScheme.primaryContainer,
      backgroundImage: hasAvatar ? NetworkImage(avatarUrl!) : null,
      child: hasAvatar
          ? null
          : Text(
              _initials,
              style: context.textTheme.headlineMedium?.copyWith(
                color: context.colorScheme.onPrimaryContainer,
                fontWeight: FontWeight.bold,
              ),
            ),
    );

    if (onEdit == null) return avatar;

    return Stack(
      alignment: Alignment.bottomRight,
      children: [
        avatar,
        Positioned(
          bottom: 0,
          right: 0,
          child: GestureDetector(
            onTap: onEdit,
            child: CircleAvatar(
              radius: 16,
              backgroundColor: context.colorScheme.primary,
              child: Icon(
                Icons.camera_alt_rounded,
                size: 16,
                color: context.colorScheme.onPrimary,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
