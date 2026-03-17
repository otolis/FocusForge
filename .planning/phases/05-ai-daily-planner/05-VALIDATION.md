---
phase: 05
slug: ai-daily-planner
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-03-18
---

# Phase 05 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | flutter_test + mockito (already in project) |
| **Config file** | pubspec.yaml (dev_dependencies section) |
| **Quick run command** | `flutter test test/unit/planner/` |
| **Full suite command** | `flutter test` |
| **Estimated runtime** | ~5 seconds |

---

## Sampling Rate

- **After every task commit:** Run `flutter test test/unit/planner/`
- **After every plan wave:** Run `flutter test`
- **Before `/gsd:verify-work`:** Full suite must be green
- **Max feedback latency:** 5 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|-----------|-------------------|-------------|--------|
| 05-01-01 | 01 | 1 | PLAN-01 | unit | `flutter test test/unit/planner/plannable_item_model_test.dart` | No -- Wave 0 | pending |
| 05-01-02 | 01 | 1 | PLAN-01 | unit | `flutter test test/unit/planner/schedule_block_model_test.dart` | No -- Wave 0 | pending |
| 05-01-03 | 01 | 1 | PLAN-01 | unit | `flutter test test/unit/planner/planner_repository_test.dart` | No -- Wave 0 | pending |
| 05-02-01 | 02 | 2 | PLAN-02 | unit | `flutter test test/unit/planner/timeline_constants_test.dart` | No -- Wave 0 | pending |
| 05-02-02 | 02 | 2 | PLAN-02 | widget | `flutter test test/widget/planner/planner_screen_test.dart` | No -- Wave 0 | pending |
| 05-02-03 | 02 | 2 | PLAN-03 | unit | `flutter test test/unit/planner/timeline_constants_test.dart` | No -- Wave 0 | pending |
| 05-02-04 | 02 | 2 | PLAN-03 | unit | `flutter test test/unit/planner/schedule_overlap_test.dart` | No -- Wave 0 | pending |

*Status: pending / green / red / flaky*

---

## Wave 0 Requirements

- [ ] `test/unit/planner/plannable_item_model_test.dart` -- stubs for PLAN-01 model serialization
- [ ] `test/unit/planner/schedule_block_model_test.dart` -- stubs for PLAN-01 block serialization
- [ ] `test/unit/planner/planner_repository_test.dart` -- stubs for PLAN-01 Edge Function invocation (mocked)
- [ ] `test/unit/planner/timeline_constants_test.dart` -- stubs for PLAN-02/PLAN-03 pixel math and snap logic
- [ ] `test/unit/planner/schedule_overlap_test.dart` -- stubs for PLAN-03 push-down displacement
- [ ] `test/widget/planner/planner_screen_test.dart` -- stubs for PLAN-02 timeline rendering

*If none: "Existing infrastructure covers all phase requirements."*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Drag-to-reschedule gesture interaction | PLAN-03 | Gesture timing (LongPressDraggable 500ms hold) and visual feedback require device interaction | 1. Long-press a schedule block, 2. Drag vertically, 3. Verify 15-min snap lines appear, 4. Release and verify block snaps to grid |
| Shimmer skeleton loading animation | PLAN-02 | Visual animation quality is subjective | 1. Tap "Plan My Day", 2. Verify shimmer animation plays during load, 3. Verify it resolves to schedule blocks |
| Energy zone background colors | PLAN-02 | Color perception requires visual check | 1. Set peak hours in profile, 2. View timeline, 3. Verify amber bands on peak hours, sage bands on low hours |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 5s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
