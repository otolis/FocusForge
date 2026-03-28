import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Repository for all authentication operations.
///
/// Wraps the Supabase Auth API in a thin layer for testability. Accepts an
/// optional [SupabaseClient] for dependency injection in tests.
class AuthRepository {
  AuthRepository([SupabaseClient? client])
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  /// Web Client ID for Google Sign-In.
  ///
  /// Replace with your actual Web Application OAuth Client ID from
  /// Google Cloud Console -> APIs & Services -> Credentials.
  static const String webClientId =
      'YOUR_WEB_CLIENT_ID.apps.googleusercontent.com';

  /// Whether a real Google client ID is configured (not the placeholder).
  static bool get isGoogleSignInConfigured =>
      webClientId.isNotEmpty &&
      !webClientId.startsWith('YOUR_WEB_CLIENT_ID');

  bool _googleInitialized = false;

  /// Ensures the Google Sign-In platform is initialized exactly once.
  Future<void> _ensureGoogleInitialized() async {
    if (_googleInitialized) return;
    await GoogleSignIn.instance.initialize(
      serverClientId: webClientId,
    );
    _googleInitialized = true;
  }

  /// Signs up a new user with email and password.
  ///
  /// Optionally passes [displayName] as `full_name` in user metadata,
  /// which the `handle_new_user` database trigger uses to populate the
  /// profiles table.
  Future<AuthResponse> signUpWithEmail({
    required String email,
    required String password,
    String? displayName,
  }) async {
    return await _client.auth.signUp(
      email: email,
      password: password,
      data: displayName != null ? {'full_name': displayName} : null,
    );
  }

  /// Signs in an existing user with email and password.
  Future<AuthResponse> signInWithEmail({
    required String email,
    required String password,
  }) async {
    return await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  /// Signs in with Google using the native Android flow.
  ///
  /// Uses [GoogleSignIn] to obtain an ID token via [authenticate], which
  /// is then passed to Supabase via [signInWithIdToken]. Requires both a
  /// Web Application OAuth Client ID (used as `serverClientId`) and an
  /// Android OAuth Client ID (registered in Google Cloud Console with
  /// your SHA-1).
  Future<AuthResponse> signInWithGoogle() async {
    await _ensureGoogleInitialized();

    final GoogleSignInAccount account;
    try {
      account = await GoogleSignIn.instance.authenticate();
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) {
        throw Exception('Google sign-in cancelled');
      }
      rethrow;
    }

    final idToken = account.authentication.idToken;
    if (idToken == null) {
      throw Exception('No ID token received from Google');
    }

    return await _client.auth.signInWithIdToken(
      provider: OAuthProvider.google,
      idToken: idToken,
    );
  }

  /// Signs out the current user.
  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  /// Sends a password reset email to the given address.
  Future<void> resetPassword(String email) async {
    await _client.auth.resetPasswordForEmail(email);
  }

  /// The currently authenticated user, or `null` if not signed in.
  User? get currentUser => _client.auth.currentUser;

  /// The current session, or `null` if not signed in.
  Session? get currentSession => _client.auth.currentSession;

  /// Stream of auth state changes (sign in, sign out, token refresh, etc.).
  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;
}
