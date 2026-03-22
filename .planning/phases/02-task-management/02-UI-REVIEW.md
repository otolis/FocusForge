# Phase 02 — UI Review

**Audited:** 2026-03-22
**Baseline:** Abstract 6-pillar standards (no UI-SPEC.md present)
**Screenshots:** Not captured (no dev server detected — Flutter mobile app, code-only audit)

---

## Pillar Scores

| Pillar | Score | Key Finding |
|--------|-------|-------------|
| 1. Copywriting | 3/4 | Copy is mostly purposeful; error snackbars expose raw exception text |
| 2. Visuals | 3/4 | Clear hierarchy and empty states; delete icon-button on form lacks tooltip |
| 3. Color | 2/4 | Priority badge colors and swipe-action colors are hardcoded outside theme; P3 blue clashes with amber/teal brand |
| 4. Typography | 4/4 | Consistent use of Material 3 text styles; no ad-hoc sizes or weights |
| 5. Spacing | 3/4 | Generally consistent; minor inconsistency between card padding (12) and form padding (16) |
| 6. Experience Design | 3/4 | Loading, error, and empty states present everywhere; undo snackbar doesn't actually undo (calls refresh) |

**Overall: 18/24**

---

## Top 3 Priority Fixes

1. **Raw exception text in error snackbars** — Users see `Error: PostgrestException(...)` instead of a human-readable message — Replace `SnackBar(content: Text('Error: $e'))` in `task_form_screen.dart` (lines 305, 439, 467, 547) with a fixed message like `'Could not save task. Please try again.'`

2. **Priority badge P3 blue is off-brand** — `Color(0xFF1976D2)` (Material Blue 700) is a cold blue that conflicts with the warm amber/teal theme — Replace with a theme-derived neutral, e.g. `colorScheme.secondary` or a muted teal `Color(0xFF00838F)` to keep it within the amber/teal palette

3. **Undo snackbar calls refresh instead of restoring the deleted task** — Users tap "Undo" after deleting and the task does not come back — Wire the undo action to re-insert the task (capture the deleted `Task` object before calling `deleteTask`, then pass it to `addTask` on undo) in `task_list_screen.dart` lines 129-131 and 186-188

---

## Detailed Findings

### Pillar 1: Copywriting (3/4)

**Strengths:**
- Empty state copy is warm and action-oriented: "No tasks yet" + "Tap + to add your first task" (`task_list_screen.dart` lines 216, 223)
- Quick-create hint text "What do you need to do?" is conversational and on-brand
- Destructive dialogs explain the impact: "Tasks using '...' will have their category removed. This cannot be undone." (`category_management_screen.dart` lines 282-283)
- CTA labels are specific: "Create Task", "Save Changes", "Add", "More details" — no generic "Save/OK"
- Recurring scope dialogs use clear natural language: "This instance only", "All future instances", "Entire series"

**Issues:**
- `task_form_screen.dart` lines 305, 439, 467, 547: `SnackBar(content: Text('Error: $e'))` exposes raw Dart exception objects (e.g. `PostgrestException`) to users. This is confusing and reveals implementation details.
- `category_management_screen.dart` lines 34, 217: `Text('Error loading categories: $err')` has the same problem — raw error printed inline in the body.
- `task_form_screen.dart` line 480: "This cannot be undone." is correct but abrupt — a slightly warmer phrase like "This action cannot be undone." with the task name would be more helpful.
- `task_list_screen.dart` line 246: "Failed to load tasks" error view copy is functional but generic — a more specific phrase like "Couldn't load your tasks" would be warmer.

---

### Pillar 2: Visuals (3/4)

**Strengths:**
- Clear visual hierarchy on TaskCard: title (titleMedium, prominent) → metadata row (labelSmall chips, subordinate) — the `Wrap` layout gracefully handles overflow
- Date section headers use color semantically: `colorScheme.error` for Overdue, `colorScheme.primary` for all other sections (`date_section_header.dart` lines 17-18)
- Empty state uses a large icon (64px) as a visual anchor before the text (`task_list_screen.dart` lines 209-213)
- Category management empty state mirrors the task list empty state pattern — consistent visual language
- Swipe action feedback is semantically colored (green/red) with icon + label — discoverable

**Issues:**
- `task_form_screen.dart` line 96-99: The delete `IconButton` (`Icons.delete_outline`) in the AppBar has no `tooltip`. Icon-only action buttons must have a tooltip for accessibility and discoverability. Fix: add `tooltip: 'Delete task'` to the `IconButton`.
- `category_management_screen.dart` line 25-28: The add `IconButton` (`Icons.add`) in the AppBar also has no tooltip. Add `tooltip: 'Add category'`.
- TaskCard card border radius is `12` (`task_card.dart` line 65) but the global `cardTheme` sets `16` (`app_theme.dart` line 52). The card overrides the theme with a smaller radius, creating a subtle inconsistency — the card corners will look less rounded than other cards in the app.
- The `RecurrencePicker` monthly dropdown lists 31 bare numbers (1–31) with no suffix ("1st", "2nd", "3rd") even though the domain model `displayLabel` helper generates ordinal suffixes. Using the raw number reduces legibility.

