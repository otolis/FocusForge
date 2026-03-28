---
phase: quick
plan: 260328-4yd
subsystem: ui, ai
tags: [groq, supabase-edge-functions, flutter, ai-rewrite, shared-widget]

# Dependency graph
requires:
  - phase: 02-smart-input
    provides: "Groq API integration pattern via Supabase Edge Functions"
provides:
  - "rewrite-title Supabase Edge Function for polishing raw titles via Groq"
  - "AiRewriteButton shared widget reusable across any title input field"
  - "AI rewrite integration on all 6 title input fields (tasks, habits, planner, boards)"
affects: [tasks, habits, planner, boards]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "AiRewriteButton pattern: ConsumerStatefulWidget with loading state, functions.invoke, snackbar errors"
    - "Row(Expanded(SmartInputField), AiRewriteButton) pattern for adding suffix to SmartInputField widgets"

key-files:
  created:
    - supabase/functions/rewrite-title/index.ts
    - lib/shared/widgets/ai_rewrite_button.dart
  modified:
    - lib/features/tasks/presentation/screens/task_form_screen.dart
    - lib/features/tasks/presentation/widgets/task_quick_create_sheet.dart
    - lib/features/habits/presentation/screens/habit_form_screen.dart
    - lib/features/planner/presentation/widgets/add_item_sheet.dart
    - lib/features/boards/presentation/screens/board_detail_screen.dart
    - lib/features/boards/presentation/widgets/card_detail_sheet.dart

key-decisions:
  - "Used suffixIcon for AppTextField/TextFormField, Row wrapper for SmartInputField"
  - "Kept AiRewriteButton as ConsumerStatefulWidget (not StatelessWidget) to manage loading state internally"

patterns-established:
  - "AiRewriteButton(controller: X) pattern for adding AI rewrite to any text field"

requirements-completed: []

# Metrics
duration: 3min
completed: 2026-03-28
---

# Quick Task 260328-4yd: Add AI Title Rewrite Button Summary

**Groq-powered AI title rewrite button (auto_awesome icon) added to all 6 title fields across tasks, habits, planner, and boards via shared AiRewriteButton widget and new rewrite-title Edge Function**

## Performance

- **Duration:** 3 min
- **Started:** 2026-03-28T01:39:07Z
- **Completed:** 2026-03-28T01:41:30Z
- **Tasks:** 3 (2 auto + 1 human-verify checkpoint)
- **Files modified:** 8

## Accomplishments
- Created `rewrite-title` Supabase Edge Function that calls Groq API (llama-3.3-70b-versatile) to polish raw titles into clear, professional, action-oriented text
- Built shared `AiRewriteButton` widget with loading spinner, empty-text disabling, and snackbar error handling
- Integrated the AI rewrite button into all 6 title input fields: TaskFormScreen (create + edit), TaskQuickCreateSheet, HabitFormScreen, AddItemSheet (planner), BoardDetailScreen add-card dialog, CardDetailSheet

## Task Commits

Each task was committed atomically:

1. **Task 1: Create rewrite-title Edge Function and AiRewriteButton shared widget** - `69c0581` (feat)
2. **Task 2: Integrate AiRewriteButton into all title input fields** - `dd9a3b0` (feat)
3. **Task 3: Human verification checkpoint** - approved by user

## Files Created/Modified
- `supabase/functions/rewrite-title/index.ts` - Edge Function: accepts raw title, calls Groq, returns polished title
- `lib/shared/widgets/ai_rewrite_button.dart` - Shared widget: auto_awesome icon, loading state, functions.invoke call, snackbar errors
- `lib/features/tasks/presentation/screens/task_form_screen.dart` - Row wrapper for create mode, suffixIcon for edit mode
- `lib/features/tasks/presentation/widgets/task_quick_create_sheet.dart` - Row wrapper around SmartInputField
- `lib/features/habits/presentation/screens/habit_form_screen.dart` - suffixIcon on Habit Name AppTextField
- `lib/features/planner/presentation/widgets/add_item_sheet.dart` - Row wrapper around planner SmartInputField
- `lib/features/boards/presentation/screens/board_detail_screen.dart` - suffixIcon on Add Card dialog AppTextField
- `lib/features/boards/presentation/widgets/card_detail_sheet.dart` - suffixIcon in card title TextFormField decoration

## Decisions Made
- Used `suffixIcon` parameter for `AppTextField` and `TextFormField` integrations (cleaner, native support)
- Used `Row(Expanded(SmartInputField), AiRewriteButton)` pattern for `SmartInputField` integrations (SmartInputField does not have suffixIcon param)
- Kept `AiRewriteButton` as `ConsumerStatefulWidget` to manage loading state internally without burdening parent widgets

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None.

## User Setup Required

Edge Function deployment required: `supabase functions deploy rewrite-title`. The GROQ_API_KEY secret must already be configured in Supabase (set during earlier phases).

## Next Phase Readiness
- AI rewrite button is fully operational across all title fields
- Pattern established for adding AI-powered features to other text fields in the future

## Self-Check: PASSED

All 8 modified/created files verified present on disk. Both task commits (69c0581, dd9a3b0) verified in git history.

---
*Quick task: 260328-4yd*
*Completed: 2026-03-28*
