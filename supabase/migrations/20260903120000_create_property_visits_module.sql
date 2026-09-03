-- =============================================================================
-- Migration: 20260903120000_create_property_visits_module.sql
-- Description: Creates the property_visits and property_visit_history tables,
--              triggers for search_text/fts and audit history, RLS policies,
--              realtime publication, and the get_property_visits RPC function.
-- =============================================================================

-- 1. Create property_visits table
CREATE TABLE IF NOT EXISTS public.property_visits (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  broker_id uuid NOT NULL,
  property_id uuid NOT NULL,
  client_name text NOT NULL,
  client_phone text NOT NULL,
  phone_country_code text DEFAULT '91'::text,
  phone_country_iso text DEFAULT 'IN'::text,
  visit_date date NOT NULL,
  time_slot text NOT NULL,
  status text NOT NULL DEFAULT 'pending'::text CHECK (
    status = ANY (ARRAY['pending'::text, 'confirmed'::text, 'rescheduled'::text, 'completed'::text, 'cancelled'::text, 'no_show'::text])
  ),
  notes text,
  reschedule_count integer NOT NULL DEFAULT 0,
  reschedule_reason text,
  cancelled_reason text,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  updated_at timestamp with time zone NOT NULL DEFAULT now(),
  is_deleted boolean NOT NULL DEFAULT false,
  deleted_at timestamp with time zone,
  search_text text,
  fts tsvector,
  CONSTRAINT property_visits_pkey PRIMARY KEY (id),
  CONSTRAINT property_visits_broker_id_fkey FOREIGN KEY (broker_id) REFERENCES public.brokers(id) ON DELETE CASCADE,
  CONSTRAINT property_visits_property_id_fkey FOREIGN KEY (property_id) REFERENCES public.properties(id) ON DELETE CASCADE
);

-- 2. Create property_visit_history audit table
CREATE TABLE IF NOT EXISTS public.property_visit_history (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  visit_id uuid NOT NULL,
  action text NOT NULL,
  previous_status text,
  new_status text,
  previous_visit_date date,
  new_visit_date date,
  previous_time_slot text,
  new_time_slot text,
  reason text,
  notes text,
  changed_by_user_id uuid,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT property_visit_history_pkey PRIMARY KEY (id),
  CONSTRAINT property_visit_history_visit_id_fkey FOREIGN KEY (visit_id) REFERENCES public.property_visits(id) ON DELETE CASCADE,
  CONSTRAINT property_visit_history_changed_by_user_id_fkey FOREIGN KEY (changed_by_user_id) REFERENCES auth.users(id) ON DELETE SET NULL
);

-- 3. Indexes for high performance querying
CREATE INDEX IF NOT EXISTS idx_property_visits_broker_id ON public.property_visits(broker_id);
CREATE INDEX IF NOT EXISTS idx_property_visits_property_id ON public.property_visits(property_id);
CREATE INDEX IF NOT EXISTS idx_property_visits_visit_date ON public.property_visits(visit_date);
CREATE INDEX IF NOT EXISTS idx_property_visits_status ON public.property_visits(status);
CREATE INDEX IF NOT EXISTS idx_property_visits_created_at ON public.property_visits(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_property_visits_fts ON public.property_visits USING gin(fts);
CREATE INDEX IF NOT EXISTS idx_property_visit_history_visit_id ON public.property_visit_history(visit_id);
CREATE INDEX IF NOT EXISTS idx_property_visit_history_created_at ON public.property_visit_history(created_at DESC);

-- 4. Enable Supabase Realtime
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_publication_tables 
    WHERE pubname = 'supabase_realtime' 
      AND schemaname = 'public' 
      AND tablename = 'property_visits'
  ) THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.property_visits;
  END IF;
END $$;

-- 5. Trigger for updated_at and search_text/fts vector
CREATE OR REPLACE FUNCTION public.trg_property_visits_before_upsert()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
  NEW.updated_at := now();
  NEW.search_text := LOWER(
    COALESCE(NEW.client_name, '') || ' ' ||
    COALESCE(NEW.client_phone, '') || ' ' ||
    COALESCE(NEW.time_slot, '') || ' ' ||
    COALESCE(NEW.notes, '') || ' ' ||
    COALESCE(NEW.reschedule_reason, '') || ' ' ||
    COALESCE(NEW.cancelled_reason, '')
  );
  NEW.fts := to_tsvector('simple', COALESCE(NEW.search_text, ''));
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS property_visits_before_upsert ON public.property_visits;
CREATE TRIGGER property_visits_before_upsert
  BEFORE INSERT OR UPDATE ON public.property_visits
  FOR EACH ROW
  EXECUTE FUNCTION public.trg_property_visits_before_upsert();

