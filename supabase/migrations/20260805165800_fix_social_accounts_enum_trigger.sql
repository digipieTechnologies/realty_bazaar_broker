-- Migration: Fix generate_social_accounts_search_text and generate_social_posts_search_text trigger functions
-- Root Cause: coalesce(NEW.platform, '') tried to cast the fallback '' to public.social_platform enum, throwing invalid input value for enum social_platform: ""

CREATE OR REPLACE FUNCTION generate_social_accounts_search_text()
RETURNS trigger AS $$
DECLARE
  combined_text text;
BEGIN
  combined_text := lower(
    coalesce(NEW.id::text, '') || ' ' ||
    coalesce(NEW.page_name, '') || ' ' ||
    coalesce(NEW.platform::text, '') || ' ' ||
    coalesce(NEW.page_id, '') || ' ' ||
    coalesce(NEW.instagram_username, '')
  );
  NEW.search_text := combined_text;
  NEW.fts := to_tsvector('simple', combined_text);
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION generate_social_posts_search_text()
RETURNS trigger AS $$
DECLARE
  combined_text text;
BEGIN
  combined_text := lower(
    coalesce(NEW.id::text, '') || ' ' ||
    coalesce(NEW.caption, '') || ' ' ||
    coalesce(NEW.platform::text, '') || ' ' ||
    coalesce(NEW.post_id, '') || ' ' ||
    coalesce(NEW.page_id, '')
  );
  NEW.search_text := combined_text;
  NEW.fts := to_tsvector('simple', combined_text);
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;
