# Phase 10: RPC & Edge Function Security - Research

**Researched:** 2026-03-28
**Domain:** Supabase SECURITY DEFINER RPC hardening + Edge Function JWT enforcement
**Confidence:** HIGH

## Summary

This phase hardens all SECURITY DEFINER database functions to derive caller identity from `auth.uid()` instead of trusting client-supplied user IDs, enables JWT verification on Edge Functions, and updates client code to pass proper auth tokens. The codebase has six SECURITY DEFINER functions across three migration files, two Edge Functions with `verify_jwt = false`, and two client-side locations that manually override the SDK's automatic auth header with the anon key.

The security surface is well-bounded: four RPC functions need `auth.uid()` enforcement (`search_tasks`, `generate_recurring_instances`, `create_board_with_defaults`, `invite_board_member`), two helper functions already use `auth.uid()` correctly (`is_board_member`, `is_board_owner`, `is_board_editor`), two Edge Functions need `verify_jwt = true`, and two Dart files need their manual `Authorization` header removed. The `invite_board_member` function also lacks an ownership check -- any authenticated user can invite anyone to any board.

**Primary recommendation:** Create a single new migration (`00010_harden_rpc_functions.sql`) that rewrites the four vulnerable functions to use `auth.uid()`, adds REVOKE/GRANT EXECUTE restrictions, and leaves helper functions untouched. Change `verify_jwt = false` to `true` in `config.toml`. Remove the manual `Authorization: Bearer ${SupabaseConstants.anonKey}` headers from two Dart files so the SDK's automatic session JWT flows through.

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
All implementation choices are at Claude's discretion -- pure infrastructure/security phase. Key constraints:
- SQL migrations must be additive (new migration file, not modifying existing ones)
- Client-side changes must use the existing Supabase auth session token
- Edge Function JWT verification via config.toml `verify_jwt = true`
- REVOKE/GRANT approach for RPC access control

### Claude's Discretion
All implementation choices.

### Deferred Ideas (OUT OF SCOPE)
None -- discussion stayed within phase scope.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|-----------------|
| SEC-01 | SECURITY DEFINER RPCs derive caller identity from `auth.uid()` instead of trusting client-supplied user ID parameters | Rewrite `search_tasks`, `generate_recurring_instances`, `create_board_with_defaults`, `invite_board_member` to use `auth.uid()` -- see Architecture Patterns section |
| SEC-02 | Task RPCs (`search_tasks`, `generate_recurring_instances`) validate ownership via `auth.uid()` | Remove `p_user_id` param from `search_tasks`, use `auth.uid()` inline; add ownership check to `generate_recurring_instances` -- see Code Examples |
| SEC-03 | Board RPCs (`create_board_with_defaults`, `invite_board_member`) validate ownership/auth via `auth.uid()` | Replace `creator_id` param with `auth.uid()` in `create_board_with_defaults`; add board ownership assertion to `invite_board_member` -- see Code Examples |
| SEC-04 | Function permissions hardened with REVOKE/GRANT EXECUTE to restrict direct client invocation | REVOKE from `public, anon, authenticated` on privileged helpers; GRANT EXECUTE to `authenticated` only on user-facing RPCs -- see Architecture Patterns |
| SEC-05 | Edge Functions require valid JWT -- unauthenticated anon-key-only calls rejected | Set `verify_jwt = true` in `supabase/config.toml` for both functions -- see Standard Stack |
| SEC-06 | Client code passes user's auth token (not just anon key) when invoking Edge Functions | Remove manual `Authorization` header override from `planner_repository.dart` and `ai_rewrite_button.dart` -- SDK auto-includes session JWT -- see Code Examples |
</phase_requirements>

## Standard Stack

### Core
| Component | Version/File | Purpose | Why Standard |
|-----------|-------------|---------|--------------|
| PostgreSQL `auth.uid()` | Built-in Supabase | Server-side caller identity | Cryptographically derived from JWT -- cannot be forged by client |
| `SECURITY DEFINER` | PostgreSQL native | Bypass RLS for helper queries | Standard Supabase pattern for functions that need cross-user reads (e.g., `auth.users` email lookup) |
| `REVOKE/GRANT EXECUTE` | PostgreSQL native | Function-level access control | Supabase-recommended approach for restricting who can call specific functions |
| `verify_jwt = true` | `supabase/config.toml` | Edge Function gateway JWT enforcement | Supabase relay rejects requests without valid JWT before function code runs |