---

### Pillar 3: Color (2/4)

**Hardcoded colors found:**

| Location | Color | Issue |
|---|---|---|
| `priority_badge.dart:18` | `Color(0xFFD32F2F)` P1 red | Outside theme — semantically correct but not theme-managed |
| `priority_badge.dart:19` | `Color(0xFFF57C00)` P2 orange | Amber-adjacent, close to brand but not derived from seed |
| `priority_badge.dart:20` | `Color(0xFF1976D2)` P3 blue | Material Blue 700 — cold blue clashes with amber/teal warmth |
| `priority_badge.dart:21` | `Color(0xFF78909C)` P4 blue-grey | Neutral; acceptable but not theme-derived |
| `task_card.dart:41` | `Color(0xFF43A047)` swipe-complete green | Not from theme; no dark mode variant |
| `task_card.dart:56` | `Color(0xFFE53935)` swipe-delete red | Not from theme; could use `colorScheme.error` |
| `category_model.dart:21-30` | 10 preset colors | Intentional palette — acceptable as user-choice colors |

**Analysis:**
- 6 unique presentation-critical hardcoded colors exist. Category preset colors are a deliberate user-facing palette and acceptable.
- The swipe delete background (`0xFFE53935`) is functionally the same hue as `colorScheme.error` but is not linked to it — dark mode will not adapt.
- P3 blue (`0xFF1976D2`) has no relationship to the amber seed. The amber seed at `brightness.light` generates a warm secondary/tertiary palette; a cold blue-700 sits outside that palette family.
- `Colors.white` is used as foreground in swipe actions — correct for contrast on the chosen backgrounds but should be `colorScheme.onError` or `colorScheme.onPrimary` for theme safety.

**Suggested remediation:**
- Swipe delete: replace `Color(0xFFE53935)` with `context.colorScheme.error`, replace `Colors.white` foreground with `context.colorScheme.onError`
- P3 priority: replace `Color(0xFF1976D2)` with `Color(0xFF0277BD)` (lighter blue) or use a teal derived from the theme tertiary `Color(0xFF2E7D6F)`

---

### Pillar 4: Typography (4/4)

**Text styles in use across all phase-02 files:**

| Style | Usage |
|---|---|
| `textTheme.titleLarge` | Empty state heading (`task_list_screen.dart:217`) |
| `textTheme.titleMedium` | Card title, quick-create header, category empty heading |
| `textTheme.titleSmall` | Section labels (Priority, Category, Repeat), section headers, completed count |
| `textTheme.bodyMedium` | Empty state subtext, category empty subtext |
| `textTheme.labelSmall` | Priority badge, deadline chip, recurrence label, category chip |

**Assessment:**
- Exactly 5 distinct text style roles used — well within the 4-role guideline for a content-dense task screen.
- No `fontWeight` overrides except the intentional `FontWeight.w600` on section headers (`date_section_header.dart:25`, `task_list_screen.dart:168`) — these are meaningful emphasis, not random weight variation.
- All text is derived from `context.textTheme`, which inherits the Nunito/Inter typography from `app_theme.dart`. No ad-hoc `TextStyle(fontSize: N)` values found.
- Font scale is coherent: large headings for empty states, medium for card titles, small for metadata chips — proper visual hierarchy from top to bottom.

---

### Pillar 5: Spacing (3/4)

**Spacing values observed:**

| Value | Usage |
|---|---|
| `EdgeInsets.all(12)` | TaskCard internal padding |
| `EdgeInsets.all(16)` | TaskFormScreen body padding |
| `EdgeInsets.symmetric(horizontal: 12, vertical: 2)` | Card outer padding in list |
| `EdgeInsets.symmetric(horizontal: 16, vertical: 8)` | Filter bar outer padding |
| `EdgeInsets.symmetric(horizontal: 24, ...)` | Quick-create sheet padding |
| `EdgeInsets.only(left: 16, top: 20, bottom: 8)` | Date section header |
| `SizedBox(height: 6/8/12/16/24)` | Vertical gaps throughout |

**Strengths:**
- Spacing values use the 4/8-point grid: 2, 4, 6, 8, 12, 16, 20, 24, 80 — all multiples of 2 with most on the standard 4-point grid.
- Consistent `SizedBox(height: 16)` between form fields in `task_form_screen.dart`.
- FAB clearance is handled with `SliverPadding(padding: EdgeInsets.only(bottom: 80))` — correctly prevents FAB overlap.
- No arbitrary `[N.Npx]` or `[N.Nrem]` values (Flutter/Dart equivalent: no fractional EdgeInsets with unusual decimals).

