import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/notification_repository.dart';
import '../../domain/notification_preferences.dart';

/// Provides a singleton [NotificationRepository] instance.
///
/// Uses the default Supabase client. Override in tests via
/// `container.updateOverrides`.
final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  return NotificationRepository();
});

/// Fetches [NotificationPreferences] for the given [userId].
///
/// Uses `FutureProvider.family` so each user's preferences are cached
/// independently. Invalidate with `ref.invalidate(notificationPreferencesProvider)`.
final notificationPreferencesProvider =
    FutureProvider.family<NotificationPreferences, String>(
        (ref, userId) async {
  final repo = ref.watch(notificationRepositoryProvider);
  return repo.getPreferences(userId);
});
