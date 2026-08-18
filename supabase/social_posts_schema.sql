-- Create the social_posts table to store synced feeds and reels
CREATE TABLE IF NOT EXISTS public.social_posts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    broker_id UUID NOT NULL REFERENCES public.brokers(id) ON DELETE CASCADE,
    platform TEXT NOT NULL CHECK (platform IN ('facebook', 'instagram')),
    page_id TEXT NOT NULL, -- Facebook Page ID or Instagram Business Account ID
    post_id TEXT NOT NULL, -- Platform-specific post ID
    caption TEXT,
    media_urls JSONB DEFAULT '[]'::jsonb, -- Array of media items (e.g., [{type: "image", url: "...", thumbnail: "..."}])
    permalink TEXT,
    views_count INTEGER DEFAULT 0,
    comment_count INTEGER DEFAULT 0,
    likes_count INTEGER DEFAULT 0,
    published_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    CONSTRAINT unique_broker_platform_post UNIQUE (broker_id, platform, post_id)
);

-- Index for faster queries by broker and platform
CREATE INDEX IF NOT EXISTS idx_social_posts_broker_platform ON public.social_posts (broker_id, platform);

-- Enable Row Level Security
ALTER TABLE public.social_posts ENABLE ROW LEVEL SECURITY;

-- Create RLS Policies
-- Allow authenticated users to read posts
CREATE POLICY "Allow authenticated read access"
    ON public.social_posts
    FOR SELECT
    TO authenticated
    USING (true);

-- Allow service_role / service scripts full access
CREATE POLICY "Allow service role full access"
    ON public.social_posts
    FOR ALL
    TO service_role
    USING (true)
    WITH CHECK (true);
