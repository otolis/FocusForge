# Phase 8: Integration, Animations & Deployment - Research

**Researched:** 2026-03-22
**Domain:** Flutter cross-feature integration, Lottie animations, Flutter web deployment
**Confidence:** HIGH

## Summary

Phase 8 is a wiring and polish phase. It has three distinct workstreams: (1) integrating smart input into the task creation flow and connecting the AI planner to real tasks/habits, (2) adding Lottie celebration animations on key user actions, and (3) deploying the app as a Flutter web demo. The codebase is well-structured for integration -- smart input already has `SmartInputField` widget with `onParsed` callback, and the planner already has a `PlannableItemsNotifier` that can be adapted to pull from `taskListProvider` and `habitListProvider` instead of its own `plannable_items` table.

The biggest technical risk is **tflite_flutter NOT supporting Flutter web**. The TFLite classifier service uses native bindings (`package:tflite_flutter/tflite_flutter.dart`) that do not compile for web targets. The regex-based NLP parser will work on web, but the TFLite model inference will fail. The service already handles this gracefully (`_isLoaded` stays false, regex parsing still works), so a conditional disable for web is the correct approach.

**Primary recommendation:** Wire SmartInputField into TaskFormScreen and TaskQuickCreateSheet for NLP parsing, create a bridge provider that converts real Tasks + Habits into PlannableItems for the AI planner, add the `lottie` package (v3.3.2) with 3 animation files for task completion/habit check-in/streak milestones, conditionally disable TFLite on web, run `flutter create --platforms web .` to scaffold the web directory, and deploy via GitHub Pages with a GitHub Actions workflow.

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|-----------------|
| UX-02 | User sees Lottie animations on task completion, habit check-in, and streak milestones | Lottie package v3.3.2 supports all platforms including web; animation overlay pattern documented below; LottieFiles provides free task completion and confetti animations |
| UX-04 | App is deployed as Flutter web for live portfolio demo accessible via URL | Flutter web builds with CanvasKit renderer; GitHub Pages free hosting with base-href; web directory scaffolding needed; tflite_flutter web incompatibility must be handled |
</phase_requirements>

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| lottie | 3.3.2 | Render After Effects animations (JSON) in Flutter | Pure Dart implementation, works on all 6 platforms including web, 99% Likes on pub.dev, actively maintained |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| flutter (web platform) | >=3.29.0 | Web target support via CanvasKit | For `flutter build web` deployment |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| lottie (pub.dev) | rive | Rive requires Rive-specific animation files, not compatible with LottieFiles ecosystem; Lottie JSON files are widely available for free |
| GitHub Pages | Firebase Hosting | Firebase requires project setup and CLI; GitHub Pages is zero-config for existing repo |
| GitHub Pages | Cloudflare Pages | Cloudflare has unlimited bandwidth but more setup; GitHub Pages is simpler for portfolio demo |

**Installation:**
```bash
flutter pub add lottie
```

**Version verification:** lottie v3.3.2 confirmed on pub.dev (published ~September 2025). Supports Flutter >=3.27.

## Architecture Patterns

### Recommended Project Structure
```
lib/
  features/
    tasks/
      presentation/
        screens/
          task_form_screen.dart         # MODIFY: Add SmartInputField toggle
        widgets/
          task_quick_create_sheet.dart   # MODIFY: Replace TextField with SmartInputField
    planner/
      presentation/
        providers/
          real_items_bridge_provider.dart  # NEW: Bridges tasks+habits to PlannableItems
        screens/
          planner_screen.dart             # MODIFY: Wire real items bridge
  shared/
    widgets/
      celebration_overlay.dart            # NEW: Lottie animation overlay widget
assets/
  animations/                             # NEW: Lottie JSON files
    task_complete.json
    habit_checkin.json
    streak_milestone.json
web/
  index.html                              # SCAFFOLD: flutter create --platforms web
  manifest.json
  favicon.png
.github/
  workflows/
    deploy-web.yml                        # NEW: GitHub Actions deploy workflow
```

