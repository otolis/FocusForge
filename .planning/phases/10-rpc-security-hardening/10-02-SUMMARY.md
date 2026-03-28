---
phase: 10-rpc-security-hardening
plan: 02
subsystem: api
tags: [supabase, rpc, jwt, edge-functions, security]

# Dependency graph
requires:
  - phase: 10-rpc-security-hardening (plan 01)
    provides: Hardened server-side RPC functions with 1-param signatures and verify_jwt=true
provides:
  - Client-side RPC calls matching hardened server signatures (no client-supplied user IDs)
  - Edge Function calls using SDK auto-auth (session JWT) instead of anon key override
affects: []

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Server-derived identity: RPC calls never pass user IDs -- server uses auth.uid()"
    - "SDK auto-auth: Edge Function calls rely on supabase_flutter session JWT, no manual headers"

key-files:
  created: []
  modified:
    - lib/features/tasks/data/task_repository.dart
    - lib/features/boards/data/board_repository.dart
    - lib/shared/widgets/ai_rewrite_button.dart
    - lib/features/planner/data/planner_repository.dart

key-decisions:
  - "Removed userId parameter from searchTasks() entirely -- callers no longer need to supply it"
  - "Removed SupabaseConstants imports when no longer referenced (clean unused import removal)"

patterns-established:
  - "Server-derived identity: All RPC functions derive user identity from JWT, never from client parameters"
  - "SDK auto-auth: Edge Function invocations omit manual Authorization headers, relying on SDK session management"

requirements-completed: [SEC-02, SEC-03, SEC-06]

# Metrics
duration: 2min
completed: 2026-03-28
---

# Phase 10 Plan 02: Client-Side RPC & Edge Function Auth Hardening Summary

**Removed client-supplied user IDs from RPC calls and manual anon-key auth headers from Edge Function invocations, letting the server derive identity from JWT**

## Performance

- **Duration:** 2 min
- **Started:** 2026-03-28T13:14:54Z
- **Completed:** 2026-03-28T13:16:41Z
- **Tasks:** 2
- **Files modified:** 4

## Accomplishments
- searchTasks() now takes only a query parameter; server derives user from auth.uid()
- createBoard() no longer passes creator_id; server uses auth.uid()
- ai_rewrite_button.dart and planner_repository.dart use SDK auto-auth instead of manually overriding Authorization header with anon key
- Removed unused SupabaseConstants imports from both Edge Function caller files

## Task Commits

Each task was committed atomically:

1. **Task 1: Update RPC call signatures in task and board repositories** - `bd89f0e` (feat)
2. **Task 2: Remove manual auth header overrides from Edge Function calls** - `1a8f6bf` (feat)

## Files Created/Modified
- `lib/features/tasks/data/task_repository.dart` - Removed userId param from searchTasks(), removed p_user_id from RPC params
- `lib/features/boards/data/board_repository.dart` - Removed creator_id from createBoard() RPC params, removed userId variable
- `lib/shared/widgets/ai_rewrite_button.dart` - Removed manual Authorization header and SupabaseConstants import
- `lib/features/planner/data/planner_repository.dart` - Removed manual Authorization header, SupabaseConstants import, and updated doc comment

## Decisions Made
- Removed userId parameter from searchTasks() method signature entirely -- no callers found passing 2 arguments, so this was a clean removal
- Removed SupabaseConstants imports from both files since the anon key was the only reference

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered
None

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness
- Client-side code now matches hardened server-side function signatures from Plan 01
- Edge Function calls will work correctly with verify_jwt=true since SDK sends session JWT
- All 4 files pass flutter analyze clean

## Self-Check: PASSED

- All 4 modified files exist on disk
- SUMMARY.md created at expected path
- Commit bd89f0e (Task 1) verified in git log
- Commit 1a8f6bf (Task 2) verified in git log

---
*Phase: 10-rpc-security-hardening*
*Completed: 2026-03-28*
