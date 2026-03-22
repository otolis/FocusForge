---
phase: 06-collaborative-boards
plan: 03
subsystem: ui
tags: [flutter, riverpod, presence, avatar, member-management, go-router]

# Dependency graph
requires:
  - phase: 06-collaborative-boards
    provides: "Board data models, repositories, providers, presence provider (Plan 01)"
provides:
  - "PresenceAvatar widget with green online dot and dimmed offline state"
  - "MemberAvatarRow widget with overlapping avatars and +N overflow chip"
  - "BoardSettingsScreen with invite flow, role management, member removal, board deletion"
  - "Router route /boards/:id/settings"
affects: [08-integration]

# Tech tracking
tech-stack:
  added: []
  patterns: [role-based-ui-visibility, presence-indicator-overlay, overlapping-avatar-row]

key-files:
  created:
    - lib/features/boards/presentation/widgets/presence_avatar.dart
    - lib/features/boards/presentation/widgets/member_avatar_row.dart
    - lib/features/boards/presentation/screens/board_settings_screen.dart
  modified:
    - lib/core/router/app_router.dart

key-decisions:
  - "Used TextField directly for invite email (AppTextField uses label param not hintText, and inline TextField better fits the compact invite row layout)"
  - "Board settings route placed before /boards/:id in router to ensure path specificity"
  - "Invite role dropdown limited to editor/viewer only (owner role assignment via role change dropdown after invite)"

patterns-established:
  - "Role-based UI: use state.isOwner to conditionally show management controls"
  - "Presence overlay: Stack with Positioned green dot on AvatarWidget"
  - "Overlapping avatars: Transform.translate with negative x offset proportional to index"

requirements-completed: [BOARD-03, BOARD-04]

# Metrics
duration: 2min
completed: 2026-03-22
---

# Phase 06 Plan 03: Member Management UI & Presence Indicators Summary

**Board settings screen with invite-by-email, role management dropdowns, and PresenceAvatar/MemberAvatarRow widgets with green online dots and +N overflow**

## Performance

- **Duration:** 2 min
- **Started:** 2026-03-22T11:51:29Z
- **Completed:** 2026-03-22T11:53:46Z
- **Tasks:** 2
- **Files modified:** 4

## Accomplishments
- PresenceAvatar widget wraps AvatarWidget with green dot for online users and 50% opacity dimming for offline users
- MemberAvatarRow displays up to 4 overlapping member avatars with +N overflow chip, consuming boardPresenceProvider for live status
- BoardSettingsScreen provides full member management: invite by email with role selection, role change via dropdown, member removal with confirmation, board rename and delete
- Role-based visibility enforced: owners see all controls, editors/viewers see read-only member list

## Task Commits

Each task was committed atomically:

1. **Task 1: Presence avatar and member avatar row widgets** - `7bb8cf9` (feat)
2. **Task 2: Board settings screen with member management and router wiring** - `4cdf8a4` (feat)

## Files Created/Modified
- `lib/features/boards/presentation/widgets/presence_avatar.dart` - Avatar with green online dot and dimmed offline state
- `lib/features/boards/presentation/widgets/member_avatar_row.dart` - Horizontal overlapping avatar row with +N overflow chip
- `lib/features/boards/presentation/screens/board_settings_screen.dart` - Board settings with invite flow, role management, danger zone
- `lib/core/router/app_router.dart` - Added /boards/:id/settings route and BoardSettingsScreen import

## Decisions Made
- Used TextField directly for invite email input instead of AppTextField (AppTextField uses `label` param not `hintText`, and inline TextField better fits the compact invite row layout)
- Board settings route placed before /boards/:id in router to ensure go_router matches the more specific path first
- Invite role dropdown limited to editor/viewer only; owner role can be assigned afterward via the role change dropdown on existing members

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered
None

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness
- Board collaboration UI is fully wired: board list, board detail (Kanban), and board settings with member management
- Presence indicators ready for realtime integration (boardPresenceProvider already wired to Supabase Realtime in board_realtime_provider)
- Integration phase (08) can wire cross-feature interactions

## Self-Check: PASSED

All 4 files verified present. Both task commits (7bb8cf9, 4cdf8a4) verified in git log.

---
*Phase: 06-collaborative-boards*
*Completed: 2026-03-22*