### Pattern 1: Smart Input Integration into Task Form
**What:** Replace the title TextField in TaskFormScreen with SmartInputField, auto-populating priority/deadline/category fields from NLP parsing.
**When to use:** When the user creates a new task (not edit mode).
**Example:**
```dart
// In TaskFormScreen (create mode only)
SmartInputField(
  controller: _titleController,
  onParsed: (parsed) {
    setState(() {
      if (parsed.suggestedPriority != null) {
        _selectedPriority = _mapStringToPriority(parsed.suggestedPriority!);
      }
      if (parsed.suggestedDeadline != null) {
        _selectedDeadline = parsed.suggestedDeadline;
      }
      if (parsed.suggestedCategory != null) {
        _selectedCategoryId = _matchCategoryByName(parsed.suggestedCategory!.displayName);
      }
    });
  },
),
```

### Pattern 2: Real Items Bridge Provider
**What:** A Riverpod provider that reads from `taskListProvider` and `habitListProvider` to create `PlannableItem` objects, replacing the manual `plannable_items` table for the planner.
**When to use:** When the planner generates a schedule, it should use real tasks/habits from the app.
**Example:**
```dart
// Bridge provider that combines tasks + habits into plannable items
final realPlannableItemsProvider = Provider.family<List<PlannableItem>, String>(
  (ref, userId) {
    final tasks = ref.watch(taskListProvider).valueOrNull ?? [];
    final habits = ref.watch(habitListProvider).valueOrNull ?? [];

    final items = <PlannableItem>[];

    // Convert uncompleted tasks with today's deadline
    for (final task in tasks.where((t) => !t.isCompleted)) {
      items.add(PlannableItem(
        id: task.id,
        userId: userId,
        title: task.title,
        durationMinutes: 30, // default estimate
        energyLevel: _mapPriorityToEnergy(task.priority),
        planDate: DateTime.now(),
        createdAt: task.createdAt,
      ));
    }

    // Convert habits due today
    for (final habit in habits.where((h) => !h.isCompletedToday)) {
      items.add(PlannableItem(
        id: habit.id,
        userId: userId,
        title: habit.name,
        durationMinutes: 15, // habits are typically short
        energyLevel: EnergyLevel.medium,
        planDate: DateTime.now(),
        createdAt: habit.createdAt,
      ));
    }

    return items;
  },
);
```

### Pattern 3: Lottie Celebration Overlay
**What:** A reusable overlay widget that plays a Lottie animation on top of content, then auto-dismisses.
**When to use:** On task completion, habit check-in, and streak milestones.
**Example:**
```dart
class CelebrationOverlay extends StatelessWidget {
  final String animationAsset;
  final VoidCallback onComplete;

  const CelebrationOverlay({
    required this.animationAsset,
    required this.onComplete,
  });

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Lottie.asset(
        animationAsset,
        repeat: false,
        onLoaded: (composition) {
          // Auto-dismiss after animation completes
          Future.delayed(composition.duration, onComplete);
        },
      ),
    );
  }
}
```

### Pattern 4: Conditional TFLite Disable for Web
**What:** Use `kIsWeb` to skip TFLite initialization on web, letting regex-only parsing work.
**When to use:** During smart input initialization.
**Example:**
```dart
// In smart_input_provider.dart
final smartInputInitProvider = FutureProvider<void>((ref) async {
  if (kIsWeb) return; // TFLite not supported on web
  final service = ref.read(smartInputServiceProvider);
  await service.initialize();
});
```

### Pattern 5: Flutter Web Scaffold and Build
**What:** Run `flutter create --platforms web .` in the project root to scaffold web support, then build with `flutter build web`.
**When to use:** One-time setup for web deployment.
**Example:**
```bash
# Scaffold web platform support
flutter create --platforms web .

# Build for deployment (CanvasKit renderer, default)
flutter build web --release --base-href '/FocusForge/'

# Output goes to build/web/
```

