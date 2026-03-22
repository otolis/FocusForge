# FocusForge

## What This Is

FocusForge is a cross-platform Flutter productivity app that combines AI-powered task management, habit tracking with streaks, an intelligent daily planner, and real-time collaborative project boards — all backed by Supabase. It's a portfolio project targeting full-stack roles, demonstrating Flutter + Supabase + on-device AI + realtime collaboration in one polished product.

## Core Value

Users can capture tasks naturally (voice or text), get an AI-optimized daily schedule, and track habits with visual streaks — a productivity system that feels intelligent, not just a CRUD app.

## Requirements

### Validated

- ✓ AI daily planner via Supabase Edge Function calling Groq API (Llama 3) — Phase 5
- ✓ Daily timeline view with drag-to-reschedule — Phase 5
- ✓ Energy pattern settings that influence AI schedule optimization — Phase 5
- ✓ Authentication with email and Google sign-in via Supabase Auth — Phase 1
- ✓ User profiles with display name, avatar, and energy pattern preferences — Phase 1
- ✓ Dark mode and custom Material 3 theme toggle — Phase 1
- ✓ Task CRUD with title, description, priority (1-4), category, and deadline — Phase 2
- ✓ Task list with filters, search, and priority badges — Phase 2
- ✓ Smart task input: regex+NLP heuristics for deadline, priority, category extraction — Phase 3
- ✓ TFLite on-device model for task classification — Phase 3
- ✓ Habit CRUD with daily/weekly/custom frequency and target counts — Phase 4
- ✓ Habit streak calculation and visual streaks via `fl_chart` — Phase 4
- ✓ Habit analytics screen with progress charts — Phase 4
- ✓ Push notifications via FCM with adaptive reminder timing — Phase 7
- ✓ Notification preferences configurable from settings — Phase 7
- ✓ Collaborative project boards with Kanban UI and drag-and-drop — Phase 6
- ✓ Board member invite and role management — Phase 6
- ✓ Supabase Realtime subscriptions for live board updates — Phase 6
- ✓ Live presence indicators on shared boards — Phase 6

### Active

- [ ] Lottie/Rive animations on task completions and milestones
- [ ] Flutter web deployment for live portfolio demo
- [ ] Cross-feature wiring (smart input → task creation, real items → AI planner)
- [ ] Polished GitHub README with screenshots and demo video

### Out of Scope

- Apple sign-in — no Mac available for testing, defer to post-v1
- Offline-first with SQLite sync — adds complexity without portfolio payoff for v1
- iOS builds — will use Codemagic CI later, Android-first for now
- Real-time chat — high complexity, not core to productivity value
- Video/file attachments — storage costs, defer to future
- Payment/subscription features — portfolio project, no monetization needed

## Context

- **Primary goal**: Portfolio piece showcasing full-stack Flutter + Supabase + AI skills for recruiters hiring full-stack developers
- **Development environment**: Windows 11, Android-only local testing (no Mac), Flutter web for demo deployment
- **AI strategy**: Two-tier approach — on-device NLP (regex first, TFLite upgrade later) for task parsing, cloud AI (Groq free tier via Edge Functions) for daily planning and summaries
- **Supabase**: Auth, PostgreSQL, Realtime, Edge Functions — covers entire backend with free tier
- **The collaborative boards module** is the most complex feature but a must-have — realtime multiplayer is a strong portfolio differentiator
- **Existing CLAUDE.md** in repo with project overview — will need updating to reflect Clean Architecture decision and GSD workflow

## Constraints

- **Tech stack**: Flutter 3.x + Dart, Supabase backend, Riverpod 2 state management
- **Architecture**: Clean Architecture (data/domain/presentation layers per feature)
- **AI cost**: Must be free — Groq free tier (14,400 req/day), on-device TFLite (zero cost)
- **Platform**: Android-first development, Flutter web for live demo
- **Auth**: Email + Google only for v1
- **No Mac**: iOS testing deferred, no Apple sign-in

## Key Decisions

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| Riverpod 2 over Bloc | Modern, less boilerplate, cleaner code for reviewers | — Pending |
| Clean Architecture over MVVM | Better separation of concerns, more recognizable pattern for full-stack roles | — Pending |
| Regex parser first, TFLite later | Ship faster with heuristics, upgrade to on-device ML as a clear portfolio "evolution" | — Pending |
| Online-only for v1 | Offline sync adds complexity without proportional portfolio impact | — Pending |
| GSD workflow over custom orchestrator | GSD handles phasing/execution, remove custom subagent delegation from CLAUDE.md | — Pending |
| Android + Web deployment | Develop on Android, deploy Flutter web as live demo for recruiters | — Pending |
| Email + Google auth only | Apple requires Mac for testing, defer to post-v1 | — Pending |

---
*Last updated: 2026-03-22 after Phase 7*
