# Stack Research

**Domain:** Cross-platform Flutter productivity app with AI features, Supabase backend, and realtime collaboration
**Researched:** 2026-03-16
**Confidence:** HIGH (versions verified via pub.dev, patterns verified via multiple authoritative sources)

## Recommended Stack

### Core Framework

| Technology | Version | Purpose | Why Recommended |
|------------|---------|---------|-----------------|
| Flutter SDK | ^3.41.x (latest stable) | Cross-platform UI framework | Latest stable (Feb 2026). 868 commits, enhanced rendering, improved web support. Required for Android-first + web demo deployment. |
| Dart SDK | ^3.8.x | Language runtime | Ships with Flutter 3.41. Pattern matching, records, sealed classes for Clean Architecture domain modeling. |
| Supabase | (cloud service) | Backend-as-a-Service | Auth, PostgreSQL, Realtime, Edge Functions, Storage -- replaces entire custom backend. Free tier sufficient for portfolio project. |
| Groq API | (cloud service, free tier) | AI inference for daily planner | 14,400 req/day free tier. Llama 3 models via Supabase Edge Functions. Fastest inference provider, ideal for real-time AI planning responses. |

### State Management & Architecture

| Technology | Version | Purpose | Why Recommended |
|------------|---------|---------|-----------------|
| flutter_riverpod | ^3.3.1 | State management | Riverpod 3 is the de facto Flutter state management in 2026. Auto-retry on failures, automatic listener pausing, experimental mutations support. Code-gen syntax reduces boilerplate significantly. |
| riverpod_annotation | ^4.0.2 | Provider code generation annotations | Required for `@riverpod` annotation syntax. Eliminates manual provider wiring -- generates providers from annotated functions/classes. |
| riverpod_generator | ^4.0.3 | Provider code generator | Generates provider code from annotations. Pairs with riverpod_annotation and build_runner. |
| hooks_riverpod | ^3.3.1 | Riverpod + Hooks integration | Provides `HookConsumerWidget` for combining hooks (animation controllers, text controllers) with Riverpod providers. Less boilerplate than raw StatefulWidgets. |
| flutter_hooks | ^0.21.3+1 | React-style hooks for Flutter | Use `useAnimationController`, `useTextEditingController`, etc. Reduces StatefulWidget usage for simple state. |

### Backend & Data

| Technology | Version | Purpose | Why Recommended |
|------------|---------|---------|-----------------|
| supabase_flutter | ^2.12.0 | Supabase client for Flutter | Official SDK. Handles Auth, Realtime subscriptions, Edge Function invocation, and PostgREST queries. Auto-manages session persistence via flutter_secure_storage internally. |
| google_sign_in | ^7.2.0 | Native Google sign-in | Required for Supabase Google auth flow on Android. Uses native sign-in (no browser redirect). Supabase `signInWithIdToken()` accepts the Google ID token directly. |

### Navigation

| Technology | Version | Purpose | Why Recommended |
|------------|---------|---------|-----------------|
| go_router | ^17.1.0 | Declarative routing | Official Flutter team package. Supports deep linking, nested navigation via ShellRoute (needed for bottom nav + feature routes), redirect guards for auth, and web URL patterns. Feature-complete and stable. |

### Code Generation & Serialization

| Technology | Version | Purpose | Why Recommended |
|------------|---------|---------|-----------------|
| freezed | ^3.2.5 | Immutable data classes with unions | Generates `copyWith`, `==`, `hashCode`, `toString`, and union types (sealed classes). Essential for Clean Architecture entities and domain models. Integrates with json_serializable. |
| json_serializable | ^6.13.0 | JSON serialization/deserialization | Standard Dart JSON codegen. Freezed delegates `toJson`/`fromJson` to this. Required for Supabase data model serialization. |
| json_annotation | ^4.9.x | JSON annotations | Provides `@JsonSerializable`, `@JsonKey` annotations used by json_serializable. |
| build_runner | ^2.12.2 | Code generation orchestrator (dev dep) | Runs freezed, json_serializable, riverpod_generator, and envied_generator. Single `dart run build_runner build` generates all code. |

### Environment & Configuration

| Technology | Version | Purpose | Why Recommended |
|------------|---------|---------|-----------------|
| envied | ^1.3.3 | Compile-time env variable access | Generates type-safe Dart code from `.env` files at build time. Supports obfuscation to prevent APK reverse engineering. Far more secure than flutter_dotenv which bundles .env as readable asset. |
| envied_generator | ^1.3.3 | Code generator for envied (dev dep) | Pairs with envied and build_runner. Generates the implementation classes. |

