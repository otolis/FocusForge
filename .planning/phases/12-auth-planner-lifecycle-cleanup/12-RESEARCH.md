# Phase 12: Auth, Planner & Lifecycle Cleanup - Research

**Researched:** 2026-03-28
**Domain:** Flutter UI conditionals, Dart async patterns, FCM subscription lifecycle, PostgreSQL RLS policies
**Confidence:** HIGH

## Summary

Phase 12 addresses five independent bugs/rough edges across four subsystems: auth screens, planner import, FCM lifecycle, and board RLS. Each fix is narrowly scoped and well-understood from the codebase analysis. No new libraries are needed -- all changes use existing Flutter, Dart, Firebase, and PostgreSQL primitives.

The auth fix conditionally hides Google sign-in buttons based on the placeholder client ID value in `AuthRepository.webClientId`. The planner fix adds source linkage columns (`source_type`, `source_id`) to `plannable_items` and changes the import loop from fire-and-forget to sequential `await`. The FCM fix stores the `onTokenRefresh` `StreamSubscription` and cancels it on sign-out. The RLS fix adds a new policy on `profiles` allowing co-members of shared boards to read each other's profiles.

**Primary recommendation:** Implement each fix as an independent task -- they touch different files and have no interdependencies.

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
- Detect placeholder Google client ID by checking if it equals `'YOUR_WEB_CLIENT_ID'` or is empty -- conditionally hide Google sign-in buttons on login/register screens
- Make planner import idempotent by tracking source linkage (`source_type` + `source_id` on time_blocks) -- skip if already exists for that source
- Fix sequential addItem by awaiting each call in a for-loop instead of fire-and-forget or Future.wait
- Store the FCM `onTokenRefresh` `StreamSubscription` in NotificationService, call `.cancel()` in `clearToken()`/logout flow
- Add RLS policy on `profiles` table allowing SELECT when the requesting user is a co-member of any shared board with the profile owner

### Claude's Discretion
- Migration structure for source linkage columns and RLS policy
- Exact conditional widget logic for hiding Google buttons
- Error handling patterns

### Deferred Ideas (OUT OF SCOPE)
None -- discussion stayed within phase scope.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|-----------------|
| AUTH-01 | Google sign-in buttons hidden in login/register screens while `YOUR_WEB_CLIENT_ID` placeholder is committed | Codebase analysis of `AuthRepository.webClientId`, `LoginScreen`, `RegisterScreen`, and `SocialSignInButton` provides exact insertion points |
| PLAN-01 | Planner import is idempotent (tracks source linkage to prevent duplicate imports) | Analysis of `plannable_items` table schema, `_importRealItems()`, `PlannableItemsNotifier.addItem()`, and `PlannerRepository.addItem()` reveals where source tracking columns and duplicate-skip logic go |
| PLAN-02 | `_importRealItems()` awaits each `addItem()` call to prevent race conditions | Direct analysis of `_importRealItems()` in `planner_screen.dart` shows fire-and-forget for-loop on line 373 |
| LIFE-01 | FCM `onTokenRefresh` subscription stored and cancelled on sign-out to prevent accumulation | Analysis of `NotificationService.manageFcmToken()` (line 501) shows unassigned `.listen()`, and `clearToken()` (line 509) has no subscription cancellation |
| LIFE-02 | Board member profile RLS policy allows board co-members to read each other's profiles | Analysis of `00001_create_profiles.sql` RLS policies (own-profile only), `BoardMemberRepository.getMembers()` (profile fetch in try/catch), and `is_board_member()` helper from `00008_fix_board_rls_recursion.sql` |
</phase_requirements>

## Standard Stack

No new libraries needed. All fixes use existing project dependencies:

### Core (Already in project)
| Library | Purpose | Relevance to Phase |
|---------|---------|-------------------|
| flutter / dart:async | StreamSubscription lifecycle | LIFE-01: Store and cancel FCM subscription |
| supabase_flutter | Database, Auth, RLS | PLAN-01: Migration; LIFE-02: RLS policy |
| firebase_messaging | FCM token management | LIFE-01: onTokenRefresh subscription |
| flutter_riverpod | State management | AUTH-01: Conditional UI; PLAN-01/02: Import flow |

## Architecture Patterns

### Pattern 1: Conditional Widget Visibility Based on Configuration

