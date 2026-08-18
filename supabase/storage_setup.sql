-- Supabase Storage Setup SQL Script
-- Run this in your Supabase project SQL Editor to enable public uploads for social assets & property media.

-- ==========================================
-- 1. SOCIAL ASSETS BUCKET
-- ==========================================

-- Create the bucket if it doesn't already exist and force it to be public with 500MB size limit
INSERT INTO storage.buckets (id, name, public, file_size_limit)
VALUES ('social_assets', 'social_assets', true, 524288000)
ON CONFLICT (id) DO UPDATE SET public = true, file_size_limit = 524288000;

-- Enable public uploads (INSERT) for the social_assets bucket
DROP POLICY IF EXISTS "Allow public uploads to social_assets" ON storage.objects;
CREATE POLICY "Allow public uploads to social_assets"
ON storage.objects FOR INSERT
TO public
WITH CHECK (bucket_id = 'social_assets');

-- Enable public reads (SELECT) for the social_assets bucket
DROP POLICY IF EXISTS "Allow public read of social_assets" ON storage.objects;
CREATE POLICY "Allow public read of social_assets"
ON storage.objects FOR SELECT
TO public
USING (bucket_id = 'social_assets');

-- Enable updates (UPDATE) for replacing assets
DROP POLICY IF EXISTS "Allow public updates of social_assets" ON storage.objects;
CREATE POLICY "Allow public updates of social_assets"
ON storage.objects FOR UPDATE
TO public
USING (bucket_id = 'social_assets')
WITH CHECK (bucket_id = 'social_assets');


-- ==========================================
-- 2. PROPERTY MEDIA BUCKET
-- ==========================================

-- Create the bucket if it doesn't already exist and force it to be public with 500MB size limit
INSERT INTO storage.buckets (id, name, public, file_size_limit)
VALUES ('property_media', 'property_media', true, 524288000)
ON CONFLICT (id) DO UPDATE SET public = true, file_size_limit = 524288000;

-- Enable public uploads (INSERT) for the property_media bucket
DROP POLICY IF EXISTS "Allow public uploads to property_media" ON storage.objects;
CREATE POLICY "Allow public uploads to property_media"
ON storage.objects FOR INSERT
TO public
WITH CHECK (bucket_id = 'property_media');

-- Enable public reads (SELECT) for the property_media bucket
DROP POLICY IF EXISTS "Allow public read of property_media" ON storage.objects;
CREATE POLICY "Allow public read of property_media"
ON storage.objects FOR SELECT
TO public
USING (bucket_id = 'property_media');

-- Enable updates (UPDATE) for replacing assets
DROP POLICY IF EXISTS "Allow public updates of property_media" ON storage.objects;
CREATE POLICY "Allow public updates of property_media"
ON storage.objects FOR UPDATE
TO public
USING (bucket_id = 'property_media')
WITH CHECK (bucket_id = 'property_media');
