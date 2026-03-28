-- Migration: 00008_fix_board_rls_recursion.sql
-- Fixes infinite recursion (42P17) in board_members RLS policies.
--
-- Problem: board_members SELECT policy queries board_members itself,
-- which triggers the same policy → infinite loop. The boards,
-- board_columns, and board_cards policies also query board_members,
-- triggering the recursive SELECT policy.
--
-- Fix: Create SECURITY DEFINER helper functions that bypass RLS to
-- check membership/ownership, then rewrite all board-related policies
-- to use those functions instead of direct subqueries.

-- ============================================================
-- Step 1: Create SECURITY DEFINER helper functions
-- ============================================================

-- Check if current user is a member of the given board (any role).
CREATE OR REPLACE FUNCTION public.is_board_member(p_board_id uuid)
RETURNS boolean
LANGUAGE sql
SECURITY DEFINER
SET search_path = ''
STABLE
AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.board_members
    WHERE board_id = p_board_id
    AND user_id = auth.uid()
  );
$$;

-- Check if current user is an owner of the given board.
CREATE OR REPLACE FUNCTION public.is_board_owner(p_board_id uuid)
RETURNS boolean
LANGUAGE sql
SECURITY DEFINER
SET search_path = ''
STABLE
AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.board_members
    WHERE board_id = p_board_id
    AND user_id = auth.uid()
    AND role = 'owner'
  );
$$;

-- Check if current user is an owner or editor of the given board.
CREATE OR REPLACE FUNCTION public.is_board_editor(p_board_id uuid)
RETURNS boolean
LANGUAGE sql
SECURITY DEFINER
SET search_path = ''
STABLE
AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.board_members
    WHERE board_id = p_board_id
    AND user_id = auth.uid()
    AND role IN ('owner', 'editor')
  );
$$;

-- ============================================================
-- Step 2: Drop all existing board-related policies
-- ============================================================

-- boards
DROP POLICY IF EXISTS "Members can view boards" ON public.boards;
DROP POLICY IF EXISTS "Authenticated users can create boards" ON public.boards;
DROP POLICY IF EXISTS "Owners can update boards" ON public.boards;
DROP POLICY IF EXISTS "Owners can delete boards" ON public.boards;

-- board_members
DROP POLICY IF EXISTS "Members can view board members" ON public.board_members;
DROP POLICY IF EXISTS "Owners can manage members" ON public.board_members;
DROP POLICY IF EXISTS "Owners can update member roles" ON public.board_members;
DROP POLICY IF EXISTS "Owners can remove members" ON public.board_members;

-- board_columns
DROP POLICY IF EXISTS "Members can view columns" ON public.board_columns;
DROP POLICY IF EXISTS "Editors can insert columns" ON public.board_columns;
DROP POLICY IF EXISTS "Editors can update columns" ON public.board_columns;
DROP POLICY IF EXISTS "Editors can delete columns" ON public.board_columns;

-- board_cards
DROP POLICY IF EXISTS "Members can view cards" ON public.board_cards;
DROP POLICY IF EXISTS "Editors can insert cards" ON public.board_cards;
DROP POLICY IF EXISTS "Editors can update cards" ON public.board_cards;
DROP POLICY IF EXISTS "Editors can delete cards" ON public.board_cards;

-- ============================================================
-- Step 3: Recreate policies using helper functions
-- ============================================================

-- boards
CREATE POLICY "Members can view boards"
  ON public.boards FOR SELECT TO authenticated
  USING (public.is_board_member(id));

CREATE POLICY "Authenticated users can create boards"
  ON public.boards FOR INSERT TO authenticated
  WITH CHECK (auth.uid() = created_by);

CREATE POLICY "Owners can update boards"
  ON public.boards FOR UPDATE TO authenticated
  USING (public.is_board_owner(id));

CREATE POLICY "Owners can delete boards"
  ON public.boards FOR DELETE TO authenticated
  USING (public.is_board_owner(id));

-- board_members
CREATE POLICY "Members can view board members"
  ON public.board_members FOR SELECT TO authenticated
  USING (public.is_board_member(board_id));

CREATE POLICY "Owners can manage members"
  ON public.board_members FOR INSERT TO authenticated
  WITH CHECK (
    public.is_board_owner(board_id)
    OR user_id = auth.uid()
  );

CREATE POLICY "Owners can update member roles"
  ON public.board_members FOR UPDATE TO authenticated
  USING (public.is_board_owner(board_id));

CREATE POLICY "Owners can remove members"
  ON public.board_members FOR DELETE TO authenticated
  USING (
    public.is_board_owner(board_id)
    OR user_id = auth.uid()
  );

-- board_columns
CREATE POLICY "Members can view columns"
  ON public.board_columns FOR SELECT TO authenticated
  USING (public.is_board_member(board_id));

CREATE POLICY "Editors can insert columns"
  ON public.board_columns FOR INSERT TO authenticated
  WITH CHECK (public.is_board_editor(board_id));

CREATE POLICY "Editors can update columns"
  ON public.board_columns FOR UPDATE TO authenticated
  USING (public.is_board_editor(board_id));

CREATE POLICY "Editors can delete columns"
  ON public.board_columns FOR DELETE TO authenticated
  USING (public.is_board_editor(board_id));

-- board_cards
CREATE POLICY "Members can view cards"
  ON public.board_cards FOR SELECT TO authenticated
  USING (public.is_board_member(board_id));

CREATE POLICY "Editors can insert cards"
  ON public.board_cards FOR INSERT TO authenticated
  WITH CHECK (public.is_board_editor(board_id));

CREATE POLICY "Editors can update cards"
  ON public.board_cards FOR UPDATE TO authenticated
  USING (public.is_board_editor(board_id));

CREATE POLICY "Editors can delete cards"
  ON public.board_cards FOR DELETE TO authenticated
  USING (public.is_board_editor(board_id));