### Charts & Data Visualization

| Technology | Version | Purpose | Why Recommended |
|------------|---------|---------|-----------------|
| fl_chart | ^1.2.0 | Charts for habit analytics | Most popular Flutter charting library. Supports line, bar, pie, scatter, radar, candlestick charts. Touch handling, tooltips, animations, gradient fills. Active maintenance (updated 2 days ago as of research date). |

### AI & On-Device ML

| Technology | Version | Purpose | Why Recommended |
|------------|---------|---------|-----------------|
| tflite_flutter | ^0.12.1 | On-device TFLite inference | Official TensorFlow plugin maintained by Google. Runs ML models locally for task classification without cloud costs. Supports multi-threading and isolate-based inference to avoid UI jank. Phase 2 upgrade from regex parser. |
| speech_to_text | ^7.3.0 | Voice-to-text input | Exposes platform speech recognition (Android SpeechRecognizer). Best for commands and short phrases -- exactly the task capture use case. No cloud cost (uses device APIs). |

### Push Notifications

| Technology | Version | Purpose | Why Recommended |
|------------|---------|---------|-----------------|
| firebase_core | ^4.5.0 | Firebase initialization | Required base dependency for any Firebase service. |
| firebase_messaging | ^16.1.2 | FCM push notifications | Industry standard for push notifications on Android. Handles background messages, notification permissions (Android 13+), and topic subscriptions. |
| flutter_local_notifications | ^21.0.0 | Local notification display | Required to show foreground FCM notifications (FCM only delivers to system tray when app is backgrounded). Also useful for habit reminders scheduled locally. |

### Animations & UI Polish

| Technology | Version | Purpose | Why Recommended |
|------------|---------|---------|-----------------|
| lottie | ^3.3.2 | Lottie JSON animations | Renders After Effects animations. Huge free library of pre-built animations on LottieFiles. Best for task completion celebrations, loading states, empty states. Lightweight and battle-tested. |
| rive | ^0.14.4 | Interactive state-machine animations | Use for the one or two hero animations that need interactivity (e.g., streak milestone mascot). Rive's state machines respond to user input. Overkill for simple animations -- use Lottie for those. |

### Collaborative Boards (Kanban)

| Technology | Version | Purpose | Why Recommended |
|------------|---------|---------|-----------------|
| kanban_board | ^1.0.0+2 | Drag-and-drop Kanban widget | Fully customizable Kanban board with cross-column drag-and-drop. 42 likes, 140 pub points. Updated May 2025. Use as a starting point, but plan to customize heavily for the realtime collaboration layer. |

**Note on appflowy_board:** While well-known, it was last published 23 months ago (v0.1.2). The `kanban_board` package is more recent. However, given the heavy customization needed for realtime collaboration, consider building a custom Kanban using Flutter's built-in `Draggable`, `DragTarget`, and `ReorderableListView` widgets -- this gives full control over the realtime sync layer.

### Utility Libraries

| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| uuid | ^4.5.3 | Unique ID generation | Client-side ID generation for tasks, habits, board items before Supabase insert. Use UUIDv4. |
| intl | ^0.20.2 | Date/time formatting, i18n | Format deadlines, streak dates, planner times. Flutter Favorite package. |
| cached_network_image | ^3.4.1 | Image caching | Cache user avatars and profile images. Avoids re-downloading on every render. |
| flutter_animate | ^4.x | Declarative animation builder | Simpler than raw AnimationController for common UI animations (fade, slide, scale). Use for list item entrance animations and micro-interactions. Verify exact latest version. |

### Development Tools

| Tool | Purpose | Notes |
|------|---------|-------|
| build_runner | ^2.12.2 | Code generation | Run: `dart run build_runner build --delete-conflicting-outputs`. Use `watch` during development for auto-regeneration. |
| very_good_analysis | latest | Lint rules | Strict, opinionated lint rules used by the Flutter community. Enforces consistent style across the project. |
| mocktail | latest | Testing mocks | Null-safe mocking without codegen. Simpler than mockito for unit testing repositories, use cases, and notifiers. |
| supabase_cli | latest | Supabase local dev | Run Supabase locally for Edge Function development and database migrations. Install via npm or Homebrew. |
| Deno | ^1.x or ^2.x | Edge Function runtime | Supabase Edge Functions run on Deno. Required for local Edge Function development and testing. |

