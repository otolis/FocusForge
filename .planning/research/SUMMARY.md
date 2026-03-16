# Project Research Summary

**Project:** FocusForge
**Domain:** Cross-platform Flutter AI-powered productivity app (task management + habit tracking + AI daily planning + realtime collaborative boards)
**Researched:** 2026-03-16
**Confidence:** HIGH

## Executive Summary

FocusForge is a four-pillar productivity app (tasks, habits, AI planner, collaborative boards) built with Flutter and Supabase. The expert approach for this type of app is a feature-first Clean Architecture with Riverpod 3 code generation for state management, Supabase as a complete backend-as-a-service (Auth, Postgres with RLS, Realtime, Edge Functions), and Groq's free-tier Llama 3 API proxied through Edge Functions for AI scheduling. The stack is mature and well-documented: Flutter 3.41, Riverpod 3.3, supabase_flutter 2.12, go_router 17.1, and freezed 3.2 are all stable releases with high community confidence. No competitor combines all four pillars in one app, and AI scheduling typically costs $10-34/month -- delivering it free via Groq is the flagship differentiator.

The recommended approach is to build incrementally in dependency order: foundation and auth first, then tasks (to validate the full Clean Architecture pattern end-to-end), then habits (parallel structure with streak logic), then AI planner (requires tasks + habits to exist), then collaborative boards (hardest feature, benefits from all established patterns), and finally polish and deployment. Clean Architecture should be applied pragmatically -- full layers for complex features (boards, planner) and a lighter structure for CRUD features (tasks, habits) to avoid boilerplate explosion. The on-device TFLite classification should be deferred to post-MVP and built behind an abstraction layer so the regex parser works first.

The primary risks are: (1) Supabase Realtime silently breaking when RLS is enabled -- this must be solved in the first migration with a reusable template; (2) Riverpod provider memory leaks from missing autoDispose on screen-scoped providers and Realtime channel subscriptions; (3) Realtime WebSocket connections going stale after ~15 minutes due to JWT token refresh failures; and (4) Supabase API key format changes in 2026 requiring new-style `sb_publishable_` keys from day one. All four risks have documented mitigations and should be addressed in Phase 1 (foundation) or the collaborative boards phase, not deferred to polish.

## Key Findings

### Recommended Stack

The stack centers on Flutter 3.41 with Dart 3.8, Riverpod 3 with code generation (`@riverpod` annotations), and Supabase for the entire backend. This eliminates the need for a custom server. Groq API provides free AI inference (14,400 req/day) through Supabase Edge Functions written in TypeScript/Deno. All package versions have been verified on pub.dev with high confidence.

**Core technologies:**
- **Flutter 3.41 + Dart 3.8:** Cross-platform framework -- latest stable with enhanced rendering and web support
- **Riverpod 3 (flutter_riverpod ^3.3.1):** State management with code generation -- de facto standard for Flutter in 2026, auto-retry, auto-dispose support
- **Supabase (supabase_flutter ^2.12.0):** Auth, Postgres, Realtime, Edge Functions, Storage -- replaces entire custom backend
- **Groq API (free tier):** AI inference via Llama 3 -- fastest inference provider, called only from Edge Functions
- **go_router ^17.1.0:** Declarative routing with auth guards -- official Flutter team package
- **freezed ^3.2.5:** Immutable data classes with unions -- essential for Clean Architecture entity modeling
- **fl_chart ^1.2.0:** Charts for habit analytics -- most popular Flutter charting library
- **envied ^1.3.3:** Compile-time env variable access with obfuscation -- secure alternative to flutter_dotenv

**Critical version notes:**
- Riverpod 3 requires Flutter 3.27+ and Dart 3.6+
- go_router 17.1 requires Flutter 3.32+ and Dart 3.8+
- All Riverpod packages (flutter_riverpod, hooks_riverpod, riverpod_annotation, riverpod_generator) must share the same major version
- Supabase API keys may use new `sb_publishable_` format on new projects created in 2026

### Expected Features

**Must have (table stakes):**
- Task CRUD with priority, deadline, categories, filters, search, and natural language input
- Habit CRUD with flexible frequency, visual streak tracking, and frictionless check-in UI
- Auth (email + Google), user profile with energy preferences
- Due date reminders via FCM push notifications
- Dark mode, responsive Material 3 UI, onboarding flow (3-4 screens)

**Should have (differentiators -- where the portfolio value lives):**
- AI daily planner via Groq (the flagship feature -- Motion charges $34/mo for this)
- Energy-pattern-aware scheduling (matches deep work to peak energy hours)
- Voice-to-task capture (speech_to_text + NLP parsing)
- Realtime collaborative Kanban boards with Supabase Realtime
- Live presence indicators on boards
- Drag-to-reschedule daily timeline
- Completion animations via Lottie

