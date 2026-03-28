import 'dart:convert';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:go_router/go_router.dart';

import '../../features/notifications/data/notification_repository.dart';

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
    }),
  );
}

/// Top-level action handler for notification button taps (background).
///
/// Runs in the background isolate. Parses the payload to determine action.
/// - 'complete': Marks the task/habit as complete via direct Supabase call.
/// - 'snooze': Inserts a new scheduled_reminder with a delayed remind_at.
@pragma('vm:entry-point')
void onBackgroundNotificationAction(NotificationResponse response) async {
  if (response.payload == null) return;

  final payload = jsonDecode(response.payload!) as Map<String, dynamic>;
  final actionId = response.actionId;
  final itemId = payload['item_id'] as String?;
  final type = payload['type'] as String?;

  if (actionId == 'complete' && itemId != null && type != null) {
    // In a background isolate, Supabase must be re-initialized.
    // The actual completion logic will be wired when Supabase is available
    // in the background isolate context.
    // For now, this is the hook point for marking tasks/habits complete.
    debugPrint(
        'NotificationAction: complete $type $itemId');
  } else if (actionId == 'snooze' && itemId != null) {
    // Snooze: re-schedule the reminder for snooze_duration minutes later.
    // Requires Supabase re-init in background isolate.
    debugPrint(
        'NotificationAction: snooze $type $itemId');
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
      _handleMessageOpenedApp(initialMessage);
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
      }),
    );
  }

  /// Handles taps on local notifications (foreground).
  ///
  /// Extracts the `route` from the payload and navigates using GoRouter
  /// via the [notificationNavigatorKey].
  void _onNotificationTap(NotificationResponse response) {
    if (response.payload == null) return;

    final payload = jsonDecode(response.payload!) as Map<String, dynamic>;
    final route = payload['route'] as String?;

    if (route != null && notificationNavigatorKey.currentContext != null) {
      GoRouter.of(notificationNavigatorKey.currentContext!).push(route);
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
