-- Migration: Update fetch_properties RPC function to support p_for_video_request boolean flag.
-- When p_for_video_request is TRUE, filters for properties where medias is empty AND no active video request exists in video_requests.

CREATE OR REPLACE FUNCTION public.fetch_properties(
  p_broker_id UUID,
  p_page INT DEFAULT 1,
  p_limit INT DEFAULT 10,
  p_search_query TEXT DEFAULT '',
  p_for_video_request BOOLEAN DEFAULT false
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_offset INT;
  v_total_items INT;
  v_total_pages INT;
  v_has_more BOOLEAN;
  v_properties_json JSONB;
BEGIN
  -- Calculate offset for pagination
  v_offset := (p_page - 1) * p_limit;

  -- 1. Calculate total items matching the filter (excluding deleted items)
  SELECT COUNT(*)
  INTO v_total_items
  FROM public.properties p
  LEFT JOIN public.addresses a ON p.address_id = a.id
  WHERE p.broker_id = p_broker_id
    AND p.is_deleted = false
    AND (
      p_for_video_request IS FALSE OR (
        (p.medias IS NULL OR p.medias = '[]'::jsonb OR p.medias::text = '[]' OR p.medias::text = 'null')
        AND NOT EXISTS (
          SELECT 1 FROM public.video_requests vr
          WHERE vr.property_id = p.id
            AND vr.status::text IN ('pending', 'in_progress', 'completed')
        )
      )
    )
    AND (
      p_search_query = '' OR
      p.property_title ILIKE '%' || p_search_query || '%' OR
      p.property_description ILIKE '%' || p_search_query || '%' OR
      (a.id IS NOT NULL AND (
         a.full_address ILIKE '%' || p_search_query || '%' OR
         a.city ILIKE '%' || p_search_query || '%' OR
         a.state ILIKE '%' || p_search_query || '%'
      ))
    );

  -- Calculate pagination details
  IF v_total_items = 0 THEN
    v_total_pages := 1;
    v_has_more := false;
  ELSE
    v_total_pages := CEIL(v_total_items::NUMERIC / p_limit)::INT;
    v_has_more := (p_page * p_limit) < v_total_items;
  END IF;

  -- 2. Fetch properties with pagination, ordering by latest first, and nested address serialization
  SELECT COALESCE(jsonb_agg(
    to_jsonb(p_data) || 
    jsonb_build_object(
      'address', 
      CASE 
        WHEN p_data.address_id IS NOT NULL THEN to_jsonb(a_data)
        ELSE NULL
      END
    )
  ), '[]'::jsonb)
  INTO v_properties_json
  FROM (
    SELECT p.*
    FROM public.properties p
    LEFT JOIN public.addresses a ON p.address_id = a.id
    WHERE p.broker_id = p_broker_id
      AND p.is_deleted = false
      AND (
        p_for_video_request IS FALSE OR (
          (p.medias IS NULL OR p.medias = '[]'::jsonb OR p.medias::text = '[]' OR p.medias::text = 'null')
          AND NOT EXISTS (
            SELECT 1 FROM public.video_requests vr
            WHERE vr.property_id = p.id
              AND vr.status::text IN ('pending', 'in_progress', 'completed')
          )
        )
      )
      AND (
        p_search_query = '' OR
        p.property_title ILIKE '%' || p_search_query || '%' OR
        p.property_description ILIKE '%' || p_search_query || '%' OR
        (a.id IS NOT NULL AND (
           a.full_address ILIKE '%' || p_search_query || '%' OR
           a.city ILIKE '%' || p_search_query || '%' OR
           a.state ILIKE '%' || p_search_query || '%'
        ))
      )
    ORDER BY p.created_at DESC
    LIMIT p_limit
    OFFSET v_offset
  ) p_data
  LEFT JOIN public.addresses a_data ON p_data.address_id = a_data.id;

  -- Return the final combined JSON structure
  RETURN jsonb_build_object(
    'success', true,
    'data', v_properties_json,
    'pagination', jsonb_build_object(
      'total_items', v_total_items,
      'total_pages', v_total_pages,
      'has_more', v_has_more
    )
  );
END;
$$;
