-- Migration: Convert platform column in social_posts and social_accounts tables to public.social_platform enum type

-- 1. Create social_platform enum type if not exists
DO $$ 
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'social_platform') THEN
    CREATE TYPE public.social_platform AS ENUM ('facebook', 'instagram');
  END IF;
END $$;

-- 2. Update social_posts.platform column from TEXT to public.social_platform enum
ALTER TABLE public.social_posts DROP CONSTRAINT IF EXISTS social_posts_platform_check;
ALTER TABLE public.social_posts 
  ALTER COLUMN platform TYPE public.social_platform 
  USING LOWER(platform)::public.social_platform;

-- 3. Update social_accounts.platform column from TEXT to public.social_platform enum
ALTER TABLE public.social_accounts DROP CONSTRAINT IF EXISTS social_accounts_platform_check;
ALTER TABLE public.social_accounts 
  ALTER COLUMN platform TYPE public.social_platform 
  USING LOWER(platform)::public.social_platform;
