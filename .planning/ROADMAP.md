# Roadmap: FocusForge

## Overview

FocusForge delivers an AI-powered productivity app across 8 phases. Phase 1 establishes the foundation (Supabase, auth, profile, theming). Phases 2 through 7 are independent feature phases that can execute in parallel across separate terminals -- each owns its complete vertical slice (DB schema, data layer, domain, presentation). Phase 8 integrates cross-feature interactions, adds animations, and deploys to Flutter web. The goal is a polished portfolio piece demonstrating Flutter + Supabase + AI + realtime collaboration.

## Phases

**Phase Numbering:**
- Integer phases (1, 2, 3): Planned milestone work
- Decimal phases (2.1, 2.2): Urgent insertions (marked with INSERTED)

Decimal phases appear between their surrounding integers in numeric order.

**Parallel Execution:**
- Phase 1 must complete first (hard prerequisite for all)
- Phases 2-7 are fully independent and run in parallel
- Phase 8 depends on all feature phases completing

- [x] **Phase 1: Foundation & Auth** - Supabase setup, auth flows, user profile, dark mode, onboarding
- [ ] **Phase 2: Task Management** - Task CRUD, categories, filters, search, recurring tasks
- [ ] **Phase 3: Smart Task Input** - Natural language parsing and on-device TFLite classification
- [ ] **Phase 4: Habit Tracking** - Habit CRUD, streaks, check-in, analytics charts
- [ ] **Phase 5: AI Daily Planner** - Edge Function with Groq API, timeline view, drag-to-reschedule
- [ ] **Phase 6: Collaborative Boards** - Kanban UI, realtime sync, member invites, live presence
- [ ] **Phase 7: Notifications & Reminders** - FCM push notifications, adaptive reminder timing
- [ ] **Phase 8: Integration, Animations & Deployment** - Cross-feature wiring, Lottie animations, Flutter web deploy

## Phase Details

### Phase 1: Foundation & Auth
**Goal**: Users can authenticate, manage their profile, and navigate a themed app shell with onboarding
**Depends on**: Nothing (first phase)
**Requirements**: AUTH-01, AUTH-02, AUTH-03, AUTH-04, AUTH-05, UX-01
**Success Criteria** (what must be TRUE):
  1. User can create an account with email/password and sign in successfully
  2. User can sign in with Google OAuth and land on the home screen
  3. User can view and edit their profile (display name, avatar, energy pattern preferences)
  4. User can toggle between light mode, dark mode, and system default with Material 3 theming
  5. New user sees an onboarding flow (3-4 screens) on first launch that can be skipped
**Plans**: 3 plans

Plans:
- [x] 01-01-PLAN.md — Flutter project scaffold, Material 3 theme system, shared widgets, test infrastructure
- [x] 01-02-PLAN.md — Auth feature (email/password, Google OAuth, router guards, DB migration)
- [x] 01-03-PLAN.md — Profile, app shell, onboarding, settings, final router wiring

### Phase 2: Task Management
**Goal**: Users can create, organize, filter, and manage tasks with full CRUD and recurring schedules
**Depends on**: Phase 1
**Requirements**: TASK-01, TASK-03, TASK-04, TASK-05
**Success Criteria** (what must be TRUE):
  1. User can create a task with title, description, priority (P1-P4), category, and deadline, and edit or delete it
  2. User can create and assign color-coded categories/labels to tasks
  3. User can filter tasks by priority, category, and date range, and search tasks with full-text search
  4. User can set tasks to recur on daily, weekly, monthly, or custom intervals, and recurring instances generate automatically
**Plans**: TBD

Plans:
- [ ] 02-01: TBD
- [ ] 02-02: TBD

### Phase 3: Smart Task Input
**Goal**: Users get intelligent task creation assistance through natural language parsing and ML-powered classification
**Depends on**: Phase 1
**Requirements**: TASK-02, TASK-06
**Success Criteria** (what must be TRUE):
  1. User can type a natural language sentence (e.g., "Buy groceries tomorrow high priority") and the app auto-extracts deadline, priority, and category
  2. On-device TFLite model suggests category and priority for new tasks based on the task text
  3. Parsing and classification results are presented as editable suggestions the user can accept or override
**Plans**: 3 plans

Plans:
- [ ] 03-01-PLAN.md — NLP parser service with regex priority extraction, chrono_dart date parsing, category keyword matching
- [ ] 03-02-PLAN.md — TFLite classifier service, training pipeline, model assets, and unit tests
- [ ] 03-03-PLAN.md — Smart input orchestrator, Riverpod providers, UI widgets, demo screen, widget tests

### Phase 4: Habit Tracking
**Goal**: Users can track habits with streaks, one-tap check-in, and visual analytics
**Depends on**: Phase 1
**Requirements**: HABIT-01, HABIT-02, HABIT-03, HABIT-04
**Success Criteria** (what must be TRUE):
  1. User can create, edit, and delete habits with daily/weekly/custom frequency and target counts
  2. User can see their current streak (consecutive-day counter) and a visual chain display for each habit
  3. User can check in a habit with one tap and see satisfying feedback animation
  4. User can view habit analytics with completion rate charts (weekly/monthly/yearly) rendered via fl_chart
