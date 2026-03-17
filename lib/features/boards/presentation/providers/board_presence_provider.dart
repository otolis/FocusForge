import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Represents a user currently online on a board.
class OnlineMember {
  final String userId;
  final String displayName;
  final String onlineAt;

  const OnlineMember({
    required this.userId,
    required this.displayName,
    required this.onlineAt,
  });
}

/// Tracks which users are currently viewing a specific board.
///
/// Keyed by board ID. Updated by [BoardRealtimeProvider] when presence
/// events arrive from the Supabase Realtime channel.
final boardPresenceProvider = StateNotifierProvider.family<
    BoardPresenceNotifier, List<OnlineMember>, String>(
  (ref, boardId) => BoardPresenceNotifier(),
);

class BoardPresenceNotifier extends StateNotifier<List<OnlineMember>> {
  BoardPresenceNotifier() : super(const []);

  /// Replaces the online members list with the latest presence data.
  ///
  /// Called by [boardRealtimeProvider] whenever a presence sync, join,
  /// or leave event occurs.
  void updateOnlineMembers(List<Map<String, dynamic>> presencePayloads) {
    state = presencePayloads
        .map((p) => OnlineMember(
              userId: p['user_id'] as String? ?? '',
              displayName: p['display_name'] as String? ?? 'User',
              onlineAt: p['online_at'] as String? ?? '',
            ))
        .toList();
  }

  /// Returns whether a user is currently online on this board.
  bool isOnline(String userId) {
    return state.any((m) => m.userId == userId);
  }
}
