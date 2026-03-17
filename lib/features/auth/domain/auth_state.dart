import 'package:supabase_flutter/supabase_flutter.dart';

/// Represents the current authentication status.
enum AuthStatus {
  /// App just launched, auth state not yet determined.
  initial,

  /// User has a valid session.
  authenticated,

  /// No valid session exists.
  unauthenticated,

  /// An auth operation is in progress.
  loading,

  /// An auth operation failed.
  error,
}

/// Immutable state object for authentication.
///
/// Combines the [AuthStatus] with the optional [User] and [errorMessage]
/// to provide a complete picture of the auth state for UI consumption.
class AppAuthState {
  const AppAuthState({
    this.status = AuthStatus.initial,
    this.user,
    this.errorMessage,
  });

  /// Current authentication status.
  final AuthStatus status;

  /// The authenticated Supabase user, if any.
  final User? user;

  /// Human-readable error message for display in the UI.
  final String? errorMessage;

  /// Creates a copy of this state with the given fields replaced.
  AppAuthState copyWith({
    AuthStatus? status,
    User? user,
    String? errorMessage,
  }) {
    return AppAuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      errorMessage: errorMessage,
    );
  }
}