### Supporting
| Component | Location | Purpose | When to Use |
|-----------|----------|---------|-------------|
| `Supabase.instance.client.auth.currentSession?.accessToken` | Flutter SDK | User's JWT token | Already auto-set on FunctionsClient by SDK -- no manual usage needed |
| `SET search_path = ''` | SQL function definition | Prevent search_path injection | Always use on SECURITY DEFINER functions |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| REVOKE/GRANT per-function | Private schema for functions | More invasive -- requires PostgREST schema config changes; per-function REVOKE is simpler for targeted hardening |
| `verify_jwt = true` in config.toml | In-function JWT verification via `supabase.auth.getUser()` | Config.toml approach is simpler and rejects at the gateway level before function code runs; in-function verification is for when you need the user object |

## Architecture Patterns

### Migration Strategy
```
supabase/migrations/
  00003_create_boards.sql        # Original (DO NOT MODIFY)
  00004_create_tasks.sql         # Original (DO NOT MODIFY)
  00008_fix_board_rls_recursion.sql  # Original (DO NOT MODIFY)
  00009_board_table_view.sql     # Original (DO NOT MODIFY)
  00010_harden_rpc_functions.sql # NEW -- all security changes in one file
```

The new migration uses `CREATE OR REPLACE FUNCTION` to rewrite existing functions in-place. This is additive -- it does not require dropping/recreating dependent objects.

### Pattern 1: Replace Client-Supplied ID with auth.uid()

**What:** Remove user ID parameters from function signatures where the caller should not control identity. Use `auth.uid()` directly inside the function body.

**When to use:** Any SECURITY DEFINER function that currently accepts a `user_id` or `creator_id` parameter from the client.

**Key insight:** `auth.uid()` is available inside SECURITY DEFINER functions because it reads from the JWT context set by the Supabase request, not from the caller's PostgreSQL role. This is the foundational security primitive.

**Signature changes required:**
- `search_tasks(p_user_id uuid, p_query text)` becomes `search_tasks(p_query text)`
- `create_board_with_defaults(board_name text, creator_id uuid)` becomes `create_board_with_defaults(board_name text)`
- `invite_board_member` keeps its signature but adds an ownership assertion
- `generate_recurring_instances` keeps its signature but adds an ownership assertion

### Pattern 2: Ownership Assertion in SECURITY DEFINER Functions

**What:** Before performing a privileged operation, verify that `auth.uid()` owns (or has permission for) the target resource.

**When to use:** Functions like `invite_board_member` where the caller should only be allowed if they are the board owner, or `generate_recurring_instances` where the caller should only generate instances for their own tasks.

**Example pattern:**
```sql
-- Assert caller owns the board before allowing invite
IF NOT EXISTS (
  SELECT 1 FROM public.board_members
  WHERE board_id = target_board_id
  AND user_id = auth.uid()
  AND role = 'owner'
) THEN
  RAISE EXCEPTION 'Only board owners can invite members';
END IF;
```

### Pattern 3: REVOKE/GRANT for Function Access Control

**What:** Revoke default EXECUTE permissions from all roles, then selectively grant back to `authenticated` only for user-facing RPCs.

**When to use:** All SECURITY DEFINER functions. Helper functions like `is_board_member` should remain callable by `authenticated` since they are used in RLS policies. Privileged functions that should only be called internally should have EXECUTE revoked entirely.

**SQL pattern:**
```sql
-- Revoke from everyone first
REVOKE EXECUTE ON FUNCTION public.function_name FROM public, anon, authenticated;
-- Grant back to authenticated only
GRANT EXECUTE ON FUNCTION public.function_name TO authenticated;
```

**Important:** The `anon` and `authenticated` roles are custom Supabase roles separate from the PostgreSQL `public` pseudo-role. You MUST revoke from all three to fully restrict access.

### Pattern 4: SDK Auto-Auth for Edge Functions

**What:** The `supabase_flutter` SDK automatically sets the user's session JWT on the `FunctionsClient` via `setAuth()` when auth state changes. When `functions.invoke()` is called, this JWT is included as the `Authorization: Bearer` header automatically.

**When to use:** Always. Never manually override the Authorization header with the anon key.

**Current bug:** Both `planner_repository.dart` and `ai_rewrite_button.dart` manually set `'Authorization': 'Bearer ${SupabaseConstants.anonKey}'`, which **overrides** the SDK's automatically-set user JWT with the anon key. This is why `verify_jwt = false` was needed -- the anon key JWT has role `anon`, which would fail JWT verification if the function expects an authenticated user.

