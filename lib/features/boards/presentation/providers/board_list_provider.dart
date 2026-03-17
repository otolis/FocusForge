import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/board_repository.dart';
import '../../domain/board_model.dart';

/// Provides a [BoardRepository] instance to the widget tree.
final boardRepositoryProvider = Provider<BoardRepository>((ref) {
  return BoardRepository();
});

/// Manages the list of boards the current user is a member of.
///
/// Automatically fetches boards on first read. Provides methods to
/// create and delete boards, with automatic list refresh.
final boardListProvider =
    AsyncNotifierProvider<BoardListNotifier, List<Board>>(() {
  return BoardListNotifier();
});

class BoardListNotifier extends AsyncNotifier<List<Board>> {
  @override
  Future<List<Board>> build() async {
    final repo = ref.read(boardRepositoryProvider);
    return repo.getBoards();
  }

  /// Creates a new board with default columns and owner membership.
  ///
  /// Returns the new board ID for navigation.
  Future<String> createBoard(String name) async {
    final repo = ref.read(boardRepositoryProvider);
    final boardId = await repo.createBoard(name);
    ref.invalidateSelf(); // Refresh list
    return boardId;
  }

  /// Deletes a board (owner only, enforced by RLS).
  Future<void> deleteBoard(String boardId) async {
    final repo = ref.read(boardRepositoryProvider);
    await repo.deleteBoard(boardId);
    ref.invalidateSelf();
  }

  /// Forces a refresh of the board list from the server.
  Future<void> refresh() async {
    ref.invalidateSelf();
  }
}
