import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'features/settings/presentation/providers/theme_provider.dart';

/// Root application widget.
///
/// Uses [ConsumerWidget] to watch the [themeProvider] for live theme
/// mode switching (light / dark / system) and [appRouterProvider] for
/// declarative routing with auth-based redirects.
class FocusForgeApp extends ConsumerWidget {
  const FocusForgeApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: 'FocusForge',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: themeMode,
      routerConfig: router,
    );
  }
}
