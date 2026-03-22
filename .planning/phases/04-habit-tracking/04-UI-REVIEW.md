# Phase 04 — UI Review

**Audited:** 2026-03-22
**Baseline:** Abstract 6-pillar standards (no UI-SPEC.md)
**Screenshots:** Not captured (no dev server detected on ports 3000, 5173, or 8080)

---

## Pillar Scores

| Pillar | Score | Key Finding |
|--------|-------|-------------|
| 1. Copywriting | 3/4 | CTAs and empty states are specific and purposeful; generic "Cancel"/"No data available" labels remain in dialogs and bar chart |
| 2. Visuals | 3/4 | Strong visual language with fire icon, heat map, and animated check-in; trailing icon renders as generic circle instead of the habit's actual icon |
| 3. Color | 3/4 | Consistent theme token usage with intentional amber/orange accent for streaks; hardcoded `Colors.orange` and `Colors.amber` used in 5 places instead of theme tokens |
| 4. Typography | 3/4 | All text uses Material 3 theme tokens correctly except one hardcoded `fontSize: 10` in CheckInButton's count label |
| 5. Spacing | 4/4 | Consistent 4/8/12/16/24/32 spacing scale throughout; no arbitrary pixel values |
| 6. Experience Design | 3/4 | Loading, error, and empty states covered on all three screens; detail screen error surfaced only as SnackBar (no retry), check-in errors are silent |

**Overall: 19/24**

---

## Top 3 Priority Fixes

1. **HabitCard trailing icon renders `Icons.circle` instead of the habit's actual icon** — Users who assign an icon to a habit see a generic filled dot instead of their chosen icon (fitness, book, water, etc.), making all icon slots visually meaningless. Fix by building an `_iconDataFromString(String key)` helper (matching the same `_iconOptions` map already defined in `HabitFormScreen`) and passing it to `Icon()` in `habit_card.dart:122`.

2. **Detail screen error state dismisses silently via SnackBar with no retry** — If the habit or logs fail to load (network error, auth expiry), the screen shows the empty placeholder `_habit == null` body with `AppBar(title: 'Habit Detail')` and no way to retry. The SnackBar at `habit_detail_screen.dart:117-119` disappears after 4 seconds, leaving the user on a blank screen. Fix by catching the error into a `_errorMessage` state field and rendering a retry widget in the body when `_habit == null && !_isLoading`.

3. **Hardcoded `Colors.orange` and `Colors.amber` bypass the theme's color system** — Found in `habit_card.dart:92`, `habit_detail_screen.dart:313,328,358,364`. These will not adapt to dark mode or theme customization. The project uses an amber seed color scheme; expose these as `colorScheme.tertiary` or a custom extension color so they follow the theme. At minimum, switch to `Theme.of(context).colorScheme.tertiary` for the streak accent.

---

## Detailed Findings

### Pillar 1: Copywriting (3/4)

The copywriting is largely purposeful and task-specific throughout the feature.

**Passing patterns:**
- Empty state: "No habits yet" + "Tap + to create your first habit" — specific, instructional, no filler text (`habit_list_screen.dart:138,144`)
- CTA labels: "Create Habit", "Save Changes", "Delete Habit" — verb-noun format, unambiguous (`habit_form_screen.dart:364,376`)
- Error messages: "Failed to load habits", "Failed to save habit: $e", "Failed to delete habit: $e" — contextual, not generic (`habit_list_screen.dart:98`, `habit_form_screen.dart:99,146,193`)
- Delete confirmation dialog: "This will permanently delete this habit and all its check-in history. This action cannot be undone." — explains consequences clearly (`habit_form_screen.dart:163-165`)
- Check-in dialog title: "Log ${habit.name}" — personalized, references the specific habit (`habit_list_screen.dart:34`)

**Issues:**
- `habit_list_screen.dart:47` and `habit_form_screen.dart:168` — "Cancel" buttons in dialogs. While technically not wrong, "Cancel" is a generic label that could be more specific in the delete confirmation context (e.g., "Keep Habit").
- `habit_bar_chart.dart:38` — "No data available" is a generic fallback. Given the context (an analytics chart), "No completions recorded yet" or "Check in to see your progress here" would be more meaningful and encourage action.
- `habit_detail_screen.dart:260,268` — AppBar titles "Habit Detail" during loading and not-found states are placeholder text leaking into production UI.