**Fix:** Remove the `headers` parameter entirely from both `functions.invoke()` calls. The SDK will automatically include the user's session JWT.

### Anti-Patterns to Avoid
- **Accepting user IDs as function parameters:** Never trust client-supplied identity. Use `auth.uid()` server-side.
- **Manually setting Authorization header with anon key:** Overrides the SDK's automatic session JWT. Just remove the header.
- **Forgetting to revoke from `public` role:** PostgreSQL grants EXECUTE to `public` by default. Revoking only from `anon` and `authenticated` leaves the `public` grant in place.
- **Using `SECURITY INVOKER` when you need to bypass RLS:** SECURITY DEFINER runs as the function owner (usually `postgres`), allowing cross-user queries like reading `auth.users`. SECURITY INVOKER runs as the caller and cannot bypass RLS.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Caller identity | Accepting user_id params and trusting client | `auth.uid()` built-in | Cryptographically derived from JWT -- unforgeable |
| JWT validation in Edge Functions | Manual token parsing/verification in function code | `verify_jwt = true` in config.toml | Gateway-level rejection before function code runs; simpler, more secure |
| Auth header management in Flutter | Manual `Authorization: Bearer` header construction | SDK auto-auth via `FunctionsClient.setAuth()` | SDK already handles token refresh, session changes, and header injection |
| Function access control | Custom middleware or request validation | PostgreSQL `REVOKE/GRANT EXECUTE` | Database-level enforcement -- cannot be bypassed by crafted API calls |

**Key insight:** Every security mechanism needed already exists in the Supabase/PostgreSQL stack. This phase is about using them correctly, not building new ones.

## Common Pitfalls

### Pitfall 1: Breaking Client Code by Changing Function Signatures
**What goes wrong:** Changing `search_tasks(p_user_id uuid, p_query text)` to `search_tasks(p_query text)` breaks the Dart client code that passes `p_user_id`.
**Why it happens:** PostgreSQL function overloading means the old 2-param version and new 1-param version can coexist, but the client calls the old signature.
**How to avoid:** Update client RPC calls in the same phase. `task_repository.dart` must change from `params: {'p_user_id': userId, 'p_query': query}` to `params: {'p_query': query}`. Similarly, `board_repository.dart` must remove `'creator_id': userId` from the `create_board_with_defaults` call.
**Warning signs:** `PostgrestException` with code `42883` (function does not exist) -- means the old signature was dropped but client still uses it.

### Pitfall 2: PostgreSQL Function Overloading Creates Ghost Functions
**What goes wrong:** `CREATE OR REPLACE FUNCTION search_tasks(p_query text)` does NOT replace `search_tasks(p_user_id uuid, p_query text)` -- it creates a second function with a different signature. The old insecure version remains callable.
**Why it happens:** PostgreSQL identifies functions by name + argument types, not just name.
**How to avoid:** Explicitly `DROP FUNCTION IF EXISTS public.search_tasks(uuid, text);` before creating the new version. Same for `create_board_with_defaults(text, uuid)`.
**Warning signs:** Both old and new function versions appear in `\df search_tasks` output.

### Pitfall 3: REVOKE on Helper Functions Breaks RLS Policies
**What goes wrong:** Revoking EXECUTE on `is_board_member` from `authenticated` breaks all board RLS policies that call it.
**Why it happens:** RLS policies execute in the context of the `authenticated` role. If `authenticated` cannot call `is_board_member`, every board SELECT/INSERT/UPDATE/DELETE fails.
**How to avoid:** Only revoke on truly internal functions. `is_board_member`, `is_board_owner`, `is_board_editor` MUST remain callable by `authenticated`. Apply REVOKE only to functions that should not be directly invoked via the PostgREST API (if any).
**Warning signs:** All board operations fail with "permission denied for function is_board_member".

### Pitfall 4: Edge Function Auth Token Missing on First Load
**What goes wrong:** If the app calls an Edge Function before the auth session is fully restored (e.g., during cold start), the SDK may not yet have set the user's JWT on the FunctionsClient.
**Why it happens:** `supabase_flutter` restores the session asynchronously. Early function calls may still have the anon key.
**How to avoid:** The app's auth flow already gates feature screens behind authentication. Edge Function calls only happen from authenticated screens (planner, task edit). No additional guards needed -- just verify existing auth gating is intact.
**Warning signs:** Sporadic 401 errors on Edge Functions immediately after app launch.

