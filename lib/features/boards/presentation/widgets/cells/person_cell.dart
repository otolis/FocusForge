import 'package:flutter/material.dart';

/// A cell displaying an assignee avatar and name, or a placeholder icon.
///
/// When an assignee is set, shows a [CircleAvatar] (radius 12) with the
/// assignee's initials/avatar and their truncated display name.
/// When no assignee is set, shows a centered person_outline icon.
class PersonCell extends StatelessWidget {
  /// The display name of the assigned person. Null means unassigned.
  final String? assigneeName;

  /// URL for the assignee's avatar image.
  final String? avatarUrl;

  /// Called when the cell is tapped (opens member picker).
  final VoidCallback? onTap;

  const PersonCell({
    super.key,
    this.assigneeName,
    this.avatarUrl,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final hasAssignee = assigneeName != null && assigneeName!.isNotEmpty;

    return Semantics(
      label: hasAssignee ? 'Person: $assigneeName' : 'Person: unassigned',
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 36,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          alignment: hasAssignee ? Alignment.centerLeft : Alignment.center,
          child: hasAssignee ? _buildAssignee(cs) : _buildPlaceholder(cs),
        ),
      ),
    );
  }

  Widget _buildAssignee(ColorScheme cs) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        CircleAvatar(
          radius: 12,
          backgroundColor: cs.primaryContainer,
          backgroundImage:
              avatarUrl != null ? NetworkImage(avatarUrl!) : null,
          child: avatarUrl == null
              ? Text(
                  _initials(assigneeName!),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: cs.onPrimaryContainer,
                  ),
                )
              : null,
        ),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            assigneeName!,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w400),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ),
      ],
    );
  }

  Widget _buildPlaceholder(ColorScheme cs) {
    return Icon(
      Icons.person_outline,
      size: 16,
      color: cs.onSurfaceVariant,
    );
  }

  /// Extracts up to 2 initials from a display name.
  static String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : '';
  }
}