**Plans**: 3 plans

Plans:
- [ ] 04-01-PLAN.md — Supabase migration (habits + habit_logs), domain models, repository, Riverpod providers, pubspec dependencies
- [ ] 04-02-PLAN.md — Habit list screen, creation/edit form, check-in button with animation and haptics, router wiring
- [ ] 04-03-PLAN.md — Streak calculator, GitHub-style heat map, analytics bar charts, stat cards, habit detail screen

### Phase 5: AI Daily Planner
**Goal**: Users get an AI-generated daily schedule optimized for their energy patterns with a visual timeline
**Depends on**: Phase 1
**Requirements**: PLAN-01, PLAN-02, PLAN-03
**Success Criteria** (what must be TRUE):
  1. User can generate an AI-optimized daily schedule via a Supabase Edge Function calling the Groq API, incorporating their energy preferences
  2. User can view their daily schedule as a visual time-blocked timeline
  3. User can drag tasks to different time slots on the timeline with snap-to-15-minute increments
  4. Generated schedule respects user's energy pattern (deep work in peak hours, light tasks in low-energy periods)
**Plans**: 3 plans

Plans:
- [ ] 05-01-PLAN.md — Data foundation: DB migration, domain models, Edge Function with Groq API, repository, Riverpod providers
- [ ] 05-02-PLAN.md — Timeline UI: planner screen, timeline widget, time block cards, energy zones, add-item sheet, shimmer loading, router wiring
- [ ] 05-03-PLAN.md — Drag-to-reschedule: LongPressDraggable blocks, 15-minute snap, push-down displacement, auto-save

### Phase 6: Collaborative Boards
**Goal**: Users can collaborate on Kanban boards with realtime sync, role-based access, and live presence
**Depends on**: Phase 1
**Requirements**: BOARD-01, BOARD-02, BOARD-03, BOARD-04
**Success Criteria** (what must be TRUE):
  1. User can create boards with Kanban columns and drag-and-drop cards between columns
  2. Board changes (card moves, edits, column changes) sync instantly across all connected users via Supabase Realtime
  3. User can invite members to boards by email and assign roles (owner/editor/viewer) with appropriate permissions
  4. User can see live presence indicators showing who is currently online on a shared board
**Plans**: TBD

Plans:
- [ ] 06-01: TBD
- [ ] 06-02: TBD
- [ ] 06-03: TBD

### Phase 7: Notifications & Reminders
**Goal**: Users receive timely push notifications for deadlines with adaptive reminder timing
**Depends on**: Phase 1
**Requirements**: PLAN-04, UX-03
**Success Criteria** (what must be TRUE):
  1. User receives FCM push notifications for upcoming task deadlines with configurable reminder timing
  2. Reminder timing adapts based on user's completion patterns (e.g., if user consistently completes tasks last-minute, reminders come earlier)
  3. User can configure notification preferences (enable/disable, timing offsets) from settings
**Plans**: TBD

Plans:
- [ ] 07-01: TBD
- [ ] 07-02: TBD

### Phase 8: Integration, Animations & Deployment
**Goal**: All features are wired together, polished with animations, and deployed as a live Flutter web demo
**Depends on**: Phases 1, 2, 3, 4, 5, 6, 7 (all prior phases)
**Requirements**: UX-02, UX-04
**Success Criteria** (what must be TRUE):
  1. Smart task input (Phase 3) is wired into the task creation flow (Phase 2) so NLP parsing and TFLite suggestions appear inline
  2. AI daily planner (Phase 5) pulls real tasks (Phase 2) and habits (Phase 4) to generate schedules
  3. Lottie animations play on task completion, habit check-in, and streak milestones throughout the app
  4. App is deployed as Flutter web and accessible via a public URL for portfolio demo
  5. All cross-feature navigation works (home screen links to tasks, habits, planner, boards)
**Plans**: TBD

Plans:
- [ ] 08-01: TBD
- [ ] 08-02: TBD
- [ ] 08-03: TBD

## Progress

**Execution Order:**
Phase 1 first, then Phases 2-7 in parallel, then Phase 8 last.

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 1. Foundation & Auth | 3/3 | Complete | 2026-03-17 |
| 2. Task Management | 0/0 | Not started | - |
| 3. Smart Task Input | 0/3 | Planned | - |
| 4. Habit Tracking | 0/3 | Planned | - |
| 5. AI Daily Planner | 0/3 | Planned | - |
| 6. Collaborative Boards | 0/0 | Not started | - |
| 7. Notifications & Reminders | 0/0 | Not started | - |
| 8. Integration, Animations & Deployment | 0/0 | Not started | - |
