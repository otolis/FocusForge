import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Sets up mock [SharedPreferences] with empty initial values.
///
/// Call this in `setUp()` before any test that uses [SharedPreferences].
void setupMockSharedPreferences([Map<String, Object> values = const {}]) {
  SharedPreferences.setMockInitialValues(values);
}

/// Wraps a [child] widget in a [ProviderScope] and [MaterialApp]
/// for widget testing.
///
/// Optionally accepts [overrides] for Riverpod provider overrides.
Widget createTestApp(
  Widget child, {
  // ignore: strict_raw_type
  List overrides = const [],
}) {
  return ProviderScope(
    overrides: overrides.cast(),
    child: MaterialApp(
      home: child,
    ),
  );
}

/// Creates a [ProviderContainer] for unit testing Riverpod providers.
///
/// Remember to call `container.dispose()` in `tearDown()`.
ProviderContainer createContainer({
  // ignore: strict_raw_type
  List overrides = const [],
}) {
  final container = ProviderContainer(overrides: overrides.cast());
  return container;
}