## Installation

```yaml
# pubspec.yaml

dependencies:
  flutter:
    sdk: flutter

  # State Management
  flutter_riverpod: ^3.3.1
  hooks_riverpod: ^3.3.1
  flutter_hooks: ^0.21.3+1
  riverpod_annotation: ^4.0.2

  # Backend
  supabase_flutter: ^2.12.0
  google_sign_in: ^7.2.0

  # Navigation
  go_router: ^17.1.0

  # Serialization
  freezed_annotation: ^3.2.5
  json_annotation: ^4.9.0

  # Environment
  envied: ^1.3.3

  # Charts
  fl_chart: ^1.2.0

  # AI & Voice
  speech_to_text: ^7.3.0
  tflite_flutter: ^0.12.1  # Add in Phase 2 when upgrading from regex

  # Push Notifications
  firebase_core: ^4.5.0
  firebase_messaging: ^16.1.2
  flutter_local_notifications: ^21.0.0

  # Kanban
  kanban_board: ^1.0.0+2  # Evaluate; may build custom instead

  # Animations
  lottie: ^3.3.2
  rive: ^0.14.4

  # Utilities
  uuid: ^4.5.3
  intl: ^0.20.2
  cached_network_image: ^3.4.1

dev_dependencies:
  flutter_test:
    sdk: flutter

  # Code Generation
  build_runner: ^2.12.2
  freezed: ^3.2.5
  json_serializable: ^6.13.0
  riverpod_generator: ^4.0.3
  envied_generator: ^1.3.3

  # Linting
  very_good_analysis: ^7.0.0

  # Testing
  mocktail: ^1.0.4
```

```bash
# Supabase CLI (install globally)
npm install -g supabase

# Or with Dart:
dart pub get

# Code generation
dart run build_runner build --delete-conflicting-outputs

# Watch mode during development
dart run build_runner watch --delete-conflicting-outputs
```

## Alternatives Considered

| Recommended | Alternative | When to Use Alternative |
|-------------|-------------|-------------------------|
| Riverpod 3 (flutter_riverpod) | Bloc | Only if joining a team already using Bloc, or if the strict event-driven pattern is mandated. Riverpod has less boilerplate and better DX for a solo developer portfolio project. |
| go_router | auto_route | Only if you need deeply nested type-safe routes with code generation. go_router is simpler, officially maintained by Flutter team, and sufficient for this app's routing needs. |
| freezed | dart_mappable | Only if you want a lighter-weight alternative without union types. Freezed is the community standard and integrates seamlessly with json_serializable. |
| envied | flutter_dotenv | Never for production -- flutter_dotenv bundles .env as a readable asset in the APK. Only acceptable for quick prototyping where security is irrelevant. |
| fl_chart | syncfusion_flutter_charts | Only if you need enterprise-grade charts with 30+ chart types. Syncfusion requires a license (free for individuals). fl_chart covers all chart types needed for habit analytics. |
| lottie + rive | just lottie | If you do not need interactive state-machine animations. Lottie alone covers 90% of animation needs. Rive adds value only for hero interactive animations. |
| supabase_flutter | firebase (full suite) | If you need ML Kit, Crashlytics, A/B Testing, or other Firebase-exclusive services. Supabase is better here because: open-source, real PostgreSQL, built-in Realtime, simpler Edge Functions, and the project already chose Supabase. |
| kanban_board | Custom Draggable/DragTarget | Recommended to start with kanban_board but migrate to custom implementation when realtime sync requirements demand fine-grained control over drag state broadcasting. |
| speech_to_text | google_speech | Only if you need cloud-based speech recognition for better accuracy. speech_to_text uses free on-device recognition -- perfect for the "free AI" constraint. |
| tflite_flutter | google_ml_kit | If you only need pre-built ML features (text recognition, barcode scanning). tflite_flutter is better because FocusForge needs a custom classification model for task parsing. |

## What NOT to Use

