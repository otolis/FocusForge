import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/utils/extensions.dart';
import '../../domain/board_role.dart';
import '../providers/board_detail_provider.dart';
import '../providers/board_list_provider.dart';
import '../providers/board_presence_provider.dart';
import '../widgets/presence_avatar.dart';

/// Board settings screen with member management, invite flow, and danger zone.
///
/// Role-based visibility:
/// - Owner: rename board, manage member roles, invite members, delete board
/// - Editor/Viewer: read-only member list only
class BoardSettingsScreen extends ConsumerStatefulWidget {
  final String boardId;

  const BoardSettingsScreen({super.key, required this.boardId});

  @override
  ConsumerState<BoardSettingsScreen> createState() =>
      _BoardSettingsScreenState();
}

class _BoardSettingsScreenState extends ConsumerState<BoardSettingsScreen> {
  final _emailController = TextEditingController();
  BoardRole _selectedInviteRole = BoardRole.editor;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _inviteMember() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) return;
    try {
      await ref.read(boardMemberRepositoryProvider).inviteMember(
            boardId: widget.boardId,
            email: email,
            role: _selectedInviteRole,
          );
      _emailController.clear();
      // Refresh board detail to show new member
      ref.read(boardDetailProvider(widget.boardId).notifier).refresh();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text('Invited $email as ${_selectedInviteRole.name}')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not send invite. Please try again.')),
        );
      }
    }
  }

  Future<void> _updateMemberRole(String memberId, BoardRole newRole) async {
    try {
      await ref.read(boardMemberRepositoryProvider).updateMemberRole(
            memberId: memberId,
            role: newRole,
          );
      ref.read(boardDetailProvider(widget.boardId).notifier).refresh();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not update role. Please try again.')),
        );
      }
    }
  }

  Future<void> _removeMember(String memberId, String displayName) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Member'),
        content: Text(
            'Are you sure you want to remove $displayName from this board?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(
                'Remove',
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await ref.read(boardMemberRepositoryProvider).removeMember(memberId);
      ref.read(boardDetailProvider(widget.boardId).notifier).refresh();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Could not remove member. Please try again.')),
        );
      }
    }
  }

  Future<void> _renameBoard(String currentName) async {
    final controller = TextEditingController(text: currentName);
    final newName = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rename Board'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Board name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(controller.text),
            child: const Text('Rename'),
          ),
        ],
      ),
    );
    controller.dispose();

    if (newName == null || newName.trim().isEmpty) return;

    try {
      await ref.read(boardRepositoryProvider).updateBoard(
            widget.boardId,
            name: newName.trim(),
          );
      ref.read(boardDetailProvider(widget.boardId).notifier).refresh();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Could not rename board. Please try again.')),
        );
      }
    }
  }

  Future<void> _deleteBoard() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Board'),
        content: const Text(
          'Are you sure you want to delete this board? '
          'This action cannot be undone. All columns, cards, and '
          'member associations will be permanently removed.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(
                'Delete',
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await ref.read(boardRepositoryProvider).deleteBoard(widget.boardId);
      ref.read(boardListProvider.notifier).refresh();
      if (mounted) {
        context.go('/boards');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Could not delete board. Please try again.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(boardDetailProvider(widget.boardId));
    final isOwner = state.isOwner;

    // Watch presence state so PresenceAvatars rebuild on online changes.
    ref.watch(boardPresenceProvider(widget.boardId));
    final presenceNotifier =
        ref.read(boardPresenceProvider(widget.boardId).notifier);

    if (state.isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Board Settings')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (state.error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Board Settings')),
        body: Center(child: Text('Could not load board settings.')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Board Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Section 1: Board Info
          ListTile(
            title: Text(
              state.board?.name ?? 'Untitled Board',
              style: context.textTheme.titleMedium,
            ),
            subtitle: const Text('Board name'),
            trailing: isOwner
                ? IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: () =>
                        _renameBoard(state.board?.name ?? ''),
                  )
                : null,
          ),
          const Divider(),

          // Section 2: Members header
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Text(
                  'Members',
                  style: context.textTheme.titleSmall,
                ),
                const SizedBox(width: 8),
                Chip(
                  label: Text('${state.members.length}'),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
          ),

          // Section 3: Member list
          ...state.members.map((member) => ListTile(
                leading: PresenceAvatar(
                  displayName: member.displayName,
                  avatarUrl: member.avatarUrl,
                  isOnline: presenceNotifier.isOnline(member.userId),
                ),
                title: Text(member.displayName ?? 'Unknown'),
                subtitle: Text(
                  member.role.name[0].toUpperCase() +
                      member.role.name.substring(1),
                ),
                trailing: isOwner
                    ? Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          DropdownButton<BoardRole>(
                            value: member.role,
                            underline: const SizedBox.shrink(),
                            items: BoardRole.values
                                .map((role) => DropdownMenuItem(
                                      value: role,
                                      child: Text(role.name[0]
                                              .toUpperCase() +
                                          role.name.substring(1)),
                                    ))
                                .toList(),
                            onChanged: (newRole) {
                              if (newRole != null &&
                                  newRole != member.role) {
                                _updateMemberRole(member.id, newRole);
                              }
                            },
                          ),
                          IconButton(
                            icon: Icon(
                              Icons.remove_circle_outline,
                              color: context.colorScheme.error,
                            ),
                            onPressed: () => _removeMember(
                              member.id,
                              member.displayName ?? 'Unknown',
                            ),
                          ),
                        ],
                      )
                    : null,
              )),

          const Divider(),

          // Section 4: Invite Member
          if (isOwner) ...[
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 8),
              child: Text(
                'Invite Member',
                style: context.textTheme.titleSmall,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        hintText: 'Enter email address',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  DropdownButton<BoardRole>(
                    value: _selectedInviteRole,
                    underline: const SizedBox.shrink(),
                    items: const [
                      DropdownMenuItem(
                        value: BoardRole.editor,
                        child: Text('Editor'),
                      ),
                      DropdownMenuItem(
                        value: BoardRole.viewer,
                        child: Text('Viewer'),
                      ),
                    ],
                    onChanged: (role) {
                      if (role != null) {
                        setState(() => _selectedInviteRole = role);
                      }
                    },
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.send_rounded),
                    onPressed: _inviteMember,
                  ),
                ],
              ),
            ),
          ] else ...[
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 8),
              child: Text(
                'Only board owners can invite members.',
                style: context.textTheme.bodySmall?.copyWith(
                  color: context.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],

          // Section 5: Danger Zone (owner only)
          if (isOwner) ...[
            const SizedBox(height: 24),
            const Divider(),
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 8),
              child: Text(
                'Danger Zone',
                style: context.textTheme.titleSmall?.copyWith(
                  color: context.colorScheme.error,
                ),
              ),
            ),
            ListTile(
              leading: Icon(Icons.delete_forever, color: context.colorScheme.error),
              title: Text(
                'Delete Board',
                style: TextStyle(color: context.colorScheme.error),
              ),
              subtitle: const Text(
                'Permanently delete this board and all its data',
              ),
              onTap: _deleteBoard,
            ),
          ],
        ],
      ),
    );
  }
}