**Defer (v2+):**
- On-device TFLite task classification (requires model training and task data corpus)
- Offline support with SQLite sync (massive complexity, not needed for portfolio demo)
- Calendar integration (.ics export at most)
- Multi-language support (structure code for it but implement later)
- Real-time chat, gamification with points/leaderboards, Pomodoro timer, file attachments

### Architecture Approach

Feature-first Clean Architecture with three layers per feature (data/domain/presentation), using Riverpod 3 providers as the DI boundary between features. Controllers are AsyncNotifier subclasses generated with `@riverpod`. The domain layer defines abstract repository interfaces; the data layer provides Supabase-specific implementations. Cross-feature communication happens exclusively through shared Riverpod providers. The architecture should be applied pragmatically: full layers for complex features (boards, planner), a lighter structure without use cases for simple CRUD features (tasks, habits).

**Major components:**
1. **Presentation layer (Screens + Controllers):** ConsumerWidget/HookConsumerWidget screens consume AsyncValue states from AsyncNotifier controllers. One controller per screen or screen-group.
2. **Domain layer (Entities + Repository interfaces):** Pure Dart freezed data classes and abstract repository contracts. Zero framework dependencies. Business rules live here (streak calculation, board permissions, schedule optimization).
3. **Data layer (Repository implementations + Data sources + DTOs):** Supabase-specific code. Models/DTOs handle JSON serialization. Repository implementations map DTOs to domain entities. Separate data sources for Auth, PostgREST, Realtime, Edge Functions, and Storage.
4. **Core module:** Cross-cutting concerns -- GoRouter with Riverpod auth guard, Material 3 theme, error types, Supabase client provider, shared widgets.
5. **Supabase backend (Edge Functions + Migrations):** TypeScript/Deno Edge Functions for AI proxy (Groq). SQL migrations with RLS policies. Deployed independently via Supabase CLI.

### Critical Pitfalls

1. **Supabase Realtime silently breaks with RLS enabled** -- The Realtime service cannot evaluate RLS policies unless the table is added to the `supabase_realtime` publication and the Realtime role has SELECT access. Fix: create a reusable SQL migration template that includes `ALTER PUBLICATION`, role grants, and RLS policies together. Test Realtime from the client SDK, not the SQL Editor.

2. **Riverpod provider memory leaks from missing autoDispose** -- Family providers create persistent state per parameter. Realtime subscriptions accumulate without cleanup. Fix: use `autoDispose` as the default on all screen-scoped providers. Use `ref.onDispose()` to clean up Realtime channels. Use `ref.keepAlive()` only for providers that must survive navigation (user profile, board list).

3. **Realtime channels go stale after ~15 minutes** -- WebSocket connections lose sync when JWT tokens expire. Documented in supabase-flutter issues #388 and #1012. Fix: implement heartbeat/ping checks, listen for auth token refresh events and re-establish channels, add a connection status indicator to the board UI.

4. **Supabase API key deprecation** -- New projects in 2026 use `sb_publishable_` keys instead of legacy `anon` keys. Older tutorials reference the legacy format. Fix: verify key format on project creation, update all environment variables, follow the migration at github.com/orgs/supabase/discussions/29260.

5. **Clean Architecture boilerplate explosion** -- Full Clean Architecture creates 15-20 files per simple CRUD feature. Fix: apply two tiers -- "full" for complex features (boards, planner) and "lite" for CRUD features (skip use cases when they would be pure delegation, keep under 12 files per CRUD feature).

## Implications for Roadmap

Based on research, suggested phase structure:

### Phase 1: Foundation and Auth
**Rationale:** Everything depends on having a configured Supabase project, an authenticated user, and established architecture patterns. This phase validates the entire stack end-to-end and establishes the RLS + Realtime template that prevents the silent-failure pitfall.
**Delivers:** Supabase project with new-style API keys, core module (theme, router, error types, Supabase provider), email + Google auth, user profile with energy preferences, and the reusable architecture template (both "full" and "lite" tiers).
**Addresses:** Auth, user profile, energy preferences, dark mode toggle, onboarding flow shell
**Avoids:** API key deprecation pitfall, boilerplate explosion pitfall, memory leak patterns (establish autoDispose convention), RLS template from first migration

