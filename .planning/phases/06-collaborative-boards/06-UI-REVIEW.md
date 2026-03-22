# Phase 6 — UI Review

**Audited:** 2026-03-22
**Baseline:** Abstract 6-pillar standards (no UI-SPEC.md)
**Screenshots:** Not captured (no dev server detected — Flutter mobile app, code-only audit)

---

## Pillar Scores

| Pillar | Score | Key Finding |
|--------|-------|-------------|
| 1. Copywriting | 3/4 | CTAs are specific and action-oriented; "Cancel" in dialogs is acceptable convention; one raw error dump in board list error state |
| 2. Visuals | 3/4 | Strong visual hierarchy throughout; settings icon button is a dead no-op, breaking the navigation affordance |
| 3. Color | 2/4 | Priority colors (`Colors.red/orange/blue/grey`) and danger zone (`Colors.red`) use hardcoded Material palette values instead of theme tokens |
| 4. Typography | 4/4 | Consistent Material 3 textTheme tokens throughout; one minor raw `fontSize: 9` override in assignee avatar |
| 5. Spacing | 3/4 | Mostly consistent 4/8/12/16/24px scale; two non-standard values (6px vertical between card rows, 20px top padding in card sheet) |
| 6. Experience Design | 3/4 | Loading, error, and empty states all present; settings button is tappable but fires no action; assignee field shows raw UUID instead of display name |

**Overall: 18/24**

---

## Top 3 Priority Fixes

1. **Settings button is a dead no-op** — Users tap the settings gear icon on the board detail screen and nothing happens. This silently breaks access to the entire member management flow. Fix: replace the empty `onPressed` body in `board_detail_screen.dart:167` with `context.push('/boards/${widget.boardId}/settings')`.

2. **Hardcoded `Colors.red/orange/blue/grey` for priority indicators** — Priority colors are duplicated between `kanban_card_widget.dart:28-31` and `card_detail_sheet.dart:60-63` using raw Material palette lookups. This breaks dark-mode contrast guarantees and creates a maintenance split. Fix: extract a `priorityColor(int priority, ColorScheme cs)` utility returning `cs.error`, `cs.tertiary`, `cs.primary`, `cs.outlineVariant` respectively, and delete both duplicate maps.

3. **Assignee field shows raw UUID** — `card_detail_sheet.dart:209` renders `widget.card.assigneeId` (a UUID string like `"3f2504e0-4f89-11d3-..."`) as the display name when an assignee is set. Users see a meaningless identifier. Fix: join the assignee ID against the board's `members` list from `boardDetailProvider` and display `member.displayName` instead.

---

## Detailed Findings

### Pillar 1: Copywriting (3/4)

**Strengths:**
- Empty state copy is specific and encouraging: "No boards yet" + "Create your first board" (`board_list_screen.dart:59-68`)
- Empty column placeholder uses "Add card" — clear and action-oriented (`empty_column_placeholder.dart:44`)
- Destructive confirmations include consequence language: "This action cannot be undone. All columns, cards, and member associations will be permanently removed." (`board_settings_screen.dart:165-168`)
- Invite success toast includes context: "Invited {email} as {role}" (`board_settings_screen.dart:53`)
- "Danger Zone" section heading is recognizable convention (`board_settings_screen.dart:394`)

**Issues:**
- Board list error state renders `error.toString()` directly at `board_list_screen.dart:34` — Supabase/network exceptions will produce raw technical strings visible to users. Should be replaced with a human-readable fallback like "Couldn't load your boards. Check your connection and try again."
- Board settings error state at `board_settings_screen.dart:220` also renders raw: `'Error: ${state.error}'`
- Board detail AppBar title shows `'Loading...'` at `board_detail_screen.dart:127` while loading — minor but slightly awkward; a placeholder like the board name or a shimmer would be cleaner.
- "Cancel" in confirmation dialogs is acceptable UX convention; not flagged.

---

### Pillar 2: Visuals (3/4)

**Strengths:**
- Board list grid card uses `surfaceContainerLow` background with 16px rounded corners and elevation 0 — consistent with Material 3 tonal surface pattern (`board_grid_card.dart:32-36`)
- Kanban card priority indicator is a 4px left-side color bar (`kanban_card_widget.dart:58-65`), a well-established Kanban convention giving instant scanability
- Empty column placeholder uses a dashed-style outlined container with centered add icon — matches the context spec requirement exactly (`empty_column_placeholder.dart:24-50`)
- PresenceAvatar uses 50% opacity dimming for offline state + green dot for online — clear and distinct visual states (`presence_avatar.dart:29-53`)
- MemberAvatarRow uses negative-offset overlapping avatars (+N chip) matching context spec requirement for `>4 members` (`member_avatar_row.dart:51-76`)
- Column header card-count badge uses `primaryContainer` pill — creates visual rhythm without competing with the column name

