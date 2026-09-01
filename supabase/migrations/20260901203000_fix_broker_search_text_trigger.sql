-- Migration: Fix generate_brokers_search_text trigger function to remove references to dropped plan column
-- File: supabase/migrations/20260901203000_fix_broker_search_text_trigger.sql

CREATE OR REPLACE FUNCTION public.generate_brokers_search_text()
RETURNS TRIGGER AS $$
DECLARE
  combined_text text;
BEGIN
  combined_text := lower(
    coalesce(NEW.id::text, '') || ' ' ||
    coalesce(NEW.business_name, '') || ' ' ||
    coalesce(NEW.onboarding_status, '')
  );
  NEW.search_text := combined_text;
  NEW.fts := to_tsvector('simple', combined_text);
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;