**What:** Hide Google sign-in UI elements when the client ID is a placeholder value.
**Where:** `LoginScreen` (line 171) and `RegisterScreen` (line 198) both render `SocialSignInButton` unconditionally. Also the "or" divider on lines 154-168 (login) and 180-196 (register) should be hidden.
**Approach:** Create a static getter or top-level constant `isGoogleSignInConfigured` in `AuthRepository` that returns `false` when `webClientId` starts with `'YOUR_WEB_CLIENT_ID'` or is empty. Wrap the divider + `SocialSignInButton` in a conditional.

```dart
// In AuthRepository:
static bool get isGoogleSignInConfigured =>
    webClientId.isNotEmpty &&
    !webClientId.startsWith('YOUR_WEB_CLIENT_ID');

// In LoginScreen / RegisterScreen build():
if (AuthRepository.isGoogleSignInConfigured) ...[
  // "or" divider
  Row(...),
  const SizedBox(height: 16),
  // Google Sign-In button
  SocialSignInButton(...),
],
```

**Key insight:** The constant `webClientId` in `AuthRepository` (line 18-19 of auth_repository.dart) currently has the value `'YOUR_WEB_CLIENT_ID.apps.googleusercontent.com'`. The check needs to handle both the full placeholder string and the case where someone empties it.

### Pattern 2: Idempotent Import with Source Linkage

**What:** Prevent duplicate plannable items when importing tasks/habits multiple times.
**Where:** `plannable_items` table needs `source_type` (text) and `source_id` (text) columns. The import flow in `planner_screen.dart` `_importRealItems()` (line 360-382) creates items from `realPlannableItemsProvider`.
**Approach:**
1. **Migration:** Add `source_type` (nullable text, 'task' or 'habit') and `source_id` (nullable text, UUID of source task/habit) columns to `plannable_items`. Add a unique index on `(user_id, plan_date, source_type, source_id)` WHERE `source_type IS NOT NULL` to enforce idempotency at the DB level.
2. **Repository:** Extend `PlannerRepository.addItem()` to accept optional `sourceType` and `sourceId` parameters.
3. **Model:** Extend `PlannableItem` to include `sourceType` and `sourceId` fields.
4. **Import logic:** Before inserting, query existing items for the date and check if a matching `source_type`/`source_id` already exists. Skip if it does.

```dart
// In PlannerRepository:
Future<PlannableItem> addItem({
  required String userId,
  required String title,
  required int durationMinutes,
  required EnergyLevel energyLevel,
  required DateTime planDate,
  String? sourceType,
  String? sourceId,
}) async {
  final data = await _client
      .from('plannable_items')
      .insert({
        'user_id': userId,
        'title': title,
        'duration_minutes': durationMinutes,
        'energy_level': energyLevel.name,
        'plan_date': planDate.toIso8601String().split('T').first,
        if (sourceType != null) 'source_type': sourceType,
        if (sourceId != null) 'source_id': sourceId,
      })
      .select()
      .single();
  return PlannableItem.fromJson(data);
}
```

**Deduplication approach:** Use a partial unique index in PostgreSQL: `CREATE UNIQUE INDEX ... ON plannable_items (user_id, plan_date, source_type, source_id) WHERE source_type IS NOT NULL`. This allows manual items (null source) to coexist freely while preventing duplicate imports. On conflict, use `ON CONFLICT DO NOTHING` via Supabase upsert or check client-side before inserting.

**Alternative (simpler):** Query existing items for the date, build a Set of `(source_type, source_id)` pairs, skip items already present. This avoids needing `ON CONFLICT` handling.

### Pattern 3: Sequential Async in Import Loop

**What:** The `_importRealItems()` method fires `addItem()` calls without awaiting them.
**Where:** `planner_screen.dart` lines 372-378:
```dart
for (final item in realItems) {
  notifier.addItem(
    title: item.title,
    durationMinutes: item.durationMinutes,
    energyLevel: item.energyLevel,
  );
}
```
`addItem()` is a `Future<void>` (defined in `PlannableItemsNotifier`, line 49-62). It inserts a row then calls `loadItems()`. Without `await`, all inserts fire simultaneously and each `loadItems()` call races.

