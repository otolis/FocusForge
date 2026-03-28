# Roadmap: FocusForge

## Milestones

- ✅ **v1.0 MVP** -- Phases 1-8 (shipped 2026-03-22)
- 🚧 **v1.1 Security & Hardening** -- Phases 10-12 (in progress)
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

**Parallel execution:** Phases 10, 11, and 12 touch independent subsystems (SQL migrations, notification Dart service, auth/planner/boards Dart code) and CAN run in parallel across separate terminals.

- [ ] **Phase 10: RPC Security Hardening** - Lock down SECURITY DEFINER functions to derive identity from auth.uid()
- [ ] **Phase 11: Notification Logic Fixes** - Fix cold-start routing, action handlers, snooze, and adaptive timing
- [ ] **Phase 12: Auth, Planner & Lifecycle Cleanup** - Hide placeholder Google sign-in, make planner import idempotent, fix FCM lifecycle and board RLS

### Phase 9 (Independent)

- [ ] **Phase 9: Boards UI Redesign** - Monday.com-style layout (independent of v1.1, planned separately)

## Phase Details

### Phase 10: RPC Security Hardening
**Goal**: All SECURITY DEFINER database functions derive caller identity from auth.uid() and cannot be exploited by passing arbitrary user IDs from the client
**Depends on**: Nothing (SQL-only, independent of other phases)
**Requirements**: SEC-01, SEC-02, SEC-03, SEC-04
**Success Criteria** (what must be TRUE):
  1. Calling `search_tasks` or `generate_recurring_instances` with a forged user ID returns only the caller's own data (auth.uid() enforced server-side)
  2. Calling `create_board_with_defaults` or `invite_board_member` with a forged owner/inviter ID is rejected or overridden by auth.uid()
  3. Direct client invocation of privileged RPCs is blocked via REVOKE/GRANT EXECUTE restrictions
  4. Existing app functionality (task search, recurring tasks, board creation, invites) continues working with auth.uid()-derived identity
**Plans**: TBD

Plans:
- [ ] 10-01: TBD
- [ ] 10-02: TBD

### Phase 11: Notification Logic Fixes
**Goal**: Notification actions execute correct domain logic, deep links work on cold start, and user preferences are respected
**Depends on**: Nothing (notification Dart service, independent of other phases)
**Requirements**: NOTIF-01, NOTIF-02, NOTIF-03, NOTIF-04, NOTIF-05
**Success Criteria** (what must be TRUE):
  1. Tapping a notification when the app is terminated (cold start) navigates to the correct screen after the app finishes initializing
  2. Completing a task via notification action sets both `is_completed` and `completed_at` fields, matching what happens when completing from the task list UI
  3. Completing a habit via notification action uses same-day upsert/increment logic, producing identical results to tapping the check-in button on the habit screen
  4. Snoozing a notification reschedules it by the user's configured snooze duration (from settings), not a hardcoded 15 minutes
  5. Adaptive notification timing receives real completion data via `recordCompletion` so it learns from actual user behavior
**Plans**: TBD

Plans:
- [ ] 11-01: TBD
- [ ] 11-02: TBD

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
**Plans**: TBD

Plans:
- [ ] 12-01: TBD
- [ ] 12-02: TBD

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
Phases 10, 11, 12 are parallel (no dependencies between them). Phase 9 is independent.

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
| 10. RPC Security Hardening | v1.1 | 0/? | Not started | - |
| 11. Notification Logic Fixes | v1.1 | 0/? | Not started | - |
| 12. Auth, Planner & Lifecycle | v1.1 | 0/? | Not started | - |
| 9. Boards UI Redesign | -- | 3/5 | In progress | - |
