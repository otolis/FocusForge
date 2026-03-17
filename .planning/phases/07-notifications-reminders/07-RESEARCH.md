# Phase 7: Notifications & Reminders - Research

**Researched:** 2026-03-18
**Domain:** FCM Push Notifications, Supabase Edge Functions (Deno), Adaptive Reminder Timing, Flutter Notification Handling
**Confidence:** MEDIUM-HIGH

## Summary

Phase 7 implements push notifications for task deadlines, habit reminders, and planner time blocks. The architecture is server-driven: a Supabase Edge Function runs on a pg_cron schedule, queries upcoming reminders, and sends FCM push notifications via the HTTP v1 API. On the Flutter side, `firebase_messaging` receives messages while `flutter_local_notifications` displays them with action buttons (Complete/Snooze), since FCM natively does not support notification action buttons.

A critical architectural finding is the FCM message type choice. **Data-only messages** (not notification messages) should be sent from the server. This gives the Flutter app full control over notification display via `flutter_local_notifications`, enabling action buttons in all app states (foreground, background, terminated). Data-only messages with `priority: "high"` on Android bypass Doze mode throttling. The `onBackgroundMessage` handler in `firebase_messaging` will intercept these and create local notifications with `flutter_local_notifications`.

The adaptive timing system tracks task completion proximity (how close to deadline) and time-of-day responsiveness over a 2-week rolling window. This data drives adjustments to reminder offsets. The logic lives server-side in the Edge Function so it works regardless of app state.

**Primary recommendation:** Send data-only FCM messages from a cron-triggered Edge Function; use `flutter_local_notifications` to display all notifications with action buttons; store adaptive timing data in a `completion_patterns` table that the Edge Function queries.

<user_constraints>

## User Constraints (from CONTEXT.md)

### Locked Decisions
- **Three notification sources**: task deadlines, habit check-in reminders, and AI planner time block notifications
- **Task deadlines**: two-stage default reminders (1 day before + 1 hour before). User can customize timing per task
- **Habit reminders**: per-habit reminder time if set by user (e.g., "Meditate" at 7 AM); fallback to global daily summary reminder for habits without a specific time (e.g., 8 AM -- "You have 3 habits to do today")
- **Planner time blocks**: morning summary notification when the day's plan is ready ("Your plan for today is ready -- 6 items scheduled") + individual time block reminders before each block starts. Users can toggle block-level reminders off independently
- **Dual-signal adaptation**: tracks both deadline proximity patterns (how close to deadline user completes tasks) AND time-of-day responsiveness (when user acts on notifications vs ignores them)
- **If procrastinating**: shift task reminders earlier (e.g., from 1hr to 3hrs before deadline)
- **If responsive window detected**: shift reminders to times user is most likely to act
- **Data window**: last 2 weeks of completion data -- adapts quickly to changing behavior, good for portfolio demo
- **Transparent adaptation**: show a small insight when timing changes (e.g., "Reminder moved earlier -- you tend to complete tasks closer to deadline"). Displayed as a subtitle on the notification or in notification history
- **Category-level defaults**: separate timing/toggle controls for tasks, habits, and planner notifications in settings
- **Per-task override**: optional custom reminder timing on task creation/edit form (overrides category default)
- **Quiet hours**: configurable time range picker (e.g., 10 PM -- 7 AM) during which no notifications fire
- **Master toggle**: global notifications on/off at the top
- **Server-side only**: Supabase Edge Function on cron schedule checks upcoming deadlines/reminders and sends FCM push notifications
- **Actionable notifications**: include "Complete" and "Snooze" action buttons directly on notifications -- user can act without opening the app
- **Tap action**: tapping the notification body opens the app to the relevant item (task detail, habit, planner)
- **FCM integration**: firebase_messaging Flutter package for receiving push; server sends via FCM HTTP API from Edge Function

### Claude's Discretion
- Notification preferences screen layout vs inline settings section
- Cron frequency for the reminder check Edge Function
- Exact adaptive algorithm implementation (weighted averages, simple heuristics, etc.)
- Database schema for notification preferences, reminder schedules, and completion tracking
- FCM token management and refresh strategy
- Notification channel/category configuration for Android
- Snooze duration options (5/15/30 min or custom)
- Edge Function implementation details (Deno/TypeScript)
- How "Complete" action from notification triggers task/habit completion in Supabase

### Deferred Ideas (OUT OF SCOPE)
None -- discussion stayed within phase scope

</user_constraints>

<phase_requirements>

## Phase Requirements

| ID | Description | Research Support |
|----|-------------|-----------------|
| PLAN-04 | User receives adaptive reminders that learn from their completion patterns and adjust timing | Completion pattern tracking via `completion_patterns` table, rolling 2-week window analysis in Edge Function, weighted average algorithm for deadline proximity and time-of-day responsiveness |
| UX-03 | User receives FCM push notifications for deadline reminders with configurable timing | FCM HTTP v1 API from Edge Function, data-only messages with flutter_local_notifications for action buttons, notification_preferences table for user configuration |

