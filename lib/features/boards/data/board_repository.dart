import 'package:flutter/foundation.dart';
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
  ///
  /// Throws a descriptive error if the migration hasn't been applied.
  Future<String> createBoard(String name) async {
    final userId = _client.auth.currentUser!.id;
    try {
      final result = await _client.rpc('create_board_with_defaults', params: {
        'board_name': name,
        'creator_id': userId,
      });
      return result as String;
    } on PostgrestException catch (e) {
      debugPrint('[BoardRepository] createBoard PostgrestException: '
          'code=${e.code}, message=${e.message}, details=${e.details}');
      final msg = e.message.toLowerCase();
      final code = e.code ?? '';
      if (code == '42883' || // function does not exist
          code == '42P01' || // relation does not exist
          msg.contains('does not exist')) {
        throw Exception(
          'Boards feature requires database setup. '
          'Run migration 00003_create_boards.sql on your Supabase instance.',
        );
      }
      rethrow;
    }
  }

  /// Fetches all boards the current user is a member of.
  ///
  /// RLS ensures only boards where the user has a `board_members` row
  /// are returned. Logs every step for diagnostics.
  Future<List<Board>> getBoards() async {
    debugPrint('[BoardRepository] getBoards() called');
    debugPrint('[BoardRepository] user=${_client.auth.currentUser?.id}');
    try {
      final data = await _client
          .from('boards')
          .select()
          .order('created_at', ascending: false);
      debugPrint('[BoardRepository] getBoards returned ${data.length} rows');
      final boards = <Board>[];
      for (int i = 0; i < data.length; i++) {
        try {
          boards.add(Board.fromJson(data[i]));
        } catch (parseError) {
          debugPrint('[BoardRepository] Board.fromJson failed on row $i: '
              '$parseError  raw=${ data[i]}');
          // Skip malformed rows instead of crashing the whole list
        }
      }
      return boards;
    } on PostgrestException catch (e) {
      debugPrint('[BoardRepository] getBoards PostgrestException: '
          'code=${e.code}, message=${e.message}, details=${e.details}');
      rethrow;
    } catch (e, stack) {
      debugPrint('[BoardRepository] getBoards unexpected error: $e');
      debugPrint('[BoardRepository] Stack trace: $stack');
      rethrow;
    }
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
