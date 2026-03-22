import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/completion_pattern.dart';
import '../domain/notification_preferences.dart';

/// Repository for notification-related Supabase operations.
///
/// Handles CRUD for notification preferences, FCM token storage on the
/// profiles table, and completion pattern recording for adaptive timing.
///
/// Accepts an optional [SupabaseClient] for dependency injection in tests.
class NotificationRepository {
  NotificationRepository([SupabaseClient? client])
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  /// Fetches the notification preferences for a given user.
  ///
  /// Returns the parsed [NotificationPreferences] model. Throws if no
  /// record exists (should have been auto-created by the DB trigger).
  Future<NotificationPreferences> getPreferences(String userId) async {
    final response = await _client
        .from('notification_preferences')
        .select()
        .eq('user_id', userId)
        .single();
    return NotificationPreferences.fromJson(response);
  }

  /// Updates the notification preferences for a user.
  ///
  /// Uses the `user_id` from [prefs] to identify the row.
  Future<void> updatePreferences(NotificationPreferences prefs) async {
    await _client
        .from('notification_preferences')
        .update(prefs.toJson())
        .eq('user_id', prefs.userId);
  }

  /// Stores an FCM token on the user's profile row.
  ///
  /// Called after obtaining a token from FirebaseMessaging and on token
  /// refresh events.
  Future<void> storeFcmToken(String userId, String token) async {
    await _client.from('profiles').update({
      'fcm_token': token,
      'fcm_token_updated_at': DateTime.now().toIso8601String(),
    }).eq('id', userId);
  }

  /// Clears the FCM token from the user's profile row.
  ///
  /// Called on sign-out to stop delivering push notifications.
  Future<void> clearFcmToken(String userId) async {
    await _client.from('profiles').update({
      'fcm_token': null,
      'fcm_token_updated_at': null,
    }).eq('id', userId);
  }

  /// Records a task/habit completion event for adaptive timing analysis.
  Future<void> recordCompletion(CompletionPattern pattern) async {
    await _client.from('completion_patterns').insert(pattern.toJson());
  }

  /// Fetches recent completion patterns for a user.
  ///
  /// Returns patterns from the last [days] days (default 14), ordered by
  /// most recent first. Used by the adaptive timing algorithm.
  Future<List<CompletionPattern>> getRecentCompletions(
    String userId, {
    int days = 14,
  }) async {
    final cutoff =
        DateTime.now().subtract(Duration(days: days)).toIso8601String();
    final response = await _client
        .from('completion_patterns')
        .select()
        .eq('user_id', userId)
        .gte('created_at', cutoff)
        .order('created_at', ascending: false);
    return (response as List)
        .map((row) => CompletionPattern.fromJson(row as Map<String, dynamic>))
        .toList();
  }
}
