---
phase: 2
slug: task-management
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-03-18
---

# Phase 2 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | flutter_test + mockito 5.4.4 |
| **Config file** | None (Flutter default) |
| **Quick run command** | `flutter test test/unit/tasks/` |
| **Full suite command** | `flutter test` |
| **Estimated runtime** | ~15 seconds |

---

## Sampling Rate

- **After every task commit:** Run `flutter test test/unit/tasks/`
- **After every plan wave:** Run `flutter test`
- **Before `/gsd:verify-work`:** Full suite must be green
- **Max feedback latency:** 15 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|-----------|-------------------|-------------|--------|
| 02-01-01 | 01 | 1 | TASK-01 | unit | `flutter test test/unit/tasks/task_model_test.dart` | ❌ W0 | ⬜ pending |
| 02-01-02 | 01 | 1 | TASK-01 | unit | `flutter test test/unit/tasks/task_repository_test.dart` | ❌ W0 | ⬜ pending |
| 02-01-03 | 01 | 1 | TASK-04 | unit | `flutter test test/unit/tasks/category_model_test.dart` | ❌ W0 | ⬜ pending |
| 02-01-04 | 01 | 1 | TASK-05 | unit | `flutter test test/unit/tasks/recurrence_model_test.dart` | ❌ W0 | ⬜ pending |
| 02-01-05 | 01 | 1 | TASK-05 | unit | `flutter test test/unit/tasks/recurrence_generator_test.dart` | ❌ W0 | ⬜ pending |
| 02-02-01 | 02 | 2 | TASK-03 | unit | `flutter test test/unit/tasks/task_filter_test.dart` | ❌ W0 | ⬜ pending |
| 02-02-02 | 02 | 2 | TASK-03 | unit | `flutter test test/unit/tasks/task_search_test.dart` | ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `test/unit/tasks/task_model_test.dart` — stubs for TASK-01 model serialization
- [ ] `test/unit/tasks/task_repository_test.dart` — stubs for TASK-01 repository (mocked Supabase)
- [ ] `test/unit/tasks/task_filter_test.dart` — stubs for TASK-03 filter logic
- [ ] `test/unit/tasks/task_search_test.dart` — stubs for TASK-03 search
- [ ] `test/unit/tasks/category_model_test.dart` — stubs for TASK-04 model
- [ ] `test/unit/tasks/recurrence_model_test.dart` — stubs for TASK-05 model
- [ ] `test/unit/tasks/recurrence_generator_test.dart` — stubs for TASK-05 instance generation

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Swipe actions feel natural | TASK-01 | Gesture UX requires human evaluation | Swipe task card right (should reveal green Complete action) and left (should reveal red Delete action) |
| Bottom sheet keyboard avoidance | TASK-01 | Visual layout requires human check | Open quick-create sheet, tap title field, verify keyboard doesn't cover input |
| Date section grouping display | TASK-03 | Visual layout verification | Create tasks with different deadlines, verify "Today"/"Tomorrow"/"This Week"/"Later" sections appear correctly |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 15s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
