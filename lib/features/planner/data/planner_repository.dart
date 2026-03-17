import 'package:supabase_flutter/supabase_flutter.dart';

import '../../profile/domain/profile_model.dart';
import '../domain/plannable_item_model.dart';
import '../domain/schedule_block_model.dart';

/// Repository for planner operations: CRUD on plannable items,
/// AI schedule generation via Edge Function, and schedule caching.
///
/// Accepts an optional [SupabaseClient] for dependency injection in tests.
class PlannerRepository {
  PlannerRepository([SupabaseClient? client])
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  /// Fetches all plannable items for the given [userId] and [date].
  Future<List<PlannableItem>> getItems(String userId, DateTime date) async {
    final dateStr = date.toIso8601String().split('T').first;
    final data = await _client
        .from('plannable_items')
        .select()
        .eq('user_id', userId)
        .eq('plan_date', dateStr)
        .order('created_at');
    return (data as List).map((row) => PlannableItem.fromJson(row)).toList();
  }

  /// Adds a new plannable item and returns the created item.
  Future<PlannableItem> addItem({
    required String userId,
    required String title,
    required int durationMinutes,
    required EnergyLevel energyLevel,
    required DateTime planDate,
  }) async {
    final data = await _client
        .from('plannable_items')
        .insert({
          'user_id': userId,
          'title': title,
          'duration_minutes': durationMinutes,
          'energy_level': energyLevel.name,
          'plan_date': planDate.toIso8601String().split('T').first,
        })
        .select()
        .single();
    return PlannableItem.fromJson(data);
  }

  /// Updates an existing plannable item.
  Future<void> updateItem(PlannableItem item) async {
    await _client
        .from('plannable_items')
        .update({
          'title': item.title,
          'duration_minutes': item.durationMinutes,
          'energy_level': item.energyLevel.name,
          'plan_date': item.planDate.toIso8601String().split('T').first,
        })
        .eq('id', item.id);
  }

  /// Deletes a plannable item by its [itemId].
  Future<void> deleteItem(String itemId) async {
    await _client.from('plannable_items').delete().eq('id', itemId);
  }

  /// Invokes the `generate-schedule` Edge Function with the given items
  /// and energy pattern, returning the AI-generated schedule blocks.
  Future<List<ScheduleBlock>> generateSchedule({
    required List<PlannableItem> items,
    required EnergyPattern energyPattern,
    String? constraints,
  }) async {
    final response = await _client.functions.invoke(
      'generate-schedule',
      body: {
        'items': items.map((i) => i.toEdgeFunctionJson()).toList(),
        'energyPattern': energyPattern.toJson(),
        'constraints': constraints,
      },
    );

    if (response.status != 200) {
      final errorData = response.data;
      throw Exception(
        'Schedule generation failed: ${errorData is Map ? errorData['error'] : errorData}',
      );
    }

    final data = response.data as Map<String, dynamic>;
    final blocks = (data['blocks'] as List)
        .map((b) => ScheduleBlock.fromJson(b as Map<String, dynamic>))
        .toList();
    return blocks;
  }

  /// Saves (upserts) the generated schedule blocks for the given date.
  Future<void> saveSchedule({
    required String userId,
    required DateTime planDate,
    required List<ScheduleBlock> blocks,
    String? constraintsText,
  }) async {
    await _client.from('generated_schedules').upsert(
      {
        'user_id': userId,
        'plan_date': planDate.toIso8601String().split('T').first,
        'schedule_blocks': blocks.map((b) => b.toJson()).toList(),
        'constraints_text': constraintsText,
      },
      onConflict: 'user_id,plan_date',
    );
  }

  /// Loads a previously cached schedule for the given [userId] and [date].
  ///
  /// Returns `null` if no schedule exists for that date.
  Future<List<ScheduleBlock>?> loadCachedSchedule(
    String userId,
    DateTime date,
  ) async {
    final dateStr = date.toIso8601String().split('T').first;
    final data = await _client
        .from('generated_schedules')
        .select()
        .eq('user_id', userId)
        .eq('plan_date', dateStr)
        .maybeSingle();

    if (data == null) return null;

    final blocks = (data['schedule_blocks'] as List)
        .map((b) => ScheduleBlock.fromJson(b as Map<String, dynamic>))
        .toList();
    return blocks;
  }
}
