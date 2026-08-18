-- Migration: 20260811130000_update_fetch_video_requests_ordering.sql
-- Purpose: Update fetch_video_requests RPC to order records by updated_at > completed_at > created_at DESC instead of created_at only.

CREATE OR REPLACE FUNCTION public.fetch_video_requests(
  p_broker_id UUID DEFAULT NULL,
  p_page INT DEFAULT 1,
  p_limit INT DEFAULT 10,
  p_search_query TEXT DEFAULT '',
  p_admin_approved_status public.video_request_approval_status DEFAULT NULL,
  p_status public.video_request_status DEFAULT NULL,
  p_statuses TEXT[] DEFAULT NULL
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
  v_requests_json JSONB;
BEGIN
  -- Calculate offset for pagination
  v_offset := (p_page - 1) * p_limit;

  -- 1. Calculate total items matching the filter
  SELECT COUNT(*)
  INTO v_total_items
  FROM public.video_requests vr
  JOIN public.properties p ON vr.property_id = p.id
  JOIN public.brokers b ON vr.broker_id = b.id
  LEFT JOIN public.addresses a ON p.address_id = a.id
  WHERE (p_broker_id IS NULL OR vr.broker_id = p_broker_id)
    AND (p_admin_approved_status IS NULL OR vr.admin_approval_status = p_admin_approved_status)
    AND (p_status IS NULL OR vr.status = p_status)
    AND (p_statuses IS NULL OR array_length(p_statuses, 1) IS NULL OR vr.status::text = ANY(p_statuses))
    AND (
      p_search_query = '' OR
      p.property_title ILIKE '%' || p_search_query || '%' OR
      b.business_name ILIKE '%' || p_search_query || '%' OR
      vr.notes ILIKE '%' || p_search_query || '%' OR
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

  -- 2. Fetch the video requests with pagination, ordering by updated_at > completed_at > created_at DESC, and nested serialization
  SELECT COALESCE(jsonb_agg(
    to_jsonb(vr_data) ||
    jsonb_build_object(
      'property', 
      to_jsonb(p_data) || jsonb_build_object(
        'address',
        CASE 
          WHEN p_data.address_id IS NOT NULL THEN to_jsonb(pa_data)
          ELSE NULL
        END
      ),
      'broker',
      to_jsonb(b_data) || jsonb_build_object(
        'address',
        CASE 
          WHEN b_data.address_id IS NOT NULL THEN to_jsonb(ba_data)
          ELSE NULL
        END
      )
    )
  ), '[]'::jsonb)
  INTO v_requests_json
  FROM (
    SELECT vr.*
    FROM public.video_requests vr
    JOIN public.properties p ON vr.property_id = p.id
    JOIN public.brokers b ON vr.broker_id = b.id
    LEFT JOIN public.addresses a ON p.address_id = a.id
    WHERE (p_broker_id IS NULL OR vr.broker_id = p_broker_id)
      AND (p_admin_approved_status IS NULL OR vr.admin_approval_status = p_admin_approved_status)
      AND (p_status IS NULL OR vr.status = p_status)
      AND (p_statuses IS NULL OR array_length(p_statuses, 1) IS NULL OR vr.status::text = ANY(p_statuses))
      AND (
        p_search_query = '' OR
        p.property_title ILIKE '%' || p_search_query || '%' OR
        b.business_name ILIKE '%' || p_search_query || '%' OR
        vr.notes ILIKE '%' || p_search_query || '%' OR
        (a.id IS NOT NULL AND (
           a.full_address ILIKE '%' || p_search_query || '%' OR
           a.city ILIKE '%' || p_search_query || '%' OR
           a.state ILIKE '%' || p_search_query || '%'
        ))
      )
    ORDER BY COALESCE(vr.updated_at, vr.completed_at, vr.created_at) DESC, vr.created_at DESC
    LIMIT p_limit OFFSET v_offset
  ) vr_data
  JOIN public.properties p_data ON vr_data.property_id = p_data.id
  JOIN public.brokers b_data ON vr_data.broker_id = b_data.id
  LEFT JOIN public.addresses pa_data ON p_data.address_id = pa_data.id
  LEFT JOIN public.addresses ba_data ON b_data.address_id = ba_data.id;

  RETURN jsonb_build_object(
    'success', true,
    'data', v_requests_json,
    'pagination', jsonb_build_object(
      'current_page', p_page,
      'limit', p_limit,
      'total_items', v_total_items,
      'total_pages', v_total_pages,
      'has_more', v_has_more
    )
  );
EXCEPTION WHEN OTHERS THEN
  RETURN jsonb_build_object(
    'success', false,
    'message', SQLERRM
  );
END;
$$;
