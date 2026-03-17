import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/board_model.dart';

/// Repository for board CRUD operations against the Supabase `boards` table.
///
/// Accepts an optional [SupabaseClient] for dependency injection in tests.
class BoardRepository {
  BoardRepository([SupabaseClient? client])
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  /// Creates a board with default columns and owner membership via RPC.
  ///
  /// The `create_board_with_defaults` function atomically inserts the board,
  /// adds the creator as owner, and creates 3 default columns (To Do,
  /// In Progress, Done).
  ///
  /// Returns the new board ID.
  Future<String> createBoard(String name) async {
    final userId = _client.auth.currentUser!.id;
    final result = await _client.rpc('create_board_with_defaults', params: {
      'board_name': name,
      'creator_id': userId,
    });
    return result as String;
  }

  /// Fetches all boards the current user is a member of.
  ///
  /// RLS ensures only boards where the user has a `board_members` row
  /// are returned.
  Future<List<Board>> getBoards() async {
    final data = await _client
        .from('boards')
        .select()
        .order('created_at', ascending: false);
    return data.map((json) => Board.fromJson(json)).toList();
  }

  /// Fetches a single board by ID.
  Future<Board> getBoard(String boardId) async {
    final data = await _client
        .from('boards')
        .select()
        .eq('id', boardId)
        .single();
    return Board.fromJson(data);
  }

  /// Updates board name.
  Future<void> updateBoard(String boardId, {required String name}) async {
    await _client
        .from('boards')
        .update({
          'name': name,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', boardId);
  }

  /// Deletes a board (owner only, enforced by RLS).
  Future<void> deleteBoard(String boardId) async {
    await _client.from('boards').delete().eq('id', boardId);
  }
}
