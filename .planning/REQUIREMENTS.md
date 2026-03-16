# Requirements: FocusForge

**Defined:** 2026-03-16
**Core Value:** Users can capture tasks naturally, get an AI-optimized daily schedule, and track habits with visual streaks — a productivity system that feels intelligent, not just a CRUD app.

## v1 Requirements

Requirements for initial release. Each maps to roadmap phases.

### Authentication & Profile

- [ ] **AUTH-01**: User can sign up with email and password via Supabase Auth
- [ ] **AUTH-02**: User can sign in with Google OAuth via Supabase Auth
- [ ] **AUTH-03**: User can create and edit profile with display name and avatar
- [ ] **AUTH-04**: User can set energy pattern preferences (peak/low hours) for AI scheduling
- [ ] **AUTH-05**: New user sees 3-4 screen onboarding flow explaining app features

### Task Management

- [ ] **TASK-01**: User can create, read, update, and delete tasks with title, description, priority (P1-P4), category, and deadline
- [ ] **TASK-02**: User can input tasks with natural language text that auto-parses deadline, priority, and category via regex+NLP heuristics
- [ ] **TASK-03**: User can filter tasks by priority, category, and date range, and search tasks with full-text search
- [ ] **TASK-04**: User can create, edit, and assign color-coded categories/labels to tasks
- [ ] **TASK-05**: User can set tasks to recur on daily, weekly, monthly, or custom intervals
- [ ] **TASK-06**: Tasks are auto-classified by on-device TFLite model for category and priority suggestions

### Habit Tracking

- [ ] **HABIT-01**: User can create, edit, and delete habits with daily/weekly/custom frequency and target counts
- [ ] **HABIT-02**: User can see visual streak tracking with consecutive-day counter and chain display
- [ ] **HABIT-03**: User can view habit analytics with completion rate charts (weekly/monthly/yearly) via fl_chart
- [ ] **HABIT-04**: User can check in habits with one-tap completion and satisfying feedback animations

### AI Daily Planner

- [ ] **PLAN-01**: User can generate an AI-optimized daily schedule from their tasks, habits, and energy preferences via Supabase Edge Function calling Groq API
- [ ] **PLAN-02**: User can view daily schedule as a visual time-blocked timeline
- [ ] **PLAN-03**: User can drag tasks to different time slots on the timeline (snap to 15-minute increments)
- [ ] **PLAN-04**: User receives adaptive reminders that learn from their completion patterns and adjust timing

### Collaborative Boards

- [ ] **BOARD-01**: User can create boards with Kanban columns and drag-and-drop cards between columns
- [ ] **BOARD-02**: Board changes sync instantly across all connected users via Supabase Realtime
- [ ] **BOARD-03**: User can invite members to boards by email and assign roles (owner/editor/viewer)
- [ ] **BOARD-04**: User can see live presence indicators showing who is online on a shared board

### Polish & Deployment

- [ ] **UX-01**: User can toggle dark mode with Material 3 theme (light/dark/system default)
- [ ] **UX-02**: User sees Lottie animations on task completion, habit check-in, and streak milestones
- [ ] **UX-03**: User receives FCM push notifications for deadline reminders with configurable timing
- [ ] **UX-04**: App is deployed as Flutter web for live portfolio demo accessible via URL

## v2 Requirements

Deferred to future release. Tracked but not in current roadmap.

### Voice & Input

- **VOICE-01**: User can capture tasks via voice using speech_to_text, parsed by NLP pipeline

### Habit Enhancements

- **HABIT-05**: User can freeze streaks to prevent anxiety from accidental breaks

### Export & Integration

- **EXPORT-01**: User can export daily plan as .ics calendar file

### Content

- **CONT-01**: User can use rich text (markdown) in task descriptions
- **CONT-02**: User can choose from board templates (sprint board, personal project)

### Localization

- **L10N-01**: App supports multiple languages (structure code with intl patterns now)

## Out of Scope

Explicitly excluded. Documented to prevent scope creep.

| Feature | Reason |
|---------|--------|
| Apple sign-in | No Mac available for testing; add post-v1 when Mac access available |
| Offline-first with SQLite sync | Adds weeks of complexity for a portfolio project; online-only is sufficient |
| Real-time chat in boards | Chat is a separate product; comments on cards suffice for async communication |
| Calendar integration (Google/Outlook) | OAuth complexity, two-way sync conflicts; AI planner provides standalone daily view |
| Gamification (points/levels/leaderboards) | Full gamification requires economy balancing; subtle streaks and animations suffice |
| Social features (friend feed, public profiles) | Requires content moderation and privacy controls; collaborative boards cover "work with others" |
| Pomodoro timer | Separate workflow; AI planner already time-blocks work sessions |
| File/image attachments | Storage costs, file validation; text descriptions and links suffice |
| Multi-language (full i18n) | Overkill for portfolio; structure code for future i18n but ship English only |

## Traceability

Which phases cover which requirements. Updated during roadmap creation.

| Requirement | Phase | Status |
|-------------|-------|--------|
| AUTH-01 | — | Pending |
| AUTH-02 | — | Pending |
| AUTH-03 | — | Pending |
| AUTH-04 | — | Pending |
| AUTH-05 | — | Pending |
| TASK-01 | — | Pending |
| TASK-02 | — | Pending |
| TASK-03 | — | Pending |
| TASK-04 | — | Pending |
| TASK-05 | — | Pending |
| TASK-06 | — | Pending |
| HABIT-01 | — | Pending |
| HABIT-02 | — | Pending |
| HABIT-03 | — | Pending |
| HABIT-04 | — | Pending |
| PLAN-01 | — | Pending |
| PLAN-02 | — | Pending |
| PLAN-03 | — | Pending |
| PLAN-04 | — | Pending |
| BOARD-01 | — | Pending |
| BOARD-02 | — | Pending |
| BOARD-03 | — | Pending |
| BOARD-04 | — | Pending |
| UX-01 | — | Pending |
| UX-02 | — | Pending |
| UX-03 | — | Pending |
| UX-04 | — | Pending |

**Coverage:**
- v1 requirements: 27 total
- Mapped to phases: 0
- Unmapped: 27 (pending roadmap creation)

---
*Requirements defined: 2026-03-16*
*Last updated: 2026-03-16 after initial definition*
