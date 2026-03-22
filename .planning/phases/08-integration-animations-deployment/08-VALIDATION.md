---
phase: 08
slug: integration-animations-deployment
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-03-22
---

# Phase 08 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | flutter_test (Dart) |
| **Config file** | pubspec.yaml (dev_dependencies: flutter_test, mockito) |
| **Quick run command** | `flutter test test/unit/` |
| **Full suite command** | `flutter test` |
| **Estimated runtime** | ~15 seconds |

---

## Sampling Rate

- **After every task commit:** Run `flutter test test/unit/`
- **After every plan wave:** Run `flutter test`
- **Before `/gsd:verify-work`:** Full suite must be green
- **Max feedback latency:** 15 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|-----------|-------------------|-------------|--------|
| 08-01-01 | 01 | 1 | UX-02 | integration | `grep -r "SmartInputField" lib/features/tasks/` | ❌ W0 | ⬜ pending |
| 08-01-02 | 01 | 1 | UX-02 | integration | `grep -r "PlannableItem" lib/features/planner/` | ❌ W0 | ⬜ pending |
| 08-02-01 | 02 | 2 | UX-04 | unit | `flutter test test/unit/animations/` | ❌ W0 | ⬜ pending |
| 08-03-01 | 03 | 3 | UX-04 | manual | `flutter build web --release` | ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] Test infrastructure already exists from Phase 1
- [ ] Lottie animation JSON files must be added to assets/

*Existing infrastructure covers most phase requirements.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Lottie animations play smoothly | UX-04 | Visual quality check | Trigger task completion, habit check-in, streak milestone; verify animations render without jank |
| Flutter web loads in browser | UX-04 | Deployment verification | Run `flutter build web`, serve, verify app loads at public URL |
| Cross-feature navigation | UX-02 | Integration flow | Navigate home → tasks → habits → planner → boards, verify all routes work |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 15s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
