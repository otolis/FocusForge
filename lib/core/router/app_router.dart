import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../features/auth/presentation/providers/auth_provider.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/register_screen.dart';
import '../../features/auth/presentation/screens/forgot_password_screen.dart';
import '../../features/onboarding/presentation/screens/onboarding_screen.dart';
import '../../features/profile/presentation/screens/profile_screen.dart';
import '../../features/settings/presentation/screens/settings_screen.dart';
import '../../shared/widgets/app_shell.dart';
import '../../shared/widgets/placeholder_tab.dart';

/// Tracks whether onboarding has been completed so the redirect guard
/// can check synchronously.
///
/// Call [loadOnboardingStatus] during app initialization (before runApp)
/// to populate this value.
bool _onboardingCompleted = false;

/// Loads the onboarding flag from [SharedPreferences].
///
/// Must be called once during app startup so the router redirect can
/// check [_onboardingCompleted] synchronously.
Future<void> loadOnboardingStatus() async {
  final prefs = await SharedPreferences.getInstance();
  _onboardingCompleted = prefs.getBool('onboarding_completed') ?? false;
}

/// Provides the [GoRouter] instance configured with auth-based and
/// onboarding-based redirects.
///
/// Uses [AuthNotifier] as a [refreshListenable] so the router re-evaluates
/// its redirect logic whenever the user signs in or out. Unauthenticated
/// users are always sent to `/login`. Authenticated users who have not
/// completed onboarding are sent to `/onboarding`. All other authenticated
/// users land on `/tasks` (the first tab).
final appRouterProvider = Provider<GoRouter>((ref) {
  final authNotifier = ref.read(authNotifierProvider);

  return GoRouter(
    refreshListenable: authNotifier,
    initialLocation: '/login',
    redirect: (context, state) {
      final isAuth = authNotifier.isAuthenticated;
      final location = state.matchedLocation;
      final isLoginRoute = location == '/login';
      final isRegisterRoute = location == '/register';
      final isForgotPassword = location == '/forgot-password';
      final authRoutes = isLoginRoute || isRegisterRoute || isForgotPassword;

      // Unauthenticated users can only access auth routes.
      if (!isAuth && !authRoutes) return '/login';

      // Authenticated users on auth routes are sent to home.
      if (isAuth && authRoutes) {
        // If onboarding not completed, redirect to onboarding first.
        if (!_onboardingCompleted) return '/onboarding';
        return '/tasks';
      }

      // Authenticated users on root redirect to first tab.
      if (isAuth && location == '/') return '/tasks';

      return null; // No redirect needed.
    },
    routes: [
      // Auth routes (outside the shell)
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/forgot-password',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),

      // Onboarding (outside the shell)
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),

      // Main app shell with bottom navigation
      ShellRoute(
        builder: (context, state, child) => AppShell(child: child),
        routes: [
          GoRoute(
            path: '/tasks',
            builder: (context, state) =>
                const PlaceholderTab(title: 'Tasks'),
          ),
          GoRoute(
            path: '/habits',
            builder: (context, state) =>
                const PlaceholderTab(title: 'Habits'),
          ),
          GoRoute(
            path: '/planner',
            builder: (context, state) =>
                const PlaceholderTab(title: 'Planner'),
          ),
          GoRoute(
            path: '/profile',
            builder: (context, state) => const ProfileScreen(),
          ),
        ],
      ),

      // Settings (outside the shell — full screen)
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsScreen(),
      ),
    ],
  );
});
