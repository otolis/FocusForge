---
phase: 3
slug: smart-task-input
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-03-18
---

# Phase 3 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | flutter_test + mockito (already in project) |
| **Config file** | none — flutter_test is built-in |
| **Quick run command** | `flutter test test/unit/smart_input/` |
| **Full suite command** | `flutter test` |
| **Estimated runtime** | ~15 seconds |

---

## Sampling Rate

- **After every task commit:** Run `flutter test test/unit/smart_input/`
- **After every plan wave:** Run `flutter test`
- **Before `/gsd:verify-work`:** Full suite must be green
- **Max feedback latency:** 15 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|-----------|-------------------|-------------|--------|
| 03-01-01 | 01 | 1 | TASK-02 | unit | `flutter test test/unit/smart_input/nlp_parser_service_test.dart` | ❌ W0 | ⬜ pending |
| 03-01-02 | 01 | 1 | TASK-02 | unit | `flutter test test/unit/smart_input/nlp_parser_service_test.dart` | ❌ W0 | ⬜ pending |
| 03-01-03 | 01 | 1 | TASK-02 | unit | `flutter test test/unit/smart_input/nlp_parser_service_test.dart` | ❌ W0 | ⬜ pending |
| 03-02-01 | 02 | 1 | TASK-06 | unit | `flutter test test/unit/smart_input/tflite_classifier_service_test.dart` | ❌ W0 | ⬜ pending |
| 03-02-02 | 02 | 1 | TASK-06 | unit | `flutter test test/unit/smart_input/tflite_classifier_service_test.dart` | ❌ W0 | ⬜ pending |
| 03-03-01 | 03 | 2 | TASK-02/06 | widget | `flutter test test/widget/smart_input/suggestion_chips_test.dart` | ❌ W0 | ⬜ pending |
| 03-03-02 | 03 | 2 | TASK-02/06 | widget | `flutter test test/widget/smart_input/smart_input_field_test.dart` | ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `test/unit/smart_input/nlp_parser_service_test.dart` — stubs for TASK-02 (NLP parsing: deadline, priority, category extraction)
- [ ] `test/unit/smart_input/tflite_classifier_service_test.dart` — stubs for TASK-06 (TFLite classification with mock interpreter)
- [ ] `test/widget/smart_input/suggestion_chips_test.dart` — stubs for suggestion chip display
- [ ] `test/widget/smart_input/smart_input_field_test.dart` — stubs for input field with parsing feedback
- [ ] Mock/stub for `Interpreter` class from tflite_flutter — for unit testing without actual model

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| TFLite model loads from bundled assets on real device | TASK-06 | Requires real Android device with GPU delegate | Install debug build, type a task, verify category suggestion appears within 1s |
| chrono_dart parses locale-specific date formats | TASK-02 | Locale-dependent behavior hard to test in CI | On device, type "αύριο" or locale-specific date words, verify parsing |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 15s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
