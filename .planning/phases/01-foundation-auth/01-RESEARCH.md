# Phase 1: Foundation & Auth - Research

**Researched:** 2026-03-17
**Domain:** Flutter project scaffold, Supabase Auth, Material 3 theming, onboarding
**Confidence:** HIGH

## Summary

Phase 1 is a greenfield Flutter project setup covering: project scaffold with MVVM/Clean Architecture, Supabase initialization (Auth + PostgreSQL profiles table with RLS), email/password and Google OAuth sign-in, user profile management (display name, avatar, energy pattern preferences), Material 3 theming with light/dark/system toggle, and a skippable onboarding flow.

The Flutter + Supabase ecosystem is mature and well-documented. All required packages are actively maintained with recent releases. The key architectural decisions are: Riverpod 2/3 for state management (manual providers, no code generation -- simpler for a portfolio project), go_router for declarative routing with auth guards via `refreshListenable`, and Supabase's built-in auth state stream driving navigation. The profiles table uses a database trigger to auto-create on signup, with RLS policies for user-owned data.

**Primary recommendation:** Use `supabase_flutter` 2.12.x for Auth + DB, `flutter_riverpod` 3.3.x for state, `go_router` 17.x for routing with auth redirect guards, and `ColorScheme.fromSeed` with amber seed color (#FF8F00) for Material 3 theming.

<user_constraints>

## User Constraints (from CONTEXT.md)

### Locked Decisions
- Warm & friendly overall vibe -- approachable, encouraging, "You've got this" feel
- Rounded corners throughout, friendly micro-copy
- Amber/orange seed color (#FF8F00 range) for Material 3 dynamic color scheme
- Light mode: deep amber primary, cream white surfaces, teal/forest green accents
- Dark mode: soft gold primary, warm charcoal surfaces, sage green accents
- System default theme on first launch (follows device setting), user can override in settings to light/dark/system
- Google Fonts for custom typography -- specific font pairing at Claude's discretion, matching warm & friendly direction
- Clean Architecture decided (data/domain/presentation layers per feature)
- Riverpod 2 for state management
- go_router for navigation
- Theme configuration must be accessible app-wide via Riverpod provider
- Auth state drives navigation (unauthenticated -> login, authenticated -> home)

### Claude's Discretion
- Specific Google Font pairing (recommended direction: rounded/friendly headings like Nunito, clean body like Inter)
- Corner radius values, elevation/shadow style
- Icon set choice (Material Icons vs alternatives)
- Onboarding flow content and illustrations
- App shell navigation structure (bottom nav tabs, placeholder sections)
- Profile screen layout and energy preference picker design
- Avatar handling approach (upload vs initials)

### Deferred Ideas (OUT OF SCOPE)
None -- discussion stayed within phase scope

</user_constraints>

<phase_requirements>

## Phase Requirements

| ID | Description | Research Support |
|----|-------------|-----------------|
| AUTH-01 | User can sign up with email and password via Supabase Auth | Supabase `signUp()` API verified, email auth enabled by default |
| AUTH-02 | User can sign in with Google OAuth via Supabase Auth | Native Google Sign-In flow via `google_sign_in` + `signInWithIdToken`, Supabase OAuth provider config documented |
| AUTH-03 | User can create and edit profile with display name and avatar | Profiles table with trigger pattern, Supabase Storage for avatars, `image_picker` for photo selection |
| AUTH-04 | User can set energy pattern preferences (peak/low hours) for AI scheduling | Stored as JSON/columns in profiles table, custom UI picker (no standard library needed) |
| AUTH-05 | New user sees 3-4 screen onboarding flow explaining app features | PageView + `smooth_page_indicator` for dot indicators, `shared_preferences` for first-launch flag |
| UX-01 | User can toggle dark mode with Material 3 theme (light/dark/system default) | `ColorScheme.fromSeed` with brightness parameter, `ThemeMode` enum, Riverpod provider for persistence |

</phase_requirements>

## Standard Stack

### Core

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| flutter | 3.x (latest stable) | UI framework | Project foundation |
| supabase_flutter | ^2.12.0 | Auth, DB, Storage, Realtime | Official Supabase Flutter SDK, handles session persistence automatically |
| flutter_riverpod | ^3.3.1 | State management | Riverpod 3.x is latest stable, backward-compatible with Riverpod 2 patterns |
| go_router | ^17.1.0 | Declarative routing | Official Flutter team package, supports auth redirects and ShellRoute |
| google_sign_in | ^7.2.0 | Native Google OAuth | Official Flutter plugin for Google Sign-In on Android/iOS |
| google_fonts | ^8.0.2 | Custom typography | Official Flutter Favorite, integrates with TextTheme |
| shared_preferences | ^2.5.4 | Theme + onboarding persistence | Lightweight key-value storage for user preferences |

### Supporting

| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| image_picker | ^1.2.1 | Avatar photo selection | Profile avatar upload feature |
| smooth_page_indicator | ^2.0.1 | Onboarding dot indicators | Onboarding PageView flow |
| flutter_svg | ^2.2.4 | SVG asset rendering | Onboarding illustrations, icons |
| riverpod_lint | ^3.1.3 | Riverpod-specific linting | Dev dependency for code quality |

### Dev Dependencies

| Library | Version | Purpose |
|---------|---------|---------|
| flutter_test | (SDK) | Widget and unit testing |
| mockito | latest | Mocking for unit tests |
| build_runner | ^2.13.0 | Code generation (mockito) |
| flutter_lints | (SDK) | Standard lint rules |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Manual Riverpod providers | riverpod_generator (code gen) | Code gen adds build_runner complexity; manual is simpler for portfolio project scope |
| smooth_page_indicator | dots_indicator | smooth_page_indicator has more animation options and is more maintained |
| image_picker (avatar upload) | Initials-based avatar | Simpler (no storage bucket needed), but less feature-rich; recommend supporting BOTH |
| shared_preferences | hive | shared_preferences is simpler for key-value; hive overkill for theme/onboarding flags |

**Installation:**
```bash
flutter pub add supabase_flutter flutter_riverpod go_router google_sign_in google_fonts shared_preferences image_picker smooth_page_indicator flutter_svg
flutter pub add --dev mockito build_runner riverpod_lint
```

## Architecture Patterns

### Recommended Project Structure (Phase 1)

```
lib/
├── main.dart                          # Entry point, Supabase.initialize, ProviderScope
├── app.dart                           # MaterialApp.router with theme config
├── core/
│   ├── constants/
│   │   └── supabase_constants.dart    # URL + anon key (gitignored)
│   ├── theme/
│   │   ├── app_theme.dart             # ThemeData for light/dark
│   │   ├── color_schemes.dart         # ColorScheme.fromSeed configs
│   │   └── text_theme.dart            # Google Fonts text theme
│   ├── router/
│   │   └── app_router.dart            # GoRouter config with auth redirect
│   └── utils/
│       └── extensions.dart            # BuildContext extensions
├── features/
│   ├── auth/
│   │   ├── data/
│   │   │   └── auth_repository.dart   # Supabase auth operations
│   │   ├── domain/
│   │   │   └── auth_state.dart        # Auth state model
│   │   ├── presentation/
│   │   │   ├── providers/
│   │   │   │   └── auth_provider.dart # Riverpod auth notifier
│   │   │   ├── screens/
│   │   │   │   ├── login_screen.dart
│   │   │   │   ├── register_screen.dart
│   │   │   │   └── forgot_password_screen.dart
│   │   │   └── widgets/
│   │   │       ├── auth_form.dart
│   │   │       └── social_sign_in_button.dart
│   ├── profile/
│   │   ├── data/
│   │   │   └── profile_repository.dart  # Supabase profiles CRUD
│   │   ├── domain/
│   │   │   └── profile_model.dart       # Profile data model
│   │   └── presentation/
│   │       ├── providers/
│   │       │   └── profile_provider.dart
│   │       ├── screens/
│   │       │   └── profile_screen.dart
│   │       └── widgets/
│   │           ├── avatar_widget.dart
│   │           └── energy_prefs_picker.dart
│   ├── onboarding/
│   │   └── presentation/
│   │       ├── screens/
│   │       │   └── onboarding_screen.dart
│   │       └── widgets/
│   │           └── onboarding_page.dart
│   └── settings/
│       └── presentation/
│           ├── providers/
│           │   └── theme_provider.dart
│           └── screens/
│               └── settings_screen.dart
├── shared/
│   └── widgets/
│       ├── app_button.dart
│       ├── app_text_field.dart
│       └── loading_overlay.dart
└── supabase/
    ├── migrations/
    │   └── 00001_create_profiles.sql
    └── seed.sql
```

### Pattern 1: Supabase Initialization

**What:** Initialize Supabase before runApp, wrap with ProviderScope
**When to use:** Always -- app entry point

```dart
// Source: Supabase official docs
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: SupabaseConstants.url,
    anonKey: SupabaseConstants.anonKey,
  );

  runApp(
    const ProviderScope(
      child: FocusForgeApp(),
    ),
  );
}
```

### Pattern 2: Auth State with GoRouter Redirect

**What:** GoRouter listens to Supabase auth state changes via refreshListenable and redirects based on auth status
**When to use:** Router configuration

```dart
// Source: go_router docs + Supabase auth docs
class AuthNotifier extends ChangeNotifier {
  AuthNotifier() {
    _subscription = Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      _isAuthenticated = data.session != null;
      notifyListeners();
    });
    _isAuthenticated = Supabase.instance.client.auth.currentSession != null;
  }

  late final StreamSubscription<AuthState> _subscription;
  bool _isAuthenticated = false;
  bool get isAuthenticated => _isAuthenticated;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

// In GoRouter config:
final authNotifier = AuthNotifier();

final router = GoRouter(
  refreshListenable: authNotifier,
  redirect: (context, state) {
    final isAuth = authNotifier.isAuthenticated;
    final isLoginRoute = state.matchedLocation == '/login';
    final isRegisterRoute = state.matchedLocation == '/register';
    final isOnboarding = state.matchedLocation == '/onboarding';

    if (!isAuth && !isLoginRoute && !isRegisterRoute) return '/login';
    if (isAuth && (isLoginRoute || isRegisterRoute)) return '/';
    return null;
  },
  routes: [...],
);
```

### Pattern 3: Theme Provider with Persistence

**What:** Riverpod StateNotifier that manages ThemeMode and persists choice to SharedPreferences
**When to use:** App-wide theme toggling

```dart
// Theme mode provider
enum AppThemeMode { light, dark, system }

class ThemeNotifier extends StateNotifier<ThemeMode> {
  ThemeNotifier() : super(ThemeMode.system) {
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final themeIndex = prefs.getInt('theme_mode') ?? 2; // default: system
    state = ThemeMode.values[themeIndex];
  }

  Future<void> setTheme(ThemeMode mode) async {
    state = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('theme_mode', mode.index);
  }
}

final themeProvider = StateNotifierProvider<ThemeNotifier, ThemeMode>(
  (ref) => ThemeNotifier(),
);
```

### Pattern 4: Material 3 Color Scheme from Seed

**What:** Generate light and dark color schemes from amber seed color with accent overrides
**When to use:** Theme configuration

```dart
// Source: Flutter ColorScheme.fromSeed docs
const seedColor = Color(0xFFFF8F00); // Amber/orange

final lightColorScheme = ColorScheme.fromSeed(
  seedColor: seedColor,
  brightness: Brightness.light,
  // Override specific colors for teal/forest green accents
  tertiary: const Color(0xFF2E7D6F),  // teal accent
);

final darkColorScheme = ColorScheme.fromSeed(
  seedColor: seedColor,
  brightness: Brightness.dark,
  tertiary: const Color(0xFF81C784),  // sage green accent
);

// In ThemeData:
ThemeData(
  useMaterial3: true,
  colorScheme: lightColorScheme,
  textTheme: GoogleFonts.nunitoTextTheme(), // warm, rounded headings
);
```

### Pattern 5: Google Sign-In Native Flow with Supabase

**What:** Native Google Sign-In on Android, then pass ID token to Supabase
**When to use:** Social authentication

```dart
// Source: Supabase Google Auth docs
Future<AuthResponse> signInWithGoogle() async {
  const webClientId = 'YOUR_WEB_CLIENT_ID.apps.googleusercontent.com';

  final googleSignIn = GoogleSignIn(
    serverClientId: webClientId,
  );
  final googleUser = await googleSignIn.signIn();
  if (googleUser == null) throw Exception('Google sign-in cancelled');

  final googleAuth = await googleUser.authentication;
  final idToken = googleAuth.idToken;
  if (idToken == null) throw Exception('No ID token');

  return await Supabase.instance.client.auth.signInWithIdToken(
    provider: OAuthProvider.google,
    idToken: idToken,
  );
}
```

### Pattern 6: Profiles Table with Auto-Creation Trigger

**What:** PostgreSQL profiles table linked to auth.users with automatic creation on signup
**When to use:** Database migration

```sql
-- Source: Supabase managing user data docs
-- Migration: 00001_create_profiles.sql

create table public.profiles (
  id uuid not null references auth.users on delete cascade,
  display_name text,
  avatar_url text,
  energy_pattern jsonb default '{"peak_hours": [9,10,11], "low_hours": [14,15]}'::jsonb,
  onboarding_completed boolean default false,
  created_at timestamptz default now(),
  updated_at timestamptz default now(),
  primary key (id)
);

alter table public.profiles enable row level security;

-- Users can read their own profile
create policy "Users can view own profile"
  on public.profiles for select
  using ((select auth.uid()) = id);

-- Users can update their own profile
create policy "Users can update own profile"
  on public.profiles for update
  using ((select auth.uid()) = id)
  with check ((select auth.uid()) = id);

-- Users can insert their own profile (fallback)
create policy "Users can insert own profile"
  on public.profiles for insert
  with check ((select auth.uid()) = id);

-- Auto-create profile on signup
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer set search_path = ''
as $$
begin
  insert into public.profiles (id, display_name, avatar_url)
  values (
    new.id,
    coalesce(new.raw_user_meta_data ->> 'full_name', new.raw_user_meta_data ->> 'name', ''),
    coalesce(new.raw_user_meta_data ->> 'avatar_url', '')
  );
  return new;
end;
$$;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure public.handle_new_user();

-- Storage bucket for avatars
insert into storage.buckets (id, name, public)
values ('avatars', 'avatars', true);

-- Storage policy: users can upload their own avatar
create policy "Users can upload own avatar"
  on storage.objects for insert
  with check (bucket_id = 'avatars' and (select auth.uid())::text = (storage.foldername(name))[1]);

-- Storage policy: anyone can view avatars (public bucket)
create policy "Avatars are publicly accessible"
  on storage.objects for select
  using (bucket_id = 'avatars');

-- Storage policy: users can update their own avatar
create policy "Users can update own avatar"
  on storage.objects for update
  using (bucket_id = 'avatars' and (select auth.uid())::text = (storage.foldername(name))[1]);
```

### Pattern 7: ShellRoute for Bottom Navigation

**What:** Persistent bottom navigation bar with go_router ShellRoute
**When to use:** App shell after authentication

```dart
// Source: go_router ShellRoute docs
ShellRoute(
  builder: (context, state, child) {
    return AppShell(child: child);
  },
  routes: [
    GoRoute(
      path: '/tasks',
      builder: (context, state) => const TasksPlaceholder(),
    ),
    GoRoute(
      path: '/habits',
      builder: (context, state) => const HabitsPlaceholder(),
    ),
    GoRoute(
      path: '/planner',
      builder: (context, state) => const PlannerPlaceholder(),
    ),
    GoRoute(
      path: '/profile',
      builder: (context, state) => const ProfileScreen(),
    ),
  ],
)
```

### Anti-Patterns to Avoid

- **Storing Supabase credentials in source code:** Use a gitignored constants file or environment variables. Never commit URL/keys to git.
- **Using `setState` for auth/theme state:** Always use Riverpod providers for cross-widget state. setState does not compose.
- **Mixing auth logic into UI widgets:** Auth operations belong in repository classes. Screens call providers, providers call repositories.
- **Skipping RLS on profiles table:** Without RLS, any authenticated user can read/modify any profile. Always enable RLS and test policies.
- **Blocking the trigger on signup:** If the `handle_new_user()` trigger fails (e.g., unique constraint violation), the entire signup transaction rolls back. Test thoroughly.
- **Hardcoding theme colors:** Use `ColorScheme.fromSeed` and reference `Theme.of(context).colorScheme` -- never hardcode hex values in widgets.
- **Not wrapping `auth.uid()` in select:** Per Supabase docs, `(select auth.uid())` performs significantly better than bare `auth.uid()` in RLS policies.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Session persistence | Custom token storage/refresh | `supabase_flutter` built-in session management | Handles token refresh, secure storage, and session restoration automatically |
| Google OAuth flow | Custom HTTP OAuth implementation | `google_sign_in` + `signInWithIdToken` | Platform-specific credential management, token exchange, error handling |
| Color palette generation | Manual hex color calculations | `ColorScheme.fromSeed` | Material 3 algorithm ensures accessible contrast ratios and harmonious palettes |
| Auth state observation | Polling or custom streams | `Supabase.auth.onAuthStateChange` + `refreshListenable` | Battle-tested stream that handles all auth events including token refresh |
| Page indicator dots | Custom AnimatedContainer | `smooth_page_indicator` | 15+ animation effects, handles edge cases, accessible |
| Avatar URL generation | Manual URL construction | `supabase.storage.from('avatars').getPublicUrl()` | Handles CDN paths, transformations, and cache busting |

**Key insight:** Supabase handles the entire auth lifecycle -- session persistence, token refresh, auth state events, and user metadata. Do not wrap these in custom abstractions beyond a thin repository layer.

## Common Pitfalls

### Pitfall 1: Google Sign-In SHA-1 Fingerprint Mismatch
**What goes wrong:** Google Sign-In silently fails or throws PlatformException on Android
**Why it happens:** The SHA-1 fingerprint registered in Google Cloud Console doesn't match the keystore used for signing the debug/release APK
**How to avoid:** Register BOTH debug and release SHA-1 fingerprints. For debug: `keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android`. Add both to your Firebase/Google Cloud project.
**Warning signs:** Sign-in button does nothing, or error code 10 (DEVELOPER_ERROR) in logs

### Pitfall 2: Supabase Auth Redirect URL Not Configured
**What goes wrong:** OAuth callback fails after Google sign-in, user stuck in browser
**Why it happens:** The redirect URL in Supabase Dashboard > Auth > URL Configuration doesn't match the app's deep link scheme
**How to avoid:** For native flow with `signInWithIdToken`, this is not needed (ID token is passed directly). Only needed for web-based OAuth flow. If using web flow, configure deep link scheme in both Supabase Dashboard and Android manifest.
**Warning signs:** Browser opens but never returns to app

### Pitfall 3: Trigger Blocking Signup
**What goes wrong:** New user registration fails silently
**Why it happens:** The `handle_new_user()` trigger function throws an error (e.g., trying to insert null into a NOT NULL column), which rolls back the entire `auth.users` insert
**How to avoid:** Use COALESCE with empty string defaults for all columns derived from `raw_user_meta_data`. Test with both email signup (no metadata) and Google signup (has metadata). Make non-critical fields nullable.
**Warning signs:** `signUp()` throws a generic error, no row appears in `auth.users`

### Pitfall 4: Theme Not Applying to All Widgets
**What goes wrong:** Some widgets use wrong colors after theme toggle
**Why it happens:** Hardcoded colors in widget code, or using `Color(0xFF...)` instead of `Theme.of(context).colorScheme.primary`
**How to avoid:** Always reference colors via `Theme.of(context).colorScheme`. Create named getters in a theme extension if needed for custom semantic colors. Never use raw hex colors in widget code.
**Warning signs:** Widgets that look correct in light mode but wrong in dark mode, or vice versa

### Pitfall 5: GoRouter Redirect Loop
**What goes wrong:** App crashes or shows blank screen with "too many redirects" error
**Why it happens:** Redirect function sends login page to login page, or authenticated users to a route that also redirects
**How to avoid:** Always check `state.matchedLocation` before redirecting. Ensure login/register routes are excluded from auth redirect. Set `redirectLimit` if needed for debugging.
**Warning signs:** White screen on launch, "redirect limit exceeded" error in console

### Pitfall 6: SharedPreferences Not Ready on First Frame
**What goes wrong:** Theme flickers from default to user's saved preference on app launch
**Why it happens:** SharedPreferences is async; reading theme preference takes a frame
**How to avoid:** Load theme preference during splash screen or before `runApp`. Use `WidgetsFlutterBinding.ensureInitialized()` and await the preference load. Consider using `FutureProvider` that shows loading state.
**Warning signs:** Brief flash of wrong theme mode on app startup

### Pitfall 7: Web Client ID vs Android Client ID Confusion
**What goes wrong:** Google Sign-In returns null `idToken`
**Why it happens:** Using the Android OAuth Client ID as `serverClientId` instead of the Web Application Client ID
**How to avoid:** In Google Cloud Console, create BOTH a Web Application OAuth client and an Android OAuth client. Use the **Web Application** client ID as `serverClientId` in Flutter code. The Android client ID is only used implicitly via `google-services.json`.
**Warning signs:** `googleAuth.idToken` is null even though `googleUser` is not null

## Code Examples

### Email/Password Sign-Up

```dart
// Source: Supabase Auth docs
class AuthRepository {
  final SupabaseClient _client;

  AuthRepository(this._client);

  Future<AuthResponse> signUpWithEmail({
    required String email,
    required String password,
    String? displayName,
  }) async {
    return await _client.auth.signUp(
      email: email,
      password: password,
      data: displayName != null ? {'full_name': displayName} : null,
    );
  }

  Future<AuthResponse> signInWithEmail({
    required String email,
    required String password,
  }) async {
    return await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  Future<void> resetPassword(String email) async {
    await _client.auth.resetPasswordForEmail(email);
  }

  User? get currentUser => _client.auth.currentUser;
  Session? get currentSession => _client.auth.currentSession;
  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;
}
```

### Profile Repository

```dart
// Source: Supabase managing user data docs
class ProfileRepository {
  final SupabaseClient _client;

  ProfileRepository(this._client);

  Future<Profile> getProfile(String userId) async {
    final data = await _client
        .from('profiles')
        .select()
        .eq('id', userId)
        .single();
    return Profile.fromJson(data);
  }

  Future<void> updateProfile(Profile profile) async {
    await _client
        .from('profiles')
        .update(profile.toJson())
        .eq('id', profile.id);
  }

  Future<String> uploadAvatar(String userId, File file) async {
    final fileExt = file.path.split('.').last;
    final filePath = '$userId/avatar.$fileExt';

    await _client.storage
        .from('avatars')
        .upload(filePath, file, fileOptions: const FileOptions(upsert: true));

    return _client.storage.from('avatars').getPublicUrl(filePath);
  }
}
```

### Onboarding Flow with First-Launch Detection

```dart
// Check if onboarding was completed
class OnboardingService {
  static const _key = 'onboarding_completed';

  Future<bool> isOnboardingCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_key) ?? false;
  }

  Future<void> markOnboardingCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, true);
  }
}

// Onboarding screen structure
class OnboardingScreen extends StatelessWidget {
  final pageController = PageController();

  final pages = [
    OnboardingPage(
      title: 'Welcome to FocusForge',
      description: 'Your intelligent productivity companion',
      // SVG illustration asset
    ),
    OnboardingPage(
      title: 'Smart Task Management',
      description: 'AI-powered scheduling that adapts to your energy',
    ),
    OnboardingPage(
      title: 'Build Lasting Habits',
      description: 'Track streaks and celebrate your progress',
    ),
  ];

  // PageView + SmoothPageIndicator + Skip/Next buttons
}
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| `Provider` package | `flutter_riverpod` 3.x | 2024 | Type-safe, compile-time provider resolution, no BuildContext needed for reads |
| Manual `Navigator.push` | `go_router` 17.x | 2023-2024 | Declarative routing, deep links, ShellRoute for persistent nav |
| Custom color palettes | `ColorScheme.fromSeed` | Flutter 3.7+ | Automatic Material 3 palette generation with accessibility compliance |
| `SharedPreferences` legacy API | `SharedPreferencesAsync` / `WithCache` | shared_preferences 2.3+ | Old API works but is deprecated path; new APIs handle multi-isolate correctly |
| `google_sign_in` web flow | Native `signInWithIdToken` | 2023 | No browser redirect needed, smoother UX, more reliable |

**Deprecated/outdated:**
- `SharedPreferences` legacy API: still works but marked for future deprecation. Use `SharedPreferencesWithCache` for new projects if multi-isolate concerns apply. For simple use cases (theme toggle), legacy API is still fine.
- Riverpod `StateNotifierProvider`: still fully supported in Riverpod 3.x, but `Notifier`/`AsyncNotifier` is the newer pattern. Both are valid; StateNotifier is simpler to understand.

## Open Questions

1. **Supabase project setup timing**
   - What we know: Supabase project URL and anon key are needed before Flutter code runs
   - What's unclear: Whether to use Supabase CLI for local development or point directly at a hosted project
   - Recommendation: Create a hosted Supabase project first (free tier), use its URL/key in a gitignored constants file. Set up Supabase CLI later if local development is needed.

2. **Google Cloud Console OAuth setup**
   - What we know: Need Web Application + Android OAuth client IDs, SHA-1 fingerprint registration
   - What's unclear: Whether to use Firebase (which auto-generates google-services.json) or standalone Google Cloud Console
   - Recommendation: Use Firebase project for easier credential management and future FCM integration (Phase 7). Firebase console auto-creates Google Cloud OAuth clients.

3. **Avatar storage approach**
   - What we know: Supabase Storage works for file uploads, `image_picker` for selection
   - What's unclear: Whether to implement full avatar upload in Phase 1 or defer to a later phase
   - Recommendation: Implement initials-based avatar as primary (from display name), with optional photo upload via Supabase Storage. This way the profile works without storage setup, but the upload path is available.

4. **Energy pattern preferences data model**
   - What we know: Needs to store peak hours and low-energy hours for AI scheduling in Phase 5
   - What's unclear: Exact schema -- JSONB vs separate columns, granularity (hours vs time ranges)
   - Recommendation: Use JSONB column in profiles table. Store as `{"peak_hours": [9,10,11], "low_hours": [14,15]}` -- flexible, easy to extend, and the AI planner (Phase 5) can parse it directly.

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | flutter_test (built-in) + mockito |
| Config file | none -- Wave 0 |
| Quick run command | `flutter test test/unit/ --reporter compact` |
| Full suite command | `flutter test` |

### Phase Requirements -> Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| AUTH-01 | Email signup/signin via Supabase Auth | unit | `flutter test test/unit/auth/auth_repository_test.dart` | Wave 0 |
| AUTH-02 | Google OAuth sign-in flow | unit | `flutter test test/unit/auth/google_auth_test.dart` | Wave 0 |
| AUTH-03 | Profile CRUD (display name, avatar) | unit | `flutter test test/unit/profile/profile_repository_test.dart` | Wave 0 |
| AUTH-04 | Energy pattern preferences save/load | unit | `flutter test test/unit/profile/energy_prefs_test.dart` | Wave 0 |
| AUTH-05 | Onboarding first-launch detection + skip | widget | `flutter test test/widget/onboarding/onboarding_screen_test.dart` | Wave 0 |
| UX-01 | Theme toggle persistence (light/dark/system) | unit | `flutter test test/unit/settings/theme_provider_test.dart` | Wave 0 |

### Sampling Rate

- **Per task commit:** `flutter test test/unit/ --reporter compact`
- **Per wave merge:** `flutter test`
- **Phase gate:** Full suite green before `/gsd:verify-work`

### Wave 0 Gaps

- [ ] `test/unit/auth/auth_repository_test.dart` -- covers AUTH-01, AUTH-02
- [ ] `test/unit/profile/profile_repository_test.dart` -- covers AUTH-03, AUTH-04
- [ ] `test/widget/onboarding/onboarding_screen_test.dart` -- covers AUTH-05
- [ ] `test/unit/settings/theme_provider_test.dart` -- covers UX-01
- [ ] `test/helpers/mocks.dart` -- shared mock setup for SupabaseClient, SharedPreferences
- [ ] `pubspec.yaml` test dependencies -- mockito, build_runner

## Sources

### Primary (HIGH confidence)
- pub.dev/packages/supabase_flutter (v2.12.0) - Auth API, initialization, session management
- pub.dev/packages/flutter_riverpod (v3.3.1) - State management setup, ProviderScope
- pub.dev/packages/go_router (v17.1.0) - Routing, ShellRoute, redirect guards
- pub.dev/packages/google_sign_in (v7.2.0) - Native Google OAuth on Android
- pub.dev/packages/google_fonts (v8.0.2) - Typography integration
- supabase.com/docs/guides/auth/social-login/auth-google - Google OAuth setup with Flutter
- supabase.com/docs/guides/auth/passwords - Email/password auth patterns
- supabase.com/docs/reference/dart/auth-onauthstatechange - Auth state stream API
- supabase.com/docs/guides/auth/managing-user-data - Profiles table + trigger pattern
- supabase.com/docs/guides/database/postgres/row-level-security - RLS policy patterns
- Flutter ColorScheme class docs - ColorScheme.fromSeed API

### Secondary (MEDIUM confidence)
- supabase.com/docs/guides/storage/uploads - Avatar upload patterns
- pub.dev/packages/shared_preferences (v2.5.4) - Preference persistence
- pub.dev/packages/smooth_page_indicator (v2.0.1) - Onboarding page indicators
- pub.dev/packages/image_picker (v1.2.1) - Avatar photo selection

### Tertiary (LOW confidence)
- Energy pattern JSONB schema design - based on domain reasoning, no authoritative source
- Initials-based avatar as primary approach - architectural recommendation, not verified pattern

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - All packages verified on pub.dev with current versions and recent publish dates
- Architecture: HIGH - Patterns sourced from official Supabase and Flutter documentation
- Pitfalls: HIGH - Common issues well-documented in community and official guides
- Database schema: MEDIUM - Profiles pattern from Supabase docs, energy_pattern JSONB is custom design
- Onboarding: MEDIUM - Standard PageView pattern, specific content is discretionary

**Research date:** 2026-03-17
**Valid until:** 2026-04-17 (stable ecosystem, 30-day validity)
