import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:focusforge/features/settings/presentation/providers/theme_provider.dart';

import '../../helpers/test_helpers.dart';

void main() {
  group('ThemeNotifier', () {
    setUp(() {
      setupMockSharedPreferences();
    });

    test('initial state is ThemeMode.system', () {
      final notifier = ThemeNotifier();
      expect(notifier.state, equals(ThemeMode.system));
    });

    test('setTheme updates state to dark', () async {
      final notifier = ThemeNotifier();
      await notifier.setTheme(ThemeMode.dark);
      expect(notifier.state, equals(ThemeMode.dark));
    });

    test('setTheme updates state to light', () async {
      final notifier = ThemeNotifier();
      await notifier.setTheme(ThemeMode.light);
      expect(notifier.state, equals(ThemeMode.light));
    });

    test('persists theme mode to SharedPreferences', () async {
      final notifier = ThemeNotifier();
      await notifier.setTheme(ThemeMode.dark);

      // Verify the value was persisted
      final prefs = await SharedPreferences.getInstance();
      final savedIndex = prefs.getInt('theme_mode');
      expect(savedIndex, equals(ThemeMode.dark.index));
    });

    test('loads persisted theme mode on creation', () async {
      // Pre-set a saved theme mode (light = index 1)
      SharedPreferences.setMockInitialValues({'theme_mode': 1});

      final notifier = ThemeNotifier();

      // Give time for the async _loadTheme to complete
      await Future<void>.delayed(const Duration(milliseconds: 100));

      expect(notifier.state, equals(ThemeMode.light));
    });
  });
}