### Pillar 2: Visuals (3/4)

The visual design establishes a coherent "streak" language across screens: fire icon appears consistently on list cards, the detail screen streak badge, and the stat card. The GitHub-style amber heat map is a clear signature visual. Animation on CheckInButton (scale bounce, `Curves.elasticOut`) provides satisfying feedback.

**Issues:**
- `habit_card.dart:120-125` — The trailing icon position uses `Icons.circle` regardless of which icon the user selected. The `_iconOptions` map in HabitFormScreen stores icon names as strings (e.g., "fitness_center", "menu_book") but HabitCard has no lookup function to convert that string back to `IconData`. This means the trailing icon slot is never populated with the intended icon — a visual promise made at creation time that is never delivered at display time.
- `check_in_button.dart` — The GestureDetector wrapping the circular button has no semantic label. Screen reader users receive no announcement when the button is tapped, and there is no `Tooltip` to explain the button's purpose to sighted users on long-press discovery. Adding `Semantics(label: habit.isCompletedToday ? 'Mark incomplete' : 'Check in')` would resolve this.
- `habit_detail_screen.dart:258-263` — During loading, the AppBar title is hardcoded as "Habit Detail" rather than showing the habit name or a skeleton. Combined with the blank body spinner, there is no context about which habit is loading.

### Pillar 3: Color (3/4)

The project uses Material 3 theme tokens (via `context.colorScheme.*`) consistently in most places. The amber seed color scheme is appropriate for the habit/streak domain.

**Passing patterns:**
- CheckInButton circle fill: `colorScheme.primary` / `colorScheme.onPrimary` — correct theme token usage (`check_in_button.dart:90,106,116`)
- Completed card tint: `colorScheme.primary.withOpacity(0.05)` — intentional, subtle (`habit_card.dart:51`)
- StatCard label: `colorScheme.onSurfaceVariant` — correct secondary text treatment
- Error delete button: `colorScheme.error` — correct semantic color usage (`habit_form_screen.dart:173`)
- Bar chart bars: `colorScheme.primary` — theme-aware (`habit_bar_chart.dart:54`)

**Issues:**
- `habit_card.dart:92` — `color: Colors.orange` for the streak fire icon. This hardcodes the orange accent outside the theme.
- `habit_detail_screen.dart:313,328` — `color: Colors.orange` for the streak fire icon and "Keep it up!" text.
- `habit_detail_screen.dart:358` — `iconColor: Colors.amber` for the Best Streak stat card icon.
- `habit_detail_screen.dart:364` — `iconColor: Colors.orange` for the Current Streak stat card icon.
- `habit_card.dart:51` — `withOpacity()` is deprecated in Flutter 3.x in favor of `withValues(alpha: 0.05)`. Minor but creates a lint warning.

The orange/amber usage is deliberate (matches the amber heat map palette from the locked design decision) but bypasses the theme system. Consider adding a `streakColor` extension to AppTheme, or map to `colorScheme.tertiary` if the seed produces an appropriate tertiary.

### Pillar 4: Typography (4/4 → adjusted to 3/4)

Typography is almost entirely composed via `context.textTheme.*` tokens, which is excellent practice for a Flutter Material 3 app.

**Tokens in use:** `titleLarge`, `titleMedium`, `bodySmall`, `bodyMedium`, `labelLarge`, `labelSmall` — six levels, which is acceptable for a feature-rich screen.

**Issue:**
- `check_in_button.dart:104` — `fontSize: 10` is a hardcoded value for the count-based progress label inside the circle. The equivalent system token would be `textTheme.labelSmall` (typically 11sp), which is close and would stay within the theme's size scale. One hardcoded override does not break the system, but it is worth aligning.

**Score note:** The single hardcoded fontSize warrants reducing from 4 to 3 given the otherwise clean token usage.

