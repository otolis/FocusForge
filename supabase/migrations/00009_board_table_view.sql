-- Migration: 00009_board_table_view.sql
-- Adds table-view support to boards: metadata JSONB on boards, new fields
-- on board_cards, group index, and updated create_board_with_defaults RPC.

-- ============================================================
-- Step 1: Add metadata JSONB column to boards
-- ============================================================

ALTER TABLE public.boards
  ADD COLUMN IF NOT EXISTS metadata jsonb DEFAULT '{
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
  }'::jsonb;

-- ============================================================
-- Step 2: Add table-view fields to board_cards
-- ============================================================

ALTER TABLE public.board_cards
  ADD COLUMN IF NOT EXISTS start_date timestamptz,
  ADD COLUMN IF NOT EXISTS status_label text,
  ADD COLUMN IF NOT EXISTS status_color text,
  ADD COLUMN IF NOT EXISTS group_id text DEFAULT 'default_group',
  ADD COLUMN IF NOT EXISTS custom_fields jsonb DEFAULT '{}'::jsonb;

-- ============================================================
-- Step 3: Index for group-based queries
-- ============================================================

CREATE INDEX IF NOT EXISTS idx_board_cards_group ON public.board_cards(group_id);

-- ============================================================
-- Step 4: Update create_board_with_defaults to include metadata
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
  -- Insert board with default table-view metadata
  INSERT INTO public.boards (name, created_by, metadata)
  VALUES (board_name, creator_id, '{
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

  -- Add creator as owner
  INSERT INTO public.board_members (board_id, user_id, role)
  VALUES (new_board_id, creator_id, 'owner');

  -- Create 3 default Kanban columns
  INSERT INTO public.board_columns (board_id, name, position)
  VALUES
    (new_board_id, 'To Do', 1000),
    (new_board_id, 'In Progress', 2000),
    (new_board_id, 'Done', 3000);

  RETURN new_board_id;
END;
$$;
