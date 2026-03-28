import 'dart:convert';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../constants/supabase_constants.dart';
import '../../features/notifications/data/notification_repository.dart';
import '../../features/notifications/domain/completion_pattern.dart';
import '../../features/tasks/data/task_repository.dart';
import '../../features/habits/data/habit_repository.dart';

/// Global navigator key used for deep-link navigation from notification taps.
///
/// Must be attached to the root [MaterialApp.router] navigator. The
/// [NotificationService] uses this to navigate when a notification is tapped.
final GlobalKey<NavigatorState> notificationNavigatorKey =
    GlobalKey<NavigatorState>();

// ---------------------------------------------------------------------------
// Top-level helpers for background isolate (must be static / top-level)
// ---------------------------------------------------------------------------

/// Returns the notification channel ID for a given reminder type string.
String _channelIdForType(String type) {
  switch (type) {
    case 'task_deadline':
      return 'task_reminders';
    case 'habit_reminder':
      return 'habit_reminders';
    case 'planner_summary':
    case 'planner_block':
      return 'planner_notifications';
    default:
      return 'task_reminders';
  }
}

/// Returns a human-readable channel name for a given channel ID.
String _channelNameForId(String id) {
  switch (id) {
    case 'task_reminders':
      return 'Task Reminders';
    case 'habit_reminders':
      return 'Habit Reminders';
    case 'planner_notifications':
      return 'Planner Notifications';
    default:
      return 'Notifications';
  }
}

/// Top-level background message handler for FCM data-only messages.
///
/// Runs in a separate isolate, so it cannot access instance state. Displays
/// the notification locally with action buttons.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();

  final plugin = FlutterLocalNotificationsPlugin();
  await plugin.initialize(
    settings: const InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
    ),
    onDidReceiveBackgroundNotificationResponse: onBackgroundNotificationAction,
  );

  final data = message.data;
  final channelId = _channelIdForType(data['type'] ?? '');
  final channelName = _channelNameForId(channelId);

  await plugin.show(
    id: message.hashCode,
    title: data['title'] ?? '',
    body: data['body'] ?? '',
    notificationDetails: NotificationDetails(
      android: AndroidNotificationDetails(
        channelId,
        channelName,
        importance: channelId == 'task_reminders'
            ? Importance.high
            : Importance.defaultImportance,
        subText: data['insight'],
        actions: const [
          AndroidNotificationAction('complete', 'Complete',
              cancelNotification: true),
          AndroidNotificationAction('snooze', 'Snooze',
              cancelNotification: true),
        ],
      ),
    ),
    payload: jsonEncode({
      'type': data['type'],
      'item_id': data['item_id'],
      'route': data['route'],
      'title': data['title'] ?? '',
      'body': data['body'] ?? '',
    }),
  );
}

/// Top-level action handler for notification button taps (background).
///
/// Runs in the background isolate. Parses the payload to determine action.
/// - 'complete': Marks the task/habit as complete via domain repositories.
/// - 'snooze': Inserts a new scheduled_reminder using user's snooze preference.
@pragma('vm:entry-point')
void onBackgroundNotificationAction(NotificationResponse response) async {
  if (response.payload == null) return;

  final payload = jsonDecode(response.payload!) as Map<String, dynamic>;
  final actionId = response.actionId;
  final itemId = payload['item_id'] as String?;
  final type = payload['type'] as String?;

  if (itemId == null || type == null) return;

  try {
    // Re-initialize Supabase in the background isolate. The persisted session
    // is restored from local storage, so the client is authenticated.
    try {
      await Supabase.initialize(
        url: SupabaseConstants.url,
        anonKey: SupabaseConstants.anonKey,
      );
    } catch (_) {
      // Already initialized (e.g. foreground isolate still alive).
    }
    final client = Supabase.instance.client;
    final userId = client.auth.currentUser?.id;

    if (actionId == 'complete') {
      if (type == 'task_deadline') {
        final taskRepo = TaskRepository(client);
        final task = await taskRepo.getTaskById(itemId);
        if (task != null && !task.isCompleted) {
          final completed = task.copyWith(
            isCompleted: true,
            completedAt: DateTime.now(),
          );
          await taskRepo.updateTask(completed);

          // Record completion for adaptive timing
          if (userId != null) {
            final notifRepo = NotificationRepository(client);
            await notifRepo.recordCompletion(CompletionPattern(
              id: '',
              userId: userId,
              itemType: 'task',
              itemId: itemId,
              deadlineAt: task.deadline,
              completedAt: DateTime.now(),
              createdAt: DateTime.now(),
            ));
          }
        }
      } else if (type == 'habit_reminder') {
        final habitRepo = HabitRepository(client);
        await habitRepo.logCompletion(itemId);

        // Record completion for adaptive timing
        if (userId != null) {
          final notifRepo = NotificationRepository(client);
          await notifRepo.recordCompletion(CompletionPattern(
            id: '',
            userId: userId,
            itemType: 'habit',
            itemId: itemId,
            completedAt: DateTime.now(),
            createdAt: DateTime.now(),
          ));
        }
      }
    } else if (actionId == 'snooze') {
      if (userId != null) {
        // Read user's snooze duration from notification_preferences
        final prefsData = await client
            .from('notification_preferences')
            .select('snooze_duration')
            .eq('user_id', userId)
            .single();
        final snoozeDuration = prefsData['snooze_duration'] as int? ?? 15;

        await client.from('scheduled_reminders').insert({
          'user_id': userId,
          'reminder_type': type,
          'item_id': itemId,
          'remind_at': DateTime.now()
              .add(Duration(minutes: snoozeDuration))
              .toUtc()
              .toIso8601String(),
          'title': payload['title'] ?? 'Reminder',
          'body': payload['body'] ?? '',
          'deep_link_route': payload['route'],
        });
      }
    }
  } catch (e) {
    debugPrint('NotificationAction error ($actionId): $e');
  }
}

