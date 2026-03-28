# Requirements: FocusForge

**Defined:** 2026-03-28
**Core Value:** Users can capture tasks naturally, get an AI-optimized daily schedule, track habits with visual streaks, and collaborate in real-time -- a productivity system that feels intelligent, not just a CRUD app.

## v1.1 Requirements

Requirements for the Security & Hardening milestone. Each maps to roadmap phases.

### Security (RPC Hardening)

- [x] **SEC-01**: SECURITY DEFINER RPCs derive caller identity from `auth.uid()` instead of trusting client-supplied user ID parameters
- [x] **SEC-02**: Task RPCs (`search_tasks`, `generate_recurring_instances`) validate ownership via `auth.uid()`
- [x] **SEC-03**: Board RPCs (`create_board_with_defaults`, `invite_board_member`) validate ownership/auth via `auth.uid()`
- [x] **SEC-04**: Function permissions hardened with REVOKE/GRANT EXECUTE to restrict direct client invocation

### Notifications

- [ ] **NOTIF-01**: Deep links from terminated app route correctly on cold start (defer navigation until navigator context exists)
- [ ] **NOTIF-02**: Notification task-complete action sets both `is_completed` and `completed_at` consistent with domain logic
- [ ] **NOTIF-03**: Notification habit-complete action uses same-day upsert/increment logic from `habit_repository`
- [ ] **NOTIF-04**: Snooze action handlers respect user's configured `snoozeDuration` preference instead of hardcoding 15 minutes
- [ ] **NOTIF-05**: `recordCompletion` in notification_repository is called by production code so adaptive timing learns from real data

### Auth

- [ ] **AUTH-01**: Google sign-in buttons hidden in login/register screens while `YOUR_WEB_CLIENT_ID` placeholder is committed

### Planner

- [ ] **PLAN-01**: Planner import is idempotent (tracks source linkage to prevent duplicate imports)
- [ ] **PLAN-02**: `_importRealItems()` awaits each `addItem()` call to prevent race conditions

### Lifecycle & Data

- [ ] **LIFE-01**: FCM `onTokenRefresh` subscription stored and cancelled on sign-out to prevent accumulation across auth cycles
- [ ] **LIFE-02**: Board member profile RLS policy allows board co-members to read each other's profiles (or use a service-role approach)

## v2 Requirements

Deferred to future release. Tracked but not in current roadmap.

### Features

- **FUT-01**: Polished GitHub README with screenshots and demo video
- **FUT-02**: iOS builds via Codemagic CI
- **FUT-03**: Offline-first with SQLite sync queue
- **FUT-04**: Voice-to-text task input via `speech_to_text`

## Out of Scope

Explicitly excluded. Documented to prevent scope creep.

| Feature | Reason |
|---------|--------|
| Full RLS redesign | Scope limited to hardening existing SECURITY DEFINER RPCs, not rewriting all policies |
| New notification types | Only fixing existing action handlers and cold-start routing |
| Google sign-in implementation | Only hiding the button; wiring real client ID is a separate task when credentials are available |
| Offline sync | Deferred to future milestone -- not a hardening concern |

## Traceability

Which phases cover which requirements. Updated during roadmap creation.

| Requirement | Phase | Status |
|-------------|-------|--------|
| SEC-01 | Phase 10 | Complete |
| SEC-02 | Phase 10 | Complete |
| SEC-03 | Phase 10 | Complete |
| SEC-04 | Phase 10 | Complete |
| NOTIF-01 | Phase 11 | Pending |
| NOTIF-02 | Phase 11 | Pending |
| NOTIF-03 | Phase 11 | Pending |
| NOTIF-04 | Phase 11 | Pending |
| NOTIF-05 | Phase 11 | Pending |
| AUTH-01 | Phase 12 | Pending |
| PLAN-01 | Phase 12 | Pending |
| PLAN-02 | Phase 12 | Pending |
| LIFE-01 | Phase 12 | Pending |
| LIFE-02 | Phase 12 | Pending |

**Coverage:**
- v1.1 requirements: 14 total
- Mapped to phases: 14
- Unmapped: 0

---
*Requirements defined: 2026-03-28*
*Last updated: 2026-03-28 after roadmap creation*
