---
phase: 6
slug: collaborative-boards
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-03-18
---

# Phase 6 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | flutter_test + mockito 5.4.4 |
| **Config file** | none — Flutter SDK not installed on machine, tests verified via content |
| **Quick run command** | `flutter test test/unit/boards/` |
| **Full suite command** | `flutter test` |
| **Estimated runtime** | ~15 seconds |

---

## Sampling Rate

- **After every task commit:** Run `flutter test test/unit/boards/`
- **After every plan wave:** Run `flutter test`
- **Before `/gsd:verify-work`:** Full suite must be green
- **Max feedback latency:** 15 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|-----------|-------------------|-------------|--------|
| 06-01-01 | 01 | 1 | BOARD-01 | unit | `flutter test test/unit/boards/board_model_test.dart` | ❌ W0 | ⬜ pending |
| 06-01-02 | 01 | 1 | BOARD-01 | unit | `flutter test test/unit/boards/board_repository_test.dart` | ❌ W0 | ⬜ pending |
| 06-01-03 | 01 | 1 | BOARD-01 | unit | `flutter test test/unit/boards/board_card_item_test.dart` | ❌ W0 | ⬜ pending |
| 06-02-01 | 02 | 1 | BOARD-02 | unit | `flutter test test/unit/boards/board_realtime_service_test.dart` | ❌ W0 | ⬜ pending |
| 06-02-02 | 02 | 1 | BOARD-02 | unit | `flutter test test/unit/boards/board_detail_provider_test.dart` | ❌ W0 | ⬜ pending |
| 06-03-01 | 03 | 2 | BOARD-03 | unit | `flutter test test/unit/boards/board_member_test.dart` | ❌ W0 | ⬜ pending |
| 06-03-02 | 03 | 2 | BOARD-03 | unit | `flutter test test/unit/boards/board_member_repository_test.dart` | ❌ W0 | ⬜ pending |
| 06-04-01 | 03 | 2 | BOARD-04 | unit | `flutter test test/unit/boards/board_presence_test.dart` | ❌ W0 | ⬜ pending |
| 06-RLS | - | - | BOARD-01 | manual-only | Requires live Supabase instance | N/A | ⬜ pending |
| 06-RT | - | - | BOARD-02 | manual-only | Requires two connected clients | N/A | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `test/unit/boards/board_model_test.dart` — covers BOARD-01 model layer
- [ ] `test/unit/boards/board_repository_test.dart` — covers BOARD-01 CRUD
- [ ] `test/unit/boards/board_card_item_test.dart` — covers BOARD-01 appflowy integration
- [ ] `test/unit/boards/board_realtime_service_test.dart` — covers BOARD-02
- [ ] `test/unit/boards/board_detail_provider_test.dart` — covers BOARD-02 state
- [ ] `test/unit/boards/board_member_test.dart` — covers BOARD-03
- [ ] `test/unit/boards/board_member_repository_test.dart` — covers BOARD-03
- [ ] `test/unit/boards/board_presence_test.dart` — covers BOARD-04

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| RLS policies enforce membership access | BOARD-01, BOARD-03 | Requires live Supabase instance with real auth | Sign in as non-member, verify boards/cards are not visible; sign in as viewer, verify write operations fail |
| Cross-device realtime sync | BOARD-02 | Requires two connected clients on same board | Open board on two devices, move a card on one, verify it appears on the other within 2 seconds |
| Live presence indicators | BOARD-04 | Requires two connected clients | Open board on two devices, verify green dot appears on the other user's avatar; close one, verify dot disappears |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 15s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