### Phase 2: Task Management
**Rationale:** Tasks are the simplest CRUD feature and the best candidate to validate the Clean Architecture pattern end-to-end. Every subsequent feature copies this pattern. Natural language input adds the first "smart" capability.
**Delivers:** Task CRUD, categories/labels, filters and search, natural language text parsing (regex + heuristics), task list and detail screens.
**Uses:** freezed (entities), Riverpod 3 AsyncNotifier (controller), supabase_flutter PostgREST (data source), go_router (navigation)
**Implements:** The full CRUD data flow: Screen -> Controller -> Repository -> Supabase -> DTO -> Entity -> AsyncValue
**Avoids:** Boilerplate explosion (use "lite" architecture -- skip use case layer for pure CRUD)

### Phase 3: Habit Tracking
**Rationale:** Parallel structure to tasks but adds streak calculation logic (a genuine domain rule) and chart rendering. Habits must exist before the AI planner can schedule them.
**Delivers:** Habit CRUD with daily/weekly frequency, streak tracking with visual chain display, habit check-in UI, habit analytics charts (fl_chart), completion animations (Lottie).
**Uses:** fl_chart (analytics), Lottie (animations), freezed (streak entities with domain logic)
**Avoids:** Streak timezone bugs -- use user's local timezone for calculations, store timezone in profile

### Phase 4: AI Daily Planner
**Rationale:** Requires tasks and habits to exist (the planner schedules them). This is the flagship differentiator. Introduces the first server-side code (Supabase Edge Functions) and external API integration (Groq).
**Delivers:** Supabase Edge Function calling Groq API, AI-generated daily schedule respecting energy patterns, daily timeline view, drag-to-reschedule interaction.
**Uses:** Supabase Edge Functions (Deno/TypeScript), Groq API (Llama 3), Supabase secrets for API key storage
**Avoids:** Groq rate limit issues -- cache daily plan in Supabase, regenerate only on task changes or user request. Never expose API key to client.

### Phase 5: Collaborative Boards
**Rationale:** The most complex feature. Requires auth (member management), Realtime channels (Postgres Changes, Presence, Broadcast), drag-and-drop UI, and role-based access control. Built last among features because it benefits from all patterns established in earlier phases.
**Delivers:** Board CRUD, Kanban columns with drag-and-drop cards, Supabase Realtime live updates, live presence indicators, board member invite and roles (owner/editor/viewer).
**Uses:** Supabase Realtime (channels, presence), kanban_board package (or custom Draggable/DragTarget), RLS with board_members junction table
**Avoids:** RLS + Realtime silent failure, channel staleness (implement heartbeat + reconnection), memory leaks (autoDispose on board controllers to clean up channels)

### Phase 6: Smart Input and Notifications
**Rationale:** Voice-to-task and push notifications enhance existing features rather than introducing new structural components. They require the task input flow to be stable first.
**Delivers:** Voice-to-task capture (speech_to_text), FCM push notifications for reminders, recurring tasks, adaptive reminder timing (requires completion data).
**Uses:** speech_to_text (on-device), firebase_messaging + flutter_local_notifications, firebase_core
**Avoids:** Over-relying on voice input -- always provide text input as primary, voice as enhancement

### Phase 7: Polish, Web Deployment, and Demo Readiness
**Rationale:** Cross-cutting enhancements that require all features to exist. The portfolio demo must load fast and work reliably for 2-3 minutes of recruiter testing.
**Delivers:** Lottie/Rive hero animations, Flutter web build optimized for performance (CanvasKit, deferred loading, tree-shaking), responsive layout tweaks, error/empty/loading state polish, onboarding flow completion.
**Avoids:** Flutter web bundle too large -- use `--wasm` compilation, lazy-load heavy features, deploy with CDN caching. Target TTI under 5 seconds on Fast 3G.

### Phase Ordering Rationale

- **Dependency-driven:** Auth enables everything. Tasks must exist before planner can schedule them. Habits must exist before planner can respect them. Boards are standalone but benefit from all established patterns.
- **Complexity escalation:** Each phase adds one new integration complexity. Phase 1 = Supabase Auth. Phase 2 = PostgREST CRUD. Phase 3 = fl_chart. Phase 4 = Edge Functions + Groq. Phase 5 = Realtime + Presence. Phase 6 = Platform plugins (speech, FCM). Phase 7 = Web deployment.
- **Risk frontloading:** The RLS + Realtime pattern is established in Phase 1 (verified with first table) so it does not surprise in Phase 5. The architecture template is set in Phase 1 so boilerplate does not slow Phases 2-5.
- **Demo value at each phase:** After Phase 4, the app demonstrates tasks + habits + AI planning -- a viable demo. Phase 5 adds the most impressive technical feature (realtime collaboration). Phase 7 makes it web-accessible.