**Issues:**
- Settings icon button in `board_detail_screen.dart:165-169` is rendered but fires no navigation — the visual affordance (tappable icon) is present but the behavior is absent. Users will discover a dead interaction point.
- `board_grid_card.dart` does not render member avatar chips in the card body, only column count and creation date — the context spec called for "member avatar chips" on the grid cards. `memberCount` parameter exists in the widget signature but is unused and always defaults to `null`.
- No tooltip on the FAB (`board_list_screen.dart:90-93`) — icon-only interactive control without an accessible label. Should add `tooltip: 'Create board'`.
- No tooltip on the send invite `IconButton` at `board_settings_screen.dart:365-368` (just `Icons.send_rounded` with no semantic label).

---

### Pillar 3: Color (2/4)

**Hardcoded color values found:**

Priority color mapping duplicated in two files:
- `kanban_card_widget.dart:28-31` — `Colors.red`, `Colors.orange`, `Colors.blue`, `Colors.grey`
- `card_detail_sheet.dart:60-63` — same four values

Danger zone / destructive action hardcoded red:
- `board_settings_screen.dart:96` — `TextStyle(color: Colors.red)` on "Remove" text
- `board_settings_screen.dart:177` — `TextStyle(color: Colors.red)` on "Delete" text
- `board_settings_screen.dart:302` — `color: Colors.red` on "Danger Zone" title
- `board_settings_screen.dart:400` — `color: Colors.red` on delete icon
- `board_settings_screen.dart:403` — `TextStyle(color: Colors.red)` on "Delete Board" text

Presence online indicator:
- `presence_avatar.dart:45` — `color: Colors.green` for the online dot

**Assessment:**
The theme correctly defines `colorScheme.error` for destructive actions, which already maps to red in the light scheme. All five `Colors.red` instances in `board_settings_screen.dart` should use `context.colorScheme.error` / `Theme.of(context).colorScheme.error` instead. The priority colors are a harder case — they are semantic (P1 = urgent = red) and widely understood, but they will break in high-contrast or custom theme scenarios. The `Colors.green` presence dot has no semantic equivalent in the Material 3 spec; a named constant like `AppColors.onlineGreen` would at least centralize it.

**Theme system usage (positive):**
- All surface, container, and outline colors use `context.colorScheme.*` tokens throughout — no hardcoded hex values or `Color(0x...)` literals found.

---

### Pillar 4: Typography (4/4)

**textTheme tokens in use:**
- `titleMedium` — board name in grid card, card title in detail sheet, board name in settings
- `titleSmall` — column header name, "Members" section header, "Invite Member" header, "Danger Zone" header
- `bodyMedium` — card titles in Kanban, description field, date/assignee rows, error text
- `bodySmall` — column count in grid card, creation date in grid card, due date on kanban card, placeholder description
- `labelMedium` — "Priority" field label in card detail sheet
- `labelSmall` — column card count badge, assignee avatar initial, overflow chip "+N"

That is 6 distinct text roles, all sourced from `context.textTheme.*` — within the acceptable range for a feature-dense screen.

**Minor issue:**
- `kanban_card_widget.dart:110` overrides `fontSize: 9` inside a `labelSmall.copyWith()`. The `labelSmall` token is already 11sp in Material 3; forcing 9sp creates a micro-size that may be illegible at standard density. This is the single deviation from the token system.

**Font weights:**
- `FontWeight.w600` used for emphasis (board name, column header, card count badge, overflow chip) — consistent single weight used for emphasis only.
- `FontWeight.normal` as the baseline default.
- Only two distinct weights in use — clean.

---

### Pillar 5: Spacing (3/4)

**Standard 4-point grid values observed:**
- `EdgeInsets.all(16)` — grid padding, board grid card internal padding, settings list padding
- `EdgeInsets.all(8)` — empty column placeholder margin, column header horizontal
- `EdgeInsets.all(12)` — kanban card internal padding
- `EdgeInsets.symmetric(horizontal: 24, vertical: 12)` — card detail sheet padding
- `SizedBox(height: 16)` — standard section gap
- `SizedBox(height: 8)` — tight gap
- `SizedBox(height: 4)` — tight label gap
- `SizedBox(height: 24)` — section break before danger zone
- `SizedBox(width: 8)` — horizontal element gap

