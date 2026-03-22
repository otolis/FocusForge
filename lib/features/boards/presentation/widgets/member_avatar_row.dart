import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/extensions.dart';
import '../../domain/board_model.dart';
import '../providers/board_presence_provider.dart';
import 'presence_avatar.dart';

/// Horizontal row of member avatars with presence dots and +N overflow.
///
/// Shows up to [maxVisible] member avatars. If there are more members,
/// the last visible slot becomes a "+N" chip showing the overflow count.
class MemberAvatarRow extends ConsumerWidget {
  final List<BoardMember> members;
  final String boardId;
  final int maxVisible;
  final double avatarRadius;
  final VoidCallback? onTap;

  const MemberAvatarRow({
    super.key,
    required this.members,
    required this.boardId,
    this.maxVisible = 4,
    this.avatarRadius = 14,
    this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch presence state to trigger rebuilds when online status changes.
    ref.watch(boardPresenceProvider(boardId));
    final presenceNotifier =
        ref.read(boardPresenceProvider(boardId).notifier);

    final visibleMembers = members.length <= maxVisible
        ? members
        : members.sublist(0, maxVisible);
    final overflowCount =
        members.length > maxVisible ? members.length - maxVisible : 0;

    return GestureDetector(
      onTap: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Overlapping avatars using negative margin via Transform
          ...visibleMembers.asMap().entries.map((entry) {
            final index = entry.key;
            final member = entry.value;
            return Transform.translate(
              offset: Offset(-6.0 * index, 0),
              child: PresenceAvatar(
                displayName: member.displayName,
                avatarUrl: member.avatarUrl,
                isOnline: presenceNotifier.isOnline(member.userId),
                radius: avatarRadius,
              ),
            );
          }),
          // +N overflow chip
          if (overflowCount > 0)
            Transform.translate(
              offset: Offset(-6.0 * visibleMembers.length, 0),
              child: CircleAvatar(
                radius: avatarRadius,
                backgroundColor: context.colorScheme.secondaryContainer,
                child: Text(
                  '+$overflowCount',
                  style: context.textTheme.labelSmall?.copyWith(
                    color: context.colorScheme.onSecondaryContainer,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