### Research Flags

Phases likely needing deeper research during planning:
- **Phase 4 (AI Planner):** Groq API prompt engineering for structured JSON output, Edge Function development/testing workflow with Supabase CLI, caching strategy for AI results
- **Phase 5 (Collaborative Boards):** Supabase Realtime channel lifecycle management, optimistic updates with conflict resolution, RLS policies for multi-role board membership, reconnection strategy for stale channels
- **Phase 6 (Smart Input):** speech_to_text browser compatibility matrix for Flutter web, FCM web push VAPID key setup, Supabase Database Webhooks for triggering push notifications

Phases with standard patterns (skip research-phase):
- **Phase 1 (Foundation):** Well-documented Supabase setup, standard Flutter project scaffolding, Riverpod boilerplate is generated
- **Phase 2 (Tasks):** Standard CRUD with PostgREST, established Clean Architecture pattern from Code with Andrea
- **Phase 3 (Habits):** Same CRUD pattern as tasks, fl_chart has extensive examples

## Confidence Assessment

| Area | Confidence | Notes |
|------|------------|-------|
| Stack | HIGH | All package versions verified on pub.dev. Riverpod 3, supabase_flutter 2.12, go_router 17.1, freezed 3.2 are stable releases. kanban_board is the only MEDIUM-confidence package (evaluate compatibility with Flutter 3.41). |
| Features | HIGH | Feature landscape mapped against 8+ competitors. Clear table stakes vs differentiators. MVP definition is well-scoped with explicit anti-features. |
| Architecture | HIGH | Feature-first Clean Architecture with Riverpod is the dominant Flutter pattern in 2026. Code examples verified against official Riverpod docs and Code with Andrea. |
| Pitfalls | MEDIUM-HIGH | Critical pitfalls verified across official Supabase docs, GitHub issues, and community reports. Realtime + RLS issue is extensively documented. Channel staleness is a known open issue. TFLite fragmentation is based on ecosystem observation. |

**Overall confidence:** HIGH

### Gaps to Address

- **kanban_board package compatibility:** Version 1.0.0+2 needs verification against Flutter 3.41. May need to build custom Kanban using Draggable/DragTarget for full Realtime control. Decision should be made at the start of Phase 5.
- **Supabase API key format:** Verify whether a new Supabase project in March 2026 uses `sb_publishable_` or legacy `anon` keys. This determines initial configuration and Edge Function env vars.
- **Groq free tier longevity:** The 14,400 req/day free tier is current as of research date. Verify tier limits have not changed before Phase 4 implementation. Have Cloudflare Workers AI as a documented fallback.
- **Flutter web Wasm maturity:** Wasm compilation is stable since Flutter 3.22, but verify that all dependencies (fl_chart, Lottie, kanban_board) work correctly under Wasm before committing to it in Phase 7.
- **Realtime channel staleness fix:** The issue (supabase-flutter #388, #1012) may be resolved in a future supabase_flutter release before Phase 5. Check for SDK updates.

## Sources

### Primary (HIGH confidence)
- pub.dev package pages for all recommended packages (versions verified 2026-03-16)
- [Supabase Official Docs](https://supabase.com/docs) -- Auth, Realtime, Edge Functions, RLS
- [Riverpod Official Docs](https://riverpod.dev) -- Riverpod 3 features, autoDispose, code generation
- [Flutter 3.41 Release Notes](https://blog.flutter.dev/whats-new-in-flutter-3-41-302ec140e632)
- [Supabase Realtime Authorization Docs](https://supabase.com/docs/guides/realtime/authorization)

### Secondary (MEDIUM confidence)
- [Code with Andrea](https://codewithandrea.com) -- Riverpod architecture patterns, AsyncNotifier, envied security analysis
- [Supabase API Key Migration Discussion #29260](https://github.com/orgs/supabase/discussions/29260)
- [supabase-flutter Issues #388, #1012](https://github.com/supabase/supabase-flutter/issues) -- Realtime staleness reports
- Competitor analysis sources: Zapier, Morgen, Kuse, Taskade productivity tool roundups (2026)
- [Trophy/Plotline](https://trophy.so) -- Streak gamification research

### Tertiary (LOW confidence)
- kanban_board ^1.0.0+2 compatibility with Flutter 3.41 (untested, 42 likes, updated May 2025)
- flutter_litert as TFLite replacement (recommended but not yet integrated in this project)
- Groq free tier stability beyond current published limits

---
*Research completed: 2026-03-16*
*Ready for roadmap: yes*