</phase_requirements>

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| firebase_core | 4.5.0 | Firebase initialization | Required dependency for all Firebase services in Flutter |
| firebase_messaging | 16.1.2 | FCM token management, message reception, background handler | Official Flutter plugin for Firebase Cloud Messaging |
| flutter_local_notifications | 21.0.0 | Display notifications with action buttons, channels | Only way to show action buttons (Complete/Snooze) since FCM SDK does not support them |
| google-auth-library (npm) | 9.x | JWT auth for FCM HTTP v1 API in Edge Function | Official Google library for service account auth, used in Supabase's own FCM example |
| @supabase/supabase-js (npm) | 2.x | Supabase client in Edge Function | Official Supabase client for Deno Edge Functions |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| supabase_flutter | 2.12.0 (already installed) | Store FCM token, update completion data | Already in project -- used for token storage and notification preference CRUD |
| shared_preferences | 2.5.4 (already installed) | Cache notification preferences locally | Already in project -- for quick quiet hours / toggle checks |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| flutter_local_notifications | awesome_notifications | More features but heavier dependency, less established, flutter_local_notifications is the community standard |
| Data-only FCM messages | Notification messages | Notification messages are auto-displayed by FCM SDK but do NOT support action buttons -- defeats the "Complete"/"Snooze" requirement |
| pg_cron + Edge Function | Database webhook trigger | Webhook fires on INSERT to notifications table (reactive), but we need proactive polling of upcoming deadlines -- cron is correct |

**Installation (Flutter):**
```bash
flutter pub add firebase_core firebase_messaging flutter_local_notifications
```

**Installation (Edge Function):**
Dependencies are imported via npm specifiers in Deno -- no separate install step:
```typescript
import { createClient } from 'npm:@supabase/supabase-js@2'
import { JWT } from 'npm:google-auth-library@9'
```

## Architecture Patterns

### Recommended Project Structure
```
lib/
├── core/
│   └── services/
│       └── notification_service.dart      # FCM init, token management, local notification display
├── features/
│   └── notifications/
│       ├── data/
│       │   └── notification_repository.dart   # Supabase CRUD for preferences, token, completion data
│       ├── domain/
│       │   ├── notification_preferences.dart  # Preferences model (fromJson/toJson/copyWith)
│       │   └── completion_pattern.dart        # Completion pattern model for adaptive timing
│       └── presentation/
│           ├── screens/
│           │   └── notification_settings_screen.dart  # Dedicated notification preferences screen
│           ├── providers/
│           │   └── notification_providers.dart         # Riverpod providers for preferences
│           └── widgets/
│               ├── quiet_hours_picker.dart
│               ├── category_toggle_card.dart
│               └── reminder_offset_selector.dart
supabase/
├── functions/
│   ├── service-account.json               # Firebase service account key (gitignored)
│   └── send-reminders/
│       └── index.ts                       # Cron-triggered Edge Function
└── migrations/
    └── 000XX_create_notification_tables.sql
```

### Pattern 1: Data-Only FCM Message Architecture
**What:** Server sends data-only messages (no `notification` field, only `data` field). Flutter app handles all display via `flutter_local_notifications`.
**When to use:** Always -- this is the only way to get action buttons on notifications.
**Example:**
```typescript
// Edge Function: send data-only FCM message
// Source: https://supabase.com/docs/guides/functions/examples/push-notifications (adapted)
const res = await fetch(
  `https://fcm.googleapis.com/v1/projects/${serviceAccount.project_id}/messages:send`,
  {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      Authorization: `Bearer ${accessToken}`,
    },
    body: JSON.stringify({
      message: {
        token: fcmToken,
        data: {
          type: 'task_deadline',       // or 'habit_reminder', 'planner_summary', 'planner_block'
          item_id: taskId,
          title: 'Task deadline approaching',
          body: 'Submit report is due in 1 hour',
          insight: 'Reminder moved earlier -- you tend to complete tasks closer to deadline',
          route: '/tasks/detail/abc-123',  // deep link for tap navigation
        },
        android: {
          priority: 'high',  // bypasses Doze mode
        },
      },
    }),
  }
)
```

### Pattern 2: Flutter Notification Service (Singleton)
**What:** Centralized service that initializes FCM, manages token lifecycle, and displays local notifications with action buttons.
**When to use:** Called once at app startup, handles all notification display.
**Example:**
```dart
// Source: https://firebase.flutter.dev/docs/messaging/notifications/
class NotificationService {
  static final NotificationService _instance = NotificationService._();
  factory NotificationService() => _instance;
  NotificationService._();

  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  static const _taskChannel = AndroidNotificationChannel(
    'task_reminders',
    'Task Reminders',
    description: 'Notifications for upcoming task deadlines',
    importance: Importance.high,
  );

  static const _habitChannel = AndroidNotificationChannel(
    'habit_reminders',
    'Habit Reminders',
    description: 'Daily habit check-in reminders',
    importance: Importance.defaultImportance,
  );

  static const _plannerChannel = AndroidNotificationChannel(
    'planner_notifications',
    'Planner Notifications',
    description: 'Daily plan summaries and time block reminders',
    importance: Importance.defaultImportance,
  );