**Fix:** Make `_importRealItems()` async, `await` each call:
```dart
Future<void> _importRealItems() async {
  // ... existing validation ...
  for (final item in realItems) {
    await notifier.addItem(
      title: item.title,
      durationMinutes: item.durationMinutes,
      energyLevel: item.energyLevel,
      sourceType: item.sourceType,  // task or habit
      sourceId: item.sourceId,      // original item ID
    );
  }
  // ... SnackBar ...
}
```

**Performance note:** Each `addItem()` does insert + `loadItems()`. With sequential awaiting, N items means N round-trips. For the common case (5-15 items), this is acceptable (~1-3 seconds). An optimization would be a bulk-insert method, but that is out of scope per the locked decision.

### Pattern 4: StreamSubscription Lifecycle for FCM Token Refresh

**What:** `manageFcmToken()` creates an `onTokenRefresh` listener (line 501) but never stores the `StreamSubscription`. On repeated sign-in/sign-out cycles, subscriptions accumulate.
**Where:** `NotificationService` (singleton), `manageFcmToken()` method.
**Fix:**
```dart
class NotificationService {
  // ... existing fields ...
  StreamSubscription<String>? _tokenRefreshSubscription;

  Future<void> manageFcmToken(String userId, NotificationRepository repo) async {
    // Cancel any previous subscription first
    await _tokenRefreshSubscription?.cancel();

    final token = await FirebaseMessaging.instance.getToken();
    if (token != null) {
      await repo.storeFcmToken(userId, token);
    }

    _tokenRefreshSubscription = FirebaseMessaging.instance.onTokenRefresh.listen(
      (newToken) {
        repo.storeFcmToken(userId, newToken);
      },
    );
  }

  Future<void> clearToken(String userId, NotificationRepository repo) async {
    // Cancel token refresh subscription
    await _tokenRefreshSubscription?.cancel();
    _tokenRefreshSubscription = null;

    await repo.clearFcmToken(userId);
    await FirebaseMessaging.instance.deleteToken();
  }
}
```

**Key insight:** Because `NotificationService` is a singleton, the subscription field persists across the app lifecycle. Cancelling in both `manageFcmToken()` (before re-subscribing) and `clearToken()` (on sign-out) ensures no leaks.

### Pattern 5: Board Co-Member Profile RLS Policy

**What:** The `profiles` table only allows `SELECT` of own profile (line 19-21 of `00001_create_profiles.sql`). When `BoardMemberRepository.getMembers()` queries profiles for all board members (lines 37-40), it fails for co-member profiles that aren't the current user's.
**Where:** The try/catch at line 44-48 catches this silently, resulting in members without names/avatars.
**Fix:** Add an RLS policy using the existing `is_board_member()` helper function:

```sql
-- Migration: 00012_board_comember_profile_visibility.sql
-- Allow board co-members to see each other's profile (display_name, avatar_url).
-- Uses the existing is_board_member() SECURITY DEFINER helper from migration 00008.

CREATE POLICY "Board co-members can view profiles"
  ON public.profiles FOR SELECT TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.board_members bm1
      JOIN public.board_members bm2 ON bm1.board_id = bm2.board_id
      WHERE bm1.user_id = auth.uid()
      AND bm2.user_id = profiles.id
    )
  );
```

**Important:** This policy uses a direct join on `board_members` which could trigger the same RLS recursion that `00008` fixed. However, this is a policy on `profiles`, not on `board_members` -- so querying `board_members` from within a `profiles` policy does not recurse (the `board_members` SELECT policy uses `is_board_member()` which is SECURITY DEFINER and bypasses RLS).

**Alternative (safer, recommended):** Create a new SECURITY DEFINER helper to avoid any recursion risk:

```sql
CREATE OR REPLACE FUNCTION public.shares_board_with(p_user_id uuid)
RETURNS boolean
LANGUAGE sql
SECURITY DEFINER
SET search_path = ''
STABLE
AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.board_members bm1
    JOIN public.board_members bm2 ON bm1.board_id = bm2.board_id
    WHERE bm1.user_id = auth.uid()
    AND bm2.user_id = p_user_id
    AND bm1.user_id != bm2.user_id
  );
$$;

CREATE POLICY "Board co-members can view profiles"
  ON public.profiles FOR SELECT TO authenticated
  USING (
    id = auth.uid()  -- own profile (keep existing behavior)
    OR public.shares_board_with(id)
  );
```

