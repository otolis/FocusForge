# FocusForge — AI-Powered Task Manager + Habit Tracker

## Project Overview

FocusForge is a cross-platform Flutter mobile app with Supabase backend. It combines intelligent task management, habit tracking with streaks, real-time collaboration, and AI-powered features (NLP task parsing, daily planner, smart notifications).

## Architecture

- **Frontend**: Flutter 3.x + Dart, MVVM pattern, Riverpod state management
- **Backend**: Supabase (PostgreSQL, Auth, Realtime, Edge Functions, Storage)
- **AI Layer**: On-device NLP via `flutter_nlp` + Groq free-tier LLM via Supabase Edge Functions
- **Target**: Android first (no Mac available), iOS via Codemagic CI later

## Tech Stack

| Layer | Technology |
|---|---|
| UI Framework | Flutter + Material 3 |
| State Management | Riverpod 2.x |
| Navigation | go_router |
| Backend | Supabase (supabase_flutter SDK) |
| Auth | Supabase Auth (email, Google, Apple) |
| Database | PostgreSQL via Supabase |
| Realtime | Supabase Realtime (WebSockets) |
| Push Notifications | Firebase Cloud Messaging (FCM) |
| Charts | fl_chart |
| AI (on-device) | Flutter NaturalLanguage / regex-based NLP |
| AI (cloud) | Groq API (Llama 3.x) via Supabase Edge Functions |
| Local Storage | shared_preferences + drift (SQLite) |
| Testing | flutter_test, mockito, integration_test |

## Project Structure

```
focusforge/
├── lib/
│   ├── main.dart
│   ├── app.dart
│   ├── core/
│   │   ├── constants/       # App constants, API keys, enums
│   │   ├── theme/           # Material 3 theme, colors, typography
│   │   ├── router/          # go_router configuration
│   │   ├── utils/           # Helpers, extensions, formatters
│   │   └── services/        # Shared services (notification, connectivity)
│   ├── features/
│   │   ├── auth/
│   │   │   ├── model/       # User model
│   │   │   ├── repository/  # Supabase auth repository
│   │   │   ├── viewmodel/   # Auth state (Riverpod notifiers)
│   │   │   └── view/        # Login, Register, Forgot password screens
│   │   ├── tasks/
│   │   │   ├── model/       # Task model, Priority enum
│   │   │   ├── repository/  # Supabase tasks CRUD + realtime
│   │   │   ├── viewmodel/   # Task list state, filters, sorting
│   │   │   ├── view/        # Task list, task detail, create task screens
│   │   │   └── widgets/     # Task card, priority badge, deadline chip
│   │   ├── habits/
│   │   │   ├── model/       # Habit model, HabitLog
│   │   │   ├── repository/  # Supabase habits CRUD
│   │   │   ├── viewmodel/   # Habit state, streak calculator
│   │   │   ├── view/        # Habit list, habit detail screens
│   │   │   └── widgets/     # Streak calendar, progress ring
│   │   ├── planner/
│   │   │   ├── model/       # DailyPlan, TimeBlock
│   │   │   ├── repository/  # AI planner repository
│   │   │   ├── viewmodel/   # Planner state
│   │   │   └── view/        # Daily planner screen
│   │   ├── collaboration/
│   │   │   ├── model/       # Board, BoardMember
│   │   │   ├── repository/  # Realtime board repository
│   │   │   ├── viewmodel/   # Board state
│   │   │   └── view/        # Board screen, invite flow
│   │   └── settings/
│   │       └── view/        # Profile, preferences, theme toggle
│   └── shared/
│       └── widgets/         # Reusable components (buttons, inputs, cards)
├── supabase/
│   ├── migrations/          # SQL migrations
│   ├── functions/           # Edge Functions (Deno/TypeScript)
│   │   ├── parse-task/      # AI task parsing endpoint
│   │   ├── daily-plan/      # AI daily plan generation
│   │   └── smart-notify/    # Smart notification logic
│   └── seed.sql             # Test data
├── test/
│   ├── unit/
│   ├── widget/
│   └── integration/
├── assets/
│   ├── images/
│   └── fonts/
└── pubspec.yaml
```

## Build Phases

### Phase 1 — Foundation (current)
- Flutter project scaffold with MVVM + Riverpod
- Supabase project setup (Auth, DB tables, RLS policies)
- Auth flow (email + Google sign-in)
- Task CRUD with local-first + Supabase sync
- Basic UI with Material 3 theming

### Phase 2 — AI + Smart Input
- NLP task parsing (extract title, deadline, priority, category)
- Groq LLM integration via Supabase Edge Functions
- AI daily planner screen
- Smart task suggestions

### Phase 3 — Habits + Real-time
- Habit tracker with streak logic
- Charts and progress visualization (fl_chart)
- Supabase Realtime subscriptions for live sync
- Offline-first with drift (SQLite) + sync queue

### Phase 4 — Collaboration + Polish
- Shared project boards with live updates
- Push notifications via FCM + smart scheduling
- Animations (Hero, page transitions, micro-interactions)
- Dark mode, haptics, accessibility
- App store preparation

## Orchestrator Rules

You are the **project lead / orchestrator**. You do NOT write code yourself. Instead:

1. **Analyze** what the user is asking for
2. **Delegate** to the appropriate subagent using the Task tool
3. **Review** the subagent's output before presenting to the user
4. **Coordinate** when a task spans multiple agents (e.g., frontend needs a new API endpoint — delegate to backend-developer first, then frontend-developer)

### Delegation Guidelines

| Task Type | Delegate To |
|---|---|
| UI screens, widgets, animations, theming | `frontend-developer` |
| Supabase schema, RLS, Edge Functions, auth | `backend-developer` |
| Architecture decisions, file structure, design patterns | `architect` |
| Unit tests, widget tests, integration tests | `qa-tester` |
| Build config, CI/CD, deployment, env setup | `devops` |

### Multi-Agent Coordination

When a feature requires both frontend and backend work:
1. Delegate to `architect` first for the design/interface contract
2. Then delegate to `backend-developer` to build the API/schema
3. Then delegate to `frontend-developer` to build the UI consuming that API
4. Finally delegate to `qa-tester` to write tests

### Important Rules

- Prefer delegating to subagents over doing work yourself — preserve your context window
- When a subagent reports an error or blocker, try to resolve it by delegating to the appropriate specialist
- Always search for documentation before implementing anything new
- When something goes wrong or a lesson is learned, update this CLAUDE.md under the "Lessons Learned" section below

## Lessons Learned

<!-- Agents: append findings here as you discover gotchas, bugs, or best practices -->

## Environment Notes

- No Mac available — Android-only development via `flutter run` on physical device or emulator
- iOS builds will be handled via Codemagic CI when ready
- Supabase project URL and anon key go in `lib/core/constants/supabase_constants.dart` (gitignored)
- Groq API key stored in Supabase Edge Function secrets, never in client code
