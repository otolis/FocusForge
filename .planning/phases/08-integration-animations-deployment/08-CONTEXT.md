# Phase 8: Integration, Animations & Deployment - Context

**Gathered:** 2026-03-22
**Status:** Ready for planning

<domain>
## Phase Boundary

Wire all independently-built features together (smart input → task creation, real tasks/habits → AI planner), add Lottie celebration animations on completions and milestones, and deploy as Flutter web for a live portfolio demo. No new features — integration, polish, and deployment only.

</domain>

<decisions>
## Implementation Decisions

### Cross-feature wiring
- Replace the title TextField in TaskFormScreen with SmartInputField — parsed deadline, priority, and category auto-fill the corresponding form fields
- Reuse SmartInputField in AddItemSheet (planner) for consistency — users can add tasks with NLP from the planner too
- Create a bridge provider that queries real tasks (from task_repository) and habits (from habit_repository) and maps them to PlannableItem models for the AI planner
- Marking a planner block as done should toggle the underlying task/habit completion (two-way sync)
- Planner blocks should deep-link to source task/habit detail screens on tap

### Animation style & triggers
- Confetti burst overlay on task completion — brief Lottie animation that auto-dismisses after 1.5s
- Habit check-in gets a smaller celebratory pulse (builds on existing CheckInButton bounce)
- Larger tiered celebrations for streak milestones: 7-day, 30-day, 100-day with distinct Lottie files
- Animations are interruptible — tap anywhere to dismiss early, never block interaction
- Respect system reduce-motion accessibility setting (MediaQuery.disableAnimations) — no separate app toggle
- Use lottie package for Flutter (lottie: ^3.x in pubspec.yaml)

### Web deployment strategy
- Deploy to GitHub Pages via GitHub Actions CI/CD pipeline
- TFLite graceful degradation on web — skip TFLite classification, fall back to regex-only NLP parsing
- Supabase credentials injected as GitHub Actions secrets (SUPABASE_URL, SUPABASE_ANON_KEY)
- Direct app experience — no separate landing page, the Flutter web app itself is the portfolio demo
- Build command: `flutter build web --release --base-href /FocusForge/`

### Home screen & navigation
- Tasks tab remains the default home tab (existing pattern)
- No dashboard/overview screen — keep bottom nav with 4 tabs (Tasks, Habits, Planner, Boards)
- Cross-feature deep links from planner blocks to source task/habit detail screens
- Planner stays in its own tab — users navigate there intentionally

### Claude's Discretion
- Exact Lottie animation files to use (free LottieFiles assets)
- CelebrationOverlay widget implementation details
- GitHub Actions workflow YAML structure
- Bridge provider caching strategy
- Error handling for web-specific limitations

</decisions>

<canonical_refs>
## Canonical References

No external specs — requirements are fully captured in decisions above and REQUIREMENTS.md.

### Key implementation files
- `lib/features/smart_input/presentation/widgets/smart_input_field.dart` — SmartInputField widget to integrate into TaskFormScreen
- `lib/features/tasks/presentation/screens/task_form_screen.dart` — Task creation form to receive SmartInputField
- `lib/features/planner/presentation/providers/plannable_items_provider.dart` — PlannableItemsNotifier to bridge with real data
- `lib/features/planner/presentation/widgets/add_item_sheet.dart` — Add item sheet to receive SmartInputField
- `lib/features/habits/presentation/widgets/check_in_button.dart` — Existing bounce animation to enhance
- `lib/core/router/app_router.dart` — Router for cross-feature navigation wiring

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `SmartInputField` (smart_input): ConsumerStatefulWidget with `onParsed` callback emitting `ParsedTaskInput` — ready to drop into TaskFormScreen
- `SuggestionChips` (smart_input): Shows extracted deadline/priority/category below input — accompanies SmartInputField
- `CheckInButton` (habits): Already has 200ms elasticOut scale bounce — can layer Lottie on top
- `PlannableItem` model: Has `sourceType` and `sourceId` fields — designed for bridging to real tasks/habits
- `AppButton`, `AppTextField` (shared): Reusable UI components following Material 3 patterns

### Established Patterns
- Riverpod StateNotifier + AsyncValue for async state (all features)
- go_router with ShellRoute for tab navigation, parentNavigatorKey for full-screen pushes
- Repository pattern with optional SupabaseClient param for DI
- Feature-based directory structure: data/domain/presentation per feature

### Integration Points
- `TaskFormScreen` title field (line ~1-17 imports) → replace with SmartInputField
- `PlannableItemsNotifier.loadItems()` → redirect to query real tasks + habits instead of plannable_items table
- `PlannerScreen.onBlockMoved` → add completion callback for two-way sync
- `app_router.dart` → already has all feature routes wired; may need planner→task/habit deep links
- `main.dart` → Firebase already initialized (Phase 7); no additional init needed for Lottie

</code_context>

<specifics>
## Specific Ideas

No specific requirements — open to standard approaches. This is a portfolio project, so animations should be polished but not excessive. The goal is to demonstrate technical breadth (cross-feature integration, animations, CI/CD deployment) to recruiters.

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope

</deferred>

---

*Phase: 08-integration-animations-deployment*
*Context gathered: 2026-03-22*
