-- Migration: Create public.fetch_video_request_details RPC function
-- Purpose: Atomically fetch the latest video_request record and property details for a given property in a single call.

CREATE OR REPLACE FUNCTION public.fetch_video_request_details(
  p_property_id UUID
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_video_request_json JSONB := NULL;
  v_property_json JSONB := NULL;
BEGIN
  -- 1. Fetch latest video_request record with nested property and address
  SELECT to_jsonb(vr_data) || jsonb_build_object(
    'property',
    CASE
      WHEN p_data.id IS NOT NULL THEN to_jsonb(p_data) || jsonb_build_object(
        'address',
        CASE
          WHEN a_data.id IS NOT NULL THEN to_jsonb(a_data)
          ELSE NULL
        END
      )
      ELSE NULL
    END
  )
  INTO v_video_request_json
  FROM (
    SELECT *
    FROM public.video_requests
    WHERE property_id = p_property_id
    ORDER BY created_at DESC
    LIMIT 1
  ) vr_data
  LEFT JOIN public.properties p_data ON vr_data.property_id = p_data.id
  LEFT JOIN public.addresses a_data ON p_data.address_id = a_data.id;

  -- 2. Fetch property details with nested address
  SELECT to_jsonb(p) || jsonb_build_object(
    'address',
    CASE
      WHEN a.id IS NOT NULL THEN to_jsonb(a)
      ELSE NULL
    END
  )
  INTO v_property_json
  FROM public.properties p
  LEFT JOIN public.addresses a ON p.address_id = a.id
  WHERE p.id = p_property_id;

  RETURN jsonb_build_object(
    'success', true,
    'video_request', v_video_request_json,
    'property', v_property_json
  );
END;
$$;