// ---------------------------------------------------------------------------
// NotificationService singleton
// ---------------------------------------------------------------------------

/// Central notification orchestrator for the Flutter client.
///
/// Handles FCM initialization, permission requests, notification channel
/// creation, local notification display with action buttons, FCM token
/// lifecycle management, and deep-link navigation from all app states
/// (foreground, background, terminated).
///
/// Usage:
/// ```dart
/// await NotificationService().initialize();
/// ```
class NotificationService {
  static final NotificationService _instance = NotificationService._();

  factory NotificationService() => _instance;

  NotificationService._();

  /// Pending deep-link route from a cold-start notification tap.
  /// Stored during initialize(), consumed once by the router redirect.
  static String? _pendingDeepLink;

  /// Returns and clears the pending deep-link route. Returns null if none.
  static String? consumePendingDeepLink() {
    final link = _pendingDeepLink;
    _pendingDeepLink = null;
    return link;
  }

  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  /// The three Android notification channels.
  static const _taskChannel = AndroidNotificationChannel(
    'task_reminders',
    'Task Reminders',
    description: 'Reminders for upcoming task deadlines',
    importance: Importance.high,
  );

  static const _habitChannel = AndroidNotificationChannel(
    'habit_reminders',
    'Habit Reminders',
    description: 'Daily habit reminders and summaries',
    importance: Importance.defaultImportance,
  );

  static const _plannerChannel = AndroidNotificationChannel(
    'planner_notifications',
    'Planner Notifications',
    description: 'Daily plan summaries and time-block reminders',
    importance: Importance.defaultImportance,
  );

  /// Returns the appropriate [AndroidNotificationChannel] for a reminder type.
  AndroidNotificationChannel _channelForType(String type) {
    switch (type) {
      case 'task_deadline':
        return _taskChannel;
      case 'habit_reminder':
        return _habitChannel;
      case 'planner_summary':
      case 'planner_block':
        return _plannerChannel;
      default:
        return _taskChannel;
    }
  }

