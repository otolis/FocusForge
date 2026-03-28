import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/constants/supabase_constants.dart';
import 'core/router/app_router.dart';
import 'core/services/notification_service.dart';
import 'app.dart';

/// Whether Firebase was successfully initialized during startup.
///
/// Other services (FCM, notifications) should check this before using
/// Firebase APIs to avoid crashes when google-services.json is missing.
bool firebaseInitialized = false;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase requires google-services.json and the Google Services Gradle
  // plugin. Wrap in try-catch so the app can still launch without it.
  try {
    await Firebase.initializeApp();
    firebaseInitialized = true;
  } catch (e) {
    debugPrint('[FocusForge] Firebase init failed (is google-services.json '
        'configured?): $e');
  }

  await Supabase.initialize(
    url: SupabaseConstants.url,
    anonKey: SupabaseConstants.anonKey,
  );

  // Pre-load onboarding flag so the router redirect can check synchronously.
  await loadOnboardingStatus();

  // Notification service depends on Firebase/FCM — skip if Firebase is down.
  if (firebaseInitialized) {
    try {
      await NotificationService().initialize();
    } catch (e) {
      debugPrint('[FocusForge] Notification init failed: $e');
    }
  } else {
    debugPrint('[FocusForge] Skipping notification init (Firebase unavailable)');
  }

  runApp(const ProviderScope(child: FocusForgeApp()));
}
