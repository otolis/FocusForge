---
phase: 01
slug: foundation-auth
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-03-17
---

# Phase 01 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | flutter_test (built-in) + mockito 5.x |
| **Config file** | `pubspec.yaml` (dev_dependencies section) |
| **Quick run command** | `flutter test test/unit/` |
| **Full suite command** | `flutter test` |
| **Estimated runtime** | ~30 seconds |

---

## Sampling Rate

- **After every task commit:** Run `flutter test test/unit/`
- **After every plan wave:** Run `flutter test`
- **Before `/gsd:verify-work`:** Full suite must be green
- **Max feedback latency:** 30 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|-----------|-------------------|-------------|--------|
| 01-01-01 | 01 | 1 | AUTH-01 | unit | `flutter test test/unit/auth/` | ❌ W0 | ⬜ pending |
| 01-01-02 | 01 | 1 | AUTH-02 | unit | `flutter test test/unit/auth/` | ❌ W0 | ⬜ pending |
| 01-02-01 | 02 | 1 | AUTH-03 | unit | `flutter test test/unit/profile/` | ❌ W0 | ⬜ pending |
| 01-02-02 | 02 | 1 | AUTH-04 | manual | N/A (theme toggle visual) | ❌ W0 | ⬜ pending |
| 01-03-01 | 03 | 1 | AUTH-05 | unit | `flutter test test/unit/auth/` | ❌ W0 | ⬜ pending |
| 01-03-02 | 03 | 1 | UX-01 | manual | N/A (onboarding flow visual) | ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `test/unit/auth/auth_repository_test.dart` — stubs for AUTH-01, AUTH-02, AUTH-05
- [ ] `test/unit/profile/profile_repository_test.dart` — stubs for AUTH-03
- [ ] `test/helpers/test_helpers.dart` — shared mocks and fixtures
- [ ] `mockito` + `build_runner` in dev_dependencies — if not already present

*Test infrastructure must be set up before execution begins.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Theme toggle visual | AUTH-04 | Material 3 color rendering requires visual inspection | Toggle light/dark/system in settings, verify colors match seed palette |
| Onboarding flow UX | UX-01 | Page transitions and skip behavior require visual check | Launch as new user, swipe through 3-4 pages, tap skip, verify home screen |
| Google OAuth redirect | AUTH-02 | Requires real Google OAuth credentials and device | Tap Google sign-in, complete OAuth flow, verify home screen landing |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 30s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
