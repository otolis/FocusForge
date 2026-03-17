import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/providers/auth_provider.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/register_screen.dart';
import '../../features/auth/presentation/screens/forgot_password_screen.dart';

/// Provides the [GoRouter] instance configured with auth-based redirects.
///
/// Uses [AuthNotifier] as a [refreshListenable] so the router re-evaluates
/// its redirect logic whenever the user signs in or out. Unauthenticated
/// users are always sent to `/login`. Authenticated users on auth routes
/// are redirected to `/` (home).
final appRouterProvider = Provider<GoRouter>((ref) {
  final authNotifier = ref.read(authNotifierProvider);

  return GoRouter(
    refreshListenable: authNotifier,
    initialLocation: '/login',
    redirect: (context, state) {
      final isAuth = authNotifier.isAuthenticated;
      final isLoginRoute = state.matchedLocation == '/login';
      final isRegisterRoute = state.matchedLocation == '/register';
      final isForgotPassword = state.matchedLocation == '/forgot-password';
      final isOnboarding = state.matchedLocation == '/onboarding';
      final authRoutes = isLoginRoute || isRegisterRoute || isForgotPassword;

      // Unauthenticated users can only access auth routes and onboarding.
      if (!isAuth && !authRoutes && !isOnboarding) return '/login';

      // Authenticated users on auth routes are sent to home.
      if (isAuth && authRoutes) return '/';

      return null; // No redirect needed.
    },
    routes: [
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
      GoRoute(
        path: '/',
        builder: (context, state) => const Scaffold(
          body: Center(
            child: Text('Home — will be replaced by ShellRoute in Plan 03'),
          ),
        ),
      ),
    ],
  );
});