**Issues:**
- Card internal padding is `EdgeInsets.all(12)` (`task_card.dart:73`) while the form screen uses `EdgeInsets.all(16)` (`task_form_screen.dart:105`). These are both sensible values, but the inconsistency means task cards feel slightly tighter than the form — a noticeable gap when the user navigates from list to form.
- Quick-create sheet uses `left: 24, right: 24` (`task_quick_create_sheet.dart:91-92`) while the list uses `horizontal: 12` for cards. The 2x difference in horizontal margins makes the sheet feel disconnected from the list layout language.
- `EdgeInsets.only(left: 16, top: 20, bottom: 8)` on date section headers — the asymmetric horizontal padding (left: 16, no right padding) is intentional for a section label but worth noting as a pattern to keep consistent if new section types are added.

---

### Pillar 6: Experience Design (3/4)

**State coverage audit:**

| State | Covered | Location |
|---|---|---|
| Loading (task list) | Yes | `CircularProgressIndicator` — `task_list_screen.dart:42-43` |
| Loading (form save) | Yes | `isLoading` flag disables button + spinner — `task_form_screen.dart:157-158` |
| Loading (categories) | Yes | `CircularProgressIndicator` in category section — `task_form_screen.dart:215-216` |
| Error (task list) | Yes | `_ErrorView` with Retry button — `task_list_screen.dart:44-46` |
| Error (save/delete) | Yes | SnackBar on catch — `task_form_screen.dart:304-306` |
| Empty (task list) | Yes | `_EmptyState` with icon + instruction — `task_list_screen.dart:201-231` |
| Empty (categories) | Yes | Icon + "Create your first category" + CTA — `category_management_screen.dart:46-76` |
| Disabled state (save) | Yes | `onPressed: _isLoading ? null : _handleSave` — `task_form_screen.dart:158` |
| Delete confirmation | Yes | AlertDialog with named consequences — `task_form_screen.dart:475-496` |
| Recurring scope dialog | Yes | Scope selection for edit and delete — `task_form_screen.dart:377-401, 498-525` |
| Undo delete | Partial | SnackBar shown, but undo calls `refresh()` not re-insert |

**Issues:**

1. **Undo is broken** (`task_list_screen.dart` lines 130-131, 187-188): The SnackBar "Undo" action calls `ref.read(taskListProvider.notifier).refresh()`, which re-fetches from the server. If the delete already propagated to Supabase (optimistic update with actual delete), the task will not reappear. True undo requires capturing the deleted task and calling `addTask` — or implementing a soft-delete with a time-window before the server call.

2. **Empty filter state not handled**: When a user applies filters and no tasks match, `filteredTasks.isEmpty && completedTasks.isEmpty` shows the "No tasks yet" empty state — which is misleading (the user has tasks, just none matching the filter). A separate "No tasks match your filters" message with a "Clear filters" button would prevent confusion. The current check at `task_list_screen.dart:53` does not distinguish the two cases.

3. **Category error displays raw text inline** (`category_management_screen.dart:34`, `task_form_screen.dart:217`): The error is rendered as a plain `Text` widget in the body, not as a structured error view with a retry action. This is functional but provides no recovery path for the user.

4. **No haptic feedback on task complete/delete swipe**: The swipe-to-complete and swipe-to-delete gestures (flutter_slidable) perform state-changing actions without haptic confirmation. Adding `HapticFeedback.mediumImpact()` in the `onToggleComplete` and `onDelete` callbacks would meaningfully improve tactile feedback on mobile.

---

## Files Audited

**Screens:**
- `lib/features/tasks/presentation/screens/task_list_screen.dart`
- `lib/features/tasks/presentation/screens/task_form_screen.dart`
- `lib/features/tasks/presentation/screens/category_management_screen.dart`

**Widgets:**
- `lib/features/tasks/presentation/widgets/task_card.dart`
- `lib/features/tasks/presentation/widgets/task_quick_create_sheet.dart`
- `lib/features/tasks/presentation/widgets/task_filter_bar.dart`
- `lib/features/tasks/presentation/widgets/priority_badge.dart`
- `lib/features/tasks/presentation/widgets/category_chip.dart`
- `lib/features/tasks/presentation/widgets/deadline_chip.dart`
- `lib/features/tasks/presentation/widgets/recurrence_label.dart`
- `lib/features/tasks/presentation/widgets/date_section_header.dart`
- `lib/features/tasks/presentation/widgets/recurrence_picker.dart`
- `lib/features/tasks/presentation/widgets/category_color_picker.dart`

**Domain / Theme (reference):**
- `lib/features/tasks/domain/category_model.dart`
- `lib/core/theme/app_theme.dart`
- `lib/core/theme/color_schemes.dart`

**Registry audit:** shadcn not initialized — skipped.