  Future<void> initialize() async {
    // Request permission
    await FirebaseMessaging.instance.requestPermission();

    // Create notification channels
    final androidPlugin = _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.createNotificationChannel(_taskChannel);
    await androidPlugin?.createNotificationChannel(_habitChannel);
    await androidPlugin?.createNotificationChannel(_plannerChannel);

    // Initialize local notifications with action handler
    await _localNotifications.initialize(
      const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      ),
      onDidReceiveNotificationResponse: _onNotificationTap,
      onDidReceiveBackgroundNotificationResponse: _onBackgroundAction,
    );

    // Listen for foreground data messages
    FirebaseMessaging.onMessage.listen(_showLocalNotification);
  }

  void _showLocalNotification(RemoteMessage message) {
    final data = message.data;
    final type = data['type'] ?? '';
    final channel = _channelForType(type);

    _localNotifications.show(
      message.hashCode,
      data['title'] ?? '',
      data['body'] ?? '',
      NotificationDetails(
        android: AndroidNotificationDetails(
          channel.id,
          channel.name,
          channelDescription: channel.description,
          importance: channel.importance,
          subText: data['insight'],  // Adaptive timing insight
          actions: [
            const AndroidNotificationAction(
              'complete', 'Complete',
              cancelNotification: true,
            ),
            const AndroidNotificationAction(
              'snooze', 'Snooze',
              cancelNotification: true,
            ),
          ],
        ),
      ),
      payload: data['route'],  // For deep link on tap
    );
  }
}
```

### Pattern 3: FCM Token Lifecycle Management
**What:** Get token on login, store in Supabase, refresh monthly, clear on logout.
**When to use:** User auth state changes.
**Example:**
```dart
// Source: https://firebase.google.com/docs/cloud-messaging/manage-tokens
Future<void> _manageFcmToken(String userId) async {
  // Get current token
  final token = await FirebaseMessaging.instance.getToken();
  if (token != null) {
    await _supabase.from('profiles').update({
      'fcm_token': token,
      'fcm_token_updated_at': DateTime.now().toIso8601String(),
    }).eq('id', userId);
  }

  // Listen for token refresh
  FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
    await _supabase.from('profiles').update({
      'fcm_token': newToken,
      'fcm_token_updated_at': DateTime.now().toIso8601String(),
    }).eq('id', userId);
  });
}
```

### Pattern 4: Background Message Handler (Top-Level Function)
**What:** A top-level function that handles FCM data messages when app is in background/terminated.
**When to use:** Required for data-only messages to display notifications when app is not in foreground.
**Example:**
```dart
// MUST be top-level function (not a class method)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();

  // Initialize local notifications plugin
  final plugin = FlutterLocalNotificationsPlugin();
  await plugin.initialize(
    const InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
    ),
    onDidReceiveBackgroundNotificationResponse: _onBackgroundAction,
  );

  // Display notification with action buttons
  final data = message.data;
  await plugin.show(
    message.hashCode,
    data['title'] ?? '',
    data['body'] ?? '',
    NotificationDetails(
      android: AndroidNotificationDetails(
        'task_reminders',
        'Task Reminders',
        importance: Importance.high,
        actions: [
          const AndroidNotificationAction('complete', 'Complete', cancelNotification: true),
          const AndroidNotificationAction('snooze', 'Snooze', cancelNotification: true),
        ],
      ),
    ),
    payload: data['route'],
  );
}

