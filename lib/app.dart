import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/theme/app_theme.dart';
import 'features/settings/presentation/providers/theme_provider.dart';

/// Root application widget.
///
/// Uses [ConsumerWidget] to watch the [themeProvider] for live theme
/// mode switching (light / dark / system).
class FocusForgeApp extends ConsumerWidget {
  const FocusForgeApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);

    return MaterialApp(
      title: 'FocusForge',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: themeMode,
      home: const Scaffold(
        body: Center(
          child: Text('FocusForge'),
        ),
      ),
    );
  }
}
