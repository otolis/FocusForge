# Roadmap: FocusForge

## Milestones

- ✅ **v1.0 MVP** -- Phases 1-8 (shipped 2026-03-22)
- 🚧 **v1.1 Security & Hardening** -- Phases 10-13 (in progress)
- 📋 **Phase 9: Boards Redesign** -- (planned, independent of v1.1)

## Phases

<details>
<summary>✅ v1.0 MVP (Phases 1-8) -- SHIPPED 2026-03-22</summary>

- [x] Phase 1: Foundation & Auth (3/3 plans) -- completed 2026-03-17
- [x] Phase 2: Task Management (3/3 plans) -- completed 2026-03-22
- [x] Phase 3: Smart Task Input (3/3 plans) -- completed 2026-03-22
- [x] Phase 4: Habit Tracking (3/3 plans) -- completed 2026-03-22
- [x] Phase 5: AI Daily Planner (3/3 plans) -- completed 2026-03-22
- [x] Phase 6: Collaborative Boards (3/3 plans) -- completed 2026-03-22
- [x] Phase 7: Notifications & Reminders (3/3 plans) -- completed 2026-03-22
- [x] Phase 8: Integration, Animations & Deployment (4/4 plans) -- completed 2026-03-22

</details>

### v1.1 Security & Hardening

**Milestone Goal:** Lock down security vulnerabilities in SECURITY DEFINER RPCs, fix notification logic gaps, and harden auth/planner/lifecycle subsystems discovered during post-v1.0 audit.

**Parallel execution:** Phases 10, 11, 12, and 13 touch independent subsystems (SQL/Edge Functions, notification Dart service, auth/planner/boards Dart code, onboarding/task forms) and CAN run in parallel across separate terminals.

- [x] **Phase 10: RPC & Edge Function Security** - Lock down SECURITY DEFINER RPCs + enable JWT verification on Edge Functions (completed 2026-03-28)
- [x] **Phase 11: Notification Logic Fixes** - Fix cold-start routing, action handlers, snooze, reminder scheduling, and preference honoring (completed 2026-03-28)
- [x] **Phase 12: Auth, Planner & Lifecycle Cleanup** - Hide placeholder Google sign-in, make planner import idempotent, fix FCM lifecycle and board RLS (completed 2026-03-28)
- [ ] **Phase 13: Onboarding, Recurring Tasks & Filter Fixes** - Fix onboarding bypass, recurring task editing, and date-range filter off-by-one

### Phase 9 (Independent)

- [ ] **Phase 9: Boards UI Redesign** - Monday.com-style layout (independent of v1.1, planned separately)

## Phase Details

### Phase 10: RPC & Edge Function Security
**Goal**: All SECURITY DEFINER database functions derive caller identity from auth.uid(), and Edge Functions require valid JWT tokens — preventing cost abuse and unauthorized data access
**Depends on**: Nothing (SQL migrations + Edge Function config, independent of other phases)
**Requirements**: SEC-01, SEC-02, SEC-03, SEC-04, SEC-05, SEC-06
**Success Criteria** (what must be TRUE):
  1. Calling `search_tasks` or `generate_recurring_instances` with a forged user ID returns only the caller's own data (auth.uid() enforced server-side)
  2. Calling `create_board_with_defaults` or `invite_board_member` with a forged owner/inviter ID is rejected or overridden by auth.uid()
  3. Direct client invocation of privileged RPCs is blocked via REVOKE/GRANT EXECUTE restrictions
  4. Existing app functionality (task search, recurring tasks, board creation, invites) continues working with auth.uid()-derived identity
  5. Edge Functions (`generate-schedule`, `rewrite-title`) require a valid JWT — unauthenticated calls with only the anon key are rejected
  6. Client code in `planner_repository.dart` and `ai_rewrite_button.dart` passes the user's auth token (not just anon key) when invoking Edge Functions
**Plans**: 2 plans

Plans:
- [ ] 10-01-PLAN.md -- SQL migration hardening RPCs with auth.uid() + Edge Function JWT config
- [ ] 10-02-PLAN.md -- Client-side Dart fixes: RPC signature updates + remove manual auth headers

### Phase 11: Notification Logic Fixes
**Goal**: Notification actions execute correct domain logic, deep links work on cold start, user preferences are respected, and reminders are actually scheduled for initial delivery
**Depends on**: Nothing (notification Dart service + Edge Function, independent of other phases)
**Requirements**: NOTIF-01, NOTIF-02, NOTIF-03, NOTIF-04, NOTIF-05, NOTIF-06, NOTIF-07
**Success Criteria** (what must be TRUE):
  1. Tapping a notification when the app is terminated (cold start) navigates to the correct screen after the app finishes initializing
  2. Completing a task via notification action sets both `is_completed` and `completed_at` fields, matching what happens when completing from the task list UI
  3. Completing a habit via notification action uses same-day upsert/increment logic, producing identical results to tapping the check-in button on the habit screen
  4. Snoozing a notification reschedules it by the user's configured snooze duration (from settings), not a hardcoded 15 minutes
  5. Adaptive notification timing receives real completion data via `recordCompletion` so it learns from actual user behavior
  6. Creating a task with a deadline, a habit, or a planner time block inserts initial rows into `scheduled_reminders` so `send-reminders` can deliver them (not just snooze re-inserts)
  7. Quiet hours are evaluated using the user's timezone (stored with the preference), not the Edge Function server's local time
**Plans**: 3 plans

Plans:
- [ ] 11-01-PLAN.md -- Notification service action handler rewrites + cold-start deep link + snooze prefs + adaptive timing wiring
- [ ] 11-02-PLAN.md -- Initial reminder scheduling in task, habit, and planner repositories
- [ ] 11-03-PLAN.md -- Timezone-aware quiet hours (migration + Dart model + Edge Function)

