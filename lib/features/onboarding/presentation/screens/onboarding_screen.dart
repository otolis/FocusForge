import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

import '../../../../core/utils/extensions.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../profile/presentation/providers/profile_provider.dart';
import '../widgets/onboarding_page.dart';

/// A 3-page onboarding flow shown to first-time users.
///
/// Features:
/// - Swipeable PageView with three informational pages
/// - Skip button at top right to bypass onboarding
/// - Next button on pages 1-2, "Get Started" on page 3
/// - SmoothPageIndicator with tertiary accent color
/// - Marks onboarding complete in both SharedPreferences and Supabase
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _pageController = PageController();
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController.addListener(() {
      final page = _pageController.page?.round() ?? 0;
      if (page != _currentPage) {
        setState(() => _currentPage = page);
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  /// Marks onboarding as completed in SharedPreferences and Supabase,
  /// then navigates to the home screen.
  Future<void> _completeOnboarding() async {
    // Store locally
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_completed', true);

    // Update Supabase profile
    final userId = ref.read(authStateProvider).user?.id;
    if (userId != null) {
      try {
        final repo = ref.read(profileRepositoryProvider);
        final profile = await repo.getProfile(userId);
        final updated = profile.copyWith(onboardingCompleted: true);
        await repo.updateProfile(updated);
      } catch (_) {
        // Non-critical: onboarding flag saved locally even if remote fails
      }
    }

    if (mounted) {
      context.go('/tasks');
    }
  }

  void _skip() => _completeOnboarding();

  void _nextPage() {
    _pageController.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _getStarted() => _completeOnboarding();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Skip button — top right
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.only(top: 8, right: 16),
                child: TextButton(
                  onPressed: _skip,
                  child: const Text('Skip'),
                ),
              ),
            ),

            // PageView
            Expanded(
              child: PageView(
                controller: _pageController,
                children: const [
                  OnboardingPage(
                    title: 'Welcome to FocusForge',
                    description:
                        'Smart task management that adapts to your energy and schedule.',
                    icon: Icons.auto_awesome_rounded,
                  ),
                  OnboardingPage(
                    title: 'Build Lasting Habits',
                    description:
                        'Track streaks, celebrate milestones, and make progress visible.',
                    icon: Icons.local_fire_department_rounded,
                  ),
                  OnboardingPage(
                    title: 'Your Day, Optimized',
                    description:
                        'AI-powered daily planning that puts the right tasks at the right time.',
                    icon: Icons.calendar_today_rounded,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Page indicator
            Center(
              child: SmoothPageIndicator(
                controller: _pageController,
                count: 3,
                effect: WormEffect(
                  dotHeight: 10,
                  dotWidth: 10,
                  activeDotColor: context.colorScheme.tertiary,
                  dotColor: context.colorScheme.outlineVariant,
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Bottom button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: _currentPage < 2
                  ? AppButton(
                      label: 'Next',
                      onPressed: _nextPage,
                    )
                  : FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: context.colorScheme.tertiary,
                        foregroundColor: context.colorScheme.onTertiary,
                        minimumSize: const Size(double.infinity, 48),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: _getStarted,
                      child: const Text('Get Started'),
                    ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