// Also MUST be top-level
@pragma('vm:entry-point')
void _onBackgroundAction(NotificationResponse response) {
  // Handle "Complete" or "Snooze" action in background
  // This runs in an isolate -- use direct Supabase calls, not Riverpod
}
```

### Anti-Patterns to Avoid
- **Sending notification messages from server:** FCM SDK auto-displays these without action buttons. You lose control over display. Always send data-only messages.
- **Relying on data-only messages without high priority:** Normal priority data messages are throttled/dropped by Android Doze mode. Always set `android.priority: "high"`.
- **Putting background handler inside a class:** `onBackgroundMessage` handler MUST be a top-level or static function. It runs in a separate isolate.
- **Using Riverpod in background handler:** Background handlers run in a separate isolate without access to the provider tree. Use direct Supabase client calls instead.
- **Scheduling local notifications from the app:** The user decision is server-side delivery only. Do NOT use `flutter_local_notifications` scheduling (zonedSchedule). All timing logic lives in the Edge Function.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| FCM auth token generation | Custom JWT signing | `google-auth-library` JWT class | OAuth2 scope handling, token caching, key parsing -- all edge cases handled |
| Notification display with actions | Custom Android native code | `flutter_local_notifications` AndroidNotificationAction | Platform channel complexity, backward compatibility across Android versions |
| Notification channels | Manual Android manifest-only channels | `flutter_local_notifications` createNotificationChannel | Runtime channel creation handles Android 8+ requirement cleanly |
| Cron scheduling | Custom timer/polling in Edge Function | pg_cron + pg_net | Database-level scheduling survives function restarts, no cold-start timing issues |
| Time zone handling | Manual UTC offset math | Store all times in UTC in database, convert in Edge Function using standard library | DST transitions, user timezone changes -- use proven libraries |

**Key insight:** The notification stack has many moving parts (FCM auth, message types, Android channels, action buttons, background isolates, deep links). Each piece has a well-tested library solution. Custom implementations will miss edge cases around Android Doze mode, app state transitions, and token lifecycle.

## Common Pitfalls

### Pitfall 1: FCM Notification vs Data Message Confusion
**What goes wrong:** Sending notification messages from the server causes FCM SDK to auto-display them. The app cannot add action buttons to these notifications. Users see plain notifications without Complete/Snooze.
**Why it happens:** The FCM docs default to notification messages. Most tutorials show notification messages because they are simpler.
**How to avoid:** Always send data-only messages (only `data` field, no `notification` field). Handle display entirely via `flutter_local_notifications`.
**Warning signs:** Notifications appear but without action buttons; foreground notifications don't appear at all.

### Pitfall 2: Background Handler Isolate Restrictions
**What goes wrong:** Background message handler crashes or silently fails because it tries to access Riverpod providers, Navigator, or other main-isolate objects.
**Why it happens:** `onBackgroundMessage` runs in a separate Dart isolate. No access to widget tree, providers, or main isolate state.
**How to avoid:** Make the handler a top-level function. Use `@pragma('vm:entry-point')`. Initialize Firebase and local notifications independently inside the handler. For Supabase calls (e.g., marking task complete from "Complete" action), create a fresh SupabaseClient instance.
**Warning signs:** Handler never fires; app crashes on notification arrival in background.

### Pitfall 3: Missing Android Notification Permission (API 33+)
**What goes wrong:** No notifications appear on Android 13+ devices.
**Why it happens:** Android 13 (API 33) introduced the `POST_NOTIFICATIONS` runtime permission. Without requesting it, notifications are silently blocked.
**How to avoid:** Add `<uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>` to AndroidManifest.xml. Call `FirebaseMessaging.instance.requestPermission()` at app startup. Handle the case where user denies permission gracefully.
**Warning signs:** Notifications work on emulator (older API) but not on newer physical devices.

### Pitfall 4: FCM Token Not Stored/Refreshed
**What goes wrong:** Server sends FCM messages to stale tokens, receiving UNREGISTERED (404) errors. User stops receiving notifications.
**Why it happens:** FCM tokens can change when the app is reinstalled, restored to a new device, or when FCM decides to refresh. If the new token is not sent to the server, messages go to the void.
**How to avoid:** Store token on login. Listen to `onTokenRefresh`. Update token in Supabase whenever it changes. Clear token on logout. Consider monthly forced refresh per Firebase best practices.
**Warning signs:** Notifications work initially but stop after a few weeks; UNREGISTERED errors in Edge Function logs.

### Pitfall 5: Quiet Hours Race Condition
**What goes wrong:** Cron job runs at 10:01 PM and sends a notification for a task due at 11 PM, but quiet hours start at 10 PM.
**Why it happens:** The cron job checks "is there a reminder to send now?" but doesn't check quiet hours before sending.
**How to avoid:** In the Edge Function, after identifying reminders to send, filter out any where the current time falls within the user's quiet hours range. For reminders that would fire during quiet hours, either skip them (if the deadline hasn't passed) or send them at the end of quiet hours.
**Warning signs:** Users receive notifications during their configured quiet hours.

### Pitfall 6: Cron Frequency vs Notification Precision
**What goes wrong:** User sets a reminder for 2:03 PM but the cron runs every 5 minutes (at :00, :05, :10...). The reminder fires at 2:05 PM instead.
**Why it happens:** pg_cron runs on a fixed schedule. If the cron interval is too coarse, reminders are delivered late.
**How to avoid:** Run the cron every 1 minute for acceptable precision. pg_cron supports this. The Edge Function will be lightweight (query + send) so 1-minute frequency is fine.
**Warning signs:** Reminders consistently arrive late by up to N minutes (where N is the cron interval).

### Pitfall 7: google-services.json Missing
**What goes wrong:** App crashes on startup with Firebase initialization error.
**Why it happens:** Firebase requires `google-services.json` in `android/app/` (downloaded from Firebase Console). This is project-specific and must not be committed to git.
**How to avoid:** Add `google-services.json` to `.gitignore`. Document the setup step clearly. Add a startup check that provides a clear error message if the file is missing.
**Warning signs:** "No Firebase App '[DEFAULT]' has been created" error.

## Code Examples

### Edge Function: Cron-Triggered Reminder Sender
```typescript
// supabase/functions/send-reminders/index.ts
// Source: https://supabase.com/docs/guides/functions/examples/push-notifications (adapted)
import { createClient } from 'npm:@supabase/supabase-js@2'
import { JWT } from 'npm:google-auth-library@9'
import serviceAccount from '../service-account.json' with { type: 'json' }

const supabase = createClient(
  Deno.env.get('SUPABASE_URL')!,
  Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
)

