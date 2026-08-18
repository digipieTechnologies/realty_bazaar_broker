-- Migration: 20260812130000_create_soft_delete_property_rpc_and_fix_rls.sql
-- Purpose:
-- 1. Drop conflicting SELECT RLS policy ("Enforce non-deleted on SELECT") that blocks soft-delete UPDATE returning rows.
-- 2. Create RPC function public.soft_delete_property(p_property_id UUID) to safely soft delete properties along with associated video requests and social leads.

-- Drop conflicting old policies if present
DROP POLICY IF EXISTS "Enforce non-deleted on SELECT" ON public.properties;
DROP POLICY IF EXISTS "Hide soft-deleted properties for non-admins" ON public.properties;

-- Re-create SELECT policy for properties
CREATE POLICY "Hide soft-deleted properties for non-admins" ON public.properties
  FOR SELECT
  USING (
    (is_deleted IS FALSE OR is_deleted IS NULL)
    OR EXISTS (
      SELECT 1 FROM public.users u
      WHERE u.id = auth.uid()
        AND LOWER(u.role::text) IN ('super_admin', 'superadmin', 'admin')
    )
  );

-- Create or Replace soft_delete_property RPC function with cascading soft deletion
CREATE OR REPLACE FUNCTION public.soft_delete_property(p_property_id UUID)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_updated_video_requests INT := 0;
  v_updated_social_leads INT := 0;
BEGIN
  -- 1. Soft delete property
  UPDATE public.properties
  SET is_deleted = TRUE,
      deleted_at = NOW(),
      updated_at = NOW()
  WHERE id = p_property_id;

  -- 2. Soft delete associated video requests
  UPDATE public.video_requests
  SET is_deleted = TRUE,
      deleted_at = NOW(),
      updated_at = NOW()
  WHERE property_id = p_property_id
    AND (is_deleted IS FALSE OR is_deleted IS NULL);
  GET DIAGNOSTICS v_updated_video_requests = ROW_COUNT;

  -- 3. Soft delete associated social leads (if referenced directly or via social_posts)
  BEGIN
    UPDATE public.social_leads
    SET is_deleted = TRUE,
        deleted_at = NOW(),
        updated_at = NOW()
    WHERE (
      property_id = p_property_id
      OR social_post_id IN (SELECT id FROM public.social_posts WHERE property_id = p_property_id)
    )
    AND (is_deleted IS FALSE OR is_deleted IS NULL);
    GET DIAGNOSTICS v_updated_social_leads = ROW_COUNT;
  EXCEPTION WHEN OTHERS THEN
    -- Fallback: Soft delete social leads directly by property_id if social_posts table is absent
    BEGIN
      UPDATE public.social_leads
      SET is_deleted = TRUE,
          deleted_at = NOW(),
          updated_at = NOW()
      WHERE property_id = p_property_id
        AND (is_deleted IS FALSE OR is_deleted IS NULL);
      GET DIAGNOSTICS v_updated_social_leads = ROW_COUNT;
    EXCEPTION WHEN OTHERS THEN
      NULL;
    END;
  END;

  RETURN jsonb_build_object(
    'success', true,
    'deleted_property_id', p_property_id,
    'deleted_video_requests', v_updated_video_requests,
    'deleted_social_leads', v_updated_social_leads
  );
END;
$$;

GRANT EXECUTE ON FUNCTION public.soft_delete_property(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION public.soft_delete_property(UUID) TO service_role;