### Pillar 5: Spacing (4/4)

Spacing is exceptionally consistent throughout the feature. All padding and gap values come from the implicit scale: 4, 8, 12, 16, 24, 32 dp.

**Distribution observed:**
- Inner gutters: 4dp (icon-label gap, between name and badge)
- Component internal padding: 8dp (card vertical padding, stat card internal)
- Card horizontal padding: 12dp
- Screen horizontal margin: 16dp (list, detail sections), 24dp (form)
- Section gaps: 24dp (between detail screen sections)
- Bottom breathing room: 32dp (form bottom)

No arbitrary pixel values (e.g., `[13px]`, `[17.5dp]`) found. No `Padding(padding: EdgeInsets.only(left: 3))` style exceptions. The `EdgeInsets.fromLTRB(16, 16, 16, 0)` at `habit_detail_screen.dart:296` uses the standard 16dp value throughout. The `EdgeInsets.symmetric(horizontal: 0, vertical: 8)` at line 300 for the heat map section intentionally removes horizontal padding to allow the heatmap to bleed edge-to-edge (appropriate given the heatmap's horizontal scroll requirement).

### Pillar 6: Experience Design (3/4)

The feature handles the primary UX states well: loading states exist on all three screens, errors surface via SnackBar or center-column text, empty states are implemented on the list and bar chart, and destructive actions require confirmation.

**Passing patterns:**
- List screen: `AsyncValue.when` covers loading, error (with retry button), and empty/data states (`habit_list_screen.dart:91-114`) — excellent pattern
- Form screen: `isLoading` prop passed to AppButton to disable during save (`habit_form_screen.dart:365`)
- Delete: confirmation dialog with consequence description before executing destructive action (`habit_form_screen.dart:158-179`)
- Check-in animation: 200ms scale bounce + haptic provides perceptible feedback that the tap registered
- Milestone haptics: light at every check-in, medium at 7/30/100 day streaks

**Issues:**
- `habit_detail_screen.dart:114-119` — Error during initial data load is communicated via SnackBar then disappears, leaving the user on a screen that shows `_habit == null` body (the "Habit not found" state). There is no retry mechanism. The user must navigate back and re-enter the screen to try again.
- `habit_list_screen.dart:173-178` — `onCheckIn` callback (`checkIn` via Riverpod notifier) can fail if the Supabase call fails, but there is no catch around the `await ref.read(habitListProvider.notifier).checkIn(...)` call in `_buildHabitList`. A failed check-in would silently not update the UI with no user feedback.
- `habit_detail_screen.dart` — When the detail screen loads, the `_habit` data is fetched independently of the `habitListProvider`. If the user navigates back to the list, the list may show stale data (e.g., streak from before re-entry). Consider calling `ref.invalidate(habitListProvider)` in `dispose()` or after a successful check-in flow.
- No `Semantics` or `Tooltip` annotations on the FAB, the CheckInButton, or the icon-only edit button in the detail AppBar (`habit_detail_screen.dart:283-288`). The edit `IconButton` has only `icon: const Icon(Icons.edit)` with no `tooltip` parameter — Flutter's `IconButton` will use the tooltip as the accessibility label.

---

## Files Audited

**Screens:**
- `lib/features/habits/presentation/screens/habit_list_screen.dart`
- `lib/features/habits/presentation/screens/habit_form_screen.dart`
- `lib/features/habits/presentation/screens/habit_detail_screen.dart`

**Widgets:**
- `lib/features/habits/presentation/widgets/check_in_button.dart`
- `lib/features/habits/presentation/widgets/habit_card.dart`
- `lib/features/habits/presentation/widgets/stat_card.dart`
- `lib/features/habits/presentation/widgets/period_selector.dart`
- `lib/features/habits/presentation/widgets/habit_heat_map.dart`
- `lib/features/habits/presentation/widgets/habit_bar_chart.dart`

**Domain / Theme (reference):**
- `lib/features/habits/domain/streak_calculator.dart`
- `lib/core/theme/app_theme.dart`

**Registry audit:** Not applicable (no `components.json` found — shadcn not initialized).
