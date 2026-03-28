import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Manages the app-wide [ThemeMode] and persists the user's choice
/// to [SharedPreferences].
///
/// Defaults to [ThemeMode.system] on first launch.
class ThemeNotifier extends Notifier<ThemeMode> {
  static const _key = 'theme_mode';

  @override
  ThemeMode build() {
    _loadTheme();
    return ThemeMode.system;
  }

  /// Loads the persisted theme mode from [SharedPreferences].
  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    // Guard removed — Notifier lifecycle managed by Riverpod
    final themeIndex = prefs.getInt(_key) ?? 2; // default: system
    state = ThemeMode.values[themeIndex];
  }

  /// Sets the theme mode and persists it to [SharedPreferences].
  Future<void> setTheme(ThemeMode mode) async {
    state = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_key, mode.index);
  }
}

/// Provides the current [ThemeMode] for the app.
///
/// Watch this provider in [MaterialApp] to reactively switch between
/// light, dark, and system theme modes.
final themeProvider = NotifierProvider<ThemeNotifier, ThemeMode>(
  ThemeNotifier.new,
);
