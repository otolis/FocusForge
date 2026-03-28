---
phase: 10-rpc-security-hardening
plan: 01
subsystem: database
tags: [postgresql, security-definer, auth-uid, revoke-grant, jwt, edge-functions, rpc, supabase]

# Dependency graph
requires:
  - phase: 04-create-tasks
    provides: search_tasks and generate_recurring_instances RPC definitions
  - phase: 03-create-boards
    provides: create_board_with_defaults and invite_board_member RPC definitions
  - phase: 08-fix-board-rls-recursion
    provides: is_board_member, is_board_owner, is_board_editor helper functions
  - phase: 09-redesign-boards-ui-monday-layout
    provides: create_board_with_defaults updated with metadata JSONB
provides:
  - Hardened search_tasks RPC (1-param, auth.uid()-based)
  - Hardened generate_recurring_instances RPC with ownership assertion
  - Hardened create_board_with_defaults RPC (1-param, auth.uid()-based)
  - Hardened invite_board_member RPC with board ownership assertion
  - REVOKE/GRANT permissions restricting RPCs to authenticated role only
  - JWT verification enabled on both Edge Functions
affects: [10-02-client-auth-fixes, client-rpc-callers, edge-function-invocations]

# Tech tracking
tech-stack:
  added: []
  patterns: [auth.uid()-based identity derivation, ownership assertion before privileged operations, REVOKE/GRANT function access control]

key-files:
  created:
    - supabase/migrations/00010_harden_rpc_functions.sql
  modified:
    - supabase/config.toml

key-decisions:
  - "All 4 RPC rewrites in a single additive migration (00010) rather than separate files"
  - "Helper functions (is_board_member/owner/editor) revoked from anon but kept for authenticated to preserve RLS"
  - "Edge Function comments updated to reflect JWT-required security posture"

patterns-established:
  - "auth.uid() identity derivation: all SECURITY DEFINER RPCs derive caller identity server-side"
  - "Ownership assertion pattern: check v_task.user_id != auth.uid() or board_members ownership before privileged operations"
  - "REVOKE/GRANT pattern: REVOKE FROM public, anon then GRANT TO authenticated for all user-facing RPCs"

requirements-completed: [SEC-01, SEC-02, SEC-03, SEC-04, SEC-05]

# Metrics
duration: 2min
completed: 2026-03-28
---

# Phase 10 Plan 01: RPC Security Hardening Summary

**Hardened 4 SECURITY DEFINER RPCs with auth.uid() identity derivation, ownership assertions, REVOKE/GRANT permissions, and JWT enforcement on Edge Functions**

## Performance

- **Duration:** 2 min
- **Started:** 2026-03-28T13:14:59Z
- **Completed:** 2026-03-28T13:16:58Z
- **Tasks:** 2
- **Files modified:** 2

## Accomplishments
- Rewrote search_tasks and create_board_with_defaults to derive caller identity from auth.uid() (removed client-supplied user ID parameters, dropped old signatures to prevent ghost functions)
- Added ownership assertions to generate_recurring_instances (task ownership) and invite_board_member (board ownership) to prevent cross-user privilege escalation
- Applied REVOKE/GRANT EXECUTE to restrict all 4 RPCs to authenticated role only, while preserving helper function access for RLS policies
- Enabled verify_jwt = true on both Edge Functions (generate-schedule, rewrite-title) to reject unauthenticated anon-key-only calls at the gateway

## Task Commits

Each task was committed atomically:

1. **Task 1: Create RPC security hardening migration** - `6205d5c` (feat)
2. **Task 2: Enable JWT verification on Edge Functions** - `1885610` (feat)

## Files Created/Modified
- `supabase/migrations/00010_harden_rpc_functions.sql` - New migration with all 4 RPC rewrites + REVOKE/GRANT permissions
- `supabase/config.toml` - Changed verify_jwt from false to true for both Edge Functions

## Decisions Made
- All 4 RPC rewrites placed in a single additive migration (00010) rather than separate migration files -- keeps the security hardening atomic and reviewable
- Helper functions (is_board_member, is_board_owner, is_board_editor) revoked from anon/public but explicitly kept callable by authenticated to preserve RLS policy functionality (Pitfall 3 from research)
- Edge Function comments updated to reflect the new security posture, removing references to "anon key" and "disable"

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None.

## User Setup Required

None - no external service configuration required. The migration will be applied automatically on next `supabase db push` and config.toml changes take effect on next deploy.

## Next Phase Readiness
- Plan 10-02 (client-side auth fixes) can proceed immediately -- it updates Dart code to match the new RPC signatures and remove manual Authorization header overrides
- search_tasks signature changed from (uuid, text) to (text) -- client code MUST be updated before calling
- create_board_with_defaults signature changed from (text, uuid) to (text) -- client code MUST be updated before calling

## Self-Check: PASSED

All files and commits verified:
- supabase/migrations/00010_harden_rpc_functions.sql: FOUND
- supabase/config.toml: FOUND
- Commit 6205d5c (Task 1): FOUND
- Commit 1885610 (Task 2): FOUND

---
*Phase: 10-rpc-security-hardening*
*Completed: 2026-03-28*
