# Phase 6: Collaborative Boards - Context

**Gathered:** 2026-03-18
**Status:** Ready for planning

<domain>
## Phase Boundary

Deliver collaborative Kanban boards with realtime sync, role-based member management, and live presence indicators. Users can create boards, organize cards across columns with drag-and-drop, invite members by email with role-based permissions, and see who's online. This is the app's first use of Supabase Realtime.

</domain>

<decisions>
## Implementation Decisions

### Board navigation & access
- Boards get a 5th tab in the bottom navigation bar (Tasks, Habits, Planner, Boards, Profile)
- Board list screen displays boards as a card grid (2-column) — each card shows board name, member avatar chips, and column count
- FAB on board list screen to create a new board
- New boards start with 3 default columns: To Do, In Progress, Done (user can rename/add/remove later)
- Tap a board card to open full-screen Kanban view

### Kanban layout & interactions
- Horizontal scroll with swipeable columns on mobile — each column takes ~85% screen width
- Cards show: title, assignee avatar chip, priority color indicator, due date if set
- Long-press to initiate drag-and-drop of cards between columns (prevents accidental drags)
- Column management: add, rename, reorder, and delete columns (owner/editor only)
- Tap card to open bottom sheet with full details and edit capability
- Empty columns show subtle dashed outline with "+ Add card" prompt

### Member management & roles
- Invite flow: email input field on board settings screen — sends invite, recipient sees board on login
- Three roles with clear permissions:
  - Owner: full control, delete board, manage members and roles
  - Editor: add/move/edit cards, manage columns
  - Viewer: read-only access, no edits
- Member avatars displayed at top-right of board header, overflow to "+N" chip when >4 members
- Role assignment via dropdown next to each member in board settings

### Presence & realtime sync
- Green dot on member avatars when online, dimmed avatar when offline
- Optimistic UI: card moves and edits appear instantly, sync in background
- Conflict handling: last-write-wins with subtle toast notification when another user's change arrives
- Supabase Realtime channel per board — subscribes to card inserts/updates/deletes and column changes

### Claude's Discretion
- Drag-and-drop library choice (flutter built-in vs third-party package)
- Card detail bottom sheet layout and field arrangement
- Board settings screen layout
- Exact RLS policy structure for multi-role access
- Database schema design (boards, columns, cards, members tables)
- Realtime channel configuration and subscription management
- Animation/transition details for card drag and column swipe

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

No external specs — requirements are fully captured in decisions above and in REQUIREMENTS.md.

### Requirements
- `.planning/REQUIREMENTS.md` — BOARD-01 through BOARD-04 define the acceptance criteria for this phase

### Prior context
- `.planning/phases/01-foundation-auth/01-CONTEXT.md` — Theme decisions (warm amber/teal, rounded corners), architecture patterns (Clean Architecture, Riverpod, go_router)
- `.planning/PROJECT.md` — Collaborative boards called out as "most complex feature but must-have" and "strong portfolio differentiator"

### Existing code
- `lib/core/router/app_router.dart` — Current routing with ShellRoute + 4 tabs (needs 5th tab for Boards)
- `lib/shared/widgets/app_shell.dart` — Bottom nav bar (needs Boards destination added)
- `lib/features/auth/data/auth_repository.dart` — SupabaseClient injection pattern to follow
- `lib/features/profile/domain/profile_model.dart` — Model fromJson/toJson/copyWith pattern to follow
- `supabase/migrations/00001_create_profiles.sql` — RLS policy pattern to follow for board tables

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `AppButton`, `AppTextField`, `LoadingOverlay` shared widgets — reuse for board creation and card editing forms
- `AvatarWidget` — reuse for member display on boards and cards
- `PlaceholderTab` — currently at `/boards` path (needs replacement with actual board list screen)
- Material 3 theme with amber/teal color scheme — board UI should follow established palette

### Established Patterns
- Clean Architecture: data/domain/presentation layers per feature
- Riverpod 2 providers with `SupabaseClient` injection for repositories
- `fromJson`/`toJson`/`copyWith` pattern on models (see `Profile`)
- GoRouter with `ShellRoute` for bottom nav tabs and auth-based redirects
- RLS policies: per-user access using `auth.uid()` (boards will need multi-user RLS)

### Integration Points
- `app_router.dart`: Add `/boards` route inside ShellRoute, add board detail route
- `app_shell.dart`: Add 5th NavigationDestination for Boards
- Supabase Realtime: First usage — establish subscription pattern that other phases could follow
- Auth: Board membership linked to `auth.users` via `profiles.id`

</code_context>

<specifics>
## Specific Ideas

- Board cards in the list should feel visual and inviting (card grid, not a plain list) — consistent with the warm/friendly app personality
- This is the portfolio's realtime showcase — the instant sync and presence indicators should feel polished and impressive to recruiters
- Kanban interaction should feel native on mobile — horizontal swiping between columns, not cramped desktop-style layout

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope

</deferred>

---

*Phase: 06-collaborative-boards*
*Context gathered: 2026-03-18*