Deno.serve(async (_req) => {
  const now = new Date()

  // 1. Query tasks with deadlines approaching in the next minute
  //    that haven't had their reminder sent yet
  const { data: pendingReminders } = await supabase
    .from('pending_reminders')  // View joining tasks + preferences + profiles
    .select('*')
    .lte('remind_at', now.toISOString())
    .eq('sent', false)

  if (!pendingReminders?.length) {
    return new Response(JSON.stringify({ sent: 0 }))
  }

  // 2. Get FCM access token
  const accessToken = await getAccessToken({
    clientEmail: serviceAccount.client_email,
    privateKey: serviceAccount.private_key,
  })

  // 3. Send each reminder
  let sentCount = 0
  for (const reminder of pendingReminders) {
    // Check quiet hours
    if (isInQuietHours(now, reminder.quiet_start, reminder.quiet_end)) {
      continue
    }

    try {
      await fetch(
        `https://fcm.googleapis.com/v1/projects/${serviceAccount.project_id}/messages:send`,
        {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
            Authorization: `Bearer ${accessToken}`,
          },
          body: JSON.stringify({
            message: {
              token: reminder.fcm_token,
              data: {
                type: reminder.reminder_type,
                item_id: reminder.item_id,
                title: reminder.title,
                body: reminder.body,
                insight: reminder.insight || '',
                route: reminder.deep_link_route,
              },
              android: { priority: 'high' },
            },
          }),
        }
      )
      sentCount++

      // Mark reminder as sent
      await supabase
        .from('scheduled_reminders')
        .update({ sent: true, sent_at: now.toISOString() })
        .eq('id', reminder.id)
    } catch (err) {
      console.error(`Failed to send reminder ${reminder.id}:`, err)
    }
  }

  return new Response(JSON.stringify({ sent: sentCount }))
})

function isInQuietHours(
  now: Date,
  quietStart: string | null,
  quietEnd: string | null,
): boolean {
  if (!quietStart || !quietEnd) return false
  const currentMinutes = now.getHours() * 60 + now.getMinutes()
  const [startH, startM] = quietStart.split(':').map(Number)
  const [endH, endM] = quietEnd.split(':').map(Number)
  const start = startH * 60 + startM
  const end = endH * 60 + endM

  if (start <= end) {
    return currentMinutes >= start && currentMinutes < end
  }
  // Wraps midnight (e.g., 22:00 -- 07:00)
  return currentMinutes >= start || currentMinutes < end
}

const getAccessToken = ({
  clientEmail,
  privateKey,
}: {
  clientEmail: string
  privateKey: string
}): Promise<string> => {
  return new Promise((resolve, reject) => {
    const jwtClient = new JWT({
      email: clientEmail,
      key: privateKey,
      scopes: ['https://www.googleapis.com/auth/firebase.messaging'],
    })
    jwtClient.authorize((err, tokens) => {
      if (err) {
        reject(err)
        return
      }
      resolve(tokens!.access_token!)
    })
  })
}
```

### pg_cron Setup for Edge Function Scheduling
```sql
-- Source: https://supabase.com/docs/guides/functions/schedule-functions
-- Store credentials in Vault for security
select vault.create_secret('https://YOUR_PROJECT_REF.supabase.co', 'project_url');
select vault.create_secret('YOUR_SUPABASE_ANON_KEY', 'anon_key');

-- Schedule Edge Function to run every 1 minute
select cron.schedule(
  'send-reminders',
  '* * * * *',  -- every minute
  $$
  select net.http_post(
    url := (select decrypted_secret from vault.decrypted_secrets where name = 'project_url') || '/functions/v1/send-reminders',
    headers := jsonb_build_object(
      'Content-Type', 'application/json',
      'Authorization', 'Bearer ' || (select decrypted_secret from vault.decrypted_secrets where name = 'anon_key')
    ),
    body := jsonb_build_object('time', now()::text)
  );
  $$
);
```

### Notification Deep Link Handling with go_router
```dart
// In app initialization or NotificationService
void _onNotificationTap(NotificationResponse response) {
  final route = response.payload;
  if (route != null && route.isNotEmpty) {
    // Use the global navigator key or GoRouter to navigate
    GoRouter.of(navigatorKey.currentContext!).push(route);
  }
}

// Handle app opened from terminated state via FCM
Future<void> _handleInitialMessage() async {
  final initialMessage = await FirebaseMessaging.instance.getInitialMessage();
  if (initialMessage != null) {
    final route = initialMessage.data['route'];
    if (route != null) {
      GoRouter.of(navigatorKey.currentContext!).push(route);
    }
  }
}

