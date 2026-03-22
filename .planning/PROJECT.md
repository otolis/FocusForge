# FocusForge

## What This Is

FocusForge is a cross-platform Flutter productivity app that combines AI-powered task management with NLP parsing, habit tracking with streaks and analytics, an intelligent daily planner with energy-aware scheduling, real-time collaborative Kanban boards, and adaptive push notifications — all backed by Supabase. Shipped as v1.0 MVP with 17,991 LOC across Dart, TypeScript, and SQL.

## Core Value

Users can capture tasks naturally, get an AI-optimized daily schedule, track habits with visual streaks, and collaborate in real-time — a productivity system that feels intelligent, not just a CRUD app.

## Current State

**Version:** v1.0 MVP shipped 2026-03-22
**Codebase:** 17,991 LOC (Dart + TypeScript + SQL), 273 files
**Stack:** Flutter 3.x, Supabase (Auth, PostgreSQL, Realtime, Edge Functions), Groq API, TFLite, FCM
**Deployment:** GitHub Actions CI/CD → GitHub Pages (Flutter web)

## Requirements

### Validated

- ✓ Authentication with email and Google sign-in via Supabase Auth — v1.0
- ✓ User profiles with display name, avatar, and energy pattern preferences — v1.0
- ✓ Dark mode and custom Material 3 theme toggle — v1.0
- ✓ Task CRUD with title, description, priority (1-4), category, and deadline — v1.0
- ✓ Task list with filters, search, and priority badges — v1.0
- ✓ Smart task input: regex+NLP heuristics for deadline, priority, category extraction — v1.0
- ✓ TFLite on-device model for task classification — v1.0
- ✓ Habit CRUD with daily/weekly/custom frequency and target counts — v1.0
- ✓ Habit streak calculation and visual streaks via `fl_chart` — v1.0
- ✓ Habit analytics screen with progress charts — v1.0
- ✓ AI daily planner via Supabase Edge Function calling Groq API (Llama 3) — v1.0
- ✓ Daily timeline view with drag-to-reschedule — v1.0
- ✓ Energy pattern settings that influence AI schedule optimization — v1.0
- ✓ Collaborative project boards with Kanban UI and drag-and-drop — v1.0
- ✓ Board member invite and role management — v1.0
- ✓ Supabase Realtime subscriptions for live board updates — v1.0
- ✓ Live presence indicators on shared boards — v1.0
- ✓ Push notifications via FCM with adaptive reminder timing — v1.0
- ✓ Notification preferences configurable from settings — v1.0
- ✓ Lottie animations on task completion, habit check-in, and streak milestones — v1.0
- ✓ Flutter web deployment for live portfolio demo — v1.0
- ✓ Cross-feature wiring (smart input → task creation, real items → AI planner) — v1.0

### Active

- [ ] Polished GitHub README with screenshots and demo video
- [ ] iOS builds via Codemagic CI
- [ ] Offline-first with SQLite sync queue
- [ ] Voice-to-text task input via `speech_to_text`

### Out of Scope

- Apple sign-in — no Mac available for testing
- Real-time chat — high complexity, not core to productivity value
- Video/file attachments — storage costs, defer to future
- Payment/subscription features — portfolio project, no monetization needed

## Context

- **Primary goal**: Portfolio piece showcasing full-stack Flutter + Supabase + AI skills for recruiters
- **Development environment**: Windows 11, Android-only local testing (no Mac), Flutter web for demo
- **AI strategy**: Two-tier — on-device NLP (regex + TFLite) for task parsing, cloud AI (Groq free tier) for daily planning
- **Supabase**: Auth, PostgreSQL, Realtime, Edge Functions — covers entire backend with free tier
- **v1.0 shipped**: 8 phases, 25 plans, 6 days from init to completion

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
| Riverpod 2 over Bloc | Modern, less boilerplate, cleaner code for reviewers | ✓ Good — clean provider composition across all features |
| Clean Architecture over MVVM | Better separation of concerns, more recognizable pattern | ✓ Good — consistent data/domain/presentation split |
| Regex parser first, TFLite later | Ship faster with heuristics, upgrade to on-device ML | ✓ Good — both shipped, TFLite fills gaps regex misses |
| Online-only for v1 | Offline sync adds complexity without portfolio payoff | ✓ Good — simpler codebase, deferred to v1.1 |
| GSD workflow over custom orchestrator | GSD handles phasing/execution automatically | ✓ Good — 25 plans across 8 phases in 6 days |
| Android + Web deployment | Develop on Android, deploy Flutter web as live demo | ✓ Good — GitHub Pages deployment via CI/CD |
| Email + Google auth only | Apple requires Mac for testing | ✓ Good — covers most users, Apple deferred |
| Groq llama-3.3-70b-versatile | Free tier, json_object mode, temperature 0.3 | ✓ Good — deterministic scheduling output |
| Parallel phase execution (2-7) | Independent vertical slices enable concurrent development | ✓ Good — all 6 feature phases ran in parallel |
| Supabase Realtime with REPLICA IDENTITY FULL | Complete DELETE payloads for board cards/columns | ✓ Good — clean realtime event handling |
| Data-only FCM messages | Flutter control over notification display and actions | ✓ Good — consistent cross-platform behavior |

---
*Last updated: 2026-03-22 after v1.0 milestone*