-- 6. Trigger to automatically log all audit history
CREATE OR REPLACE FUNCTION public.trg_log_property_visit_history()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_action text;
BEGIN
  IF TG_OP = 'INSERT' THEN
    INSERT INTO public.property_visit_history (
      visit_id,
      action,
      previous_status,
      new_status,
      previous_visit_date,
      new_visit_date,
      previous_time_slot,
      new_time_slot,
      reason,
      notes,
      changed_by_user_id
    ) VALUES (
      NEW.id,
      'created',
      NULL,
      NEW.status,
      NULL,
      NEW.visit_date,
      NULL,
      NEW.time_slot,
      NULL,
      NEW.notes,
      auth.uid()
    );
  ELSIF TG_OP = 'UPDATE' THEN
    -- Check if date or slot rescheduled
    IF (NEW.visit_date IS DISTINCT FROM OLD.visit_date) OR (NEW.time_slot IS DISTINCT FROM OLD.time_slot) THEN
      v_action := 'rescheduled';
    ELSIF NEW.status IS DISTINCT FROM OLD.status THEN
      v_action := CASE 
        WHEN NEW.status = 'cancelled' THEN 'cancelled'
        WHEN NEW.status = 'completed' THEN 'completed'
        WHEN NEW.status = 'no_show' THEN 'no_show'
        WHEN NEW.status = 'confirmed' THEN 'confirmed'
        ELSE 'status_changed'
      END;
    ELSE
      v_action := 'updated';
    END IF;

    -- Only log when meaningful changes occur
    IF (NEW.visit_date IS DISTINCT FROM OLD.visit_date) 
       OR (NEW.time_slot IS DISTINCT FROM OLD.time_slot) 
       OR (NEW.status IS DISTINCT FROM OLD.status)
       OR (NEW.reschedule_reason IS DISTINCT FROM OLD.reschedule_reason)
       OR (NEW.cancelled_reason IS DISTINCT FROM OLD.cancelled_reason) THEN
      INSERT INTO public.property_visit_history (
        visit_id,
        action,
        previous_status,
        new_status,
        previous_visit_date,
        new_visit_date,
        previous_time_slot,
        new_time_slot,
        reason,
        notes,
        changed_by_user_id
      ) VALUES (
        NEW.id,
        v_action,
        OLD.status,
        NEW.status,
        OLD.visit_date,
        NEW.visit_date,
        OLD.time_slot,
        NEW.time_slot,
        COALESCE(NEW.reschedule_reason, NEW.cancelled_reason),
        NEW.notes,
        auth.uid()
      );
    END IF;
  END IF;

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS property_visits_audit_trigger ON public.property_visits;
CREATE TRIGGER property_visits_audit_trigger
  AFTER INSERT OR UPDATE ON public.property_visits
  FOR EACH ROW
  EXECUTE FUNCTION public.trg_log_property_visit_history();

-- 7. Row Level Security (RLS) Policies
ALTER TABLE public.property_visits ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.property_visit_history ENABLE ROW LEVEL SECURITY;

-- Brokers can view visits for their brokerage
CREATE POLICY "Brokers can view visits for their broker_id"
  ON public.property_visits
  FOR SELECT
  TO authenticated
  USING (
    broker_id IN (
      SELECT broker_id FROM public.users WHERE id = auth.uid() AND is_deleted IS FALSE
    )
  );

-- Brokers can insert visits for their brokerage
CREATE POLICY "Brokers can insert visits"
  ON public.property_visits
  FOR INSERT
  TO authenticated
  WITH CHECK (
    broker_id IN (
      SELECT broker_id FROM public.users WHERE id = auth.uid() AND is_deleted IS FALSE
    )
  );

-- Allow public/anonymous insert for client site visit requests from external links/web listings
CREATE POLICY "Public can submit visit requests"
  ON public.property_visits
  FOR INSERT
  TO anon
  WITH CHECK (true);

-- Brokers can update their visits
CREATE POLICY "Brokers can update visits for their broker_id"
  ON public.property_visits
  FOR UPDATE
  TO authenticated
  USING (
    broker_id IN (
      SELECT broker_id FROM public.users WHERE id = auth.uid() AND is_deleted IS FALSE
    )
  );

-- Brokers can view visit history
CREATE POLICY "Brokers can view visit history"
  ON public.property_visit_history
  FOR SELECT
  TO authenticated
  USING (
    visit_id IN (
      SELECT id FROM public.property_visits
      WHERE broker_id IN (
        SELECT broker_id FROM public.users WHERE id = auth.uid() AND is_deleted IS FALSE
      )
    )
  );

