---
phase: 12-auth-planner-lifecycle-cleanup
plan: 01
subsystem: auth, notifications, database
tags: [google-sign-in, fcm, rls, security-definer, subscription-lifecycle]

# Dependency graph
requires:
  - phase: 01-foundation
    provides: AuthRepository, profiles table, RLS policies
  - phase: 08-notifications
    provides: NotificationService, FCM token management
  - phase: 08-collaboration
    provides: board_members table, SECURITY DEFINER pattern
provides:
  - isGoogleSignInConfigured static getter on AuthRepository
  - Conditional Google sign-in button rendering on login/register screens
  - FCM _tokenRefreshSubscription lifecycle management (cancel on re-subscribe and sign-out)
  - shares_board_with() SECURITY DEFINER helper function
  - Board co-member profile visibility RLS policy
affects: [auth, notifications, boards, profiles]

# Tech tracking
tech-stack:
  added: []
  patterns: [spread-if conditional widget rendering, subscription lifecycle management, SECURITY DEFINER self-join for co-membership]

key-files:
  created:
    - supabase/migrations/00012_board_comember_profile_visibility.sql
  modified:
    - lib/features/auth/data/auth_repository.dart
    - lib/features/auth/presentation/screens/login_screen.dart
    - lib/features/auth/presentation/screens/register_screen.dart
    - lib/core/services/notification_service.dart

key-decisions:
  - "Spread-if pattern for conditional widget lists in Column children"
  - "Cancel previous subscription before creating new one in manageFcmToken to prevent accumulation"
  - "Self-join on board_members for co-membership check rather than separate lookup table"

patterns-established:
  - "AuthRepository.isGoogleSignInConfigured: static getter pattern for feature flag on placeholder config values"
  - "_tokenRefreshSubscription lifecycle: cancel-before-resubscribe in manageFcmToken, cancel-and-null in clearToken"
  - "shares_board_with(): SECURITY DEFINER helper for cross-user relationship checks"

requirements-completed: [AUTH-01, LIFE-01, LIFE-02]

# Metrics
duration: 2min
completed: 2026-03-28
---

# Phase 12 Plan 01: Auth & Lifecycle Cleanup Summary

**Conditional Google sign-in buttons with placeholder detection, FCM subscription leak prevention, and board co-member profile visibility via SECURITY DEFINER RLS**

## Performance

- **Duration:** 2 min
- **Started:** 2026-03-28T14:33:35Z
- **Completed:** 2026-03-28T14:35:57Z
- **Tasks:** 3
- **Files modified:** 5

## Accomplishments
- Google sign-in buttons and "or" dividers hidden on login/register screens when webClientId is a placeholder value
- FCM onTokenRefresh subscription stored, cancelled before re-subscribing, and cancelled on sign-out to prevent stale listener accumulation
- New SECURITY DEFINER function and RLS policy enabling board co-members to read each other's profile display names and avatars

## Task Commits

Each task was committed atomically:

1. **Task 1: Hide Google sign-in buttons when client ID is placeholder** - `cfe71d9` (feat)
2. **Task 2: Fix FCM onTokenRefresh subscription lifecycle** - `7f4d70f` (fix)
3. **Task 3: Add RLS policy for board co-member profile visibility** - `6396287` (feat)

## Files Created/Modified
- `lib/features/auth/data/auth_repository.dart` - Added isGoogleSignInConfigured static getter
- `lib/features/auth/presentation/screens/login_screen.dart` - Conditional Google sign-in button visibility
- `lib/features/auth/presentation/screens/register_screen.dart` - Conditional Google sign-in button visibility
- `lib/core/services/notification_service.dart` - FCM subscription lifecycle management with _tokenRefreshSubscription field
- `supabase/migrations/00012_board_comember_profile_visibility.sql` - SECURITY DEFINER helper + RLS policy for co-member profile visibility

## Decisions Made
- Spread-if pattern (`if (condition) ...[widgets]`) for conditional widget rendering in Column children lists
- Cancel previous subscription before creating new one in manageFcmToken to prevent accumulation across sign-in cycles
- Self-join on board_members table for co-membership check rather than a separate lookup table or view

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered
None

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- Auth screens now gracefully handle placeholder Google client IDs
- FCM subscription lifecycle is clean across auth cycles
- Board co-member profile visibility ready for UI consumption (display names and avatars in board views)
- Phase 12 Plan 02 can proceed independently

## Self-Check: PASSED

All 5 modified/created files verified on disk. All 3 task commits (cfe71d9, 7f4d70f, 6396287) verified in git log.

---
*Phase: 12-auth-planner-lifecycle-cleanup*
*Completed: 2026-03-28*
