-- Migration: Create public.update_property_media RPC function
-- Purpose: Atomically update property media and complete the video request in a single transaction.

CREATE OR REPLACE FUNCTION public.update_property_media(
  p_property_id UUID,
  p_medias JSONB,
  p_request_id UUID
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  -- 1. Update the property media column
  UPDATE public.properties
  SET
    medias = p_medias,
    updated_at = NOW()
  WHERE id = p_property_id;

  -- 2. Update the video request status to completed
  UPDATE public.video_requests
  SET
    status = 'completed',
    completed_at = NOW(),
    updated_at = NOW()
  WHERE id = p_request_id;

  RETURN jsonb_build_object(
    'success', true,
    'message', 'Property media updated and request completed successfully'
  );
EXCEPTION WHEN OTHERS THEN
  RETURN jsonb_build_object(
    'success', false,
    'error', SQLERRM
  );
END;
$$;
