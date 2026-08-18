-- Migration: Fix generate_users_search_text trigger function for user_role and user_gender enums
-- File: supabase/migrations/20260806163000_fix_users_enum_search_text_trigger.sql
-- Root Cause: coalesce(NEW.role, '') tried to cast fallback '' to public.user_role enum, throwing invalid input value for enum user_role: ""

CREATE OR REPLACE FUNCTION generate_users_search_text()
RETURNS trigger AS $$
DECLARE
  combined_text text;
BEGIN
  combined_text := lower(
    coalesce(NEW.id::text, '') || ' ' ||
    coalesce(NEW.name, '') || ' ' ||
    coalesce(NEW.email, '') || ' ' ||
    coalesce(NEW.phone, '') || ' ' ||
    coalesce(NEW.phone_country_code, '') || ' ' ||
    coalesce(NEW.phone_country_iso, '') || ' ' ||
    coalesce(NEW.role::text, '') || ' ' ||
    coalesce(NEW.gender::text, '')
  );
  NEW.search_text := combined_text;
  NEW.fts := to_tsvector('simple', combined_text);
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_users_search_text ON public.users;
CREATE TRIGGER trg_users_search_text
BEFORE INSERT OR UPDATE ON public.users
FOR EACH ROW EXECUTE FUNCTION generate_users_search_text();