### Anti-Patterns to Avoid
- **Don't remove TFLite imports entirely:** Just guard initialization with `kIsWeb`. The imports are tree-shaken on web; only the native binding calls fail.
- **Don't create a separate "web version" of the app:** Use conditional compilation (`kIsWeb`) for platform-specific code paths, keeping one codebase.
- **Don't use Lottie.network() for animation files:** Bundle them as assets. Network loading adds latency and requires CORS-friendly hosting. Asset files are under 100KB each.
- **Don't wire SmartInputField into edit mode:** In edit mode the user is modifying existing fields, not parsing natural language. Only enable smart input in create mode.
- **Don't replace the existing PlannableItems system entirely:** Add a bridge that can populate from real data alongside the manual add-item flow. Users may still want to add ad-hoc items to the planner.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Celebration animations | Custom Canvas-based particle systems | `lottie` package with pre-made LottieFiles animations | Animation authoring is a design discipline; pre-made files look professional and are tested |
| Web deployment CI/CD | Manual build+push scripts | GitHub Actions with `bluefireteam/flutter-gh-pages` action or manual deploy step | Battle-tested, handles base-href, caching, and branch management |
| Confetti/fireworks effects | Custom AnimationController with random particles | Lottie confetti animation JSON | Physics-based particle systems are complex and never look as good |
| Flutter web index.html | Custom HTML boilerplate | `flutter create --platforms web .` scaffold | Generated file has correct service worker, loading spinner, and base-href placeholder |

**Key insight:** Phase 8 is an integration phase, not a feature-building phase. The goal is to wire existing components together and add polish. Resist the urge to rebuild or heavily modify working features.

## Common Pitfalls

### Pitfall 1: tflite_flutter Crashes on Web
**What goes wrong:** `tflite_flutter` uses FFI native bindings that are incompatible with Flutter web. The app will crash on web if TFLite model loading is attempted.
**Why it happens:** `tflite_flutter` loads `.tflite` model files via native C++ bindings; web has no FFI support.
**How to avoid:** Guard TFLite initialization with `import 'package:flutter/foundation.dart' show kIsWeb;` and skip on web. The existing `SmartInputService` already handles `isLoaded == false` gracefully -- regex parsing works without TFLite.
**Warning signs:** Build succeeds but app throws `UnimplementedError` or `UnsupportedError` at runtime on web.

### Pitfall 2: base-href Mismatch on GitHub Pages
**What goes wrong:** App loads with blank screen because asset paths are wrong. JavaScript console shows 404 for `main.dart.js` or `canvaskit.wasm`.
**Why it happens:** GitHub Pages serves from a subpath (`/RepoName/`), but Flutter's default base-href is `/`. All asset URLs resolve to wrong paths.
**How to avoid:** Always use `flutter build web --base-href '/FocusForge/'` (trailing slash required). The generated `index.html` has a `<base href="$FLUTTER_BASE_HREF">` placeholder that gets replaced.
**Warning signs:** Works locally (`flutter run -d chrome`) but fails when deployed.

### Pitfall 3: Lottie Animation Blocking UI Thread
**What goes wrong:** Complex Lottie animations (many layers, high frame count) cause jank, especially on web/low-end devices.
**Why it happens:** Lottie renders frame-by-frame; complex animations require more GPU/CPU per frame.
**How to avoid:** Use simple animations (< 50KB JSON, < 3 seconds duration, < 30 layers). Use `renderCache: RenderCache.drawingCommands` for repeated animations. Test on web specifically.
**Warning signs:** Dropped frames visible during animation playback.