**Non-standard values:**
- `SizedBox(height: 6)` — used twice in `kanban_card_widget.dart:80` and `kanban_card_widget.dart:101` for spacing between card rows. Neither 4 nor 8 — breaks the 4-point grid. Use `SizedBox(height: 8)`.
- `SizedBox(height: 20)` — used in `card_detail_sheet.dart:110` as top padding after drag handle. Neither 16 nor 24. Use `SizedBox(height: 16)` or `SizedBox(height: 24)`.
- `EdgeInsets.symmetric(horizontal: 8, vertical: 2)` — card count badge padding in `column_header_widget.dart:61`. The `vertical: 2` is below the 4-point minimum. Acceptable for a badge but worth noting.
- `Transform.translate(offset: Offset(-6.0 * index, 0))` — avatar overlap offset of 6px in `member_avatar_row.dart:52`. Not a spacing unit per se (it's a visual overlap calculation), so this is acceptable.

**Overall:** The spacing system is predominantly 4-point grid compliant. The two non-standard SizedBox heights are low-impact but worth normalizing.

---

### Pillar 6: Experience Design (3/4)

**Loading states — present:**
- `board_list_screen.dart:28` — `CircularProgressIndicator` while board list loads
- `board_detail_screen.dart:125-129` — full-screen loading state with spinner
- `board_settings_screen.dart:210-214` — spinner while board detail loads for settings
- `card_detail_sheet.dart:223-225` — `AppButton` `isLoading` disables save and shows spinner during save

**Error states — present but inconsistent quality:**
- `board_list_screen.dart:29-43` — error state with raw exception text and Retry button
- `board_detail_screen.dart:132-156` — error state with raw error string and Retry button
- `board_settings_screen.dart:217-221` — error state with raw "Error: {message}" but no Retry action — user is stranded; this screen has no recovery path
- All mutation failures (invite, role change, remove, rename, delete) surface via `SnackBar` with raw exception string — 20 SnackBar occurrences across 4 files

**Empty states — present and polished:**
- Board list empty state: icon + "No boards yet" + "Create your first board" hint (`board_list_screen.dart:48-72`)
- Empty column placeholder: outlined dashed box with add icon + "Add card" (`empty_column_placeholder.dart`)
- Missing: no empty state on board settings if there are no members other than the owner (only the owner row would show, no explanatory text)

**Disabled states — present:**
- `card_detail_sheet.dart:223`, `234` — save and delete buttons disabled during save (`_isSaving ? null`)
- Column management (rename/delete/add) hidden for viewer role via `_canEdit` guard (`column_header_widget.dart:40-41`)
- Owner-only controls hidden via `isOwner` guard throughout `board_settings_screen.dart`

**Destructive action confirmations — present:**
- Column delete: dialog with `"Delete \"$columnName\" and all its cards? This cannot be undone."` (`column_header_widget.dart:162`)
- Card delete: dialog with "This cannot be undone." (`card_detail_sheet.dart:295-298`)
- Member remove: dialog with member name (`board_settings_screen.dart:83-100`)
- Board delete: detailed confirmation dialog (`board_settings_screen.dart:159-181`)

**Critical UX gap:**
- Settings icon button in `board_detail_screen.dart:167-169` has `onPressed: () { // Will be wired in Plan 03 }` — the comment was not removed and the navigation was not added. The route `/boards/:id/settings` exists in the router and `BoardSettingsScreen` is imported, but the button's callback is a no-op. This means the entire member management flow (invite, role change, presence) is inaccessible from the main board view.

**Secondary UX gap:**
- Assignee field in `card_detail_sheet.dart:209` renders `widget.card.assigneeId` directly. When an assignee is set, the field displays a raw UUID. The `boardDetailProvider` state includes `members`, so a display name lookup is feasible.

---

## Files Audited

**Screens (3):**
- `lib/features/boards/presentation/screens/board_list_screen.dart`
- `lib/features/boards/presentation/screens/board_detail_screen.dart`
- `lib/features/boards/presentation/screens/board_settings_screen.dart`

**Widgets (7):**
- `lib/features/boards/presentation/widgets/board_grid_card.dart`
- `lib/features/boards/presentation/widgets/kanban_card_widget.dart`
- `lib/features/boards/presentation/widgets/column_header_widget.dart`
- `lib/features/boards/presentation/widgets/empty_column_placeholder.dart`
- `lib/features/boards/presentation/widgets/card_detail_sheet.dart`
- `lib/features/boards/presentation/widgets/presence_avatar.dart`
- `lib/features/boards/presentation/widgets/member_avatar_row.dart`

**Providers (4):**
- `lib/features/boards/presentation/providers/board_list_provider.dart`
- `lib/features/boards/presentation/providers/board_detail_provider.dart`
- `lib/features/boards/presentation/providers/board_realtime_provider.dart`
- `lib/features/boards/presentation/providers/board_presence_provider.dart`

**Theme:**
- `lib/core/theme/app_theme.dart`

**Registry audit:** Not applicable — no `components.json` (shadcn not used; Flutter project).
