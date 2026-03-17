import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/extensions.dart';
import '../../providers/theme_provider.dart';

/// A settings screen providing theme toggle and app information.
///
/// The primary theme toggle lives on the Profile screen per UI-SPEC.
/// This screen provides an additional settings entry point for future
/// Phase 2+ features like notification preferences, data export, etc.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentThemeMode = ref.watch(themeProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        children: [
          // Theme section
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Appearance',
                    style: context.textTheme.labelLarge?.copyWith(
                      color: context.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: SegmentedButton<ThemeMode>(
                      segments: const [
                        ButtonSegment(
                          value: ThemeMode.light,
                          label: Text('Light'),
                          icon: Icon(Icons.light_mode_rounded),
                        ),
                        ButtonSegment(
                          value: ThemeMode.dark,
                          label: Text('Dark'),
                          icon: Icon(Icons.dark_mode_rounded),
                        ),
                        ButtonSegment(
                          value: ThemeMode.system,
                          label: Text('System'),
                          icon: Icon(Icons.settings_brightness_rounded),
                        ),
                      ],
                      selected: {currentThemeMode},
                      onSelectionChanged: (modes) =>
                          ref.read(themeProvider.notifier).setTheme(modes.first),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // About section
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.info_outline_rounded),
                  title: const Text('About FocusForge'),
                  subtitle: const Text('Version 1.0.0'),
                  onTap: () {
                    showAboutDialog(
                      context: context,
                      applicationName: 'FocusForge',
                      applicationVersion: '1.0.0',
                      applicationLegalese:
                          'AI-Powered Task Manager + Habit Tracker',
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