  /// Initializes FCM, creates notification channels, and sets up listeners.
  ///
  /// Must be called once during app startup (after Firebase.initializeApp).
  Future<void> initialize() async {
    // 1. Request notification permission (Android 13+ POST_NOTIFICATIONS).
    await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // 2. Create Android notification channels.
    final androidPlugin =
        _localNotifications.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.createNotificationChannel(_taskChannel);
    await androidPlugin?.createNotificationChannel(_habitChannel);
    await androidPlugin?.createNotificationChannel(_plannerChannel);

    // 3. Initialize local notifications plugin.
    await _localNotifications.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      ),
      onDidReceiveNotificationResponse: _onNotificationTap,
      onDidReceiveBackgroundNotificationResponse:
          onBackgroundNotificationAction,
    );

    // 4. Listen for foreground FCM messages and display as local notification.
    FirebaseMessaging.onMessage.listen(_showLocalNotification);

    // 5. Register the top-level background message handler.
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    // 6. Handle notification tap when app is in background (not terminated).
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);

    // 7. Handle notification tap that launched the app from terminated state.
    final initialMessage =
        await FirebaseMessaging.instance.getInitialMessage();
    if (initialMessage != null) {
      // On cold start, navigator context does not exist yet.
      // Store the route for consumption by the router redirect.
      _pendingDeepLink = initialMessage.data['route'] as String?;
    }
  }

  /// Displays a foreground FCM data message as a local notification.
  void _showLocalNotification(RemoteMessage message) {
    final data = message.data;
    final channel = _channelForType(data['type'] ?? '');

    _localNotifications.show(
      id: message.hashCode,
      title: data['title'] ?? '',
      body: data['body'] ?? '',
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          channel.id,
          channel.name,
          channelDescription: channel.description,
          importance: channel.importance,
          subText: data['insight'],
          actions: const [
            AndroidNotificationAction('complete', 'Complete',
                cancelNotification: true),
            AndroidNotificationAction('snooze', 'Snooze',
                cancelNotification: true),
          ],
        ),
      ),
      payload: jsonEncode({
        'type': data['type'],
        'item_id': data['item_id'],
        'route': data['route'],
        'title': data['title'] ?? '',
        'body': data['body'] ?? '',
      }),
    );
  }

  /// Handles taps on local notifications and action buttons (foreground).
  ///
  /// If an action button was pressed, delegates to [_handleComplete] or
  /// [_handleSnooze]. Otherwise extracts the `route` from the payload and
  /// navigates using GoRouter via the [notificationNavigatorKey].
  void _onNotificationTap(NotificationResponse response) {
    if (response.payload == null) return;

    final payload = jsonDecode(response.payload!) as Map<String, dynamic>;
    final actionId = response.actionId;

    if (actionId == 'complete') {
      _handleComplete(payload);
    } else if (actionId == 'snooze') {
      _handleSnooze(payload);
    } else {
      // Body tap — navigate via deep link.
      final route = payload['route'] as String?;
      if (route != null && notificationNavigatorKey.currentContext != null) {
        GoRouter.of(notificationNavigatorKey.currentContext!).push(route);
      }
    }
  }

  /// Handles a FCM message that opened the app from background/terminated.
  ///
  /// Extracts the deep link route from message data and navigates.
  void _handleMessageOpenedApp(RemoteMessage message) {
    final route = message.data['route'] as String?;
    if (route != null && notificationNavigatorKey.currentContext != null) {
      GoRouter.of(notificationNavigatorKey.currentContext!).push(route);
    }
  }

  /// Marks a task as completed or records a habit log via domain repositories.
  Future<void> _handleComplete(Map<String, dynamic> payload) async {
    final itemId = payload['item_id'] as String?;
    final type = payload['type'] as String?;
    if (itemId == null || type == null) return;

    try {
      final client = Supabase.instance.client;
      final userId = client.auth.currentUser?.id;

      if (type == 'task_deadline') {
        final taskRepo = TaskRepository(client);
        final task = await taskRepo.getTaskById(itemId);
        if (task != null && !task.isCompleted) {
          final completed = task.copyWith(
            isCompleted: true,
            completedAt: DateTime.now(),
          );
          await taskRepo.updateTask(completed);

          // Record completion for adaptive timing
          if (userId != null) {
            final notifRepo = NotificationRepository(client);
            await notifRepo.recordCompletion(CompletionPattern(
              id: '',
              userId: userId,
              itemType: 'task',
              itemId: itemId,
              deadlineAt: task.deadline,
              completedAt: DateTime.now(),
              createdAt: DateTime.now(),
            ));
          }
        }
      } else if (type == 'habit_reminder') {
        final habitRepo = HabitRepository(client);
        await habitRepo.logCompletion(itemId);

        // Record completion for adaptive timing
        if (userId != null) {
          final notifRepo = NotificationRepository(client);
          await notifRepo.recordCompletion(CompletionPattern(
            id: '',
            userId: userId,
            itemType: 'habit',
            itemId: itemId,
            completedAt: DateTime.now(),
            createdAt: DateTime.now(),
          ));
        }
      }
    } catch (e) {
      debugPrint('NotificationAction complete error: $e');
    }
  }

  /// Snoozes a notification by inserting a new scheduled reminder using the
  /// user's configured snooze duration from notification_preferences.
  Future<void> _handleSnooze(Map<String, dynamic> payload) async {
    final itemId = payload['item_id'] as String?;
    final type = payload['type'] as String?;
    if (itemId == null || type == null) return;

    try {
      final client = Supabase.instance.client;
      final userId = client.auth.currentUser?.id;
      if (userId == null) return;

      // Read user's snooze duration from notification_preferences
      final prefsData = await client
          .from('notification_preferences')
          .select('snooze_duration')
          .eq('user_id', userId)
          .single();
      final snoozeDuration = prefsData['snooze_duration'] as int? ?? 15;

      await client.from('scheduled_reminders').insert({
        'user_id': userId,
        'reminder_type': type,
        'item_id': itemId,
        'remind_at': DateTime.now()
            .add(Duration(minutes: snoozeDuration))
            .toUtc()
            .toIso8601String(),
        'title': payload['title'] ?? 'Reminder',
        'body': payload['body'] ?? '',
        'deep_link_route': payload['route'],
      });
    } catch (e) {
      debugPrint('NotificationAction snooze error: $e');
    }
  }

  /// Obtains the FCM token and stores it, then listens for refreshes.
  ///
  /// Call after the user signs in so push notifications can be delivered.
  Future<void> manageFcmToken(
    String userId,
    NotificationRepository repo,
  ) async {
    final token = await FirebaseMessaging.instance.getToken();
    if (token != null) {
      await repo.storeFcmToken(userId, token);
    }

    FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
      repo.storeFcmToken(userId, newToken);
    });
  }

  /// Clears the FCM token from the server and deletes it locally.
  ///
  /// Call on sign-out to stop delivering push notifications.
  Future<void> clearToken(
    String userId,
    NotificationRepository repo,
  ) async {
    await repo.clearFcmToken(userId);
    await FirebaseMessaging.instance.deleteToken();
  }
}