// Handle app opened from background via FCM
void _setupMessageOpenedApp() {
  FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
    final route = message.data['route'];
    if (route != null) {
      GoRouter.of(navigatorKey.currentContext!).push(route);
    }
  });
}
```

### Action Button Handler (Complete/Snooze)
```dart
// Handle notification action button press
// Source: flutter_local_notifications docs (adapted)
@pragma('vm:entry-point')
void onBackgroundNotificationAction(NotificationResponse response) async {
  if (response.actionId == 'complete') {
    // Direct Supabase call (no Riverpod in background isolate)
    await Supabase.initialize(url: supabaseUrl, anonKey: supabaseAnonKey);
    final client = Supabase.instance.client;
    final data = _parsePayload(response.payload);

    if (data['type'] == 'task_deadline') {
      await client.from('tasks')
          .update({'completed': true, 'completed_at': DateTime.now().toIso8601String()})
          .eq('id', data['item_id']);
    } else if (data['type'] == 'habit_reminder') {
      await client.from('habit_logs')
          .insert({'habit_id': data['item_id'], 'completed_at': DateTime.now().toIso8601String()});
    }
  } else if (response.actionId == 'snooze') {
    // Re-show notification after snooze duration (15 min default)
    // Insert a new scheduled_reminder row with remind_at = now + 15 min
    await Supabase.initialize(url: supabaseUrl, anonKey: supabaseAnonKey);
    final client = Supabase.instance.client;
    final data = _parsePayload(response.payload);

    await client.from('scheduled_reminders').insert({
      'user_id': client.auth.currentUser?.id,
      'reminder_type': data['type'],
      'item_id': data['item_id'],
      'remind_at': DateTime.now().add(const Duration(minutes: 15)).toIso8601String(),
      'title': data['title'],
      'body': data['body'],
      'sent': false,
    });
  }
}
```

## Database Schema (Recommended)

### notification_preferences Table
```sql
create table public.notification_preferences (
  id uuid not null default gen_random_uuid() primary key,
  user_id uuid not null references auth.users(id) on delete cascade unique,
  enabled boolean default true,                          -- master toggle
  task_reminders_enabled boolean default true,
  task_default_offsets jsonb default '[1440, 60]'::jsonb, -- minutes before deadline [1 day, 1 hour]
  habit_reminders_enabled boolean default true,
  habit_daily_summary_time time default '08:00',          -- fallback daily summary time
  planner_summary_enabled boolean default true,
  planner_block_reminders_enabled boolean default true,
  planner_block_offset integer default 15,                -- minutes before time block
  quiet_hours_enabled boolean default false,
  quiet_start time default '22:00',
  quiet_end time default '07:00',
  snooze_duration integer default 15,                     -- minutes
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

alter table public.notification_preferences enable row level security;

create policy "Users can manage own notification preferences"
  on public.notification_preferences for all
  using ((select auth.uid()) = user_id)
  with check ((select auth.uid()) = user_id);
```

### scheduled_reminders Table
```sql
create table public.scheduled_reminders (
  id uuid not null default gen_random_uuid() primary key,
  user_id uuid not null references auth.users(id) on delete cascade,
  reminder_type text not null check (reminder_type in ('task_deadline', 'habit_reminder', 'planner_summary', 'planner_block')),
  item_id uuid not null,                    -- references task, habit, or planner_item
  remind_at timestamptz not null,
  title text not null,
  body text not null,
  insight text,                             -- adaptive timing explanation
  deep_link_route text,                     -- e.g., '/tasks/detail/abc-123'
  sent boolean default false,
  sent_at timestamptz,
  snoozed_from uuid references public.scheduled_reminders(id),  -- if this is a snooze of another reminder
  created_at timestamptz default now()
);

create index idx_pending_reminders on public.scheduled_reminders (remind_at)
  where sent = false;

alter table public.scheduled_reminders enable row level security;

create policy "Users can view own reminders"
  on public.scheduled_reminders for select
  using ((select auth.uid()) = user_id);

create policy "Users can insert own reminders"
  on public.scheduled_reminders for insert
  with check ((select auth.uid()) = user_id);

create policy "Service role can manage all reminders"
  on public.scheduled_reminders for all
  using (true)
  with check (true);
-- Note: Edge Function uses service_role key, bypasses RLS
```

### completion_patterns Table (for Adaptive Timing)
```sql
create table public.completion_patterns (
  id uuid not null default gen_random_uuid() primary key,
  user_id uuid not null references auth.users(id) on delete cascade,
  item_type text not null check (item_type in ('task', 'habit')),
  item_id uuid not null,
  deadline_at timestamptz,                    -- when was it due
  completed_at timestamptz not null,          -- when was it completed
  reminder_sent_at timestamptz,               -- when was the reminder that prompted completion sent
  response_delay_minutes integer,             -- minutes between reminder and completion
  created_at timestamptz default now()
);

create index idx_completion_patterns_user_recent
  on public.completion_patterns (user_id, created_at desc);

alter table public.completion_patterns enable row level security;

create policy "Users can manage own completion patterns"
  on public.completion_patterns for all
  using ((select auth.uid()) = user_id)
  with check ((select auth.uid()) = user_id);
```

### Profiles Table Addition
```sql
-- Add FCM token columns to existing profiles table
alter table public.profiles
  add column if not exists fcm_token text,
  add column if not exists fcm_token_updated_at timestamptz;
```

## Adaptive Timing Algorithm (Recommended)

### Approach: Weighted Moving Average (Simple Heuristic)
**Confidence:** MEDIUM -- this is a Claude's Discretion area. The algorithm below is a reasonable starting point.

```typescript
// In Edge Function: calculate adaptive offset for a user
interface CompletionData {
  deadline_at: string
  completed_at: string
  reminder_sent_at: string | null
  response_delay_minutes: number | null
}

function calculateAdaptiveOffset(
  completions: CompletionData[],
  defaultOffsetMinutes: number,
): { offsetMinutes: number; insight: string | null } {
  if (completions.length < 3) {
    return { offsetMinutes: defaultOffsetMinutes, insight: null }
  }

  // Signal 1: Deadline proximity -- how many minutes before deadline do they complete?
  const proximities = completions
    .filter(c => c.deadline_at)
    .map(c => {
      const deadline = new Date(c.deadline_at).getTime()
      const completed = new Date(c.completed_at).getTime()
      return (deadline - completed) / (1000 * 60) // minutes before deadline
    })

  const avgProximity = proximities.reduce((a, b) => a + b, 0) / proximities.length

  // Signal 2: Response delay -- how quickly do they act after receiving a reminder?
  const delays = completions
    .filter(c => c.response_delay_minutes != null)
    .map(c => c.response_delay_minutes!)

  const avgDelay = delays.length > 0
    ? delays.reduce((a, b) => a + b, 0) / delays.length
    : 30  // default assumption: 30 min response time

  // If user completes tasks close to deadline (< 30 min before), they're procrastinating
  // Shift reminder earlier by the average delay + buffer
  let newOffset = defaultOffsetMinutes
  let insight: string | null = null

  if (avgProximity < 30 && avgProximity < defaultOffsetMinutes * 0.5) {
    // Procrastinator: push reminder earlier
    newOffset = Math.min(defaultOffsetMinutes * 3, defaultOffsetMinutes + avgDelay + 30)
    insight = `Reminder moved earlier -- you tend to complete tasks ${Math.round(avgProximity)} min before deadline`
  } else if (avgProximity > defaultOffsetMinutes * 2) {
    // Early completer: could reduce reminder frequency (but keep at least default)
    newOffset = defaultOffsetMinutes
    insight = null  // no change needed
  }

  // Clamp to reasonable range (15 min to 48 hours)
  newOffset = Math.max(15, Math.min(2880, Math.round(newOffset)))

  return { offsetMinutes: newOffset, insight }
}
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| FCM Legacy HTTP API | FCM HTTP v1 API | June 2024 (legacy deprecated) | Must use HTTP v1 with OAuth2 service account auth; legacy API no longer supported |
| Notification messages for all | Data-only messages for rich notifications | Ongoing best practice | Required for action buttons, custom display, full app control |
| Client-side notification scheduling | Server-side cron + push | Current best practice | More reliable, works across app states, centralizes timing logic |
| firebase-admin SDK (Node) | google-auth-library JWT + fetch | For Deno/Edge Functions | Deno doesn't have full firebase-admin; use JWT + raw HTTP v1 API instead |

**Deprecated/outdated:**
- **FCM Legacy HTTP API**: Fully deprecated as of June 2024. Must use HTTP v1 API with OAuth2.
- **`FirebaseMessaging.instance.subscribeToTopic()` for per-user notifications**: Topics are for broadcast. Per-user reminders need individual device tokens.

## Open Questions

1. **Snooze from background isolate reliability**
   - What we know: Background action handlers run in a separate isolate. Supabase can be initialized there.
   - What's unclear: Whether `Supabase.initialize()` in a background isolate reliably works if the main isolate also has it initialized. May need a separate initialization path or use raw HTTP calls.
   - Recommendation: Test early. If unreliable, snooze action can simply re-schedule a local notification with `flutter_local_notifications.zonedSchedule()` instead of going through the server.

2. **Per-task reminder offset storage**
   - What we know: User can set custom reminder timing per task. This overrides the category default.
   - What's unclear: Whether this should be a column on the tasks table (tight coupling) or a row in `scheduled_reminders` (requires sync when task deadline changes).
   - Recommendation: Add a `reminder_offsets` JSONB column to the tasks table (e.g., `[60, 1440]` for 1hr and 1day). When a task deadline changes, a database trigger regenerates the `scheduled_reminders` rows.

3. **Habit reminder time storage**
   - What we know: Each habit can have a specific reminder time. Habits without a time get a daily summary.
   - What's unclear: Whether the habit model (from Phase 4) already has a `reminder_time` field or if it needs to be added.
   - Recommendation: Add `reminder_time TIME` column to habits table if not present. The Edge Function queries habits with `reminder_time` IS NOT NULL for individual reminders, and groups the rest for daily summary.

4. **Firebase project setup status**
   - What we know: The Android directory exists but is minimal (no build.gradle, no google-services.json).
   - What's unclear: Whether the user has a Firebase project created and configured.
   - Recommendation: First wave of implementation should include Firebase project setup instructions and Android configuration as a prerequisite step.

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | flutter_test + mockito (already configured) |
| Config file | pubspec.yaml (dev_dependencies section) |
| Quick run command | `flutter test test/unit/notifications/` |
| Full suite command | `flutter test` |

### Phase Requirements to Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| PLAN-04 | Adaptive timing algorithm produces correct offsets from completion data | unit | `flutter test test/unit/notifications/adaptive_timing_test.dart -x` | Wave 0 |
| PLAN-04 | Completion patterns are recorded on task/habit completion | unit | `flutter test test/unit/notifications/completion_pattern_test.dart -x` | Wave 0 |
| UX-03 | Notification preferences CRUD operations work | unit | `flutter test test/unit/notifications/notification_repository_test.dart -x` | Wave 0 |
| UX-03 | FCM token is stored and refreshed correctly | unit | `flutter test test/unit/notifications/fcm_token_test.dart -x` | Wave 0 |
| UX-03 | Notification settings screen renders with correct toggles | widget | `flutter test test/widget/notifications/notification_settings_test.dart -x` | Wave 0 |
| UX-03 | Quiet hours filtering logic works correctly | unit | `flutter test test/unit/notifications/quiet_hours_test.dart -x` | Wave 0 |

### Sampling Rate
- **Per task commit:** `flutter test test/unit/notifications/`
- **Per wave merge:** `flutter test`
- **Phase gate:** Full suite green before `/gsd:verify-work`

### Wave 0 Gaps
- [ ] `test/unit/notifications/adaptive_timing_test.dart` -- covers PLAN-04 adaptive algorithm
- [ ] `test/unit/notifications/completion_pattern_test.dart` -- covers PLAN-04 data recording
- [ ] `test/unit/notifications/notification_repository_test.dart` -- covers UX-03 preference CRUD
- [ ] `test/unit/notifications/fcm_token_test.dart` -- covers UX-03 token management
- [ ] `test/unit/notifications/quiet_hours_test.dart` -- covers UX-03 quiet hours logic
- [ ] `test/widget/notifications/notification_settings_test.dart` -- covers UX-03 settings UI

## Discretion Recommendations

### Notification Preferences: Dedicated Screen
**Recommendation:** Create a dedicated `NotificationSettingsScreen` rather than inline settings section. Rationale: with master toggle, 3 category sections, quiet hours picker, and snooze duration -- that is 10+ controls. Too much for inline in the existing settings screen. Add a `ListTile` in SettingsScreen that navigates to `/settings/notifications`.

### Cron Frequency: Every 1 Minute
**Recommendation:** Run the cron job every 1 minute (`* * * * *`). Rationale: pg_cron supports this, the Edge Function is lightweight (query + send), and it gives acceptable precision for reminders. Users expect reminders within ~1 minute of the configured time.

### Snooze Duration: Fixed Options (15/30/60 min)
**Recommendation:** Offer 3 fixed snooze options (15, 30, 60 minutes) configurable in settings. Default to 15 minutes. Rationale: simpler UX than a custom picker, covers common use cases, and the default matches common notification snooze patterns.

### Android Notification Channels: 3 Channels
**Recommendation:** Create 3 Android notification channels (task_reminders at HIGH importance, habit_reminders at DEFAULT, planner_notifications at DEFAULT). Rationale: allows users to control notification behavior per category via Android system settings, and task reminders get heads-up display.

## Sources

### Primary (HIGH confidence)
- [Supabase Push Notifications Docs](https://supabase.com/docs/guides/functions/examples/push-notifications) -- Edge Function + FCM HTTP v1 pattern with google-auth-library
- [Supabase Cron Scheduling Docs](https://supabase.com/docs/guides/functions/schedule-functions) -- pg_cron + pg_net for Edge Function scheduling
- [Supabase Cron Module Docs](https://supabase.com/docs/guides/cron) -- pg_cron capabilities (1 second to 1 year intervals, max 8 concurrent jobs)
- [FlutterFire Notifications Docs](https://firebase.flutter.dev/docs/messaging/notifications/) -- Foreground handling, channels, message types
- [Firebase FCM Token Best Practices](https://firebase.google.com/docs/cloud-messaging/manage-tokens) -- Monthly refresh, staleness detection, error handling
- [pub.dev firebase_messaging 16.1.2](https://pub.dev/packages/firebase_messaging) -- Latest version verified
- [pub.dev firebase_core 4.5.0](https://pub.dev/packages/firebase_core) -- Latest version verified
- [pub.dev flutter_local_notifications 21.0.0](https://pub.dev/packages/flutter_local_notifications) -- Latest version verified, AndroidNotificationAction API

### Secondary (MEDIUM confidence)
- [FlutterFire Cloud Messaging Usage](https://firebase.flutter.dev/docs/messaging/usage/) -- Data vs notification messages, background handling
- [Firebase Receive Messages in Flutter](https://firebase.google.com/docs/cloud-messaging/flutter/receive-messages) -- Message type behavior matrix
- [Flutter Deep Linking Docs](https://docs.flutter.dev/ui/navigation/deep-linking) -- go_router deep link integration

### Tertiary (LOW confidence)
- Medium articles on FCM + flutter_local_notifications combination -- patterns verified against official docs
- WebSearch results on data-only message + high priority behavior -- consistent across multiple sources but not in a single canonical doc

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH -- all packages verified on pub.dev with current versions, official Supabase FCM example confirms pattern
- Architecture: MEDIUM-HIGH -- data-only message pattern well-documented but combining FCM + flutter_local_notifications for action buttons in background state has some edge cases
- Pitfalls: HIGH -- well-documented across FlutterFire docs, GitHub issues, and community posts
- Adaptive algorithm: MEDIUM -- custom logic (Claude's Discretion), based on reasonable heuristics but not battle-tested
- Database schema: MEDIUM -- reasonable design following project patterns, but the scheduled_reminders regeneration on deadline changes needs careful trigger design

**Research date:** 2026-03-18
**Valid until:** 2026-04-18 (30 days -- stable ecosystem, packages actively maintained)
