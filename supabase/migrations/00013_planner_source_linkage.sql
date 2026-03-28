-- Migration: 00013_planner_source_linkage.sql
-- Adds source tracking columns to plannable_items for idempotent import.
-- source_type: 'task' or 'habit' (null for manually created items)
-- source_id: UUID of the source task or habit (null for manual items)

ALTER TABLE public.plannable_items
  ADD COLUMN source_type text,
  ADD COLUMN source_id text;

-- Partial unique index: prevents duplicate imports for the same source
-- on the same date. Manual items (source_type IS NULL) are unrestricted.
CREATE UNIQUE INDEX idx_plannable_items_source_unique
  ON public.plannable_items (user_id, plan_date, source_type, source_id)
  WHERE source_type IS NOT NULL;
