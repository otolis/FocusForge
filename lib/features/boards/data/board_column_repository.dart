import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/board_model.dart';

/// Repository for board column CRUD operations against the Supabase
/// `board_columns` table.
///
/// Accepts an optional [SupabaseClient] for dependency injection in tests.
class BoardColumnRepository {
  BoardColumnRepository([SupabaseClient? client])
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  /// Fetches all columns for a board, ordered by position ascending.
  Future<List<BoardColumn>> getColumns(String boardId) async {
    final data = await _client
        .from('board_columns')
        .select()
        .eq('board_id', boardId)
        .order('position', ascending: true);
    return data.map((json) => BoardColumn.fromJson(json)).toList();
  }

  /// Creates a new column in a board.
  ///
  /// Returns the created [BoardColumn] with server-generated fields.
  Future<BoardColumn> createColumn({
    required String boardId,
    required String name,
    required int position,
  }) async {
    final data = await _client
        .from('board_columns')
        .insert({
          'board_id': boardId,
          'name': name,
          'position': position,
        })
        .select()
        .single();
    return BoardColumn.fromJson(data);
  }

  /// Updates a column's name and/or position.
  Future<void> updateColumn(
    String columnId, {
    String? name,
    int? position,
  }) async {
    final updates = <String, dynamic>{};
    if (name != null) updates['name'] = name;
    if (position != null) updates['position'] = position;
    if (updates.isEmpty) return;

    await _client
        .from('board_columns')
        .update(updates)
        .eq('id', columnId);
  }

  /// Deletes a column by ID.
  Future<void> deleteColumn(String columnId) async {
    await _client.from('board_columns').delete().eq('id', columnId);
  }

  /// Batch-updates positions for a list of columns.
  ///
  /// Used after drag-and-drop reordering of columns.
  Future<void> reorderColumns(List<BoardColumn> columns) async {
    await Future.wait(
      columns.map(
        (col) => _client
            .from('board_columns')
            .update({'position': col.position})
            .eq('id', col.id),
      ),
    );
  }
}
