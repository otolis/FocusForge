import 'dart:convert';

import 'package:flutter/foundation.dart';
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
  ///
  /// The Supabase SDK throws [FunctionException] for non-2xx responses,
  /// so callers should catch that (or a general [Exception]) for error
  /// handling. On success the SDK returns a [FunctionResponse] whose
  /// [data] is the already-decoded JSON body.
  ///
  /// The supabase_flutter SDK automatically includes the user's session JWT.
  Future<List<ScheduleBlock>> generateSchedule({
    required List<PlannableItem> items,
    required EnergyPattern energyPattern,
    String? constraints,
    DateTime? planDate,
  }) async {
    final body = {
      'items': items.map((i) => i.toEdgeFunctionJson()).toList(),
      'energyPattern': energyPattern.toJson(),
      'constraints': constraints,
      if (planDate != null) 'planDate': planDate.toIso8601String().split('T').first,
    };
    debugPrint('[PlannerRepo] Invoking generate-schedule with '
        '${items.length} items');

    final FunctionResponse response;
    try {
      response = await _client.functions.invoke(
        'generate-schedule',
        body: body,
      );
    } on FunctionException catch (e) {
      // The SDK throws FunctionException for non-2xx status codes.
      // Extract meaningful details for diagnosis.
      final details = e.details;
      final errorMsg = details is Map ? details['error'] ?? details : details;
      debugPrint('[PlannerRepo] FunctionException: '
          'status=${e.status}, '
          'reasonPhrase=${e.reasonPhrase}, '
          'details=$details');
      throw Exception(
        'Edge Function error (${e.status}): $errorMsg',
      );
    }

    var data = response.data;
    debugPrint('[PlannerRepo] Response status: ${response.status}, '
        'data type: ${data.runtimeType}');

    // The SDK decodes JSON responses automatically, but if the response
    // Content-Type is missing or unexpected, data arrives as a raw String.
    // Attempt manual JSON decoding as a fallback.
    if (data is String) {
      debugPrint('[PlannerRepo] Got String response, attempting JSON decode');
      final raw = data;
      try {
        data = jsonDecode(raw);
      } catch (_) {
        throw Exception(
          'Unexpected string response (not JSON). '
          'Preview: ${raw.length > 200 ? raw.substring(0, 200) : raw}',
        );
      }
    }

    if (data is! Map<String, dynamic>) {
      throw Exception(
        'Unexpected response type: ${data.runtimeType}. '
        'Preview: ${data.toString().length > 200 ? data.toString().substring(0, 200) : data}',
      );
    }

    final blocksList = data['blocks'];
    if (blocksList is! List) {
      throw Exception(
        'Schedule response missing "blocks" array. '
        'Response keys: ${data.keys.toList()}',
      );
    }

    debugPrint('[PlannerRepo] Parsing ${blocksList.length} blocks');
    return blocksList
        .map((b) => ScheduleBlock.fromJson(b as Map<String, dynamic>))
        .toList();
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

    // Schedule reminders for each time block (NOTIF-06)
    try {
      // Read user's planner block offset preference
      final prefsData = await _client
          .from('notification_preferences')
          .select('planner_block_offset, planner_block_reminders_enabled')
          .eq('user_id', userId)
          .maybeSingle();

      final blockRemindersEnabled =
          prefsData?['planner_block_reminders_enabled'] as bool? ?? true;
      if (!blockRemindersEnabled) return;

      final blockOffset = prefsData?['planner_block_offset'] as int? ?? 15;
      final dateStr = planDate.toIso8601String().split('T').first;

      // Delete existing unsent planner reminders for this date
      final startOfDay = DateTime.parse('${dateStr}T00:00:00Z');
      final endOfDay = DateTime.parse('${dateStr}T23:59:59Z');
      await _client
          .from('scheduled_reminders')
          .delete()
          .eq('user_id', userId)
          .eq('reminder_type', 'planner_block')
          .eq('sent', false)
          .gte('remind_at', startOfDay.toIso8601String())
          .lte('remind_at', endOfDay.toIso8601String());

      final now = DateTime.now();
      for (final block in blocks) {
        // Convert startMinute to a DateTime on planDate
        final blockStart = DateTime(
          planDate.year,
          planDate.month,
          planDate.day,
          block.startMinute ~/ 60,
          block.startMinute % 60,
        );
        final remindAt = blockStart.subtract(Duration(minutes: blockOffset));

        if (remindAt.isAfter(now)) {
          await _client.from('scheduled_reminders').insert({
            'user_id': userId,
            'reminder_type': 'planner_block',
            'item_id': block.itemId,
            'remind_at': remindAt.toUtc().toIso8601String(),
            'title': 'Time block starting soon',
            'body': block.title,
            'deep_link_route': '/planner',
          });
        }
      }
    } catch (e) {
      // Non-critical: don't fail schedule save if reminder scheduling fails
      debugPrint('Planner reminder scheduling error: $e');
    }
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
