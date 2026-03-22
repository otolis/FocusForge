import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/extensions.dart';
import '../providers/planner_provider.dart';

/// A card with a constraint text field and regenerate button.
///
/// Allows users to provide optional constraints (e.g., "I have a meeting
/// at 2 PM") and regenerate the AI schedule with those constraints applied.
class RegenerateBar extends ConsumerStatefulWidget {
  /// The current user's ID, used to key the provider.
  final String userId;

  /// Called after the constraints are updated to trigger regeneration.
  final VoidCallback onRegenerate;

  const RegenerateBar({
    super.key,
    required this.userId,
    required this.onRegenerate,
  });

  @override
  ConsumerState<RegenerateBar> createState() => _RegenerateBarState();
}

class _RegenerateBarState extends ConsumerState<RegenerateBar> {
  final _constraintsController = TextEditingController();

  @override
  void dispose() {
    _constraintsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.only(left: 12, right: 4, top: 4, bottom: 4),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _constraintsController,
                decoration: InputDecoration(
                  hintText: 'e.g., I have a meeting at 2 PM',
                  hintStyle: context.textTheme.bodySmall?.copyWith(
                    color: context.colorScheme.onSurfaceVariant.withOpacity(0.6),
                  ),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(vertical: 8),
                ),
                style: context.textTheme.bodySmall,
              ),
            ),
            IconButton(
              icon: Icon(
                Icons.refresh_rounded,
                color: context.colorScheme.primary,
              ),
              tooltip: 'Regenerate schedule',
              onPressed: _onRegenerate,
            ),
          ],
        ),
      ),
    );
  }

  void _onRegenerate() {
    final text = _constraintsController.text.trim();
    ref.read(plannerProvider(widget.userId).notifier).updateConstraints(
          text.isEmpty ? null : text,
        );
    widget.onRegenerate();
  }
}
