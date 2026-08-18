-- Migration: 20260812110000_update_all_rpcs_and_soft_delete_policies.sql
-- Purpose: 
-- 1. Create/Update RLS policies on properties, social_leads, and video_requests so soft-deleted (is_deleted = true) rows are hidden from regular queries unless requested by an admin role.
-- 2. Update RPC functions (fetch_dashboard_summary, get_social_leads, fetch_properties, fetch_video_requests, fetch_video_request_counts) to cleanly handle column schemas and exclude soft-deleted records.

-- =============================================================================
-- PART 1: RLS POLICIES FOR SOFT-DELETED RECORDS
-- =============================================================================

ALTER TABLE public.properties ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.social_leads ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.video_requests ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Hide soft-deleted properties for non-admins" ON public.properties;
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

DROP POLICY IF EXISTS "Hide soft-deleted social leads for non-admins" ON public.social_leads;
CREATE POLICY "Hide soft-deleted social leads for non-admins" ON public.social_leads
  FOR SELECT
  USING (
    (is_deleted IS FALSE OR is_deleted IS NULL)
    OR EXISTS (
      SELECT 1 FROM public.users u
      WHERE u.id = auth.uid()
        AND LOWER(u.role::text) IN ('super_admin', 'superadmin', 'admin')
    )
  );

DROP POLICY IF EXISTS "Hide soft-deleted video requests for non-admins" ON public.video_requests;
CREATE POLICY "Hide soft-deleted video requests for non-admins" ON public.video_requests
  FOR SELECT
  USING (
    (is_deleted IS FALSE OR is_deleted IS NULL)
    OR EXISTS (
      SELECT 1 FROM public.users u
      WHERE u.id = auth.uid()
        AND LOWER(u.role::text) IN ('super_admin', 'superadmin', 'admin')
    )
  );

-- =============================================================================
-- PART 2: RPC FUNCTION 1 - fetch_dashboard_summary
-- =============================================================================

CREATE OR REPLACE FUNCTION public.fetch_dashboard_summary(p_broker_id UUID)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_todays_leads INT := 0;
  v_yesterdays_leads INT := 0;
  v_growth_str TEXT := '+0%';
  v_total_leads INT := 0;
  v_total_properties INT := 0;
  v_video_requests INT := 0;
BEGIN
  -- 1. Today's leads count for broker
  SELECT COUNT(*)
  INTO v_todays_leads
  FROM public.social_leads
  WHERE broker_id = p_broker_id
    AND (is_deleted IS FALSE OR is_deleted IS NULL)
    AND DATE(created_at AT TIME ZONE 'UTC') = CURRENT_DATE;

  -- 2. Yesterday's leads count for broker (to calculate growth)
  SELECT COUNT(*)
  INTO v_yesterdays_leads
  FROM public.social_leads
  WHERE broker_id = p_broker_id
    AND (is_deleted IS FALSE OR is_deleted IS NULL)
    AND DATE(created_at AT TIME ZONE 'UTC') = CURRENT_DATE - INTERVAL '1 day';

  IF v_yesterdays_leads = 0 THEN
    IF v_todays_leads > 0 THEN
      v_growth_str := '+' || (v_todays_leads * 100)::TEXT || '%';
    ELSE
      v_growth_str := '+0%';
    END IF;
  ELSE
    DECLARE
      v_diff NUMERIC;
    BEGIN
      v_diff := ((v_todays_leads - v_yesterdays_leads)::NUMERIC / v_yesterdays_leads::NUMERIC) * 100.0;
      IF v_diff >= 0 THEN
        v_growth_str := '+' || ROUND(v_diff, 0)::TEXT || '%';
      ELSE
        v_growth_str := ROUND(v_diff, 0)::TEXT || '%';
      END IF;
    END;
  END IF;

  -- 3. Total leads count for broker
  SELECT COUNT(*)
  INTO v_total_leads
  FROM public.social_leads
  WHERE broker_id = p_broker_id
    AND (is_deleted IS FALSE OR is_deleted IS NULL);

  -- 4. Total non-deleted properties count for broker
  SELECT COUNT(*)
  INTO v_total_properties
  FROM public.properties
  WHERE broker_id = p_broker_id
    AND (is_deleted IS FALSE OR is_deleted IS NULL);

  -- 5. Active video requests count for broker (pending or in_progress)
  SELECT COUNT(*)
  INTO v_video_requests
  FROM public.video_requests
  WHERE broker_id = p_broker_id
    AND (is_deleted IS FALSE OR is_deleted IS NULL)
    AND LOWER(status::text) IN ('pending', 'assigned', 'in_progress');

  RETURN jsonb_build_object(
    'todays_leads', v_todays_leads,
    'todays_leads_growth', v_growth_str,
    'total_leads', v_total_leads,
    'total_properties', v_total_properties,
    'video_requests', v_video_requests
  );