### Pitfall 5: generate_recurring_instances Ownership Check
**What goes wrong:** `generate_recurring_instances(p_task_id uuid)` does not accept a user ID, but it also does not verify that the caller owns the task. Any authenticated user could generate recurring instances for any task by guessing the task UUID.
**Why it happens:** The function was written without considering that it would be exposed via PostgREST RPC.
**How to avoid:** Add an ownership assertion: `SELECT user_id INTO v_task FROM tasks WHERE id = p_task_id` then check `v_task.user_id = auth.uid()`.
**Warning signs:** Cross-user task generation (hard to detect without audit logging).

## Code Examples

Verified patterns from project analysis and official Supabase documentation:

### Hardened search_tasks (SEC-01, SEC-02)
```sql
-- Drop old 2-param signature to prevent ghost function
DROP FUNCTION IF EXISTS public.search_tasks(uuid, text);

-- New 1-param signature using auth.uid()
CREATE OR REPLACE FUNCTION public.search_tasks(p_query text)
RETURNS SETOF public.tasks AS $$
BEGIN
  RETURN QUERY
  SELECT * FROM public.tasks
  WHERE user_id = auth.uid()
    AND fts @@ to_tsquery('english', replace(trim(p_query), ' ', ' & ') || ':*')
  ORDER BY ts_rank(fts, to_tsquery('english', replace(trim(p_query), ' ', ' & ') || ':*')) DESC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = '';
```

### Hardened create_board_with_defaults (SEC-01, SEC-03)
```sql
-- Drop old 2-param signature
DROP FUNCTION IF EXISTS public.create_board_with_defaults(text, uuid);

-- New 1-param signature using auth.uid()
CREATE OR REPLACE FUNCTION public.create_board_with_defaults(board_name text)
RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER SET search_path = ''
AS $$
DECLARE
  new_board_id uuid;
  caller_id uuid := auth.uid();
BEGIN
  INSERT INTO public.boards (name, created_by, metadata)
  VALUES (board_name, caller_id, '{ ... }'::jsonb)  -- same default metadata
  RETURNING id INTO new_board_id;

  INSERT INTO public.board_members (board_id, user_id, role)
  VALUES (new_board_id, caller_id, 'owner');

  INSERT INTO public.board_columns (board_id, name, position)
  VALUES
    (new_board_id, 'To Do', 1000),
    (new_board_id, 'In Progress', 2000),
    (new_board_id, 'Done', 3000);

  RETURN new_board_id;
END;
$$;
```

### Hardened invite_board_member (SEC-01, SEC-03)
```sql
-- Same signature, but with ownership assertion
CREATE OR REPLACE FUNCTION public.invite_board_member(
  target_board_id uuid,
  invite_email text,
  invite_role board_role DEFAULT 'editor'
)
RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER SET search_path = ''
AS $$
DECLARE
  target_user_id uuid;
  new_member_id uuid;
BEGIN
  -- Assert caller is board owner
  IF NOT EXISTS (
    SELECT 1 FROM public.board_members
    WHERE board_id = target_board_id
    AND user_id = auth.uid()
    AND role = 'owner'
  ) THEN
    RAISE EXCEPTION 'Only board owners can invite members';
  END IF;

  SELECT id INTO target_user_id
  FROM auth.users
  WHERE email = invite_email;

  IF target_user_id IS NULL THEN
    RAISE EXCEPTION 'No user found with email: %', invite_email;
  END IF;

  INSERT INTO public.board_members (board_id, user_id, role)
  VALUES (target_board_id, target_user_id, invite_role)
  ON CONFLICT (board_id, user_id) DO NOTHING
  RETURNING id INTO new_member_id;

  RETURN new_member_id;
END;
$$;
```

### Hardened generate_recurring_instances (SEC-01, SEC-02)
```sql
CREATE OR REPLACE FUNCTION public.generate_recurring_instances(p_task_id uuid)
RETURNS void AS $$
DECLARE
  v_rule recurrence_rules%rowtype;
  v_task tasks%rowtype;
  v_next_date date;
  v_end_date date := current_date + interval '14 days';
  v_last_instance date;
BEGIN
  SELECT * INTO v_task FROM public.tasks WHERE id = p_task_id;

  -- Assert caller owns the task
  IF v_task.user_id != auth.uid() THEN
    RAISE EXCEPTION 'Access denied: you do not own this task';
  END IF;

  -- ... rest of existing logic unchanged ...
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = '';
```

