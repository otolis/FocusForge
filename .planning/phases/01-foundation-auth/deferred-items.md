# Deferred Items - Phase 01

## Flutter SDK Not Installed

- **Discovered during:** Plan 01-01, Task 1
- **Impact:** Cannot run `flutter pub get`, `flutter analyze`, `flutter test`, or `flutter run`
- **Action needed:** User must install Flutter SDK 3.29.0+ and ensure `flutter` command is on PATH
- **Verification:** `flutter --version` should report 3.29.0 or later

## Runtime Test Verification Pending

- **Discovered during:** Plan 01-01, Task 3
- **Impact:** Theme provider tests written but not executed via `flutter test`
- **Action needed:** Run `flutter test test/unit/settings/theme_provider_test.dart` after Flutter SDK is installed
- **Expected result:** All 5 tests should pass green
