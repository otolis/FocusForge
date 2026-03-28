-- Migration: 00010_harden_rpc_functions.sql
-- Security hardening for all SECURITY DEFINER RPC functions.
--
-- This migration rewrites four vulnerable RPC functions to derive caller
-- identity from auth.uid() instead of trusting client-supplied user ID
-- parameters, adds ownership assertions where missing, and restricts
-- function execution permissions to the authenticated role only.
--
-- Functions hardened:
--   1. search_tasks          -- signature (uuid, text) -> (text); uses auth.uid()
--   2. generate_recurring_instances -- adds ownership assertion (v_task.user_id != auth.uid())
--   3. create_board_with_defaults  -- signature (text, uuid) -> (text); uses auth.uid()
--   4. invite_board_member         -- adds board ownership assertion before invite
--
-- Helper functions (is_board_member, is_board_owner, is_board_editor) are NOT
-- revoked from authenticated -- they are used in RLS policies and must remain
-- callable by the authenticated role.
--
-- Requirements: SEC-01, SEC-02, SEC-03, SEC-04

-- ============================================================
-- Section 1: Harden search_tasks (SEC-01, SEC-02)
-- ============================================================

-- Drop old 2-param signature to prevent ghost function (Pitfall 2)
DROP FUNCTION IF EXISTS public.search_tasks(uuid, text);

-- New 1-param signature: derive user identity from auth.uid()
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

-- ============================================================
-- Section 2: Harden generate_recurring_instances (SEC-01, SEC-02)
-- ============================================================

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

  -- Assert caller owns the task (SEC-02)
  IF v_task.user_id != auth.uid() THEN
    RAISE EXCEPTION 'Access denied: you do not own this task';
  END IF;

  SELECT * INTO v_rule FROM public.recurrence_rules WHERE task_id = p_task_id;
  IF v_rule IS NULL THEN RETURN; END IF;

  -- Skip generation if the anchor task has no deadline
  IF v_task.deadline IS NULL THEN RETURN; END IF;

  SELECT max(deadline::date) INTO v_last_instance
  FROM public.tasks WHERE parent_task_id = p_task_id;

  v_next_date := coalesce(v_last_instance + 1, v_task.deadline::date);

  WHILE v_next_date <= v_end_date LOOP
    IF v_rule.type = 'daily' THEN
      NULL;
    ELSIF v_rule.type = 'weekly' THEN
      IF NOT (extract(isodow FROM v_next_date)::int = ANY(v_rule.days_of_week)) THEN
        v_next_date := v_next_date + 1;
        CONTINUE;
      END IF;
    ELSIF v_rule.type = 'monthly' THEN
      IF extract(day FROM v_next_date)::int != v_rule.day_of_month THEN
        v_next_date := v_next_date + 1;
        CONTINUE;
      END IF;
    ELSIF v_rule.type = 'custom' THEN
      IF (v_next_date - v_task.deadline::date) % v_rule.interval_days != 0 THEN
        v_next_date := v_next_date + 1;
        CONTINUE;
      END IF;
    END IF;

    INSERT INTO public.tasks (user_id, title, description, priority, category_id, deadline, parent_task_id, recurrence_rule_id)
    SELECT v_task.user_id, v_task.title, v_task.description, v_task.priority,
           v_task.category_id, v_next_date::timestamptz, p_task_id, v_rule.id
    WHERE NOT EXISTS (
      SELECT 1 FROM public.tasks WHERE parent_task_id = p_task_id AND deadline::date = v_next_date
    );

    v_next_date := v_next_date + 1;
  END LOOP;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = '';

-- ============================================================
-- Section 3: Harden create_board_with_defaults (SEC-01, SEC-03)
-- ============================================================

-- Drop old 2-param signature to prevent ghost function (Pitfall 2)
DROP FUNCTION IF EXISTS public.create_board_with_defaults(text, uuid);

-- New 1-param signature: derive creator from auth.uid()
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
  VALUES (board_name, caller_id, '{
    "column_defs": [
      {"id": "col_status", "type": "status", "name": "Status", "width": 150, "position": 1000},
      {"id": "col_priority", "type": "priority", "name": "Priority", "width": 120, "position": 2000},
      {"id": "col_person", "type": "person", "name": "Person", "width": 100, "position": 3000},
      {"id": "col_timeline", "type": "timeline", "name": "Timeline", "width": 200, "position": 4000},
      {"id": "col_due", "type": "due_date", "name": "Due Date", "width": 120, "position": 5000},
      {"id": "col_desc", "type": "text", "name": "Description", "width": 200, "position": 6000}
    ],
    "status_labels": [
      {"id": "default_working", "name": "Working on it", "color": "#FF9800"},
      {"id": "default_done", "name": "Done", "color": "#4CAF50"},
      {"id": "default_stuck", "name": "Stuck", "color": "#F44336"},
      {"id": "default_not_started", "name": "Not Started", "color": "#9E9E9E"}
    ],
    "groups": [
      {"id": "default_group", "name": "Group 1", "color": "#2196F3", "position": 1000}
    ]
  }'::jsonb)
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

-- ============================================================
-- Section 4: Harden invite_board_member (SEC-01, SEC-03)
-- ============================================================

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
  -- Assert caller is board owner (SEC-03)
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

-- ============================================================
-- Section 5: REVOKE/GRANT permissions (SEC-04)
-- ============================================================

-- Revoke default public+anon execute on user-facing RPCs
REVOKE EXECUTE ON FUNCTION public.search_tasks(text) FROM public, anon;
REVOKE EXECUTE ON FUNCTION public.generate_recurring_instances(uuid) FROM public, anon;
REVOKE EXECUTE ON FUNCTION public.create_board_with_defaults(text) FROM public, anon;
REVOKE EXECUTE ON FUNCTION public.invite_board_member(uuid, text, board_role) FROM public, anon;

-- Grant to authenticated only
GRANT EXECUTE ON FUNCTION public.search_tasks(text) TO authenticated;
GRANT EXECUTE ON FUNCTION public.generate_recurring_instances(uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.create_board_with_defaults(text) TO authenticated;
GRANT EXECUTE ON FUNCTION public.invite_board_member(uuid, text, board_role) TO authenticated;

-- Helper functions used in RLS policies: revoke from anon but keep authenticated
REVOKE EXECUTE ON FUNCTION public.is_board_member(uuid) FROM public, anon;
REVOKE EXECUTE ON FUNCTION public.is_board_owner(uuid) FROM public, anon;
REVOKE EXECUTE ON FUNCTION public.is_board_editor(uuid) FROM public, anon;
