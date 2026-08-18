-- Migration: Add unique constraint on social_posts table for (broker_id, platform, post_id) to ensure Supabase upsert operations succeed.

ALTER TABLE public.social_posts 
  DROP CONSTRAINT IF EXISTS social_posts_broker_platform_post_id_key;

ALTER TABLE public.social_posts 
  ADD CONSTRAINT social_posts_broker_platform_post_id_key UNIQUE (broker_id, platform, post_id);
