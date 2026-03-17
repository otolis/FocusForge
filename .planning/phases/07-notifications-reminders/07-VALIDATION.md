---
phase: 7
slug: notifications-reminders
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-03-18
---

# Phase 7 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | flutter_test (unit/widget), integration_test |
| **Config file** | `pubspec.yaml` (dev_dependencies) |
| **Quick run command** | `flutter test test/unit/features/notifications/` |
| **Full suite command** | `flutter test` |
| **Estimated runtime** | ~30 seconds |

---

## Sampling Rate

- **After every task commit:** Run `flutter test test/unit/features/notifications/`
- **After every plan wave:** Run `flutter test`
- **Before `/gsd:verify-work`:** Full suite must be green
- **Max feedback latency:** 30 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|-----------|-------------------|-------------|--------|
| 07-01-01 | 01 | 1 | UX-03 | unit | `flutter test test/unit/features/notifications/` | ❌ W0 | ⬜ pending |
| 07-01-02 | 01 | 1 | UX-03 | unit | `flutter test test/unit/features/notifications/` | ❌ W0 | ⬜ pending |
| 07-02-01 | 02 | 1 | PLAN-04 | unit | `flutter test test/unit/features/notifications/` | ❌ W0 | ⬜ pending |
| 07-02-02 | 02 | 1 | PLAN-04 | unit | `flutter test test/unit/features/notifications/` | ❌ W0 | ⬜ pending |
| 07-02-03 | 02 | 2 | UX-03 | widget | `flutter test test/widget/features/notifications/` | ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `test/unit/features/notifications/` — directory and stub test files for notification service, adaptive algorithm, preferences
- [ ] `test/widget/features/notifications/` — directory and stub widget tests for notification settings screen
- [ ] `firebase_messaging`, `flutter_local_notifications` — packages added to pubspec.yaml

*Test stubs created alongside feature code in each plan task.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| FCM push delivery | UX-03 | Requires physical device + Firebase project | 1. Deploy Edge Function 2. Create task with deadline 3. Wait for cron trigger 4. Verify notification appears |
| Notification action buttons | UX-03 | Requires device interaction | 1. Receive notification 2. Tap "Complete" 3. Verify task marked done in app |
| Adaptive timing shift | PLAN-04 | Requires 2-week usage data | 1. Seed completion data 2. Trigger reminder check 3. Verify timing offset changed |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 30s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
