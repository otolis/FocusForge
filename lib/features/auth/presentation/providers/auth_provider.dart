import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/auth_repository.dart';
import '../../domain/auth_state.dart';

/// A [ChangeNotifier] that tracks whether the user is authenticated.
///
/// Used as [GoRouter.refreshListenable] so the router re-evaluates its
/// redirect logic whenever the auth state changes.
class AuthNotifier extends ChangeNotifier {
  AuthNotifier() {
    _isAuthenticated =
        Supabase.instance.client.auth.currentSession != null;
    _subscription =
        Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      _isAuthenticated = data.session != null;
      notifyListeners();
    });
  }

  late final StreamSubscription<AuthState> _subscription;
  bool _isAuthenticated = false;

  /// Whether a valid session currently exists.
  bool get isAuthenticated => _isAuthenticated;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

/// Manages the full [AppAuthState] lifecycle for UI consumption.
///
/// Handles sign-up, sign-in, sign-out, Google sign-in, and password reset.
/// Maps Supabase exceptions to user-friendly error messages matching the
/// UI-SPEC copywriting contract.
class AuthStateNotifier extends StateNotifier<AppAuthState> {
  AuthStateNotifier(this._repository) : super(const AppAuthState()) {
    _init();
  }

  final AuthRepository _repository;

  /// Checks the current session on initialization.
  void _init() {
    final user = _repository.currentUser;
    if (user != null) {
      state = state.copyWith(
        status: AuthStatus.authenticated,
        user: user,
      );
    } else {
      state = state.copyWith(status: AuthStatus.unauthenticated);
    }
  }

  /// Signs up with email and password, optionally setting a display name.
  Future<void> signUp({
    required String email,
    required String password,
    String? displayName,
  }) async {
    state = state.copyWith(status: AuthStatus.loading, errorMessage: null);
    try {
      final response = await _repository.signUpWithEmail(
        email: email,
        password: password,
        displayName: displayName,
      );
      state = state.copyWith(
        status: AuthStatus.authenticated,
        user: response.user,
      );
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: _mapError(e),
      );
    }
  }

  /// Signs in with email and password.
  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    state = state.copyWith(status: AuthStatus.loading, errorMessage: null);
    try {
      final response = await _repository.signInWithEmail(
        email: email,
        password: password,
      );
      state = state.copyWith(
        status: AuthStatus.authenticated,
        user: response.user,
      );
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: _mapError(e),
      );
    }
  }

  /// Signs in with Google OAuth (native flow).
  Future<void> signInWithGoogle() async {
    state = state.copyWith(status: AuthStatus.loading, errorMessage: null);
    try {
      final response = await _repository.signInWithGoogle();
      state = state.copyWith(
        status: AuthStatus.authenticated,
        user: response.user,
      );
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: _mapError(e),
      );
    }
  }

  /// Signs out the current user.
  Future<void> signOut() async {
    state = state.copyWith(status: AuthStatus.loading, errorMessage: null);
    try {
      await _repository.signOut();
      state = const AppAuthState(status: AuthStatus.unauthenticated);
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: _mapError(e),
      );
    }
  }

  /// Sends a password reset email. Returns `true` on success.
  Future<bool> resetPassword(String email) async {
    state = state.copyWith(status: AuthStatus.loading, errorMessage: null);
    try {
      await _repository.resetPassword(email);
      // Restore previous auth status (not loading) after success.
      state = state.copyWith(
        status: _repository.currentUser != null
            ? AuthStatus.authenticated
            : AuthStatus.unauthenticated,
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: _mapError(e),
      );
      return false;
    }
  }

  /// Maps exceptions to user-friendly messages per the UI-SPEC
  /// copywriting contract.
  String _mapError(Object error) {
    final message = error.toString().toLowerCase();

    if (message.contains('invalid login credentials')) {
      return 'Incorrect email or password. Please try again.';
    }
    if (message.contains('user already registered')) {
      return 'An account with this email already exists. Try signing in instead.';
    }
    if (message.contains('password should be at least 6 characters') ||
        message.contains('password is too short')) {
      return 'Password must be at least 6 characters.';
    }
    if (message.contains('network') ||
        message.contains('socketexception') ||
        message.contains('connection') ||
        message.contains('timeout')) {
      return 'Unable to connect. Check your internet connection and try again.';
    }
    if (message.contains('google sign-in cancelled')) {
      return 'Google sign-in was cancelled.';
    }

    return 'Something went wrong. Please try again.';
  }
}

// ---------------------------------------------------------------------------
// Riverpod Providers
// ---------------------------------------------------------------------------

/// Provides the [AuthNotifier] used by [GoRouter.refreshListenable].
final authNotifierProvider = Provider<AuthNotifier>((ref) {
  final notifier = AuthNotifier();
  ref.onDispose(notifier.dispose);
  return notifier;
});

/// Provides the [AuthRepository] instance.
final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepository(),
);

/// Provides the full [AppAuthState] for UI consumption.
final authStateProvider =
    StateNotifierProvider<AuthStateNotifier, AppAuthState>(
  (ref) => AuthStateNotifier(ref.read(authRepositoryProvider)),
);
