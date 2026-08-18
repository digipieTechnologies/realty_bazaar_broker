-- Migration: Safely cast platform to text in generate_social_posts_search_text trigger function to prevent enum casting errors on INSERT/UPDATE.

CREATE OR REPLACE FUNCTION public.generate_social_posts_search_text()
RETURNS TRIGGER AS $$
BEGIN
  NEW.search_text := COALESCE(NEW.caption, '') || ' ' || COALESCE(NEW.platform::text, '');
  NEW.fts := to_tsvector('english', COALESCE(NEW.search_text, ''));
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Re-create trigger on social_posts
DROP TRIGGER IF EXISTS trg_social_posts_search_text ON public.social_posts;

CREATE TRIGGER trg_social_posts_search_text
BEFORE INSERT OR UPDATE ON public.social_posts
FOR EACH ROW
EXECUTE FUNCTION public.generate_social_posts_search_text();
