-- Migration: Update get_social_leads RPC function to support p_platforms array filter and nested to_jsonb serialization.

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
  -- Calculate offset for pagination
  v_offset := (p_page - 1) * p_limit;

  -- 1. Calculate total items matching the filter
  SELECT COUNT(*)
  INTO v_total_items
  FROM public.social_leads sl
  LEFT JOIN public.social_posts sp ON sl.social_post_id = sp.id
  LEFT JOIN public.properties p ON sp.property_id = p.id
  LEFT JOIN public.addresses a ON p.address_id = a.id
  WHERE (p_broker_id IS NULL OR sl.broker_id = p_broker_id)
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

  -- Calculate pagination details
  IF v_total_items = 0 THEN
    v_total_pages := 1;
    v_has_more := false;
  ELSE
    v_total_pages := CEIL(v_total_items::NUMERIC / p_limit)::INT;
    v_has_more := (p_page * p_limit) < v_total_items;
  END IF;

  -- 2. Fetch leads with pagination, ordering by latest first, and nested serialization
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