**Decision:** Use the SECURITY DEFINER helper approach. It is consistent with the project's established pattern from migration 00008 and eliminates any risk of RLS recursion. The existing "Users can view own profile" policy should be dropped and merged into the new policy (or kept alongside -- PostgreSQL ORs multiple SELECT policies).

**Note on multiple SELECT policies:** PostgreSQL evaluates all SELECT policies with OR semantics. So the existing "Users can view own profile" policy can remain -- adding a second policy will allow access when EITHER condition is true. No need to drop the old one.

### Anti-Patterns to Avoid
- **Unawaited futures in loops:** The current `_importRealItems()` fires off async calls without `await`, causing race conditions. Always `await` in sequential loops when operations depend on each other.
- **Unmanaged stream subscriptions:** Creating `.listen()` without storing the `StreamSubscription` means no ability to cancel. Always store and cancel subscriptions.
- **Hardcoded UI that depends on unconfigured services:** Showing Google sign-in when no client ID is configured leads to confusing errors. Feature-flag UI based on configuration readiness.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Duplicate import detection | Client-side set tracking only | Partial unique index in PostgreSQL + client-side pre-check | Database enforces correctness even if client code has bugs |
| RLS helper for co-membership | Inline subquery in policy | SECURITY DEFINER function | Avoids RLS recursion risk, consistent with project pattern |
| Google availability detection | Complex runtime detection | Static check on constant value | Compile-time constant, no runtime overhead |

## Common Pitfalls

### Pitfall 1: RLS Policy Recursion on board_members
**What goes wrong:** Adding a policy on `profiles` that queries `board_members` could trigger recursion if `board_members` RLS evaluates a query on `profiles`.
**Why it happens:** PostgreSQL evaluates RLS policies on each table access, and circular references cause infinite loops.
**How to avoid:** Use SECURITY DEFINER helper functions (established pattern in this project). The helper bypasses RLS on `board_members` entirely.
**Warning signs:** Error `42P17` (infinite recursion detected in policy for relation).

### Pitfall 2: Fire-and-Forget Futures in Dart
**What goes wrong:** `addItem()` returns a Future that includes `loadItems()`. Without `await`, all inserts fire simultaneously, each `loadItems()` call races, and the final state may be missing items.
**Why it happens:** Dart doesn't warn about unawaited futures in for-loops by default.
**How to avoid:** Always `await` async calls in loops when order matters. The `unawaited_futures` lint rule can catch this.
**Warning signs:** Items appear and disappear during import, or fewer items than expected.

### Pitfall 3: Singleton Subscription Accumulation
**What goes wrong:** Each `manageFcmToken()` call creates a new `onTokenRefresh` listener. Since `NotificationService` is a singleton, the old listener is never cancelled. After N sign-in/sign-out cycles, N listeners exist, each calling `storeFcmToken` with potentially stale user IDs.
**Why it happens:** `.listen()` returns a `StreamSubscription` that was discarded (not stored).
**How to avoid:** Store the subscription in a field, cancel before re-subscribing, cancel on sign-out.
**Warning signs:** Multiple FCM token store calls logged per token refresh event.

### Pitfall 4: Partial Unique Index vs Full Unique Constraint
**What goes wrong:** A full unique constraint on `(user_id, plan_date, source_type, source_id)` would prevent multiple manual items (where source_type IS NULL) because NULL = NULL is not true in PostgreSQL comparisons, meaning multiple NULLs are actually allowed. However, the semantics are confusing.
**Why it happens:** PostgreSQL treats NULLs as distinct in unique constraints (two rows with NULL source_type and NULL source_id are both allowed).
**How to avoid:** Use a partial unique index with `WHERE source_type IS NOT NULL` for clarity. Manual items (NULL source) are unrestricted; imported items are deduplicated.
**Warning signs:** Unexpected constraint violations or unexpected duplicates.

### Pitfall 5: Replacing vs Augmenting SELECT Policies
**What goes wrong:** Accidentally dropping the existing "Users can view own profile" policy when adding the co-member policy would break profile access for users without shared boards.
**Why it happens:** Thinking you need to replace the old policy with a combined one.
**How to avoid:** PostgreSQL ORs all SELECT policies. Simply add the new policy alongside the existing one. Both conditions are evaluated, and access is granted if either is true.
**Warning signs:** Users unable to see their own profile after migration.

