import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/board_realtime_service.dart';
import '../../domain/board_model.dart';
import 'board_detail_provider.dart';
import 'board_presence_provider.dart';

/// Manages the Realtime subscription lifecycle for a board.
///
/// AutoDispose family provider keyed by board ID. On first read, subscribes to
/// Postgres Changes on `board_cards` and `board_columns`, plus Presence.
/// On dispose (when the board screen is popped and no widgets reference this
/// provider), unsubscribes to prevent channel leaks.
///
/// Each board gets its own [BoardRealtimeService] instance so channels
/// don't overwrite each other when multiple boards are visited.
///
/// Usage in a widget: `ref.watch(boardRealtimeProvider(boardId));`
final boardRealtimeProvider =
    Provider.autoDispose.family<void, String>((ref, boardId) {
  final service = BoardRealtimeService(Supabase.instance.client);
  final client = Supabase.instance.client;
  final user = client.auth.currentUser!;
  final detailNotifier = ref.read(boardDetailProvider(boardId).notifier);
  final presenceNotifier =
      ref.read(boardPresenceProvider(boardId).notifier);

  service.subscribeTo(
    boardId: boardId,
    userId: user.id,
    displayName: user.userMetadata?['full_name'] as String? ?? 'User',
    onCardChange: (payload) {
      final eventType = payload.eventType.name;
      // For DELETE events, use oldRecord; for INSERT/UPDATE, use newRecord
      final record = eventType.toUpperCase() == 'DELETE'
          ? payload.oldRecord
          : payload.newRecord;
      if (record.isNotEmpty) {
        try {
          final card = BoardCard.fromJson(record);
          detailNotifier.onRemoteCardChange(card, eventType);
        } catch (_) {
          // Malformed payload -- ignore
        }
      }
    },
    onColumnChange: (payload) {
      final eventType = payload.eventType.name;
      final record = eventType.toUpperCase() == 'DELETE'
          ? payload.oldRecord
          : payload.newRecord;
      if (record.isNotEmpty) {
        try {
          final column = BoardColumn.fromJson(record);
          detailNotifier.onRemoteColumnChange(column, eventType);
        } catch (_) {
          // Malformed payload -- ignore
        }
      }
    },
    onPresenceSync: () {
      presenceNotifier.updateOnlineMembers(service.onlineMembers);
    },
  );

  // Cleanup on dispose -- prevents channel leaks (Pitfall 5)
  ref.onDispose(() {
    service.unsubscribe();
  });
});
