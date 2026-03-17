-- Migration: 00003_create_boards.sql
-- Creates board tables, RLS policies, and helper functions for collaborative Kanban boards.

-- Board roles enum
CREATE TYPE board_role AS ENUM ('owner', 'editor', 'viewer');

-- Boards table
CREATE TABLE public.boards (
  id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
  name text NOT NULL,
  created_by uuid NOT NULL REFERENCES auth.users ON DELETE CASCADE,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Board members junction table
CREATE TABLE public.board_members (
  id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
  board_id uuid NOT NULL REFERENCES public.boards ON DELETE CASCADE,
  user_id uuid NOT NULL REFERENCES auth.users ON DELETE CASCADE,
  role board_role NOT NULL DEFAULT 'viewer',
  invited_at timestamptz DEFAULT now(),
  UNIQUE(board_id, user_id)
);

-- Board columns (Kanban columns)
CREATE TABLE public.board_columns (
  id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
  board_id uuid NOT NULL REFERENCES public.boards ON DELETE CASCADE,
  name text NOT NULL,
  position int NOT NULL DEFAULT 0,
  created_at timestamptz DEFAULT now()
);

-- Board cards
CREATE TABLE public.board_cards (
  id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
  board_id uuid NOT NULL REFERENCES public.boards ON DELETE CASCADE,
  column_id uuid NOT NULL REFERENCES public.board_columns ON DELETE CASCADE,
  title text NOT NULL,
  description text,
  assignee_id uuid REFERENCES auth.users,
  priority int DEFAULT 3,
  due_date timestamptz,
  position int NOT NULL DEFAULT 0,
  created_by uuid NOT NULL REFERENCES auth.users,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Enable RLS on all tables
ALTER TABLE public.boards ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.board_members ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.board_columns ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.board_cards ENABLE ROW LEVEL SECURITY;

-- Enable Realtime ONLY on tables that need it (cards and columns change frequently)
ALTER PUBLICATION supabase_realtime ADD TABLE board_cards, board_columns;

-- Set replica identity full for DELETE event payloads (Pitfall 2 from research)
ALTER TABLE board_cards REPLICA IDENTITY FULL;
ALTER TABLE board_columns REPLICA IDENTITY FULL;

-- Performance indexes for RLS policy subqueries
CREATE INDEX idx_board_members_user ON public.board_members(user_id);
CREATE INDEX idx_board_members_board ON public.board_members(board_id);
CREATE INDEX idx_board_members_board_user ON public.board_members(board_id, user_id);
CREATE INDEX idx_board_cards_board ON public.board_cards(board_id);
CREATE INDEX idx_board_cards_column ON public.board_cards(column_id);
CREATE INDEX idx_board_columns_board ON public.board_columns(board_id);

-- ============================================================
-- RLS Policies: boards
-- ============================================================
CREATE POLICY "Members can view boards"
  ON public.boards FOR SELECT TO authenticated
  USING (EXISTS (
    SELECT 1 FROM public.board_members
    WHERE board_members.board_id = boards.id
    AND board_members.user_id = (SELECT auth.uid())
  ));

CREATE POLICY "Authenticated users can create boards"
  ON public.boards FOR INSERT TO authenticated
  WITH CHECK ((SELECT auth.uid()) = created_by);

CREATE POLICY "Owners can update boards"
  ON public.boards FOR UPDATE TO authenticated
  USING (EXISTS (
    SELECT 1 FROM public.board_members
    WHERE board_members.board_id = boards.id
    AND board_members.user_id = (SELECT auth.uid())
    AND board_members.role = 'owner'
  ));

CREATE POLICY "Owners can delete boards"
  ON public.boards FOR DELETE TO authenticated
  USING (EXISTS (
    SELECT 1 FROM public.board_members
    WHERE board_members.board_id = boards.id
    AND board_members.user_id = (SELECT auth.uid())
    AND board_members.role = 'owner'
  ));

-- ============================================================
-- RLS Policies: board_members
-- ============================================================
CREATE POLICY "Members can view board members"
  ON public.board_members FOR SELECT TO authenticated
  USING (EXISTS (
    SELECT 1 FROM public.board_members AS bm
    WHERE bm.board_id = board_members.board_id
    AND bm.user_id = (SELECT auth.uid())
  ));

CREATE POLICY "Owners can manage members"
  ON public.board_members FOR INSERT TO authenticated
  WITH CHECK (EXISTS (
    SELECT 1 FROM public.board_members AS bm
    WHERE bm.board_id = board_members.board_id
    AND bm.user_id = (SELECT auth.uid())
    AND bm.role = 'owner'
  ) OR board_members.user_id = (SELECT auth.uid()));

CREATE POLICY "Owners can update member roles"
  ON public.board_members FOR UPDATE TO authenticated
  USING (EXISTS (
    SELECT 1 FROM public.board_members AS bm
    WHERE bm.board_id = board_members.board_id
    AND bm.user_id = (SELECT auth.uid())
    AND bm.role = 'owner'
  ));

CREATE POLICY "Owners can remove members"
  ON public.board_members FOR DELETE TO authenticated
  USING (EXISTS (
    SELECT 1 FROM public.board_members AS bm
    WHERE bm.board_id = board_members.board_id
    AND bm.user_id = (SELECT auth.uid())
    AND bm.role = 'owner'
  ) OR board_members.user_id = (SELECT auth.uid()));

-- ============================================================
-- RLS Policies: board_columns
-- ============================================================
CREATE POLICY "Members can view columns"
  ON public.board_columns FOR SELECT TO authenticated
  USING (EXISTS (
    SELECT 1 FROM public.board_members
    WHERE board_members.board_id = board_columns.board_id
    AND board_members.user_id = (SELECT auth.uid())
  ));

CREATE POLICY "Editors can insert columns"
  ON public.board_columns FOR INSERT TO authenticated
  WITH CHECK (EXISTS (
    SELECT 1 FROM public.board_members
    WHERE board_members.board_id = board_columns.board_id
    AND board_members.user_id = (SELECT auth.uid())
    AND board_members.role IN ('owner', 'editor')
  ));

CREATE POLICY "Editors can update columns"
  ON public.board_columns FOR UPDATE TO authenticated
  USING (EXISTS (
    SELECT 1 FROM public.board_members
    WHERE board_members.board_id = board_columns.board_id
    AND board_members.user_id = (SELECT auth.uid())
    AND board_members.role IN ('owner', 'editor')
  ));

CREATE POLICY "Editors can delete columns"
  ON public.board_columns FOR DELETE TO authenticated
  USING (EXISTS (
    SELECT 1 FROM public.board_members
    WHERE board_members.board_id = board_columns.board_id
    AND board_members.user_id = (SELECT auth.uid())
    AND board_members.role IN ('owner', 'editor')
  ));

-- ============================================================
-- RLS Policies: board_cards
-- ============================================================
CREATE POLICY "Members can view cards"
  ON public.board_cards FOR SELECT TO authenticated
  USING (EXISTS (
    SELECT 1 FROM public.board_members
    WHERE board_members.board_id = board_cards.board_id
    AND board_members.user_id = (SELECT auth.uid())
  ));

CREATE POLICY "Editors can insert cards"
  ON public.board_cards FOR INSERT TO authenticated
  WITH CHECK (EXISTS (
    SELECT 1 FROM public.board_members
    WHERE board_members.board_id = board_cards.board_id
    AND board_members.user_id = (SELECT auth.uid())
    AND board_members.role IN ('owner', 'editor')
  ));

CREATE POLICY "Editors can update cards"
  ON public.board_cards FOR UPDATE TO authenticated
  USING (EXISTS (
    SELECT 1 FROM public.board_members
    WHERE board_members.board_id = board_cards.board_id
    AND board_members.user_id = (SELECT auth.uid())
    AND board_members.role IN ('owner', 'editor')
  ));

CREATE POLICY "Editors can delete cards"
  ON public.board_cards FOR DELETE TO authenticated
  USING (EXISTS (
    SELECT 1 FROM public.board_members
    WHERE board_members.board_id = board_cards.board_id
    AND board_members.user_id = (SELECT auth.uid())
    AND board_members.role IN ('owner', 'editor')
  ));

-- ============================================================
-- RPC: Create board with defaults (atomic transaction)
-- ============================================================
CREATE OR REPLACE FUNCTION public.create_board_with_defaults(
  board_name text,
  creator_id uuid
)
RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER SET search_path = ''
AS $$
DECLARE
  new_board_id uuid;
BEGIN
  -- Insert board
  INSERT INTO public.boards (name, created_by)
  VALUES (board_name, creator_id)
  RETURNING id INTO new_board_id;

  -- Add creator as owner
  INSERT INTO public.board_members (board_id, user_id, role)
  VALUES (new_board_id, creator_id, 'owner');

  -- Create 3 default columns
  INSERT INTO public.board_columns (board_id, name, position)
  VALUES
    (new_board_id, 'To Do', 1000),
    (new_board_id, 'In Progress', 2000),
    (new_board_id, 'Done', 3000);

  RETURN new_board_id;
END;
$$;

-- ============================================================
-- RPC: Invite member by email (security definer to read auth.users)
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
  -- Look up user by email in auth.users (requires security definer)
  SELECT id INTO target_user_id
  FROM auth.users
  WHERE email = invite_email;

  IF target_user_id IS NULL THEN
    RAISE EXCEPTION 'No user found with email: %', invite_email;
  END IF;

  -- Insert board membership
  INSERT INTO public.board_members (board_id, user_id, role)
  VALUES (target_board_id, target_user_id, invite_role)
  ON CONFLICT (board_id, user_id) DO NOTHING
  RETURNING id INTO new_member_id;

  RETURN new_member_id;
END;
$$;
