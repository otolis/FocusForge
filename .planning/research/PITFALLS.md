# Pitfalls Research

**Domain:** Flutter AI-powered productivity app with Supabase backend, on-device ML, and realtime collaboration
**Researched:** 2026-03-16
**Confidence:** MEDIUM-HIGH (verified across official docs, GitHub issues, and community reports)

## Critical Pitfalls

### Pitfall 1: Supabase Realtime Silently Breaks When RLS Is Enabled

**What goes wrong:**
You enable Row Level Security on your tables (as you should), and Supabase Realtime subscriptions silently stop receiving events. No error is thrown -- queries just return nothing. The collaborative boards feature goes dark and you have no idea why. This is the single most reported Supabase issue on GitHub, and it will hit you the moment you enable RLS on board-related tables.

**Why it happens:**
Supabase Realtime is a separate service that reads from PostgreSQL's Write-Ahead Log (WAL) via a publication called `supabase_realtime`. It connects with its own internal role, not as the end-user. When RLS is enabled, this internal role lacks SELECT permissions on the table, so the Realtime service cannot evaluate RLS policies to determine which events to broadcast. It fails silently because "zero rows returned" is a valid query result.

**How to avoid:**
Three setup steps are mandatory for every table that uses Realtime + RLS:
1. Add the table to the realtime publication: `ALTER PUBLICATION supabase_realtime ADD TABLE board_tasks;`
2. Create a SELECT policy that the Realtime service can evaluate (e.g., `auth.uid() = user_id` or board membership check)
3. Grant the `supabase_realtime` role SELECT access to the table
4. Test Realtime from the client SDK, not the SQL Editor (SQL Editor bypasses RLS)

Additionally, for private channels (presence on boards), set `private: true` on the channel and create RLS policies on `realtime.messages`.

**Warning signs:**
- Realtime works perfectly in development without RLS, then stops working when RLS is enabled
- Queries return data normally but subscriptions receive no events
- No errors in client logs or Supabase dashboard

**Phase to address:**
Phase 1 (Foundation/Auth) -- establish the RLS + Realtime pattern with the first table. Create a reusable SQL migration template that includes publication registration and role grants alongside RLS policies. Every subsequent table follows this template.

---

### Pitfall 2: Supabase API Key Deprecation (anon/service_role Keys Being Retired)

**What goes wrong:**
You build the entire app using the traditional `anon` key and `service_role` key pattern. As of November 2025, new Supabase projects no longer provide these legacy JWT-based keys. Existing projects will have them rotated out throughout 2026. If you start the project using `anon` key patterns from older tutorials, you'll face a forced migration mid-development.

**Why it happens:**
Supabase is transitioning from JWT-based anon/service_role keys to a new system: `sb_publishable_...` (replaces anon) and `sb_secret_...` (replaces service_role). The legacy keys exposed the full OpenAPI spec to anyone with the anon key, which was a security concern.

**How to avoid:**
- Check if your Supabase project uses new-style keys (`sb_publishable_...`) or legacy keys
- If starting a new project in 2026, you will get the new keys by default -- use them from day one
- The new keys are mostly drop-in replacements: pass `sb_publishable_...` wherever you used `anon`, and `sb_secret_...` wherever you used `service_role`
- Update any hardcoded references in Edge Functions environment variables (these are NOT auto-migrated)
- Follow the official migration discussion: github.com/orgs/supabase/discussions/29260

**Warning signs:**
- Tutorials reference `SUPABASE_ANON_KEY` but your project dashboard shows different key formats
- Edge Functions fail silently after key migration because env vars still hold old keys
- Type generation tools may have compatibility issues with new keys

**Phase to address:**
Phase 1 (Foundation) -- verify key format on project creation and configure all environment variables with new-style keys from the start.

---

### Pitfall 3: TFLite/LiteRT Plugin Instability and Platform Fragmentation

