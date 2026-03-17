# Phase 4: Habit Tracking - Context

**Gathered:** 2026-03-18
**Status:** Ready for planning

<domain>
## Phase Boundary

Users can create, edit, and delete habits with configurable frequency (daily/weekly/custom) and target counts. Each habit shows a visual streak via a calendar heat map, supports one-tap check-in with satisfying feedback, and has an analytics section with completion rate charts rendered via fl_chart. This phase owns the complete vertical slice: DB schema, data layer, domain logic, and presentation.

</domain>

<decisions>
## Implementation Decisions

### Streak visualization
- Calendar heat map (GitHub-style contribution grid) showing the last 3 months
- Color intensity mapped to completion (empty, partial, full) using the amber/orange palette
- Heat map appears on the habit detail screen (not the list — too large)
- Current streak displayed as fire icon + "X day streak" badge below the heat map
- Streak counter (compact) also visible on the habit list card for quick reference

### Check-in interaction
- Binary habits (yes/no): one-tap on the habit card in the list view — tap the check circle to complete
- Count-based habits (e.g., "drink 8 glasses"): tap to increment by 1, long-press for custom entry dialog
- Completion animation: scale bounce + color fill on the card/circle (subtle, satisfying)
- Lottie/confetti animations deferred to Phase 8 integration
- Haptic feedback: light haptic on every check-in tap, medium haptic on streak milestones (7, 30, 100 days)

### Analytics charts
- Primary chart: bar chart showing daily completion rate for the selected period, rendered via fl_chart
- Time period selector: Material 3 SegmentedButton with Week / Month / Year options
- Summary stats: four stat cards above the chart — best streak, current streak, total completions, completion rate %
- Analytics is a dedicated section within the habit detail screen (scrollable below the heat map)

### Claude's Discretion
- Habit list layout (cards vs tiles), grouping strategy, and sort order
- Empty state design for no habits yet
- Habit creation/edit form layout and field arrangement
- Heat map color gradient exact values (stay within amber/orange family)
- Streak calculation algorithm (handling timezone, partial completions)
- Database schema design (habits table, habit_logs table, indexes)
- Bar chart styling (colors, labels, grid lines)

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

No external specs — requirements fully captured in decisions above and the following project files:

### Requirements
- `.planning/REQUIREMENTS.md` — HABIT-01 through HABIT-04 define the acceptance criteria for this phase

### Prior context
- `.planning/phases/01-foundation-auth/01-CONTEXT.md` — Theme decisions (amber palette, warm & friendly vibe, Duolingo-like encouragement)
- `.planning/PROJECT.md` — Architecture constraints (Clean Architecture, Riverpod 2, Supabase backend)

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `lib/shared/widgets/app_button.dart` — AppButton with filled/outlined/destructive variants and loading state
- `lib/shared/widgets/app_text_field.dart` — AppTextField for form inputs
- `lib/shared/widgets/loading_overlay.dart` — Loading overlay for async operations
- `lib/core/utils/extensions.dart` — BuildContext extensions for colorScheme and textTheme
- `lib/core/theme/app_theme.dart` — Material 3 theme with CardTheme (16dp radius, 0 elevation), ChipTheme (8dp radius)

### Established Patterns
- Clean Architecture: `data/` (repository), `domain/` (models), `presentation/` (screens, widgets, providers) per feature
- Riverpod 2 state management with StateNotifier and FutureProvider patterns
- Profile model uses `fromJson`/`toJson` with Supabase — habits should follow same pattern
- go_router ShellRoute with bottom nav — `/habits` route already registered

### Integration Points
- `lib/core/router/app_router.dart:98-100` — `/habits` route currently uses PlaceholderTab, needs to be replaced with HabitListScreen
- `lib/shared/widgets/app_shell.dart:59-62` — Habits tab already in bottom nav with fire icon
- Supabase client available via existing auth setup — habit repository will use same client
- `lib/features/profile/domain/profile_model.dart` — EnergyPattern model exists (relevant for Phase 5 integration, not this phase)

</code_context>

<specifics>
## Specific Ideas

- Heat map should feel like GitHub contributions — instantly recognizable pattern of consistency
- The fire icon in the nav bar + "X day streak" badge creates a cohesive "streak" visual language
- Check-in should be as frictionless as possible — one tap, done, satisfying bounce
- Count-based habits need both speed (tap to +1) and flexibility (long-press for custom amount)
- Haptic milestones at 7/30/100 days reinforce the encouraging, supportive vibe from Phase 1

</specifics>

<deferred>
## Deferred Ideas

- Streak freeze (prevent anxiety from breaks) — tracked as HABIT-05 in v2 requirements
- Lottie/confetti animations on completion — Phase 8 integration
- Habit reminders/notifications — Phase 7

</deferred>

---

*Phase: 04-habit-tracking*
*Context gathered: 2026-03-18*
