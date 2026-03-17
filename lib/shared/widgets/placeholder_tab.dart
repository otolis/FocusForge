import 'package:flutter/material.dart';

import '../../core/utils/extensions.dart';

/// A placeholder widget for tabs that are not yet implemented.
///
/// Shows a centered construction icon with "Coming Soon" text and a
/// description. Used for Tasks, Habits, and Planner tabs in Phase 1.
class PlaceholderTab extends StatelessWidget {
  const PlaceholderTab({super.key, required this.title});

  /// The name of the feature this tab will contain (e.g., "Tasks").
  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.construction_rounded,
                size: 64,
                color: context.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
              ),
              const SizedBox(height: 16),
              Text(
                'Coming Soon',
                style: context.textTheme.headlineMedium?.copyWith(
                  color: context.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'This feature is being built. Check back after the next update.',
                style: context.textTheme.bodyMedium?.copyWith(
                  color: context.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