**What goes wrong:**
You invest significant time integrating `tflite_flutter` for on-device task classification, only to discover the plugin is in a perpetual "work-in-progress" state, has platform-specific bugs (iOS symbol stripping, API level 26+ requirement on Android), and Google has rebranded TensorFlow Lite to "LiteRT" with a different recommended plugin (`flutter_litert`). Your TFLite integration works on one platform but breaks on others, or the plugin itself becomes unmaintained.

**Why it happens:**
The TFLite ecosystem for Flutter is fragmented: `tflite_flutter` (official TensorFlow repo, frequently in flux), `flutter_litert` (new drop-in replacement with bundled native libraries), and `tflite_plus` (community alternative). Google's rebranding from TFLite to LiteRT adds confusion. GPU delegate support is incomplete -- some operations run on GPU, others fall back to CPU silently, causing unpredictable performance.

**How to avoid:**
- Use `flutter_litert` instead of `tflite_flutter` -- it bundles all native libraries automatically, is a drop-in API replacement, and supports Android, iOS, macOS, Windows, and Linux out of the box
- Run TFLite inference in a Dart Isolate to prevent UI jank -- model inference on the main thread will freeze the UI
- Validate input normalization carefully -- incorrect normalization is the #1 cause of garbage model output that "looks like it works" but produces wrong classifications
- Require minimum Android API 26 in `build.gradle`
- Start with the regex/heuristics parser first (as planned), then add the TFLite model as an enhancement -- this way the app works without ML, and ML improves it

**Warning signs:**
- Model returns plausible but wrong classifications (normalization issue)
- App works on emulator but crashes on physical device (native library issue)
- Inference takes >100ms on main thread causing visible frame drops
- Plugin compilation fails after Flutter or Gradle upgrade

**Phase to address:**
Late phase (post-MVP) as explicitly planned. The regex-first, TFLite-later strategy in PROJECT.md is correct. When implementing TFLite, create an abstraction layer (`TaskClassifier` interface) so the regex implementation and TFLite implementation are interchangeable.

---

### Pitfall 4: Clean Architecture Boilerplate Explosion in a Portfolio Project

**What goes wrong:**
You create the "proper" Clean Architecture structure with data/domain/presentation layers per feature, and end up with 15-20 files for a simple CRUD feature (entity, model, mapper, repository interface, repository impl, data source interface, data source impl, use case, provider, state, screen, widgets...). Development slows to a crawl. The portfolio reviewer sees massive folder structures with trivial code spread across dozens of files, which signals over-engineering rather than competence.

**Why it happens:**
Clean Architecture was designed for large teams with complex business logic. A portfolio productivity app has relatively simple domain logic (CRUD + some AI orchestration). Applying full Clean Architecture dogmatically creates ceremony without proportional benefit. The "3 weeks setting up perfect architecture for apps that got killed after user testing" anti-pattern is real.

**How to avoid:**
- Use feature-first folder structure (each feature is a self-contained folder) rather than layer-first (all entities in one folder, all repos in another)
- Apply Clean Architecture principles selectively: full layers for complex features (AI planner, collaborative boards), simplified layers for CRUD features (basic task/habit management)
- Skip the use case layer for simple pass-through operations -- a repository method called directly from a provider is fine when the use case would just delegate
- Concrete rule: if a use case class has one method that calls one repository method with no additional logic, eliminate the use case
- Keep the domain layer for features that genuinely have business rules (streak calculation, AI schedule optimization, board permissions)

**Warning signs:**
- Use case classes that are pure delegation (no business logic)
- Mapper classes that just copy fields 1:1 between identical model/entity shapes
- More than 12 files to implement a simple CRUD feature
- Feature folders with more infrastructure files than actual logic

**Phase to address:**
Phase 1 (Foundation) -- establish the architecture template with two tiers: "full" for complex features and "lite" for CRUD features. Document the decision boundary in the project's architecture guide.

---

### Pitfall 5: Riverpod Provider State Management Causing Silent Memory Leaks

**What goes wrong:**
Family providers create a new state instance per parameter combination and never dispose them. Realtime stream subscriptions accumulate without cleanup. The app gradually consumes more memory and becomes sluggish, particularly on the collaborative boards screen where users switch between boards frequently. On Android, the OS eventually kills the app.