END;
$$;

GRANT EXECUTE ON FUNCTION public.fetch_dashboard_summary(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION public.fetch_dashboard_summary(UUID) TO service_role;

-- =============================================================================
-- PART 3: RPC FUNCTION 2 - get_social_leads
-- =============================================================================

CREATE OR REPLACE FUNCTION public.get_social_leads(
  p_broker_id UUID DEFAULT NULL,
  p_page INT DEFAULT 1,
  p_limit INT DEFAULT 10,
  p_search_query TEXT DEFAULT '',
  p_platforms TEXT[] DEFAULT NULL
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
  v_leads_json JSONB;
BEGIN
  v_offset := (p_page - 1) * p_limit;

  -- 1. Calculate total items matching the filter (excluding deleted leads)
  SELECT COUNT(*)
  INTO v_total_items
  FROM public.social_leads sl
  LEFT JOIN public.social_posts sp ON sl.social_post_id = sp.id
  LEFT JOIN public.properties p ON sp.property_id = p.id
  LEFT JOIN public.addresses a ON p.address_id = a.id
  WHERE (p_broker_id IS NULL OR sl.broker_id = p_broker_id)
    AND (sl.is_deleted IS FALSE OR sl.is_deleted IS NULL)
    AND (
      p_platforms IS NULL 
      OR array_length(p_platforms, 1) IS NULL 
      OR array_length(p_platforms, 1) = 0
      OR (
        'other' = ANY(ARRAY(SELECT LOWER(unnest(p_platforms)))) AND (
          sl.social_post_id IS NULL OR LOWER(COALESCE(sp.platform::text, '')) NOT IN ('facebook', 'instagram')
        )
      )
      OR LOWER(COALESCE(sp.platform::text, '')) = ANY(ARRAY(SELECT LOWER(unnest(p_platforms))))
    )
    AND (
      p_search_query = '' OR
      sl.user_name ILIKE '%' || p_search_query || '%' OR
      sl.phone ILIKE '%' || p_search_query || '%' OR
      sl.property_details ILIKE '%' || p_search_query || '%' OR
      sl.notes ILIKE '%' || p_search_query || '%' OR
      (sp.id IS NOT NULL AND sp.caption ILIKE '%' || p_search_query || '%') OR
      (p.id IS NOT NULL AND p.property_title ILIKE '%' || p_search_query || '%')
    );

  IF v_total_items = 0 THEN
    v_total_pages := 1;
    v_has_more := false;
  ELSE
    v_total_pages := CEIL(v_total_items::NUMERIC / p_limit)::INT;
    v_has_more := (p_page * p_limit) < v_total_items;
  END IF;

  -- 2. Fetch leads with pagination
  SELECT COALESCE(jsonb_agg(
    to_jsonb(sl_data) ||
    jsonb_build_object(
      'social_posts',
      CASE 
        WHEN sp_data.id IS NOT NULL THEN
          to_jsonb(sp_data) || jsonb_build_object(
            'properties',
            CASE 
              WHEN p_data.id IS NOT NULL THEN
                to_jsonb(p_data) || jsonb_build_object(
                  'address',
                  CASE 
                    WHEN a_data.id IS NOT NULL THEN to_jsonb(a_data)
                    ELSE NULL
                  END
                )
              ELSE NULL
            END
          )
        ELSE NULL
      END,
      'broker',
      CASE 
        WHEN b_data.id IS NOT NULL THEN to_jsonb(b_data)
        ELSE NULL
      END
    )
  ), '[]'::jsonb)
  INTO v_leads_json
  FROM (
    SELECT sl.*
    FROM public.social_leads sl
    LEFT JOIN public.social_posts sp ON sl.social_post_id = sp.id
    LEFT JOIN public.properties p ON sp.property_id = p.id
    LEFT JOIN public.addresses a ON p.address_id = a.id
    WHERE (p_broker_id IS NULL OR sl.broker_id = p_broker_id)
      AND (sl.is_deleted IS FALSE OR sl.is_deleted IS NULL)
      AND (
        p_platforms IS NULL 
        OR array_length(p_platforms, 1) IS NULL 
        OR array_length(p_platforms, 1) = 0
        OR (
          'other' = ANY(ARRAY(SELECT LOWER(unnest(p_platforms)))) AND (
            sl.social_post_id IS NULL OR LOWER(COALESCE(sp.platform::text, '')) NOT IN ('facebook', 'instagram')
          )
        )
        OR LOWER(COALESCE(sp.platform::text, '')) = ANY(ARRAY(SELECT LOWER(unnest(p_platforms))))
      )
      AND (
        p_search_query = '' OR
        sl.user_name ILIKE '%' || p_search_query || '%' OR
        sl.phone ILIKE '%' || p_search_query || '%' OR
        sl.property_details ILIKE '%' || p_search_query || '%' OR
        sl.notes ILIKE '%' || p_search_query || '%' OR
        (sp.id IS NOT NULL AND sp.caption ILIKE '%' || p_search_query || '%') OR
        (p.id IS NOT NULL AND p.property_title ILIKE '%' || p_search_query || '%')
      )
    ORDER BY sl.created_at DESC
    LIMIT p_limit OFFSET v_offset
  ) sl_data
  LEFT JOIN public.social_posts sp_data ON sl_data.social_post_id = sp_data.id
  LEFT JOIN public.properties p_data ON sp_data.property_id = p_data.id
  LEFT JOIN public.brokers b_data ON sl_data.broker_id = b_data.id
  LEFT JOIN public.addresses a_data ON p_data.address_id = a_data.id;

  RETURN jsonb_build_object(
    'success', true,
    'data', v_leads_json,
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

GRANT EXECUTE ON FUNCTION public.get_social_leads(UUID, INT, INT, TEXT, TEXT[]) TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_social_leads(UUID, INT, INT, TEXT, TEXT[]) TO service_role;

-- =============================================================================
-- PART 4: RPC FUNCTION 3 - fetch_video_requests
-- =============================================================================

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
  v_offset := (p_page - 1) * p_limit;

  -- 1. Calculate total items matching the filter (excluding deleted video_requests & properties)
  SELECT COUNT(*)
  INTO v_total_items
  FROM public.video_requests vr
  JOIN public.properties p ON vr.property_id = p.id
  JOIN public.brokers b ON vr.broker_id = b.id
  LEFT JOIN public.addresses a ON p.address_id = a.id
  WHERE (p_broker_id IS NULL OR vr.broker_id = p_broker_id)
    AND (vr.is_deleted IS FALSE OR vr.is_deleted IS NULL)
    AND (p.is_deleted IS FALSE OR p.is_deleted IS NULL)
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

  IF v_total_items = 0 THEN
    v_total_pages := 1;
    v_has_more := false;
  ELSE
    v_total_pages := CEIL(v_total_items::NUMERIC / p_limit)::INT;
    v_has_more := (p_page * p_limit) < v_total_items;
  END IF;

  -- 2. Fetch the video requests with pagination
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
      AND (vr.is_deleted IS FALSE OR vr.is_deleted IS NULL)
      AND (p.is_deleted IS FALSE OR p.is_deleted IS NULL)
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

GRANT EXECUTE ON FUNCTION public.fetch_video_requests(UUID, INT, INT, TEXT, public.video_request_approval_status, public.video_request_status, TEXT[]) TO authenticated;
GRANT EXECUTE ON FUNCTION public.fetch_video_requests(UUID, INT, INT, TEXT, public.video_request_approval_status, public.video_request_status, TEXT[]) TO service_role;

-- =============================================================================
-- PART 5: RPC FUNCTION 4 - fetch_video_request_counts
-- =============================================================================

CREATE OR REPLACE FUNCTION public.fetch_video_request_counts(
  p_broker_id UUID DEFAULT NULL,
  p_admin_approved_status public.video_request_approval_status DEFAULT NULL,
  p_status public.video_request_status DEFAULT NULL
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_total INT;
  v_pending INT;
  v_in_progress INT;
  v_completed INT;
  v_cancelled INT;
BEGIN
  -- Total count includes all non-deleted matching requests
  SELECT COUNT(*) INTO v_total
  FROM public.video_requests
  WHERE (p_broker_id IS NULL OR broker_id = p_broker_id)
    AND (is_deleted IS FALSE OR is_deleted IS NULL)
    AND (p_admin_approved_status IS NULL OR admin_approval_status = p_admin_approved_status)
    AND (p_status IS NULL OR status = p_status);

  -- Pending count
  SELECT COUNT(*) INTO v_pending
  FROM public.video_requests
  WHERE (p_broker_id IS NULL OR broker_id = p_broker_id)
    AND (is_deleted IS FALSE OR is_deleted IS NULL)
    AND (p_admin_approved_status IS NULL OR admin_approval_status = p_admin_approved_status)
    AND (p_status IS NULL OR status = p_status)
    AND status = 'pending'::public.video_request_status;

  -- In-progress count
  SELECT COUNT(*) INTO v_in_progress
  FROM public.video_requests
  WHERE (p_broker_id IS NULL OR broker_id = p_broker_id)
    AND (is_deleted IS FALSE OR is_deleted IS NULL)
    AND (p_admin_approved_status IS NULL OR admin_approval_status = p_admin_approved_status)
    AND (p_status IS NULL OR status = p_status)
    AND status IN ('assigned'::public.video_request_status, 'in_progress'::public.video_request_status);

  -- Completed count
  SELECT COUNT(*) INTO v_completed
  FROM public.video_requests
  WHERE (p_broker_id IS NULL OR broker_id = p_broker_id)
    AND (is_deleted IS FALSE OR is_deleted IS NULL)
    AND (p_admin_approved_status IS NULL OR admin_approval_status = p_admin_approved_status)
    AND (p_status IS NULL OR status = p_status)
    AND status = 'completed'::public.video_request_status;

  -- Cancelled count
  SELECT COUNT(*) INTO v_cancelled
  FROM public.video_requests
  WHERE (p_broker_id IS NULL OR broker_id = p_broker_id)
    AND (is_deleted IS FALSE OR is_deleted IS NULL)
    AND (p_admin_approved_status IS NULL OR admin_approval_status = p_admin_approved_status)
    AND (p_status IS NULL OR status = p_status)
    AND status = 'cancelled'::public.video_request_status;

  RETURN jsonb_build_object(
    'total', v_total,
    'pending', v_pending,
    'in_progress', v_in_progress,
    'completed', v_completed,
    'cancelled', v_cancelled
  );
END;
$$;

GRANT EXECUTE ON FUNCTION public.fetch_video_request_counts(UUID, public.video_request_approval_status, public.video_request_status) TO authenticated;
GRANT EXECUTE ON FUNCTION public.fetch_video_request_counts(UUID, public.video_request_approval_status, public.video_request_status) TO service_role;