### REVOKE/GRANT Pattern (SEC-04)
```sql
-- Revoke default public execute on user-facing RPCs
REVOKE EXECUTE ON FUNCTION public.search_tasks(text) FROM public, anon;
REVOKE EXECUTE ON FUNCTION public.generate_recurring_instances(uuid) FROM public, anon;
REVOKE EXECUTE ON FUNCTION public.create_board_with_defaults(text) FROM public, anon;
REVOKE EXECUTE ON FUNCTION public.invite_board_member(uuid, text, board_role) FROM public, anon;

-- Grant to authenticated only
GRANT EXECUTE ON FUNCTION public.search_tasks(text) TO authenticated;
GRANT EXECUTE ON FUNCTION public.generate_recurring_instances(uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.create_board_with_defaults(text) TO authenticated;
GRANT EXECUTE ON FUNCTION public.invite_board_member(uuid, text, board_role) TO authenticated;

-- Helper functions used in RLS policies MUST remain callable by authenticated
-- is_board_member, is_board_owner, is_board_editor -- DO NOT REVOKE from authenticated
-- But DO revoke from anon (unauthenticated users should not call these)
REVOKE EXECUTE ON FUNCTION public.is_board_member(uuid) FROM public, anon;
REVOKE EXECUTE ON FUNCTION public.is_board_owner(uuid) FROM public, anon;
REVOKE EXECUTE ON FUNCTION public.is_board_editor(uuid) FROM public, anon;
```

### Client-Side Fix: planner_repository.dart (SEC-06)
```dart
// BEFORE (insecure -- overrides user JWT with anon key):
response = await _client.functions.invoke(
  'generate-schedule',
  headers: {
    'Authorization': 'Bearer ${SupabaseConstants.anonKey}',
  },
  body: body,
);

// AFTER (secure -- SDK auto-includes user's session JWT):
response = await _client.functions.invoke(
  'generate-schedule',
  body: body,
);
```

### Client-Side Fix: ai_rewrite_button.dart (SEC-06)
```dart
// BEFORE (insecure):
final response = await Supabase.instance.client.functions.invoke(
  'rewrite-title',
  headers: {
    'Authorization': 'Bearer ${SupabaseConstants.anonKey}',
  },
  body: {'title': rawTitle},
);

// AFTER (secure):
final response = await Supabase.instance.client.functions.invoke(
  'rewrite-title',
  body: {'title': rawTitle},
);
```

### Client-Side Fix: task_repository.dart (SEC-02 signature change)
```dart
// BEFORE:
final data = await _client.rpc('search_tasks', params: {
  'p_user_id': userId,
  'p_query': query,
});

// AFTER:
final data = await _client.rpc('search_tasks', params: {
  'p_query': query,
});
```

### Client-Side Fix: board_repository.dart (SEC-03 signature change)
```dart
// BEFORE:
final result = await _client.rpc('create_board_with_defaults', params: {
  'board_name': name,
  'creator_id': userId,
});

// AFTER:
final result = await _client.rpc('create_board_with_defaults', params: {
  'board_name': name,
});
// Note: userId variable may become unused -- remove if so
```

