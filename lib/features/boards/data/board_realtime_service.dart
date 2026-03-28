import 'package:supabase_flutter/supabase_flutter.dart';

/// Manages a Supabase Realtime channel for a single board.
///
/// Subscribes to Postgres Changes on `board_cards` and `board_columns`
/// (filtered by `board_id`) for instant sync, plus Presence for tracking
/// which users are currently viewing the board.
///
/// Usage:
/// 1. Call [subscribeTo] when entering a board detail screen.
/// 2. Read [onlineMembers] to display presence indicators.
/// 3. Call [unsubscribe] when leaving the board screen.
class BoardRealtimeService {
  BoardRealtimeService(this._client);
  final SupabaseClient _client;
  RealtimeChannel? _channel;

  /// Subscribes to card changes, column changes, and presence for the
  /// given [boardId].
  ///
  /// [onCardChange] fires on INSERT, UPDATE, or DELETE of any card in
  /// this board. [onColumnChange] fires for column mutations. Both use
  /// a `PostgresChangeFilter` on `board_id` so only events for this board
  /// are received.
  ///
  /// [onPresenceSync] fires whenever the presence state changes (join,
  /// leave, or periodic sync). Read [onlineMembers] inside this callback
  /// to get the current list.
  void subscribeTo({
    required String boardId,
    required String userId,
    required String displayName,
    required void Function(PostgresChangePayload) onCardChange,
    required void Function(PostgresChangePayload) onColumnChange,
    required void Function() onPresenceSync,
  }) {
    _channel = _client
        .channel('board:$boardId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'board_cards',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'board_id',
            value: boardId,
          ),
          callback: onCardChange,
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'board_columns',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'board_id',
            value: boardId,
          ),
          callback: onColumnChange,
        )
        .onPresenceSync((_) => onPresenceSync())
        .onPresenceJoin((_) => onPresenceSync())
        .onPresenceLeave((_) => onPresenceSync());

    _channel!.subscribe((status, error) async {
      if (status == RealtimeSubscribeStatus.subscribed) {
        await _channel!.track({
          'user_id': userId,
          'display_name': displayName,
          'online_at': DateTime.now().toIso8601String(),
        });
      }
    });
  }

  /// Returns the list of currently online members on this board.
  ///
  /// Each entry contains `user_id`, `display_name`, and `online_at`
  /// from the presence payload.
  List<Map<String, dynamic>> get onlineMembers {
    if (_channel == null) return [];
    final presenceState = _channel!.presenceState();
    // presenceState() returns List<SinglePresenceState>
    return presenceState
        .expand((s) => s.presences)
        .map((p) => p.payload)
        .toList();
  }

  /// Unsubscribes from the board's Realtime channel and cleans up.
  ///
  /// Must be called when navigating away from the board detail screen
  /// to prevent channel leaks (Pitfall 5 from research).
  Future<void> unsubscribe() async {
    if (_channel != null) {
      await _client.removeChannel(_channel!);
      _channel = null;
    }
  }
}