### Pitfall 4: SmartInputField setState During Build
**What goes wrong:** Calling `setState` from `onParsed` callback during the build phase causes "setState called during build" error.
**Why it happens:** `SmartInputField` fires `onParsed` via `addPostFrameCallback`, but if the parent rebuilds in the same frame, timing can collide.
**How to avoid:** In the parent (TaskFormScreen), use `WidgetsBinding.instance.addPostFrameCallback` or guard with `mounted` check before `setState`. Alternatively, store parsed result in a separate state variable and apply on next build.
**Warning signs:** Red error screen in debug mode with "setState() or markNeedsBuild() called during build".

### Pitfall 5: Supabase Edge Functions CORS on Web
**What goes wrong:** Edge Function calls fail with CORS errors when running as Flutter web.
**Why it happens:** Browser enforces CORS preflight (OPTIONS request) for cross-origin API calls. Edge Functions must handle OPTIONS explicitly.
**How to avoid:** The existing `_shared/cors.ts` already has `Access-Control-Allow-Origin: '*'`. Verify each Edge Function handles the OPTIONS preflight request with early return: `if (req.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders })`.
**Warning signs:** Network tab shows OPTIONS request with no response, followed by CORS error.

### Pitfall 6: google_sign_in Web API Differences
**What goes wrong:** Google Sign-In on web uses different API (renderButton / Identity Services) vs mobile (native SDK).
**Why it happens:** google_sign_in v7.x changed web implementation to use Google Identity Services.
**How to avoid:** For a portfolio demo, email/password auth is sufficient. Google Sign-In on web requires additional configuration (authorized JavaScript origins, OAuth client ID for web). If needed, use `GoogleSignIn().renderButton()` widget on web instead of `signIn()`.
**Warning signs:** "authenticate is not supported on the web" error.

### Pitfall 7: Empty web/ Directory
**What goes wrong:** `flutter build web` fails because web platform was not properly scaffolded.
**Why it happens:** The project has an empty `web/` directory (no `index.html`, no `manifest.json`).
**How to avoid:** Run `flutter create --platforms web .` in the project root to scaffold all necessary web files.
**Warning signs:** Build error mentioning missing `web/index.html`.

## Code Examples

### Wiring SmartInputField into TaskQuickCreateSheet
```dart
// Source: Project codebase analysis of task_quick_create_sheet.dart
// Replace the plain TextField with SmartInputField in create mode

// Import the smart input widgets
import '../../../smart_input/presentation/widgets/smart_input_field.dart';
import '../../../smart_input/domain/parsed_task_input.dart';

// In the build method, replace the TextField with:
SmartInputField(
  controller: _titleController,
  hintText: 'e.g., "Buy groceries tomorrow high priority"',
  onParsed: (parsed) {
    setState(() {
      if (parsed.suggestedPriority != null) {
        _priority = _mapPriority(parsed.suggestedPriority!);
      }
      if (parsed.suggestedDeadline != null) {
        _deadline = parsed.suggestedDeadline;
      }
    });
  },
),
```

### Mapping SmartInputCategory to User Categories
```dart
// Source: Analysis of smart_input_category.dart and category_provider.dart
// Phase 8 integration: map SmartInputCategory enum to user's custom categories

String? _matchCategoryByName(String suggestedName, List<Category> userCategories) {
  // Try exact match first
  for (final cat in userCategories) {
    if (cat.name.toLowerCase() == suggestedName.toLowerCase()) {
      return cat.id;
    }
  }
  // Try contains match
  for (final cat in userCategories) {
    if (cat.name.toLowerCase().contains(suggestedName.toLowerCase()) ||
        suggestedName.toLowerCase().contains(cat.name.toLowerCase())) {
      return cat.id;
    }
  }
  return null; // No match found
}
```