## Code Examples

### Example 1: Checking Placeholder Client ID
```dart
// In lib/features/auth/data/auth_repository.dart
// Add static getter after webClientId declaration (line 19):
static bool get isGoogleSignInConfigured =>
    webClientId.isNotEmpty &&
    !webClientId.startsWith('YOUR_WEB_CLIENT_ID');
```

### Example 2: Migration for Source Linkage Columns
```sql
-- supabase/migrations/00012_planner_source_linkage_and_profile_rls.sql

-- Add source tracking columns to plannable_items for idempotent import
ALTER TABLE public.plannable_items
  ADD COLUMN source_type text,
  ADD COLUMN source_id text;

-- Partial unique index: prevents duplicate imports while allowing
-- multiple manual items (source_type IS NULL)
CREATE UNIQUE INDEX idx_plannable_items_source_unique
  ON public.plannable_items (user_id, plan_date, source_type, source_id)
  WHERE source_type IS NOT NULL;

-- SECURITY DEFINER helper: checks if caller shares any board with target user
CREATE OR REPLACE FUNCTION public.shares_board_with(p_user_id uuid)
RETURNS boolean
LANGUAGE sql
SECURITY DEFINER
SET search_path = ''
STABLE
AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.board_members bm1
    JOIN public.board_members bm2 ON bm1.board_id = bm2.board_id
    WHERE bm1.user_id = auth.uid()
    AND bm2.user_id = p_user_id
    AND bm1.user_id != bm2.user_id
  );
$$;

-- Allow board co-members to read each other's profiles
CREATE POLICY "Board co-members can view profiles"
  ON public.profiles FOR SELECT TO authenticated
  USING (public.shares_board_with(id));

-- Revoke direct anon access to helper (authenticated only)
REVOKE EXECUTE ON FUNCTION public.shares_board_with(uuid) FROM anon;
GRANT EXECUTE ON FUNCTION public.shares_board_with(uuid) TO authenticated;
```

### Example 3: Sequential Await in Import Loop
```dart
// In planner_screen.dart _importRealItems():
Future<void> _importRealItems() async {
  final userId = _userId;
  if (userId.isEmpty) return;

  final realItems = ref.read(realPlannableItemsProvider);
  if (realItems.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('No pending tasks or habits to import')),
    );
    return;
  }

  final notifier = ref.read(plannableItemsProvider(userId).notifier);
  int importedCount = 0;

  for (final item in realItems) {
    await notifier.addItem(
      title: item.title,
      durationMinutes: item.durationMinutes,
      energyLevel: item.energyLevel,
      sourceType: /* 'task' or 'habit' -- need to determine */,
      sourceId: item.id,
    );
    importedCount++;
  }

  if (mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Imported $importedCount items')),
    );
  }
}
```

### Example 4: FCM Subscription Lifecycle
```dart
// In NotificationService:
StreamSubscription<String>? _tokenRefreshSubscription;

Future<void> manageFcmToken(
  String userId,
  NotificationRepository repo,
) async {
  await _tokenRefreshSubscription?.cancel();

  final token = await FirebaseMessaging.instance.getToken();
  if (token != null) {
    await repo.storeFcmToken(userId, token);
  }

  _tokenRefreshSubscription =
      FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
    repo.storeFcmToken(userId, newToken);
  });
}

Future<void> clearToken(
  String userId,
  NotificationRepository repo,
) async {
  await _tokenRefreshSubscription?.cancel();
  _tokenRefreshSubscription = null;

  await repo.clearFcmToken(userId);
  await FirebaseMessaging.instance.deleteToken();
}
```

## State of the Art

No changes to the tech landscape are relevant for this phase. All fixes use established patterns already in the codebase.

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Direct subqueries in RLS | SECURITY DEFINER helpers | Phase 8 (00008 migration) | Prevents recursion; phase 12 follows same pattern |

## Open Questions