**Why it happens:**
Riverpod's `autoDispose` is not the default behavior -- providers persist by default. Family providers (e.g., `boardProvider(boardId)`) create a cached state per unique parameter. Without `autoDispose`, switching between 10 boards creates 10 persistent provider states, each potentially holding Realtime subscriptions. Additionally, `ref.read` in a Notifier's `dispose` method throws "ProviderContainer already disposed" errors, making cleanup tricky.

**How to avoid:**
- Use `autoDispose` on ALL providers that are scoped to a screen or feature (board detail, task detail, habit detail)
- Use `ref.keepAlive()` selectively for providers that should survive navigation (e.g., the user profile provider, the board list provider)
- For Realtime subscriptions, use `ref.onDispose(() => channel.unsubscribe())` to clean up channels when providers are disposed
- Avoid `ref.read` inside `dispose` -- instead, capture references to channels/subscriptions in the Notifier's constructor or build method
- Use `ref.watch` in widgets and `ref.read` only inside callbacks (onPressed, etc.)
- For family providers used in lists (like board cards), test with `autoDispose` + rapid scrolling to catch premature disposal bugs

**Warning signs:**
- Memory usage in Android profiler steadily increases as user navigates
- Realtime events fire for boards the user is no longer viewing
- "Bad state: Tried to read a provider from a ProviderContainer that was already disposed" error
- ListView.builder items crash when scrolled back into view after disposal

**Phase to address:**
Phase 1 (Foundation) -- establish the Riverpod provider pattern with `autoDispose` as the default, and `keepAlive` as the explicit opt-in. Create a base `AsyncNotifier` template that includes proper subscription cleanup.

---

### Pitfall 6: Realtime Channels Stop Working After ~15 Minutes in Long-Running Sessions

**What goes wrong:**
The collaborative boards feature works perfectly for the first 10-15 minutes. Then Realtime events silently stop arriving. The board appears frozen -- other users' changes don't appear. No errors are logged. Users must close and reopen the app to restore functionality.

