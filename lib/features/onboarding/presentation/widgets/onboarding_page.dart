import 'package:flutter/material.dart';

import '../../../../core/utils/extensions.dart';

/// A single page within the onboarding PageView.
///
/// Displays a large icon, title, and description vertically centered.
/// Per UI-SPEC: icon area is 240dp, title uses Nunito 28dp bold (display),
/// description uses Inter 16dp regular (body), onSurfaceVariant color.
class OnboardingPage extends StatelessWidget {
  const OnboardingPage({
    super.key,
    required this.title,
    required this.description,
    required this.icon,
  });

  /// The page title displayed below the icon.
  final String title;

  /// A brief description below the title (max 2 lines).
  final String description;

  /// The large icon displayed in the illustration area.
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            height: 240,
            child: Center(
              child: Icon(
                icon,
                size: 120,
                color: context.colorScheme.primary.withValues(alpha: 0.7),
              ),
            ),
          ),
          const SizedBox(height: 32),
          Text(
            title,
            style: context.textTheme.displayMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            description,
            style: context.textTheme.bodyMedium?.copyWith(
              color: context.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