1. **Source type determination in realPlannableItemsProvider**
   - What we know: `realPlannableItemsProvider` creates `PlannableItem` objects from tasks and habits. The source item's original ID is preserved as `PlannableItem.id`.
   - What's unclear: There's no explicit `sourceType` field on `PlannableItem` from the bridge provider. We need a way to distinguish task-sourced vs habit-sourced items.
   - Recommendation: The bridge provider already knows the source type (it iterates tasks then habits separately). Either add a `sourceType` field to the bridge output, or pass the type information alongside the item during import. The simplest approach: add optional `sourceType`/`sourceId` fields to `PlannableItem` model (populated by the bridge, null for manually created items).

2. **Handling import of items that already exist via unique index conflict**
   - What we know: PostgreSQL partial unique index will reject duplicates with an error.
   - What's unclear: Should we use `ON CONFLICT DO NOTHING` at the repository level, or pre-filter on the client?
   - Recommendation: Use client-side pre-filtering (query existing items, skip already-imported ones) for a better UX (accurate import count). The unique index serves as a safety net, not the primary mechanism. Wrap the insert in try/catch to gracefully handle constraint violations.

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | flutter_test + mockito |
| Config file | pubspec.yaml (test dependencies) |
| Quick run command | `flutter test test/unit/` |
| Full suite command | `flutter test` |

### Phase Requirements -> Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| AUTH-01 | Google sign-in button hidden when client ID is placeholder | unit | `flutter test test/unit/auth/auth_repository_test.dart -x` | Existing file, new test needed |
| PLAN-01 | Import skips already-imported items (idempotent) | unit | `flutter test test/unit/planner/planner_import_test.dart -x` | Wave 0 |
| PLAN-02 | Each addItem call completes before next begins | unit | `flutter test test/unit/planner/planner_import_test.dart -x` | Wave 0 |
| LIFE-01 | FCM subscription cancelled on sign-out | unit | `flutter test test/unit/features/notifications/notification_service_test.dart -x` | Existing file, new test needed |
| LIFE-02 | Board co-member profile visibility | manual-only | SQL migration verified via `supabase db push` | N/A (RLS policy, no Dart test) |

### Sampling Rate
- **Per task commit:** `flutter test test/unit/`
- **Per wave merge:** `flutter test`
- **Phase gate:** Full suite green before `/gsd:verify-work`

### Wave 0 Gaps
- [ ] `test/unit/planner/planner_import_test.dart` -- covers PLAN-01, PLAN-02 (idempotent import, sequential await)
- [ ] `test/unit/auth/auth_repository_test.dart` -- add test for `isGoogleSignInConfigured` getter (AUTH-01)
- [ ] `test/unit/features/notifications/notification_service_test.dart` -- add test for subscription lifecycle (LIFE-01)

## Sources

### Primary (HIGH confidence)
- Codebase analysis: `lib/features/auth/data/auth_repository.dart` -- webClientId constant on line 18-19
- Codebase analysis: `lib/features/auth/presentation/screens/login_screen.dart` -- Google button at line 171
- Codebase analysis: `lib/features/auth/presentation/screens/register_screen.dart` -- Google button at line 198
- Codebase analysis: `lib/features/planner/presentation/screens/planner_screen.dart` -- `_importRealItems()` at line 360-382
- Codebase analysis: `lib/features/planner/presentation/providers/plannable_items_provider.dart` -- `addItem()` at line 49-62
- Codebase analysis: `lib/core/services/notification_service.dart` -- `manageFcmToken()` at line 492-504, `clearToken()` at line 509-515
- Codebase analysis: `supabase/migrations/00001_create_profiles.sql` -- existing RLS policies
- Codebase analysis: `supabase/migrations/00008_fix_board_rls_recursion.sql` -- SECURITY DEFINER pattern
- Codebase analysis: `lib/features/boards/data/board_member_repository.dart` -- profile fetch in try/catch at lines 36-48

### Secondary (MEDIUM confidence)
- PostgreSQL documentation: Multiple SELECT policies are ORed together (standard PostgreSQL RLS behavior)
- PostgreSQL documentation: Partial unique indexes with WHERE clause
- Dart language: `StreamSubscription` cancellation pattern

### Tertiary (LOW confidence)
None -- all findings verified from codebase.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - No new libraries, all existing project dependencies
- Architecture: HIGH - All patterns derived from direct codebase analysis, exact line numbers identified
- Pitfalls: HIGH - Each pitfall identified from actual bugs visible in the current code

**Research date:** 2026-03-28
**Valid until:** 2026-04-28 (stable -- internal codebase fixes, no external dependency changes)
