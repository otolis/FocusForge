# Phase 2: Task Management - Context

**Gathered:** 2026-03-18
**Status:** Ready for planning

<domain>
## Phase Boundary

Full task CRUD (create, read, update, delete) with title, description, priority (P1-P4), category, deadline. User-created color-coded categories. Filtering by priority/category/date range and full-text search. Recurring tasks on daily/weekly/monthly/custom intervals with auto-generated instances. This phase does NOT include NLP parsing or AI classification (Phase 3).

</domain>

<decisions>
## Implementation Decisions

### Task list layout
- Card-based layout in the main task list (matches warm/friendly app vibe)
- Each card shows: title, priority badge (P1-P4 with color coding), category chip, deadline chip, completion checkbox
- Cards grouped by date sections: "Today", "Tomorrow", "This Week", "Later"
- Swipe right to complete, swipe left to delete (with undo snackbar)
- Completed tasks move to a "Completed" section at the bottom (collapsible)

### Task creation flow
- FAB (floating action button) on task list screen opens a bottom sheet for quick creation
- Bottom sheet shows: title field, priority selector (P1-P4 chips), deadline date picker — minimum viable creation in 3 taps
- "More details" expands to full-screen form with: description (multiline), category selector, recurrence settings
- Edit mode reuses the full-screen form layout
- Delete available via swipe or from the edit screen with confirmation dialog

### Category system
- Fully user-created categories (no pre-defined defaults)
- Each category has a name and color chosen from 10 preset colors (Material 3 palette-derived)
- Categories display as small colored chips on task cards
- Tasks without a category show no chip (clean default state)
- Category management accessible from a dedicated screen (reachable from task filter bar or settings)
- Category CRUD: create, rename, recolor, delete (with "reassign or remove from tasks" option on delete)

### Recurring tasks
- Recurrence options: daily, weekly (select days), monthly (select date), custom interval (every N days)
- Instances pre-generated for the next 2 weeks; more auto-generated as time passes
- Recurring tasks show a subtle recurrence label on the card (e.g., "Daily", "Mon/Wed/Fri")
- Editing a recurring task prompts: "This instance only" or "All future instances"
- Deleting a recurring task prompts: "This instance only" or "Entire series"
- Completing one instance does not affect others — each instance is independent once generated

### Claude's Discretion
- Exact card elevation, padding, and spacing values
- Priority color mapping (P1-P4 specific hex values — should fit amber/teal theme)
- Animation for task completion (checkbox feedback)
- Search bar placement and behavior (inline vs expandable)
- Filter UI design (chips bar, dropdown, or bottom sheet)
- Supabase table schema design for tasks, categories, and recurrence rules
- Full-text search implementation approach (Supabase text search vs client-side)
- Date section header styling

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

No external specs — requirements fully captured in decisions above and in these project files:

### Project requirements
- `.planning/REQUIREMENTS.md` — TASK-01, TASK-03, TASK-04, TASK-05 acceptance criteria
- `.planning/ROADMAP.md` — Phase 2 success criteria and plan structure

### Design foundation (Phase 1)
- `.planning/phases/01-foundation-auth/01-CONTEXT.md` — Theme decisions (amber/orange + teal/green, warm & friendly vibe, rounded corners)
- `lib/core/theme/app_theme.dart` — Material 3 theme implementation
- `lib/core/theme/color_schemes.dart` — Color scheme definitions

### Architecture patterns
- `lib/features/profile/data/profile_repository.dart` — Repository pattern reference (Supabase CRUD)
- `lib/features/profile/domain/profile_model.dart` — Domain model pattern reference
- `lib/features/profile/presentation/providers/profile_provider.dart` — Riverpod provider pattern reference
- `lib/features/auth/presentation/providers/auth_provider.dart` — Auth state pattern (for user ID access)

### Navigation
- `lib/core/router/app_router.dart` — Router config (tasks is `/tasks` route, currently PlaceholderTab)
- `lib/shared/widgets/app_shell.dart` — Bottom nav shell (Tasks is tab 0)

### Shared widgets
- `lib/shared/widgets/app_button.dart` — Reusable button component
- `lib/shared/widgets/app_text_field.dart` — Reusable text field component
- `lib/shared/widgets/loading_overlay.dart` — Loading state overlay

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `AppButton`: Styled button widget — use for form actions (Save, Cancel)
- `AppTextField`: Styled text input — use for task title and description fields
- `LoadingOverlay`: Loading state — use during Supabase operations
- `PlaceholderTab`: Currently at `/tasks` route — will be replaced with actual TaskListScreen

### Established Patterns
- Clean Architecture: `data/` (repository + Supabase), `domain/` (models), `presentation/` (screens + providers + widgets)
- Riverpod providers: StateNotifier for mutable state, FutureProvider for async data
- Repository pattern: Supabase client calls wrapped in repository class
- go_router: Routes defined in `app_router.dart`, ShellRoute for bottom nav tabs

### Integration Points
- `/tasks` route in `app_router.dart` — replace PlaceholderTab with TaskListScreen
- Add sub-routes: `/tasks/create`, `/tasks/:id`, `/tasks/:id/edit`
- `AppShell` bottom nav already has Tasks as first tab
- Supabase client from `supabase_constants.dart` for database operations
- Auth provider for current user ID (task ownership)

</code_context>

<specifics>
## Specific Ideas

- Card design should feel warm and encouraging — not a cold checklist. Think Todoist cards but with the amber/teal warmth of FocusForge
- Priority badges should be visually distinct at a glance (P1 = urgent red, P4 = calm blue/gray range)
- The quick-create bottom sheet is key — most tasks should be creatable without opening a full form
- Date grouping ("Today", "Tomorrow", etc.) gives a sense of temporal context without needing a calendar view

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope

</deferred>

---

*Phase: 02-task-management*
*Context gathered: 2026-03-18*
