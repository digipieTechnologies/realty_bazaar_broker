-- Migration: Create fetch_dashboard_summary RPC function
-- Purpose: Compute & return JSONB summary metrics (todays_leads, todays_leads_growth, total_leads, total_properties, video_requests) for a broker.

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
    AND DATE(created_at AT TIME ZONE 'UTC') = CURRENT_DATE;

  -- 2. Yesterday's leads count for broker (to calculate growth)
  SELECT COUNT(*)
  INTO v_yesterdays_leads
  FROM public.social_leads
  WHERE broker_id = p_broker_id
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
  WHERE broker_id = p_broker_id;

  -- 4. Active properties count for broker
  SELECT COUNT(*)
  INTO v_total_properties
  FROM public.properties
  WHERE broker_id = p_broker_id
    AND LOWER(status) != 'deleted';

  -- 5. Active video requests count for broker
  SELECT COUNT(*)
  INTO v_video_requests
  FROM public.video_requests
  WHERE broker_id = p_broker_id
    AND LOWER(status) IN ('pending', 'accepted', 'in_progress');

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