| Avoid | Why | Use Instead |
|-------|-----|-------------|
| Provider (package) | Officially superseded by Riverpod. The Provider package author (Remi Rousselet) created Riverpod as its replacement. Provider lacks compile-time safety and has context-dependency issues. | flutter_riverpod ^3.3.1 |
| GetX | Promotes anti-patterns: global singletons, magic string routes, tight coupling. Poor testability. Not taken seriously in professional Flutter development. | Riverpod + go_router |
| flutter_dotenv | Bundles .env file as a readable asset in the APK. Any user can unzip the APK and read your API keys in plaintext. Fundamentally insecure. | envied ^1.3.3 with obfuscation enabled |
| http (package) | Low-level, no interceptors, no retry logic, no request cancellation. | supabase_flutter handles all HTTP via its built-in client. For any custom HTTP, use dio. |
| sqflite / drift | Project is online-only for v1 (per constraints). Adding local SQLite adds sync complexity without portfolio payoff. | Direct Supabase PostgREST queries via supabase_flutter |
| appflowy_board | Last published 23 months ago (v0.1.2). Stale maintenance, likely compatibility issues with Flutter 3.41. | kanban_board ^1.0.0+2 or custom Draggable/DragTarget implementation |
| mockito | Requires code generation (build_runner) for mocks, adding complexity. Null-safety support was bolted on. | mocktail -- no codegen, null-safe by design, simpler API |
| StateNotifier (riverpod 2 pattern) | Deprecated in Riverpod 3. Replaced by Notifier and AsyncNotifier with the @riverpod annotation syntax. | @riverpod annotated Notifier classes |

## Stack Patterns by Variant

**If adding offline support later (v2):**
- Add `drift` (SQLite wrapper) for local persistence
- Use Riverpod 3's experimental offline persistence (mutations API)
- Implement optimistic updates with rollback on sync failure
- This is explicitly out of scope for v1

**If Groq free tier becomes insufficient:**
- Swap Groq API for Cloudflare Workers AI (also free tier) in the Edge Function
- The Edge Function abstraction means zero Flutter code changes -- only the Deno function body changes
- Alternative: use Supabase's built-in AI features (pgvector + embeddings) for simpler AI needs

**If targeting iOS later:**
- Add `sign_in_with_apple` package for Apple sign-in
- Update `google_sign_in` iOS configuration
- Add `flutter_secure_storage` explicit dependency if needed for iOS Keychain
- Firebase/FCM already supports iOS with APNs bridging

**If web performance is poor:**
- Use `flutter build web --wasm` (Wasm compilation, stable since Flutter 3.22)
- Consider CanvasKit renderer over HTML renderer for consistent rendering
- Lazy-load heavy features (charts, Kanban board) with deferred imports

## Version Compatibility

| Package | Compatible With | Notes |
|---------|-----------------|-------|
| flutter_riverpod ^3.3.1 | Flutter >=3.27 | Riverpod 3 requires Flutter 3.27+ and Dart 3.6+ |
| hooks_riverpod ^3.3.1 | flutter_hooks ^0.21.x | Must use same major version of Riverpod across all Riverpod packages |
| riverpod_annotation ^4.0.2 | riverpod_generator ^4.0.3 | Annotation and generator versions must match major version |
| supabase_flutter ^2.12.0 | Flutter >=3.19 | Uses flutter_secure_storage internally for session persistence |
| go_router ^17.1.0 | Flutter >=3.32, Dart >=3.8 | Recent versions bumped minimum SDK requirements |
| freezed ^3.2.5 | build_runner ^2.12.x | Freezed 3.x requires build_runner 2.x |
| firebase_messaging ^16.1.2 | firebase_core ^4.5.0 | All Firebase packages must use compatible versions from the same BoM release |
| tflite_flutter ^0.12.1 | Android NDK required | Must configure NDK in android/app/build.gradle. No web support. |
| speech_to_text ^7.3.0 | Android 5.0+ (API 21+) | Requires RECORD_AUDIO permission. No web support for voice input. |
| fl_chart ^1.2.0 | Flutter >=3.27.4 | v1.0 bumped minimum Flutter version significantly |
| kanban_board ^1.0.0+2 | Flutter >=3.0 | Verify compatibility with Flutter 3.41 before committing to this package |

## Supabase Edge Functions Stack

Edge Functions run in Deno (not Node.js). The AI planner function stack:

