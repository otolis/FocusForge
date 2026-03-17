import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/planner_repository.dart';
import '../../domain/plannable_item_model.dart';

/// Provides the [PlannerRepository] singleton instance.
final plannerRepositoryProvider = Provider<PlannerRepository>(
  (ref) => PlannerRepository(),
);

/// Manages the list of plannable items for a specific user and date.
///
/// Tracks the selected date internally and reloads items when the date changes.
/// Supports full CRUD operations that automatically refresh the item list.
class PlannableItemsNotifier
    extends StateNotifier<AsyncValue<List<PlannableItem>>> {
  PlannableItemsNotifier(this._repo, this._userId)
      : super(const AsyncValue.loading());

  final PlannerRepository _repo;
  final String _userId;
  DateTime _selectedDate = DateTime(
    DateTime.now().year,
    DateTime.now().month,
    DateTime.now().day,
  );

  /// The currently selected planning date.
  DateTime get selectedDate => _selectedDate;

  /// Changes the selected date and reloads items.
  Future<void> setDate(DateTime date) async {
    _selectedDate = DateTime(date.year, date.month, date.day);
    await loadItems();
  }

  /// Fetches plannable items from the repository for the current date.
  Future<void> loadItems() async {
    state = const AsyncValue.loading();
    try {
      final items = await _repo.getItems(_userId, _selectedDate);
      state = AsyncValue.data(items);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Adds a new plannable item and refreshes the list.
  Future<void> addItem({
    required String title,
    required int durationMinutes,
    required EnergyLevel energyLevel,
  }) async {
    await _repo.addItem(
      userId: _userId,
      title: title,
      durationMinutes: durationMinutes,
      energyLevel: energyLevel,
      planDate: _selectedDate,
    );
    await loadItems();
  }

  /// Deletes a plannable item by ID and refreshes the list.
  Future<void> deleteItem(String itemId) async {
    await _repo.deleteItem(itemId);
    await loadItems();
  }

  /// Updates an existing plannable item and refreshes the list.
  Future<void> updateItem(PlannableItem item) async {
    await _repo.updateItem(item);
    await loadItems();
  }
}

/// Provides the [PlannableItemsNotifier] for a specific user.
///
/// Usage: `ref.watch(plannableItemsProvider(userId))` returns
/// `AsyncValue<List<PlannableItem>>`.
final plannableItemsProvider = StateNotifierProvider.family<
    PlannableItemsNotifier, AsyncValue<List<PlannableItem>>, String>(
  (ref, userId) {
    final repo = ref.read(plannerRepositoryProvider);
    return PlannableItemsNotifier(repo, userId)..loadItems();
  },
);
