import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../profile/domain/profile_model.dart';
import '../../data/planner_repository.dart';
import '../../domain/plannable_item_model.dart';
import '../../domain/schedule_block_model.dart';
import '../../domain/timeline_constants.dart';
import 'plannable_items_provider.dart';

/// Immutable state for the AI daily planner.
///
/// Tracks the generated schedule blocks, generation status, errors,
/// and user-provided constraints text.
class PlannerState {
  final List<ScheduleBlock> blocks;
  final bool isGenerating;
  final String? error;
  final String? constraintsText;

  const PlannerState({
    this.blocks = const [],
    this.isGenerating = false,
    this.error,
    this.constraintsText,
  });

  PlannerState copyWith({
    List<ScheduleBlock>? blocks,
    bool? isGenerating,
    String? error,
    String? constraintsText,
  }) {
    return PlannerState(
      blocks: blocks ?? this.blocks,
      isGenerating: isGenerating ?? this.isGenerating,
      error: error,
      constraintsText: constraintsText ?? this.constraintsText,
    );
  }
}

/// Manages the AI-generated schedule: generation, caching, and block movement.
///
/// Depends on [PlannerRepository] for Edge Function invocation and
/// database persistence. Uses [TimelineConstants.resolveOverlaps] to
/// ensure blocks never overlap after generation or manual moves.
class PlannerNotifier extends StateNotifier<PlannerState> {
  PlannerNotifier(this._repo, this._userId) : super(const PlannerState());

  final PlannerRepository _repo;
  final String _userId;

  /// Loads a previously cached schedule for the given [date].
  ///
  /// If no cached schedule exists, sets blocks to an empty list.
  /// Always clears any stale error from a previous generation attempt.
  Future<void> loadCachedSchedule(DateTime date) async {
    final cached = await _repo.loadCachedSchedule(_userId, date);
    if (cached != null) {
      state = state.copyWith(blocks: cached, error: null);
    } else {
      state = state.copyWith(blocks: [], error: null);
    }
  }

  /// Generates a new schedule via the Edge Function and caches it.
  ///
  /// Sets [PlannerState.isGenerating] during the API call. On success,
  /// resolves overlaps and saves to the database. On failure, sets the
  /// error message.
  ///
  /// The caching step (saveSchedule) is wrapped in its own try-catch so
  /// a database error does not mask a successfully generated schedule.
  Future<void> generateSchedule({
    required List<PlannableItem> items,
    required EnergyPattern energyPattern,
    String? constraints,
  }) async {
    state = state.copyWith(isGenerating: true, error: null);
    try {
      final blocks = await _repo.generateSchedule(
        items: items,
        energyPattern: energyPattern,
        constraints: constraints,
      );
      final resolved = TimelineConstants.resolveOverlaps(blocks);
      state = state.copyWith(blocks: resolved, isGenerating: false);

      // Cache the generated schedule. Errors here should not hide the
      // successfully generated blocks from the UI.
      try {
        await _repo.saveSchedule(
          userId: _userId,
          planDate: DateTime.now(),
          blocks: resolved,
          constraintsText: constraints,
        );
      } catch (cacheError) {
        // Log but do not propagate — the schedule is already displayed.
        assert(() {
          // ignore: avoid_print
          print('[PlannerNotifier] Failed to cache schedule: $cacheError');
          return true;
        }());
      }
    } catch (e, st) {
      debugPrint('[PlannerNotifier] generateSchedule FAILED: $e');
      debugPrint('[PlannerNotifier] Stack trace:\n$st');
      // Strip the leading "Exception: " prefix for cleaner display.
      final msg = e.toString();
      final display =
          msg.startsWith('Exception: ') ? msg.substring(11) : msg;
      state = state.copyWith(
        error: display,
        isGenerating: false,
      );
    }
  }

  /// Updates the user-provided constraints text.
  void updateConstraints(String? text) {
    state = state.copyWith(constraintsText: text);
  }

  /// Moves a block to a new start time and resolves any resulting overlaps.
  void moveBlock(String itemId, int newStartMinute) {
    final updatedBlocks = state.blocks.map((block) {
      if (block.itemId == itemId) {
        return block.copyWith(startMinute: newStartMinute);
      }
      return block;
    }).toList();

    final resolved = TimelineConstants.resolveOverlaps(updatedBlocks);
    state = state.copyWith(blocks: resolved);
  }

  /// Persists the current schedule to the database.
  Future<void> saveCurrentSchedule(DateTime planDate) async {
    await _repo.saveSchedule(
      userId: _userId,
      planDate: planDate,
      blocks: state.blocks,
      constraintsText: state.constraintsText,
    );
  }
}

/// Provides the [PlannerNotifier] for a specific user.
///
/// Usage: `ref.watch(plannerProvider(userId))` returns [PlannerState].
final plannerProvider =
    StateNotifierProvider.family<PlannerNotifier, PlannerState, String>(
  (ref, userId) {
    final repo = ref.read(plannerRepositoryProvider);
    return PlannerNotifier(repo, userId);
  },
);
