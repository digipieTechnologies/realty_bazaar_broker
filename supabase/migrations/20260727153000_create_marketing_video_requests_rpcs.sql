-- Migration: Create RPC functions for video request dashboard and pagination in the marketing application

-- 1. RPC for fetching summarized request counts
CREATE OR REPLACE FUNCTION public.fetch_video_request_counts()
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_total INT;
  v_pending INT;
  v_in_progress INT;
  v_completed INT;
BEGIN
  -- Count only requests that have been admin-approved
  SELECT COUNT(*) INTO v_total
  FROM public.video_requests
  WHERE admin_approval_status = 'approved'::public.video_request_approval_status
    AND status != 'cancelled'::public.video_request_status;

  SELECT COUNT(*) INTO v_pending
  FROM public.video_requests
  WHERE admin_approval_status = 'approved'::public.video_request_approval_status
    AND status = 'pending'::public.video_request_status;

  SELECT COUNT(*) INTO v_in_progress
  FROM public.video_requests
  WHERE admin_approval_status = 'approved'::public.video_request_approval_status
    AND status IN ('assigned'::public.video_request_status, 'in_progress'::public.video_request_status);

  SELECT COUNT(*) INTO v_completed
  FROM public.video_requests
  WHERE admin_approval_status = 'approved'::public.video_request_approval_status
    AND status = 'completed'::public.video_request_status;

  RETURN jsonb_build_object(
    'total', v_total,
    'pending', v_pending,
    'in_progress', v_in_progress,
    'completed', v_completed
  );
END;
$$;

-- 2. RPC for fetching nested paginated video requests with search
CREATE OR REPLACE FUNCTION public.fetch_marketing_video_requests(
  p_page INT DEFAULT 1,
  p_limit INT DEFAULT 10,
  p_search_query TEXT DEFAULT ''
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
  -- Calculate offset
  v_offset := (p_page - 1) * p_limit;

  -- Count matching rows
  SELECT COUNT(*)
  INTO v_total_items
  FROM public.video_requests vr
  JOIN public.properties p ON vr.property_id = p.id
  JOIN public.brokers b ON vr.broker_id = b.id
  LEFT JOIN public.addresses a ON p.address_id = a.id
  WHERE vr.admin_approval_status = 'approved'::public.video_request_approval_status
    AND vr.status != 'cancelled'::public.video_request_status
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

  -- Aggregate JSON results with nested structures (property + address, broker + address)
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
    WHERE vr.admin_approval_status = 'approved'::public.video_request_approval_status
      AND vr.status != 'cancelled'::public.video_request_status
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
    ORDER BY vr.created_at DESC
    LIMIT p_limit
    OFFSET v_offset
  ) vr_data
  JOIN public.properties p_data ON vr_data.property_id = p_data.id
  JOIN public.brokers b_data ON vr_data.broker_id = b_data.id
  LEFT JOIN public.addresses pa_data ON p_data.address_id = pa_data.id
  LEFT JOIN public.addresses ba_data ON b_data.address_id = ba_data.id;

  RETURN jsonb_build_object(
    'success', true,
    'data', v_requests_json,
    'pagination', jsonb_build_object(
      'total_items', v_total_items,
      'total_pages', v_total_pages,
      'has_more', v_has_more
    )
  );
END;
$$;
