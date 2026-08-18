-- Migration: Create fetch_brokers RPC function using dynamic to_jsonb(*) row serialization in subquery
-- File: supabase/migrations/20260804130000_create_fetch_brokers_rpc.sql

CREATE OR REPLACE FUNCTION public.fetch_brokers(
  p_search_query text DEFAULT NULL,
  p_page integer DEFAULT 1,
  p_limit integer DEFAULT 10
)
RETURNS json
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_offset integer;
  v_total_items integer;
  v_total_pages integer;
  v_has_more boolean;
  v_data jsonb;
BEGIN
  -- Ensure valid page & limit values
  IF p_page < 1 THEN p_page := 1; END IF;
  IF p_limit < 1 THEN p_limit := 10; END IF;
  v_offset := (p_page - 1) * p_limit;

  -- 1. Total count of brokers matching search query on user name or business name
  SELECT COUNT(*)
  INTO v_total_items
  FROM public.users u
  LEFT JOIN public.brokers b ON u.broker_id = b.id
  WHERE u.role = 'broker'::user_role
    AND (u.is_deleted IS NOT TRUE)
    AND (
      p_search_query IS NULL OR TRIM(p_search_query) = '' OR
      u.name ILIKE '%' || TRIM(p_search_query) || '%' OR
      b.business_name ILIKE '%' || TRIM(p_search_query) || '%'
    );

  v_total_pages := CEIL(v_total_items::decimal / p_limit::decimal);
  IF v_total_pages < 1 THEN v_total_pages := 1; END IF;
  v_has_more := (p_page < v_total_pages);

  -- 2. Fetch brokers using subquery for sorting/pagination, then jsonb_agg
  SELECT COALESCE(jsonb_agg(t.broker_json), '[]'::jsonb)
  INTO v_data
  FROM (
    SELECT 
      to_jsonb(u.*)
      || jsonb_build_object(
        'broker_id', CASE 
          WHEN b.id IS NOT NULL THEN 
            to_jsonb(b.*) || jsonb_build_object(
              'address_id', (
                SELECT to_jsonb(a.*) 
                FROM public.addresses a 
                WHERE a.id = b.address_id
              )
            )
          ELSE NULL 
        END,
        'social_accounts', (
          SELECT COALESCE(jsonb_agg(to_jsonb(sa.*)), '[]'::jsonb)
          FROM public.social_accounts sa
          WHERE b.id IS NOT NULL AND sa.broker_id = b.id
        )
      ) AS broker_json
    FROM public.users u
    LEFT JOIN public.brokers b ON u.broker_id = b.id
    WHERE u.role = 'broker'::user_role
      AND (u.is_deleted IS NOT TRUE)
      AND (
        p_search_query IS NULL OR TRIM(p_search_query) = '' OR
        u.name ILIKE '%' || TRIM(p_search_query) || '%' OR
        b.business_name ILIKE '%' || TRIM(p_search_query) || '%'
      )
    ORDER BY u.created_at DESC
    OFFSET v_offset
    LIMIT p_limit
  ) t;

  -- 3. Return structured response
  RETURN json_build_object(
    'success', true,
    'data', v_data,
    'pagination', json_build_object(
      'current_page', p_page,
      'items_per_page', p_limit,
      'total_items', v_total_items,
      'total_pages', v_total_pages,
      'has_more', v_has_more
    )
  );
END;
$$;