| Technology | Purpose | Notes |
|------------|---------|-------|
| Deno runtime | Edge Function execution | TypeScript-first, built-in fetch API, no npm needed for most tasks |
| Supabase JS client | Database access from Edge Functions | `@supabase/supabase-js` for querying user data within the function |
| Groq SDK | AI inference | `groq-sdk` npm package via Deno npm: specifier, or raw fetch to `https://api.groq.com/openai/v1/chat/completions` |
| Oak or Hono | HTTP framework (optional) | Only if Edge Functions need complex routing. Simple functions can use the built-in `serve()` handler. |

## Architecture Decision: Riverpod 3 Code Generation

Use the **code generation approach** with `@riverpod` annotations, not the manual provider syntax. Rationale:

1. **Less boilerplate:** `@riverpod` on a function/class auto-generates the provider, eliminating manual `Provider`, `NotifierProvider`, `AsyncNotifierProvider` declarations
2. **Consistent with Riverpod 3 direction:** The Riverpod team is pushing code-gen as the primary API
3. **Simplified Ref types:** Code-gen uses `Ref ref` universally instead of provider-specific `ExampleRef ref`
4. **Portfolio clarity:** Reviewers see clean, annotated code rather than verbose manual wiring

```dart
// RECOMMENDED: Code-gen syntax
@riverpod
class TaskList extends _$TaskList {
  @override
  Future<List<Task>> build() async {
    return ref.read(taskRepositoryProvider).getTasks();
  }

  Future<void> addTask(Task task) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() =>
      ref.read(taskRepositoryProvider).addTask(task),
    );
  }
}

// AVOID: Manual syntax (Riverpod 2 style)
// final taskListProvider = AsyncNotifierProvider<TaskListNotifier, List<Task>>(
//   TaskListNotifier.new,
// );
```

## Sources

- [pub.dev/packages/flutter_riverpod](https://pub.dev/packages/flutter_riverpod) -- version 3.3.1 verified (HIGH confidence)
- [pub.dev/packages/supabase_flutter](https://pub.dev/packages/supabase_flutter) -- version 2.12.0 verified (HIGH confidence)
- [pub.dev/packages/go_router](https://pub.dev/packages/go_router) -- version 17.1.0 verified (HIGH confidence)
- [pub.dev/packages/freezed](https://pub.dev/packages/freezed) -- version 3.2.5 verified (HIGH confidence)
- [pub.dev/packages/fl_chart](https://pub.dev/packages/fl_chart) -- version 1.2.0 verified (HIGH confidence)
- [pub.dev/packages/tflite_flutter](https://pub.dev/packages/tflite_flutter) -- version 0.12.1 verified (HIGH confidence)
- [pub.dev/packages/speech_to_text](https://pub.dev/packages/speech_to_text) -- version 7.3.0 verified (HIGH confidence)
- [pub.dev/packages/firebase_messaging](https://pub.dev/packages/firebase_messaging) -- version 16.1.2 verified (HIGH confidence)
- [pub.dev/packages/lottie](https://pub.dev/packages/lottie) -- version 3.3.2 verified (HIGH confidence)
- [pub.dev/packages/rive](https://pub.dev/packages/rive) -- version 0.14.4 verified (HIGH confidence)
- [pub.dev/packages/envied](https://pub.dev/packages/envied) -- version 1.3.3 verified (HIGH confidence)
- [pub.dev/packages/kanban_board](https://pub.dev/packages/kanban_board) -- version 1.0.0+2 verified (MEDIUM confidence -- evaluate compatibility)
- [riverpod.dev/docs/whats_new](https://riverpod.dev/docs/whats_new) -- Riverpod 3 features (HIGH confidence)
- [blog.flutter.dev](https://blog.flutter.dev/whats-new-in-flutter-3-41-302ec140e632) -- Flutter 3.41 release notes (HIGH confidence)
- [supabase.com/docs/guides/functions](https://supabase.com/docs/guides/functions) -- Edge Functions documentation (HIGH confidence)
- [codewithandrea.com](https://codewithandrea.com/articles/flutter-riverpod-async-notifier/) -- Riverpod code-gen patterns (MEDIUM confidence)
- [codewithandrea.com](https://codewithandrea.com/articles/flutter-api-keys-dart-define-env-files/) -- envied vs flutter_dotenv security analysis (MEDIUM confidence)
- [foresightmobile.com/blog/best-flutter-state-management](https://foresightmobile.com/blog/best-flutter-state-management) -- State management comparison 2026 (MEDIUM confidence)

---
*Stack research for: FocusForge -- Flutter AI productivity app with Supabase*
*Researched: 2026-03-16*
