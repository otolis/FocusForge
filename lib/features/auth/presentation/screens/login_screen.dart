import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/utils/extensions.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../domain/auth_state.dart';
import '../providers/auth_provider.dart';
import '../../data/auth_repository.dart';
import '../widgets/social_sign_in_button.dart';

/// Login screen with email/password and Google Sign-In.
///
/// Layout follows the UI-SPEC Auth Form Layout exactly:
/// App logo -> tagline -> email -> password -> Sign In button ->
/// "or" divider -> Google button -> secondary links.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _googleLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _signIn() {
    if (_formKey.currentState?.validate() ?? false) {
      ref.read(authStateProvider.notifier).signIn(
            email: _emailController.text.trim(),
            password: _passwordController.text,
          );
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() => _googleLoading = true);
    await ref.read(authStateProvider.notifier).signInWithGoogle();
    if (mounted) setState(() => _googleLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(authStateProvider);

    // Show error SnackBar when auth fails.
    ref.listen<AppAuthState>(authStateProvider, (previous, next) {
      if (next.status == AuthStatus.error && next.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              next.errorMessage!,
              style: const TextStyle(color: Colors.white),
            ),
            backgroundColor: context.colorScheme.error,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    });

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // App logo / wordmark.
                  Text(
                    'FocusForge',
                    style: context.textTheme.displayMedium?.copyWith(
                      color: context.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Tagline.
                  Text(
                    'Your intelligent productivity companion',
                    style: context.textTheme.bodyMedium?.copyWith(
                      color: context.colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  // Email field.
                  AppTextField(
                    label: 'Email',
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Email is required';
                      }
                      if (!value.contains('@')) {
                        return 'Enter a valid email address';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),
                  // Password field with visibility toggle.
                  AppTextField(
                    label: 'Password',
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => _signIn(),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility
                            : Icons.visibility_off,
                      ),
                      onPressed: () {
                        setState(() => _obscurePassword = !_obscurePassword);
                      },
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Password is required';
                      }
                      if (value.length < 6) {
                        return 'Password must be at least 6 characters';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  // Primary CTA.
                  AppButton(
                    label: 'Sign In',
                    onPressed: _signIn,
                    isLoading: state.status == AuthStatus.loading &&
                        !_googleLoading,
                  ),
                  if (AuthRepository.isGoogleSignInConfigured) ...[
                    const SizedBox(height: 16),
                    // "or" divider.
                    Row(
                      children: [
                        const Expanded(child: Divider()),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            'or',
                            style: context.textTheme.bodyMedium?.copyWith(
                              color: context.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                        const Expanded(child: Divider()),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Google Sign-In button.
                    SocialSignInButton(
                      onPressed: _signInWithGoogle,
                      isLoading: _googleLoading,
                    ),
                  ],
                  const SizedBox(height: 24),
                  // Navigate to register.
                  TextButton(
                    onPressed: () => context.go('/register'),
                    child: Text(
                      "Don't have an account? Sign up",
                      style: TextStyle(
                        color: context.colorScheme.primary,
                      ),
                    ),
                  ),
                  // Navigate to forgot password.
                  TextButton(
                    onPressed: () => context.go('/forgot-password'),
                    child: Text(
                      'Forgot password?',
                      style: TextStyle(
                        color: context.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
