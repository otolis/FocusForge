import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/board_model.dart';
import '../domain/board_table_column.dart';

/// Repository for board group CRUD operations.
///
/// Groups are stored inside the `boards.metadata` JSONB field's `groups`
/// array -- there is no separate `board_groups` table. Each mutation
/// reads the current metadata, modifies the groups list, and writes it
/// back as a single atomic update.
///
/// Accepts an optional [SupabaseClient] for dependency injection in tests.
class BoardGroupRepository {
  BoardGroupRepository([SupabaseClient? client])
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  /// Fetches the board's metadata and returns the groups list.
  Future<List<BoardGroup>> getGroups(String boardId) async {
    final data = await _client
        .from('boards')
        .select('metadata')
        .eq('id', boardId)
        .single();
    final metadata =
        BoardMetadata.fromJson(data['metadata'] as Map<String, dynamic>?);
    return metadata.groups;
  }

  /// Adds a group to the board's metadata.groups array.
  Future<void> addGroup(String boardId, BoardGroup group) async {
    final board = await _client
        .from('boards')
        .select('metadata')
        .eq('id', boardId)
        .single();
    final metadata =
        BoardMetadata.fromJson(board['metadata'] as Map<String, dynamic>?);
    final updatedGroups = [...metadata.groups, group];
    final updatedMetadata = BoardMetadata(
      columnDefs: metadata.columnDefs,
      statusLabels: metadata.statusLabels,
      groups: updatedGroups,
    );
    await _client
        .from('boards')
        .update({
          'metadata': updatedMetadata.toJson(),
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', boardId);
  }

  /// Updates a group in the board's metadata.groups array by ID.
  Future<void> updateGroup(String boardId, BoardGroup updatedGroup) async {
    final board = await _client
        .from('boards')
        .select('metadata')
        .eq('id', boardId)
        .single();
    final metadata =
        BoardMetadata.fromJson(board['metadata'] as Map<String, dynamic>?);
    final updatedGroups = metadata.groups
        .map((g) => g.id == updatedGroup.id ? updatedGroup : g)
        .toList();
    final updatedMetadata = BoardMetadata(
      columnDefs: metadata.columnDefs,
      statusLabels: metadata.statusLabels,
      groups: updatedGroups,
    );
    await _client
        .from('boards')
        .update({
          'metadata': updatedMetadata.toJson(),
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', boardId);
  }

  /// Removes a group from the board's metadata.groups array.
  Future<void> deleteGroup(String boardId, String groupId) async {
    final board = await _client
        .from('boards')
        .select('metadata')
        .eq('id', boardId)
        .single();
    final metadata =
        BoardMetadata.fromJson(board['metadata'] as Map<String, dynamic>?);
    final updatedGroups =
        metadata.groups.where((g) => g.id != groupId).toList();
    final updatedMetadata = BoardMetadata(
      columnDefs: metadata.columnDefs,
      statusLabels: metadata.statusLabels,
      groups: updatedGroups,
    );
    await _client
        .from('boards')
        .update({
          'metadata': updatedMetadata.toJson(),
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', boardId);
  }
}