### Config Fix: supabase/config.toml (SEC-05)
```toml
# BEFORE:
[functions.generate-schedule]
verify_jwt = false

[functions.rewrite-title]
verify_jwt = false

# AFTER:
[functions.generate-schedule]
verify_jwt = true

[functions.rewrite-title]
verify_jwt = true
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Trust client-supplied user IDs in SECURITY DEFINER functions | Use `auth.uid()` exclusively | Supabase best practice since 2023+ | Prevents privilege escalation via forged IDs |
| `verify_jwt = false` for convenience | `verify_jwt = true` with proper client auth | Always recommended | Prevents unauthenticated API abuse |
| Manual `Authorization: Bearer ${anonKey}` in client | Let SDK auto-include session JWT | supabase-dart SDK auto-auth since v1.x | Correct auth flow without manual header management |

**Deprecated/outdated:**
- Passing anon key as Bearer token to Edge Functions: This was a workaround when `verify_jwt` was true but the function didn't need auth. The correct approach is either set `verify_jwt = false` (for truly public endpoints like webhooks) or let the SDK pass the real user JWT.

## Open Questions

1. **send-reminders function JWT setting**
   - What we know: `send-reminders` is not in `config.toml` (defaults to `verify_jwt = true`). It uses `SUPABASE_SERVICE_ROLE_KEY` internally and is likely invoked by cron, not by client.
   - What's unclear: Whether it needs any changes.
   - Recommendation: Out of scope -- it is not called from client code and already defaults to `verify_jwt = true`.

2. **update_updated_at trigger function**
   - What we know: This is a SECURITY INVOKER trigger function, not SECURITY DEFINER. It runs automatically on UPDATE and is not directly callable via RPC.
   - What's unclear: Whether REVOKE is needed.
   - Recommendation: No action needed -- trigger functions are not exposed via PostgREST RPC.

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | flutter_test (Dart) + manual SQL verification |
| Config file | `pubspec.yaml` (test dependency) |
| Quick run command | `flutter test test/unit/` |
| Full suite command | `flutter test` |

### Phase Requirements to Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| SEC-01 | auth.uid() used in all 4 functions | manual-only | SQL inspection of migration file | N/A -- SQL migration |
| SEC-02 | search_tasks uses auth.uid(); generate_recurring checks ownership | manual-only | Verify SQL + test client call compiles | N/A -- SQL migration |
| SEC-03 | create_board_with_defaults uses auth.uid(); invite checks ownership | manual-only | Verify SQL + test client call compiles | N/A -- SQL migration |
| SEC-04 | REVOKE/GRANT restricts anon access | manual-only | SQL inspection of migration file | N/A -- SQL migration |
| SEC-05 | verify_jwt = true in config.toml | manual-only | Inspect config file | N/A -- config change |
| SEC-06 | Client code no longer passes anonKey as auth header | unit | `flutter test test/unit/` (compilation check) | Partial -- existing tests cover compilation |

**Justification for manual-only on SEC-01 through SEC-05:** These are SQL migration and config changes that execute against a live Supabase instance. Testing would require either a local Supabase instance with pgTAP or integration tests with a test database. The project does not currently have this infrastructure. Verification is done by inspecting the migration SQL and confirming correct patterns, plus running the app against the live database after deployment.

### Sampling Rate
- **Per task commit:** `flutter test` (ensures client changes compile and existing tests pass)
- **Per wave merge:** `flutter test` + manual verification of RPC calls in running app
- **Phase gate:** Full `flutter test` green + manual smoke test of task search, board creation, board invite, and Edge Function calls

### Wave 0 Gaps
None -- this phase's changes are primarily SQL migrations and config file edits. The client-side changes are minimal (removing headers, adjusting RPC params) and covered by existing compilation checks. No new test files needed.

## Sources

### Primary (HIGH confidence)
- Supabase official docs: [Securing your API](https://supabase.com/docs/guides/api/securing-your-api) -- auth.uid() patterns, SECURITY DEFINER best practices
- Supabase official docs: [Function Configuration](https://supabase.com/docs/guides/functions/function-configuration) -- verify_jwt config.toml syntax
- Supabase official docs: [Securing Edge Functions](https://supabase.com/docs/guides/functions/auth) -- JWT verification patterns
- Supabase official docs: [Database Functions](https://supabase.com/docs/guides/database/functions) -- REVOKE/GRANT EXECUTE syntax
- Supabase official docs: [Flutter functions.invoke](https://supabase.com/docs/reference/dart/functions-invoke) -- SDK auto-auth behavior
- GitHub: [supabase/supabase-dart](https://github.com/supabase/supabase-dart/blob/main/lib/src/supabase_client.dart) -- FunctionsClient.setAuth() called on auth state change (verified via source)
- GitHub Discussion [#3269](https://github.com/orgs/supabase/discussions/3269) -- REVOKE EXECUTE patterns for SECURITY DEFINER functions
- GitHub Discussion [#17606](https://github.com/orgs/supabase/discussions/17606) -- Exact REVOKE syntax for public, anon, authenticated roles

### Secondary (MEDIUM confidence)
- GitHub Discussion [#802](https://github.com/orgs/supabase/discussions/802) -- auth.uid() to prevent forged user IDs
- [DeepWiki supabase-flutter Edge Functions](https://deepwiki.com/supabase/supabase-flutter/7-edge-functions) -- SDK auto-auth confirmation

### Tertiary (LOW confidence)
- None -- all findings verified with primary sources.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH -- all components are built-in Supabase/PostgreSQL primitives documented in official docs
- Architecture: HIGH -- patterns derived directly from existing codebase analysis + official documentation
- Pitfalls: HIGH -- pitfalls 1-3 derived from PostgreSQL semantics (well-documented); pitfall 4-5 from codebase analysis

**Research date:** 2026-03-28
**Valid until:** 2026-04-28 (stable PostgreSQL/Supabase primitives, unlikely to change)