-- 8. High performance paginated RPC: get_property_visits
CREATE OR REPLACE FUNCTION public.get_property_visits(
  p_broker_id UUID DEFAULT NULL,
  p_page INT DEFAULT 1,
  p_limit INT DEFAULT 10,
  p_search_query TEXT DEFAULT '',
  p_statuses TEXT[] DEFAULT NULL,
  p_date_filter TEXT DEFAULT 'all',
  p_property_id UUID DEFAULT NULL
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
  v_visits_json JSONB;
  v_today DATE := CURRENT_DATE;
BEGIN
  v_offset := (p_page - 1) * p_limit;

  -- 1. Calculate total matching items (excluding soft deleted)
  SELECT COUNT(*)
  INTO v_total_items
  FROM public.property_visits pv
  JOIN public.properties p ON pv.property_id = p.id
  WHERE (p_broker_id IS NULL OR pv.broker_id = p_broker_id)
    AND (p_property_id IS NULL OR pv.property_id = p_property_id)
    AND (pv.is_deleted IS FALSE OR pv.is_deleted IS NULL)
    AND (
      p_statuses IS NULL 
      OR array_length(p_statuses, 1) IS NULL 
      OR array_length(p_statuses, 1) = 0
      OR pv.status = ANY(ARRAY(SELECT LOWER(unnest(p_statuses))))
    )
    AND (
      p_date_filter = 'all' OR
      (p_date_filter = 'today' AND pv.visit_date = v_today) OR
      (p_date_filter = 'upcoming' AND pv.visit_date > v_today) OR
      (p_date_filter = 'past' AND pv.visit_date < v_today)
    )
    AND (
      p_search_query = '' OR
      pv.client_name ILIKE '%' || p_search_query || '%' OR
      pv.client_phone ILIKE '%' || p_search_query || '%' OR
      pv.time_slot ILIKE '%' || p_search_query || '%' OR
      pv.notes ILIKE '%' || p_search_query || '%' OR
      p.property_title ILIKE '%' || p_search_query || '%' OR
      p.property_code ILIKE '%' || p_search_query || '%'
    );

  IF v_total_items = 0 THEN
    v_total_pages := 1;
    v_has_more := false;
  ELSE
    v_total_pages := CEIL(v_total_items::NUMERIC / p_limit)::INT;
    v_has_more := (p_page * p_limit) < v_total_items;
  END IF;

  -- 2. Fetch paginated visits with joined property, address, broker, and history
  SELECT COALESCE(jsonb_agg(
    to_jsonb(v_data) ||
    jsonb_build_object(
      'property',
      CASE 
        WHEN prop.id IS NOT NULL THEN
          to_jsonb(prop) || jsonb_build_object(
            'address',
            CASE 
              WHEN addr.id IS NOT NULL THEN to_jsonb(addr)
              ELSE NULL
            END
          )
        ELSE NULL
      END,
      'broker',
      CASE 
        WHEN brk.id IS NOT NULL THEN to_jsonb(brk)
        ELSE NULL
      END,
      'history',
      COALESCE((
        SELECT jsonb_agg(to_jsonb(hist) ORDER BY hist.created_at DESC)
        FROM public.property_visit_history hist
        WHERE hist.visit_id = v_data.id
      ), '[]'::jsonb)
    )
  ), '[]'::jsonb)
  INTO v_visits_json
  FROM (
    SELECT pv.*
    FROM public.property_visits pv
    JOIN public.properties p ON pv.property_id = p.id
    WHERE (p_broker_id IS NULL OR pv.broker_id = p_broker_id)
      AND (p_property_id IS NULL OR pv.property_id = p_property_id)
      AND (pv.is_deleted IS FALSE OR pv.is_deleted IS NULL)
      AND (
        p_statuses IS NULL 
        OR array_length(p_statuses, 1) IS NULL 
        OR array_length(p_statuses, 1) = 0
        OR pv.status = ANY(ARRAY(SELECT LOWER(unnest(p_statuses))))
      )
      AND (
        p_date_filter = 'all' OR
        (p_date_filter = 'today' AND pv.visit_date = v_today) OR
        (p_date_filter = 'upcoming' AND pv.visit_date > v_today) OR
        (p_date_filter = 'past' AND pv.visit_date < v_today)
      )
      AND (
        p_search_query = '' OR
        pv.client_name ILIKE '%' || p_search_query || '%' OR
        pv.client_phone ILIKE '%' || p_search_query || '%' OR
        pv.time_slot ILIKE '%' || p_search_query || '%' OR
        pv.notes ILIKE '%' || p_search_query || '%' OR
        p.property_title ILIKE '%' || p_search_query || '%' OR
        p.property_code ILIKE '%' || p_search_query || '%'
      )
    ORDER BY 
      CASE WHEN pv.status = 'pending' THEN 0 WHEN pv.status = 'rescheduled' THEN 1 ELSE 2 END ASC,
      pv.visit_date ASC,
      pv.created_at DESC
    LIMIT p_limit OFFSET v_offset
  ) v_data
  LEFT JOIN public.properties prop ON v_data.property_id = prop.id
  LEFT JOIN public.brokers brk ON v_data.broker_id = brk.id
  LEFT JOIN public.addresses addr ON prop.address_id = addr.id;

  RETURN jsonb_build_object(
    'success', true,
    'data', v_visits_json,
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

GRANT EXECUTE ON FUNCTION public.get_property_visits(UUID, INT, INT, TEXT, TEXT[], TEXT, UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_property_visits(UUID, INT, INT, TEXT, TEXT[], TEXT, UUID) TO service_role;
GRANT EXECUTE ON FUNCTION public.get_property_visits(UUID, INT, INT, TEXT, TEXT[], TEXT, UUID) TO anon;
