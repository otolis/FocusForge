import 'package:flutter/material.dart';

import '../../../domain/board_model.dart';

/// Full-width colored header bar for a table-view group.
///
/// Displays the group name, item count, and a collapse/expand chevron.
/// The parent manages collapse state and passes [isCollapsed] + [onToggle].
class GroupHeaderWidget extends StatelessWidget {
  final BoardGroup group;
  final int itemCount;
  final bool isCollapsed;
  final VoidCallback onToggle;
  final VoidCallback? onLongPress;

  const GroupHeaderWidget({
    super.key,
    required this.group,
    required this.itemCount,
    required this.isCollapsed,
    required this.onToggle,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label:
          'Group: ${group.name}, $itemCount items, ${isCollapsed ? 'collapsed' : 'expanded'}',
      child: GestureDetector(
        onTap: onToggle,
        onLongPress: onLongPress,
        child: Container(
          height: 40,
          color: _parseHex(group.color),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Icon(
                isCollapsed ? Icons.chevron_right : Icons.expand_more,
                size: 20,
                color: Colors.white,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  group.name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '$itemCount items',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                  color: const Color(0xFFFFFFFF).withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Converts a hex color string (with or without '#' prefix) to a [Color].
  static Color _parseHex(String hex) {
    final buffer = StringBuffer();
    final cleaned = hex.replaceAll('#', '');
    buffer.write('FF'); // Full opacity
    buffer.write(cleaned);
    return Color(int.parse(buffer.toString(), radix: 16));
  }
}
