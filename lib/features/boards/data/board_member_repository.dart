import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/board_model.dart';
import '../domain/board_role.dart';

/// Repository for board member CRUD operations against the Supabase
/// `board_members` table.
///
/// Accepts an optional [SupabaseClient] for dependency injection in tests.
class BoardMemberRepository {
  BoardMemberRepository([SupabaseClient? client])
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  /// Fetches all members for a board, joined with profiles for display info.
  ///
  /// The Supabase query uses a foreign-key join on `user_id` to pull
  /// `display_name` and `avatar_url` from the `profiles` table.
  Future<List<BoardMember>> getMembers(String boardId) async {
    final data = await _client
        .from('board_members')
        .select('*, profiles:user_id(display_name, avatar_url)')
        .eq('board_id', boardId);
    return data.map((json) => BoardMember.fromJson(json)).toList();
  }

  /// Invites a user to a board by email.
  ///
  /// Uses the `invite_board_member` RPC function which securely looks up
  /// the user by email in `auth.users` (requires security definer).
  ///
  /// Returns the new member ID, or null if the user was already a member.
  Future<String?> inviteMember({
    required String boardId,
    required String email,
    BoardRole role = BoardRole.editor,
  }) async {
    final result = await _client.rpc('invite_board_member', params: {
      'target_board_id': boardId,
      'invite_email': email,
      'invite_role': role.name,
    });
    return result as String?;
  }

  /// Updates a member's role.
  Future<void> updateMemberRole({
    required String memberId,
    required BoardRole role,
  }) async {
    await _client
        .from('board_members')
        .update({'role': role.name})
        .eq('id', memberId);
  }

  /// Removes a member from a board.
  ///
  /// Members can remove themselves; owners can remove anyone (enforced by RLS).
  Future<void> removeMember(String memberId) async {
    await _client.from('board_members').delete().eq('id', memberId);
  }

  /// Returns the current user's role on a specific board.
  Future<BoardRole> getCurrentUserRole(String boardId) async {
    final userId = _client.auth.currentUser!.id;
    final data = await _client
        .from('board_members')
        .select('role')
        .eq('board_id', boardId)
        .eq('user_id', userId)
        .single();
    return BoardRole.fromString(data['role'] as String);
  }
}
