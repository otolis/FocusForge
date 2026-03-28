-- Migration: 00012_board_comember_profile_visibility.sql
-- Allows board co-members to read each other's profile (display_name, avatar_url).
--
-- Uses a SECURITY DEFINER helper function to avoid RLS recursion risk,
-- consistent with the pattern established in 00008_fix_board_rls_recursion.sql.
-- The existing "Users can view own profile" policy remains unchanged --
-- PostgreSQL ORs all SELECT policies, so access is granted if either condition is true.

-- SECURITY DEFINER helper: checks if caller shares any board with target user.
-- Bypasses RLS on board_members to avoid recursion.
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

-- Allow board co-members to read each other's profiles.
-- Works alongside "Users can view own profile" policy (PostgreSQL ORs SELECT policies).
CREATE POLICY "Board co-members can view profiles"
  ON public.profiles FOR SELECT TO authenticated
  USING (public.shares_board_with(id));

-- Restrict helper to authenticated users only (not anon).
REVOKE EXECUTE ON FUNCTION public.shares_board_with(uuid) FROM anon;
GRANT EXECUTE ON FUNCTION public.shares_board_with(uuid) TO authenticated;