### Phase 12: Auth, Planner & Lifecycle Cleanup
**Goal**: Remove user-facing rough edges in auth flow, prevent planner import duplication, and fix resource lifecycle issues in FCM and board member visibility
**Depends on**: Nothing (touches auth screens, planner provider, notification service lifecycle, board RLS -- all independent of phases 10-11)
**Requirements**: AUTH-01, PLAN-01, PLAN-02, LIFE-01, LIFE-02
**Success Criteria** (what must be TRUE):
  1. Login and register screens show only email sign-in when the Google client ID is a placeholder value; Google buttons appear only when a real client ID is configured
  2. Importing tasks/habits into the planner multiple times does not create duplicate time blocks (idempotent import with source linkage tracking)
  3. Each `addItem()` call during planner import completes before the next begins (no race conditions from unawaited futures)
  4. Signing out and back in does not accumulate stale FCM token refresh subscriptions (subscription cancelled on sign-out)
  5. Board co-members can see each other's profile display names and avatars on shared boards without RLS visibility errors
**Plans**: 2 plans

Plans:
- [ ] 12-01-PLAN.md -- Hide Google sign-in buttons, fix FCM subscription lifecycle, add board co-member profile RLS
- [ ] 12-02-PLAN.md -- Idempotent planner import with source linkage and sequential await

### Phase 13: Onboarding, Recurring Tasks & Filter Fixes
**Goal**: Fix onboarding bypass allowing direct navigation to app routes, complete recurring task editing lifecycle, and fix date-range filter off-by-one exclusion
**Depends on**: Nothing (touches onboarding/router, task form, task filter — all independent of phases 10-12)
**Requirements**: ONBOARD-01, RECTASK-01, FILTER-01
**Success Criteria** (what must be TRUE):
  1. Navigating directly to any app route (e.g., `/tasks`, `/habits`) when onboarding is incomplete redirects to the onboarding screen — not just auth routes and `/`
  2. Opening the edit form for a recurring task pre-populates the recurrence picker with the existing rule, and saving updates both the parent task and the recurrence rule
  3. Editing recurrence on "all future instances" regenerates instances using the updated rule, not the old one
  4. Selecting a date range filter with start=Mar 1 and end=Mar 31 includes tasks with deadlines on Mar 31 at any time of day (end date is inclusive)
**Plans**: 2 plans

Plans:
- [ ] 13-01-PLAN.md -- Onboarding redirect guard for all routes + date-range filter end-date inclusive fix
- [ ] 13-02-PLAN.md -- Recurring task editing: load existing rule, upsert on save, regenerate with updated pattern

### Phase 9: Boards UI Redesign
**Goal**: Replace current Kanban-only board view with a Monday.com-style spreadsheet/table layout featuring customizable columns for priorities, timelines, deadlines, status, and assignees. Inline editing, timeline bars, priority badges, deadline indicators, and column reordering.
**Depends on**: Phase 6 (Collaborative Boards)
**Requirements**: BOARD-TABLE-MODELS, BOARD-TABLE-MIGRATION, BOARD-TABLE-REPOS, BOARD-TABLE-CELLS, BOARD-TABLE-ACCESSIBILITY, BOARD-TABLE-GROUPS, BOARD-TABLE-HEADERS, BOARD-TABLE-ROWS, BOARD-TABLE-PROVIDER, BOARD-TABLE-WIDGET, BOARD-TABLE-CONFIG, BOARD-VIEW-SWITCHER, BOARD-TABLE-INTEGRATION, BOARD-TABLE-VISUAL
**Plans**: 5 plans

Plans:
- [x] 09-01-PLAN.md -- Domain models, migration, and repository extensions
- [x] 09-02-PLAN.md -- Cell widgets (Status, Priority, Person, Timeline, DueDate, Text, Number, Checkbox, Link)
- [x] 09-03-PLAN.md -- Table structure widgets (group header/footer, table header/data rows, add item row)
- [ ] 09-04-PLAN.md -- Table provider, config sheets, BoardTableWidget, ViewSwitcher, board detail refactor
- [ ] 09-05-PLAN.md -- Integration tests and visual verification checkpoint

## Progress

**Execution Order:**
Phases 10, 11, 12, 13 are parallel (no dependencies between them). Phase 9 is independent.

| Phase | Milestone | Plans Complete | Status | Completed |
|-------|-----------|----------------|--------|-----------|
| 1. Foundation & Auth | v1.0 | 3/3 | Complete | 2026-03-17 |
| 2. Task Management | v1.0 | 3/3 | Complete | 2026-03-22 |
| 3. Smart Task Input | v1.0 | 3/3 | Complete | 2026-03-22 |
| 4. Habit Tracking | v1.0 | 3/3 | Complete | 2026-03-22 |
| 5. AI Daily Planner | v1.0 | 3/3 | Complete | 2026-03-22 |
| 6. Collaborative Boards | v1.0 | 3/3 | Complete | 2026-03-22 |
| 7. Notifications & Reminders | v1.0 | 3/3 | Complete | 2026-03-22 |
| 8. Integration & Deployment | v1.0 | 4/4 | Complete | 2026-03-22 |
| 10. RPC & Edge Function Security | 2/2 | Complete    | 2026-03-28 | - |
| 11. Notification Logic Fixes | 3/3 | Complete    | 2026-03-28 | - |
| 12. Auth, Planner & Lifecycle | 2/2 | Complete    | 2026-03-28 | - |
| 13. Onboarding, Recurring & Filter | v1.1 | 0/2 | Not started | - |
| 9. Boards UI Redesign | -- | 3/5 | In progress | - |
