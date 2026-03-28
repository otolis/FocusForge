import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../features/auth/presentation/providers/auth_provider.dart';
import '../services/notification_service.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/register_screen.dart';
import '../../features/auth/presentation/screens/forgot_password_screen.dart';
import '../../features/onboarding/presentation/screens/onboarding_screen.dart';
import '../../features/profile/presentation/screens/profile_screen.dart';
import '../../features/settings/presentation/screens/settings_screen.dart';
import '../../features/boards/presentation/screens/board_list_screen.dart';
import '../../features/boards/presentation/screens/board_detail_screen.dart';
import '../../features/boards/presentation/screens/board_settings_screen.dart';
import '../../features/habits/presentation/screens/habit_list_screen.dart';
import '../../features/habits/presentation/screens/habit_detail_screen.dart';
import '../../features/habits/presentation/screens/habit_form_screen.dart';
import '../../features/planner/presentation/screens/planner_screen.dart';
import '../../features/notifications/presentation/screens/notification_settings_screen.dart';
import '../../features/smart_input/presentation/screens/smart_input_demo_screen.dart';
import '../../shared/widgets/app_shell.dart';
import '../../features/tasks/presentation/screens/task_list_screen.dart';
import '../../features/tasks/presentation/screens/task_form_screen.dart';
import '../../features/tasks/presentation/screens/category_management_screen.dart';

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

/// Allows external code (e.g., OnboardingScreen) to update the
/// module-level onboarding flag after the user completes onboarding,
/// so the router redirect does not loop back.
void setOnboardingCompleted(bool value) {
  _onboardingCompleted = value;
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
    navigatorKey: notificationNavigatorKey,
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

      // Consume pending deep link from cold-start notification tap
      if (isAuth) {
        final pendingRoute = NotificationService.consumePendingDeepLink();
        if (pendingRoute != null) return pendingRoute;
      }

      // ONBOARD-01: Redirect to onboarding for ANY authenticated route
      // if onboarding is not completed (except /onboarding itself to prevent loop)
      if (isAuth && !_onboardingCompleted && location != '/onboarding') {
        return '/onboarding';
      }

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
            builder: (context, state) => const TaskListScreen(),
            routes: [
              GoRoute(
                path: 'create',
                parentNavigatorKey: notificationNavigatorKey,
                builder: (context, state) => const TaskFormScreen(),
              ),
              GoRoute(
                path: 'categories',
                parentNavigatorKey: notificationNavigatorKey,
                builder: (context, state) =>
                    const CategoryManagementScreen(),
              ),
              GoRoute(
                path: ':id',
                parentNavigatorKey: notificationNavigatorKey,
                builder: (context, state) {
                  final taskId = state.pathParameters['id']!;
                  return TaskFormScreen(taskId: taskId);
                },
              ),
            ],
          ),
          GoRoute(
            path: '/habits',
            builder: (context, state) => const HabitListScreen(),
          ),
          GoRoute(
            path: '/planner',
            builder: (context, state) => const PlannerScreen(),
          ),
          GoRoute(
            path: '/boards',
            builder: (context, state) => const BoardListScreen(),
          ),
          GoRoute(
            path: '/profile',
            builder: (context, state) => const ProfileScreen(),
          ),
        ],
      ),

      // Habit form: create new habit (outside the shell -- full screen)
      GoRoute(
        path: '/habits/new',
        builder: (context, state) => const HabitFormScreen(),
      ),

      // Habit detail (outside the shell -- full screen)
      GoRoute(
        path: '/habits/:id',
        builder: (context, state) {
          final habitId = state.pathParameters['id']!;
          return HabitDetailScreen(habitId: habitId);
        },
      ),

      // Habit form: edit existing habit (outside the shell -- full screen)
      GoRoute(
        path: '/habits/:id/edit',
        builder: (context, state) {
          final habitId = state.pathParameters['id']!;
          return HabitFormScreen(habitId: habitId);
        },
      ),

      // Board settings (outside the shell -- full screen)
      GoRoute(
        path: '/boards/:id/settings',
        builder: (context, state) {
          final boardId = state.pathParameters['id']!;
          return BoardSettingsScreen(boardId: boardId);
        },
      ),

      // Board detail (outside the shell -- full screen Kanban view)
      GoRoute(
        path: '/boards/:id',
        builder: (context, state) {
          final boardId = state.pathParameters['id']!;
          return BoardDetailScreen(boardId: boardId);
        },
      ),

      // Settings (outside the shell -- full screen)
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsScreen(),
      ),

      // Notification settings (outside the shell -- full screen)
      GoRoute(
        path: '/settings/notifications',
        builder: (context, state) => const NotificationSettingsScreen(),
      ),

      // Smart input demo (outside the shell -- dev/demo screen)
      GoRoute(
        path: '/smart-input-demo',
        name: 'smartInputDemo',
        builder: (context, state) => const SmartInputDemoScreen(),
      ),
    ],
  );
});
