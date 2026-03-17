---
phase: 4
slug: habit-tracking
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-03-18
---

# Phase 4 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | flutter_test + mockito 5.4.4 |
| **Config file** | None (Flutter default) |
| **Quick run command** | `flutter test test/unit/habits/` |
| **Full suite command** | `flutter test` |
| **Estimated runtime** | ~15 seconds |

---

## Sampling Rate

- **After every task commit:** Run `flutter test test/unit/habits/`
- **After every plan wave:** Run `flutter test`
- **Before `/gsd:verify-work`:** Full suite must be green
- **Max feedback latency:** 15 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|-----------|-------------------|-------------|--------|
| 04-01-01 | 01 | 1 | HABIT-01 | unit | `flutter test test/unit/habits/habit_model_test.dart` | No — W0 | pending |
| 04-01-02 | 01 | 1 | HABIT-01 | unit | `flutter test test/unit/habits/habit_repository_test.dart` | No — W0 | pending |
| 04-02-01 | 02 | 1 | HABIT-02 | unit | `flutter test test/unit/habits/streak_calculator_test.dart` | No — W0 | pending |
| 04-02-02 | 02 | 1 | HABIT-02 | widget | `flutter test test/widget/habits/habit_heat_map_test.dart` | No — W0 | pending |
| 04-02-03 | 02 | 2 | HABIT-03 | unit | `flutter test test/unit/habits/habit_analytics_test.dart` | No — W0 | pending |
| 04-02-04 | 02 | 2 | HABIT-03 | widget | `flutter test test/widget/habits/habit_bar_chart_test.dart` | No — W0 | pending |
| 04-02-05 | 02 | 2 | HABIT-04 | widget | `flutter test test/widget/habits/check_in_button_test.dart` | No — W0 | pending |
| 04-02-06 | 02 | 2 | HABIT-04 | unit | `flutter test test/unit/habits/habit_check_in_test.dart` | No — W0 | pending |

*Status: pending / green / red / flaky*

---

## Wave 0 Requirements

- [ ] `test/unit/habits/habit_model_test.dart` — covers HABIT-01 (model serialization, frequency enum, isBinary/isCompletedToday)
- [ ] `test/unit/habits/habit_repository_test.dart` — covers HABIT-01 (mock Supabase CRUD)
- [ ] `test/unit/habits/streak_calculator_test.dart` — covers HABIT-02 (daily, weekly, custom streaks, edge cases)
- [ ] `test/unit/habits/habit_analytics_test.dart` — covers HABIT-03 (completion rate aggregation)
- [ ] `test/widget/habits/check_in_button_test.dart` — covers HABIT-04 (tap handler, animation trigger)
- [ ] Test helper extensions for habit fixtures in `test/helpers/test_helpers.dart`

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Haptic feedback feels correct | HABIT-04 | Physical device required for haptic verification | Tap check-in on Android device, verify light haptic fires. Complete 7-day streak, verify medium haptic fires. |
| Heat map amber gradient matches theme | HABIT-02 | Visual comparison needed | Open habit detail screen, compare heat map amber to app bar/button amber. Should look cohesive. |
| Scale bounce animation feels satisfying | HABIT-04 | Subjective perception | Tap check-in rapidly, verify bounce is snappy (200ms), not janky. |

---

## Validation Sign-Off

- [ ] All tasks have automated verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 15s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
