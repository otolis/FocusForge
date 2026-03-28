import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/board_model.dart';

/// Repository for board card CRUD operations against the Supabase
/// `board_cards` table.
///
/// Accepts an optional [SupabaseClient] for dependency injection in tests.
class BoardCardRepository {
  BoardCardRepository([SupabaseClient? client])
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  /// Fetches all cards for a board, ordered by position ascending.
  Future<List<BoardCard>> getCards(String boardId) async {
    final data = await _client
        .from('board_cards')
        .select()
        .eq('board_id', boardId)
        .order('position', ascending: true);
    return data.map((json) => BoardCard.fromJson(json)).toList();
  }

  /// Creates a new card in a column.
  ///
  /// Sets `created_by` to the current user. Returns the created [BoardCard]
  /// with server-generated fields.
  ///
  /// Table-view fields ([statusLabel], [statusColor], [groupId], [startDate],
  /// [customFields]) are optional. [groupId] defaults to `'default_group'`
  /// when not provided.
  Future<BoardCard> createCard({
    required String boardId,
    required String columnId,
    required String title,
    String? description,
    int? priority,
    DateTime? dueDate,
    required int position,
    // Table-view fields
    String? statusLabel,
    String? statusColor,
    String? groupId,
    DateTime? startDate,
    Map<String, dynamic>? customFields,
  }) async {
    final userId = _client.auth.currentUser!.id;
    final insertMap = <String, dynamic>{
      'board_id': boardId,
      'column_id': columnId,
      'title': title,
      'description': description,
      'priority': priority ?? 3,
      'due_date': dueDate?.toIso8601String(),
      'position': position,
      'created_by': userId,
      'group_id': groupId ?? 'default_group',
    };
    if (statusLabel != null) insertMap['status_label'] = statusLabel;
    if (statusColor != null) insertMap['status_color'] = statusColor;
    if (startDate != null) {
      insertMap['start_date'] = startDate.toIso8601String();
    }
    if (customFields != null) insertMap['custom_fields'] = customFields;

    final data = await _client
        .from('board_cards')
        .insert(insertMap)
        .select()
        .single();
    return BoardCard.fromJson(data);
  }

  /// Updates a card's mutable fields. Only non-null parameters are applied.
  ///
  /// Supports both original Kanban fields and table-view extensions.
  Future<void> updateCard(
    String cardId, {
    String? columnId,
    String? title,
    String? description,
    String? assigneeId,
    int? priority,
    DateTime? dueDate,
    int? position,
    // Table-view fields
    String? statusLabel,
    String? statusColor,
    String? groupId,
    DateTime? startDate,
    Map<String, dynamic>? customFields,
  }) async {
    final updates = <String, dynamic>{
      'updated_at': DateTime.now().toIso8601String(),
    };
    if (columnId != null) updates['column_id'] = columnId;
    if (title != null) updates['title'] = title;
    if (description != null) updates['description'] = description;
    if (assigneeId != null) updates['assignee_id'] = assigneeId;
    if (priority != null) updates['priority'] = priority;
    if (dueDate != null) updates['due_date'] = dueDate.toIso8601String();
    if (position != null) updates['position'] = position;
    // Table-view fields
    if (statusLabel != null) updates['status_label'] = statusLabel;
    if (statusColor != null) updates['status_color'] = statusColor;
    if (groupId != null) updates['group_id'] = groupId;
    if (startDate != null) {
      updates['start_date'] = startDate.toIso8601String();
    }
    if (customFields != null) updates['custom_fields'] = customFields;

    await _client
        .from('board_cards')
        .update(updates)
        .eq('id', cardId);
  }

  /// Deletes a card by ID.
  Future<void> deleteCard(String cardId) async {
    await _client.from('board_cards').delete().eq('id', cardId);
  }
}