### Playing Lottie Animation on Task Completion
```dart
// Source: Lottie package docs (pub.dev/packages/lottie)
// Overlay approach: show animation then remove

void _onTaskCompleted(BuildContext context) {
  final overlay = OverlayEntry(
    builder: (context) => Positioned.fill(
      child: IgnorePointer(
        child: Center(
          child: SizedBox(
            width: 200,
            height: 200,
            child: Lottie.asset(
              'assets/animations/task_complete.json',
              repeat: false,
            ),
          ),
        ),
      ),
    ),
  );

  Overlay.of(context).insert(overlay);
  Future.delayed(const Duration(seconds: 2), overlay.remove);
}
```

### GitHub Actions Deploy Workflow
```yaml
# Source: GitHub flutter/website docs and flutter-gh-pages action
# .github/workflows/deploy-web.yml

name: Deploy to GitHub Pages
on:
  push:
    branches: [main]
  workflow_dispatch:

permissions:
  contents: write

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
        with:
          channel: stable
      - run: flutter pub get
      - run: flutter build web --release --base-href '/FocusForge/'
      - uses: peaceiris/actions-gh-pages@v4
        with:
          github_token: ${{ secrets.GITHUB_TOKEN }}
          publish_dir: ./build/web
```

### Conditional TFLite Guard
```dart
// Source: Analysis of smart_input_provider.dart
import 'package:flutter/foundation.dart' show kIsWeb;

final smartInputInitProvider = FutureProvider<void>((ref) async {
  if (kIsWeb) {
    // TFLite not supported on web; regex parser still works
    return;
  }
  final service = ref.read(smartInputServiceProvider);
  await service.initialize();
});
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| HTML renderer for web | CanvasKit (default) / Skwasm (WASM) | Flutter 3.24+ (2024) | HTML renderer deprecated; CanvasKit is default; Skwasm for better perf |
| Manual web deploy | GitHub Actions + Pages | 2023+ | Automated CI/CD on push to main |
| Custom animations | Lottie JSON from LottieFiles | Stable since lottie 2.x | Professional-grade animations without designer dependency |
| `--web-renderer html` flag | Removed; auto-selects CanvasKit | Flutter 3.24+ | No need to specify renderer; CanvasKit is default |

**Deprecated/outdated:**
- Flutter HTML renderer: officially deprecated, CanvasKit is the only supported renderer
- `--web-renderer` flag: removed; no longer needed in build command
- Lottie v1.x API: replaced by v3.x with `renderCache` and `backgroundLoading` options

## Open Questions

1. **LottieFiles Animation Selection**
   - What we know: LottieFiles has free task completion and confetti animations
   - What's unclear: Exact animation files to use (need to be small, visually appropriate for the app's Material 3 theme)
   - Recommendation: Download 3 small (< 50KB) animations from LottieFiles: a checkmark for task completion, a gentle pulse/glow for habit check-in, and confetti for streak milestones. Store as `assets/animations/*.json`.

2. **Planner Bridge: Real Tasks vs Manual Items**
   - What we know: Planner currently uses `plannable_items` Supabase table for manual item entry
   - What's unclear: Should the bridge fully replace manual items or supplement them?
   - Recommendation: Add a toggle or "Import from Tasks" button that populates plannable items from real tasks. Keep the manual AddItemSheet as a fallback for ad-hoc items.

3. **google_sign_in on Web**
   - What we know: google_sign_in v7.x requires different web implementation (renderButton)
   - What's unclear: Whether the current GoogleSignIn configuration will work on web without changes
   - Recommendation: For the portfolio demo, email/password login is sufficient. Document Google Sign-In web setup as a follow-up if needed. The app already supports email auth via Supabase.

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | flutter_test + mockito |
| Config file | none (Flutter default) |
| Quick run command | `flutter test test/unit/` |
| Full suite command | `flutter test` |

### Phase Requirements to Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| UX-02 | Lottie overlay appears on task completion | widget | `flutter test test/widget/shared/celebration_overlay_test.dart -x` | No -- Wave 0 |
| UX-02 | Lottie overlay auto-dismisses after animation | widget | `flutter test test/widget/shared/celebration_overlay_test.dart -x` | No -- Wave 0 |
| UX-04 | Web build completes without errors | integration | `flutter build web --release --base-href '/FocusForge/'` | N/A (build step) |
| UX-04 | tflite_flutter guarded on web | unit | `flutter test test/unit/smart_input/web_guard_test.dart -x` | No -- Wave 0 |
| INT-01 | SmartInputField wired into TaskFormScreen | widget | `flutter test test/widget/tasks/task_form_smart_input_test.dart -x` | No -- Wave 0 |
| INT-02 | Real tasks bridge to PlannableItems | unit | `flutter test test/unit/planner/real_items_bridge_test.dart -x` | No -- Wave 0 |

### Sampling Rate
- **Per task commit:** `flutter test test/unit/`
- **Per wave merge:** `flutter test`
- **Phase gate:** Full suite green before `/gsd:verify-work`

### Wave 0 Gaps
- [ ] `test/widget/shared/celebration_overlay_test.dart` -- covers UX-02 (Lottie overlay display and dismissal)
- [ ] `test/unit/smart_input/web_guard_test.dart` -- covers UX-04 (kIsWeb conditional guard)
- [ ] `test/unit/planner/real_items_bridge_test.dart` -- covers INT-02 (tasks+habits to plannable items conversion)
- [ ] `test/widget/tasks/task_form_smart_input_test.dart` -- covers INT-01 (SmartInputField in task form)
- [ ] `assets/animations/task_complete.json` -- placeholder Lottie JSON file for tests
- [ ] `assets/animations/habit_checkin.json` -- placeholder Lottie JSON file
- [ ] `assets/animations/streak_milestone.json` -- placeholder Lottie JSON file

## Sources

### Primary (HIGH confidence)
- Project codebase analysis: `lib/features/smart_input/`, `lib/features/tasks/`, `lib/features/planner/`, `lib/features/habits/` -- all integration points analyzed
- [pub.dev/packages/lottie](https://pub.dev/packages/lottie) -- v3.3.2, supports all 6 platforms including web
- [docs.flutter.dev/deployment/web](https://docs.flutter.dev/deployment/web) -- official Flutter web deployment guide
- [docs.flutter.dev/platform-integration/web/renderers](https://docs.flutter.dev/platform-integration/web/renderers) -- CanvasKit default, HTML deprecated

### Secondary (MEDIUM confidence)
- [github.com/tensorflow/flutter-tflite/issues/207](https://github.com/tensorflow/flutter-tflite/issues/207) -- confirmed tflite_flutter does NOT support web
- [github.com/supabase/supabase/issues/18018](https://github.com/supabase/supabase/issues/18018) -- Supabase CORS handling for Flutter web
- [codewithandrea.com/articles/flutter-web-github-pages/](https://codewithandrea.com/articles/flutter-web-github-pages/) -- Flutter web on GitHub Pages with base-href
- [lottiefiles.com/free-animations/task-completion](https://lottiefiles.com/free-animations/task-completion) -- free Lottie task completion animations

### Tertiary (LOW confidence)
- [coldfusion-example.blogspot.com](https://coldfusion-example.blogspot.com/2026/01/flutter-web-performance-2025-canvaskit.html) -- CanvasKit vs WASM performance claims (blog, not official)

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - lottie package well-established, Flutter web stable, GitHub Pages straightforward
- Architecture: HIGH - integration patterns derived from direct analysis of existing codebase, SmartInputField already has onParsed callback, PlannableItem model already exists
- Pitfalls: HIGH - tflite_flutter web incompatibility confirmed via GitHub issue tracker, base-href issue well-documented, CORS headers already in project
- Integration points: HIGH - all source/target code files read and analyzed, callback signatures confirmed

**Research date:** 2026-03-22
**Valid until:** 2026-04-22 (stable domain, no fast-moving dependencies)