**Why it happens:**
This is a documented issue (supabase-flutter GitHub Issue #388, #1012). The Supabase Realtime WebSocket connection goes stale, likely related to access token refresh failures. The JWT token expires, but the Realtime client does not automatically reconnect with a fresh token. Desktop and web deployments are especially vulnerable because the OS doesn't kill the app to trigger a fresh connection.

**How to avoid:**
- Implement a heartbeat/ping mechanism that periodically checks channel connectivity
- Listen for Supabase auth token refresh events and manually re-establish Realtime channels when the token refreshes
- Add a "connection status" indicator on the board UI so users know if they are connected
- Implement a reconnection strategy: detect stale connections and re-subscribe to channels
- On app resume (from background), proactively re-establish all Realtime subscriptions
- For the Flutter web deployment (portfolio demo), this is especially critical -- the demo must work reliably for the 2-3 minutes a recruiter spends testing it

**Warning signs:**
- Board changes stop appearing after the app has been open for 10+ minutes
- Presence indicators show stale data (users shown as "online" who left)
- Works perfectly in quick test sessions but fails in real usage

**Phase to address:**
Collaborative boards phase -- implement reconnection logic alongside the initial Realtime integration. Do not defer this to a "polish" phase; it will break the demo.

---

### Pitfall 7: RLS Policies That Are Too Permissive or Missing Entirely

**What goes wrong:**
Tables are created without RLS enabled (Supabase default is RLS disabled), or RLS is enabled but policies are too broad (e.g., `true` for SELECT). Anyone with the API key can read, modify, or delete any user's data. For a portfolio project, a security-conscious reviewer checking the Supabase configuration would immediately flag this.

**Why it happens:**
RLS is disabled by default on new tables. Development feels easier without it -- everything "just works." Developers enable RLS late in the process, discover everything breaks (see Pitfall 1), and either leave it disabled or write overly permissive policies to "fix" the immediate problem. The USING vs WITH CHECK distinction is confusing -- many developers only write USING and forget WITH CHECK for INSERT/UPDATE.

**How to avoid:**
- Enable RLS on every table at creation time, with no exceptions
- Write both USING (for SELECT/UPDATE/DELETE) and WITH CHECK (for INSERT/UPDATE) policies
- Always use `auth.uid()` for user-scoping, never trust user IDs passed in the request body
- For collaborative boards: create a board_members junction table and write policies that check membership
- Test all policies from the client SDK (SQL Editor bypasses RLS)
- Index columns used in RLS policy conditions (user_id, board_id) -- unindexed RLS columns are the #1 Supabase performance killer
- For UPDATE operations: remember that BOTH USING and WITH CHECK must pass -- USING checks the old row, WITH CHECK validates the new values

**Warning signs:**
- Queries work without being logged in (missing RLS entirely)
- Users can see other users' data in the app
- UPDATE operations silently fail (missing SELECT policy -- UPDATE requires SELECT)
- Database queries are slow on tables with many rows (missing index on RLS column)

**Phase to address:**
Phase 1 (Foundation) -- write RLS policies alongside every table migration. Create a standard policy template for user-owned tables and for shared (board) tables.

---

## Technical Debt Patterns

Shortcuts that seem reasonable but create long-term problems.

| Shortcut | Immediate Benefit | Long-term Cost | When Acceptable |
|----------|-------------------|----------------|-----------------|
| Skipping RLS during development | Faster iteration, no auth headaches | Must retrofit all tables later; Realtime integration breaks | Never -- enable from day one |
| Putting TFLite inference on main thread | Simpler code, no Isolate management | UI freezes during classification, dropped frames | Never -- always use Isolates for ML |
| Using `ref.read` everywhere instead of `ref.watch` | Avoids "unnecessary" rebuilds | Widget doesn't react to state changes, stale UI | Only inside callbacks (onPressed, onTap) |
| Hardcoding Groq API key in Edge Function code | Quick to deploy | Key rotation requires redeployment; key exposed in version control | Never -- use Supabase secrets/env vars |
| Skipping use cases for ALL features | Less boilerplate | Business logic leaks into providers, harder to test | Acceptable for pure CRUD features with no business rules |
| One giant Riverpod provider per feature | Fewer files, faster initial development | Untestable, hard to refactor, unnecessary rebuilds | Never -- split by responsibility |
| Not indexing RLS policy columns | Faster migration writing | Queries slow dramatically beyond ~10k rows | Never -- always index auth-referenced columns |

## Integration Gotchas

Common mistakes when connecting to external services.

| Integration | Common Mistake | Correct Approach |
|-------------|----------------|------------------|
| Supabase Realtime + RLS | Enabling RLS without granting `supabase_realtime` SELECT access or adding table to publication | Run `ALTER PUBLICATION supabase_realtime ADD TABLE <name>` and grant SELECT to realtime role for every RLS-protected table |
| Groq API via Edge Functions | Not handling rate limits (free tier: ~6,000 TPM for Llama 3.3 70B) | Implement retry with exponential backoff in Edge Function; cache AI planner results per user per day; show loading state not error on rate limit |
| speech_to_text on Flutter Web | Assuming web support equals mobile parity | Web support is limited to browsers with WebRTC (no Firefox Linux, no Brave); the plugin targets "commands and short phrases" not continuous dictation; provide manual text input as primary, voice as enhancement |
| Supabase Auth (Google Sign-In) | Using client-side Google Sign-In flow without server-side token verification | Use Supabase's built-in `signInWithOAuth` which handles the full flow; do not manually exchange tokens |
| Supabase Edge Functions cold start | Expecting instant responses for AI planner | Cold start median is 400ms, hot is 125ms; the Groq API call itself adds 1-3s; show skeleton UI or "generating your plan..." animation |
| Firebase Cloud Messaging (FCM) | Not handling FCM token refresh or web push differences | Register for token refresh events; web push requires VAPID key setup and service worker; test on actual devices, not just emulator |

## Performance Traps

Patterns that work at small scale but fail as usage grows.

| Trap | Symptoms | Prevention | When It Breaks |
|------|----------|------------|----------------|
| Unindexed RLS policy columns | Board queries slow from <50ms to >2s | Add indexes on `user_id`, `board_id`, and any column in RLS WHERE clauses | Beyond ~5,000 rows per table |
| Rebuilding entire widget tree on Realtime events | Board screen stutters when collaborators make rapid changes | Use `ref.select()` to watch specific fields; rebuild only the changed card, not the whole board | 3+ collaborators making simultaneous changes |
| Loading all board tasks in a single query | Initial board load takes several seconds | Paginate by column/status; load visible columns first, lazy-load others | Beyond ~200 tasks per board |
| Supabase Realtime subscriptions per board column | Too many channels degrades Realtime service | Use one channel per board (not per column); filter events client-side by column | Beyond 5-6 open channels per client |
| Flutter Web initial bundle size | Portfolio demo takes 5+ seconds to load | Use `--web-renderer canvaskit` with deferred loading; tree-shake unused packages; compress assets | Any first-time visitor on average connection |
| No caching of AI planner results | Groq API called on every app open, hitting rate limits | Cache daily plan in Supabase; only regenerate when tasks change or user requests it | Beyond 5-10 users hitting the Edge Function concurrently |

## Security Mistakes

Domain-specific security issues beyond general web security.

| Mistake | Risk | Prevention |
|---------|------|------------|
| RLS disabled on tables (Supabase default) | Any user with API key can read/write all data | Enable RLS on table creation; use Supabase dashboard Security Advisor lint (rule 0013) |
| Board invitation links with no expiry | Stale links grant access to boards indefinitely | Add `expires_at` column to invitations; check expiry in RLS policy |
| Storing Groq API key in client-side code | Key extracted from APK/web bundle; attacker gets free API access | Only call Groq from Edge Functions; Edge Functions access key via `Deno.env.get()` |
| Not validating board membership in RLS | Users can access boards by guessing board IDs | RLS policy must JOIN `board_members` table: `EXISTS (SELECT 1 FROM board_members WHERE board_id = ... AND user_id = auth.uid())` |
| Edge Function accepting arbitrary model/prompt parameters from client | Prompt injection; cost abuse (if not on free tier) | Edge Function should accept only structured parameters (task list, energy prefs); it constructs the prompt server-side |
| Trusting client-sent user_id in requests | User A can impersonate user B | Always use `auth.uid()` from the JWT in RLS policies; never accept user_id from request body |

## UX Pitfalls

Common user experience mistakes in this domain.

| Pitfall | User Impact | Better Approach |
|---------|-------------|-----------------|
| No loading states for AI planner generation | User thinks app is broken while Groq processes (1-3s) | Show skeleton screen or Lottie animation with "Building your optimal day..." message |
| Optimistic updates without rollback on boards | Card appears moved, then jumps back on Realtime conflict | Implement optimistic UI with conflict detection; on mismatch, animate card to correct position with subtle notification |
| Streak counter resets on timezone edge cases | User completes habit at 11:55 PM, but server time says next day | Use user's local timezone for streak calculation; store timezone in profile; calculate streaks client-side with server validation |
| Voice input as primary input method | Fails in noisy environments, non-English speakers frustrated | Voice is enhancement, not primary; always show text input prominently; voice button is secondary action |
| No visual feedback during drag-and-drop on boards | User unsure if drag registered, drops card in wrong column | Show drag shadow, highlight drop target column, animate card into position |
| AI planner generates schedule but user can't easily modify it | Schedule feels imposed rather than suggested | Present AI plan as draggable suggestions; "tap to accept" individual slots; easy manual override |

## "Looks Done But Isn't" Checklist

Things that appear complete but are missing critical pieces.

- [ ] **Supabase Realtime:** Works without RLS -- verify it works WITH RLS enabled and policies active
- [ ] **Authentication:** Login works -- verify token refresh works after 1 hour (JWT expiry default)
- [ ] **Board collaboration:** Works in isolation -- verify two simultaneous users see each other's changes in real-time
- [ ] **Streak calculation:** Works for daily habits -- verify weekly habits, custom frequencies, and timezone edge cases
- [ ] **AI daily planner:** Returns a plan -- verify it respects energy patterns, handles empty task lists gracefully, and handles Groq rate limit errors
- [ ] **RLS policies:** User sees own data -- verify user CANNOT see other users' data (test with two accounts)
- [ ] **Push notifications:** Arrive on device -- verify they work when app is killed (not just backgrounded), and verify FCM token refresh
- [ ] **Flutter web build:** Runs locally -- verify it loads in under 5 seconds on a throttled connection (portfolio demo reality)
- [ ] **Presence indicators:** Show online status -- verify they clear when user disconnects (not stuck as "online" forever)
- [ ] **Drag-and-drop on boards:** Works on mobile -- verify it works on Flutter web (different gesture handling)
- [ ] **Voice input:** Works on Android -- verify graceful fallback on Flutter web (limited browser support)
- [ ] **Dark mode:** Colors look good -- verify charts (fl_chart), animations (Lottie/Rive), and third-party widgets respect theme

## Recovery Strategies

When pitfalls occur despite prevention, how to recover.

| Pitfall | Recovery Cost | Recovery Steps |
|---------|---------------|----------------|
| RLS not enabled on tables | MEDIUM | Write migration to enable RLS on all tables; create policies; test every query path; update Realtime publication |
| TFLite plugin breaks after Flutter upgrade | LOW | Swap `tflite_flutter` for `flutter_litert` (drop-in replacement); re-run tests |
| Provider memory leaks discovered late | MEDIUM | Audit all providers; add `autoDispose` modifier; add `ref.onDispose` cleanup for subscriptions; profile with DevTools |
| Clean Architecture boilerplate slowing development | MEDIUM | Identify pure-delegation use cases and inline them; merge trivial mapper classes; adopt "lite" layer pattern for CRUD features |
| Realtime channels going stale | LOW-MEDIUM | Add heartbeat check on a timer; listen to auth refresh events; re-subscribe on app resume; add connection indicator to UI |
| Groq rate limits hit during demo | LOW | Cache the last generated plan; show cached result with "last generated at" timestamp; add manual refresh button |
| Flutter web bundle too large for demo | MEDIUM | Enable deferred loading for heavy features (boards, charts); tree-shake; use `--release` with `canvaskit` renderer; deploy with CDN caching |
| RLS policies too permissive (security review) | HIGH | Audit every table's policies; write integration tests that verify cross-user data isolation; use Supabase Security Advisor |

## Pitfall-to-Phase Mapping

How roadmap phases should address these pitfalls.

| Pitfall | Prevention Phase | Verification |
|---------|------------------|--------------|
| Realtime + RLS silent failure | Foundation (first table setup) | Create a test that subscribes to Realtime with RLS enabled and verifies events arrive |
| API key deprecation | Foundation (project setup) | Confirm `sb_publishable_` key format in config; no references to legacy `anon` key |
| TFLite plugin instability | Post-MVP (ML enhancement phase) | Use `flutter_litert`; run classification on 100 sample inputs; verify Isolate execution |
| Clean Architecture boilerplate | Foundation (architecture setup) | Count files per feature; enforce <12 files for CRUD, <20 for complex features |
| Riverpod memory leaks | Foundation (state management setup) | Profile memory after navigating 10 screens back and forth; verify disposal in DevTools |
| Realtime channel staleness | Collaborative boards phase | Keep app open 20+ minutes; verify events still arrive; test with token refresh |
| RLS missing or too permissive | Foundation (first migration) | Two-account test: log in as User B, attempt to read User A's data; must return empty |
| Groq rate limits | AI planner phase | Simulate 20 rapid plan requests; verify graceful degradation with cached results |
| Flutter web performance | Deployment/polish phase | Lighthouse audit; verify TTI < 5s on throttled "Fast 3G" network |
| speech_to_text web limitations | Task input phase | Test voice input on Chrome, Firefox, Safari; verify text fallback works on unsupported browsers |
| Streak timezone bugs | Habit tracking phase | Test habit completion at 11:55 PM and 12:05 AM in different timezones |
| Board drag-drop conflicts | Collaborative boards phase | Two users drag same card simultaneously; verify convergent state within 2 seconds |

## Sources

- [Supabase Realtime Authorization Docs](https://supabase.com/docs/guides/realtime/authorization) -- RLS + Realtime setup requirements
- [Supabase RLS Guide](https://supabase.com/docs/guides/database/postgres/row-level-security) -- Official RLS documentation
- [Supabase Realtime + RLS Discussion #7630](https://github.com/orgs/supabase/discussions/7630) -- Silent failure reports
- [Fix Supabase Realtime When RLS Enabled (Medium)](https://medium.com/@kidane10g/supabase-realtime-stops-working-when-rls-is-enabled-heres-the-fix-154f0b43c69a) -- Fix documentation
- [Supabase API Key Migration Discussion #29260](https://github.com/orgs/supabase/discussions/29260) -- Key deprecation timeline
- [Supabase API Key Migration Discussion #40300](https://github.com/orgs/supabase/discussions/40300) -- Migration details
- [Supabase Edge Functions Limits](https://supabase.com/docs/guides/functions/limits) -- Free tier constraints
- [Supabase Realtime Limits](https://supabase.com/docs/guides/realtime/limits) -- 200 concurrent connections on free tier
- [supabase-flutter Issue #1012](https://github.com/supabase/supabase-flutter/issues/1012) -- Realtime issues tracking
- [supabase-flutter Issue #388](https://github.com/supabase/supabase-flutter/issues/388) -- Channel staleness after ~15 minutes
- [Riverpod autoDispose Docs](https://riverpod.dev/docs/concepts2/auto_dispose) -- Disposal behavior
- [Riverpod Issue #193](https://github.com/rrousselGit/riverpod/issues/193) -- StreamProvider memory leak
- [Riverpod Issue #2425](https://github.com/rrousselGit/riverpod/issues/2425) -- Disposed ProviderContainer error
- [Codewithandrea: Riverpod Architecture](https://codewithandrea.com/articles/flutter-app-architecture-riverpod-introduction/) -- Architecture patterns
- [Codewithandrea: Riverpod Data Caching](https://codewithandrea.com/articles/flutter-riverpod-data-caching-providers-lifecycle/) -- Provider lifecycle management
- [flutter_litert Package](https://pub.dev/packages/flutter_litert) -- LiteRT drop-in replacement for tflite_flutter
- [tflite_flutter Package](https://pub.dev/packages/tflite_flutter) -- Official TFLite Flutter plugin (work-in-progress status)
- [Groq API Rate Limits](https://console.groq.com/docs/rate-limits) -- Free tier constraints
- [Groq Free Tier Community Discussion](https://community.groq.com/t/what-are-the-rate-limits-for-the-groq-api-for-the-free-and-dev-tier-plans/42) -- Community-confirmed limits
- [speech_to_text Package](https://pub.dev/packages/speech_to_text) -- Platform support and limitations
- [Flutter Web Deployment Docs](https://docs.flutter.dev/deployment/web) -- Official web build guidance
- [Supabase RLS Best Practices (Makerkit)](https://makerkit.dev/blog/tutorials/supabase-rls-best-practices) -- Production RLS patterns
- [Supabase Security Hidden Dangers (DEV Community)](https://dev.to/fabio_a26a4e58d4163919a53/supabase-security-the-hidden-dangers-of-rls-and-how-to-audit-your-api-29e9) -- Security audit guide
- [Flutter Clean Architecture Practical Guide (Etere Studio)](https://blog.eterestudio.co/flutter-clean-architecture-practical-guide/) -- When to apply full vs. lite architecture
- [appflowy_board Package](https://pub.dev/packages/appflowy_board) -- Kanban board widget for Flutter

---
*Pitfalls research for: FocusForge -- Flutter AI-powered productivity app*
*Researched: 2026-03-16*
