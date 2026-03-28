import 'package:flutter/foundation.dart';
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

  /// Fetches all members for a board.
  ///
  /// Fetches members first, then enriches with profile data (display name,
  /// avatar) in a separate query. The two-step approach avoids the PostgREST
  /// PGRST200 error that occurs because `board_members.user_id` has a FK to
  /// `auth.users`, not directly to `profiles` — so the `profiles:user_id()`
  /// embedded join syntax is unsupported.
  Future<List<BoardMember>> getMembers(String boardId) async {
    // Step 1: fetch members without profile join
    final data = await _client
        .from('board_members')
        .select()
        .eq('board_id', boardId);

    if (data.isEmpty) return [];

    // Step 2: fetch profiles for all member user IDs
    final userIds = data.map((m) => m['user_id'] as String).toList();
    Map<String, Map<String, dynamic>> profileMap = {};
    try {
      final profiles = await _client
          .from('profiles')
          .select('id, display_name, avatar_url')
          .inFilter('id', userIds);
      for (final p in profiles) {
        profileMap[p['id'] as String] = p;
      }
    } catch (e) {
      // Profile fetch may fail due to RLS (users can only see own profile).
      // Continue without profile data — members still work, just no names.
      debugPrint('[BoardMemberRepository] Profile fetch failed: $e');
    }

    // Step 3: merge profile data into member JSON
    return data.map((json) {
      final userId = json['user_id'] as String;
      final profile = profileMap[userId];
      final enriched = Map<String, dynamic>.from(json);
      if (profile != null) {
        enriched['profiles'] = profile;
      }
      return BoardMember.fromJson(enriched);
    }).toList();
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
