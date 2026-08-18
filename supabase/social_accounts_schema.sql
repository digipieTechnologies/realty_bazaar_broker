-- Create the social_accounts table to store connected Facebook and Instagram account credentials
CREATE TABLE IF NOT EXISTS public.social_accounts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    broker_id UUID NOT NULL REFERENCES public.brokers(id) ON DELETE CASCADE,
    platform TEXT NOT NULL CHECK (platform IN ('facebook', 'instagram')),
    facebook_user_id TEXT,
    page_id TEXT,
    page_name TEXT,
    page_access_token TEXT,
    instagram_account_id TEXT,
    instagram_username TEXT,
    ad_account_id TEXT,
    access_token TEXT,
    expires_at TIMESTAMPTZ,
    is_active BOOLEAN DEFAULT true,
    is_connected BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    CONSTRAINT unique_broker_platform UNIQUE (broker_id, platform)
);

-- SQL statement to alter existing table in Supabase SQL Editor:
ALTER TABLE public.social_accounts ADD COLUMN IF NOT EXISTS ad_account_id TEXT;


-- Index for faster queries by broker and platform
CREATE INDEX IF NOT EXISTS idx_social_accounts_broker_platform ON public.social_accounts (broker_id, platform);

-- Enable Row Level Security
ALTER TABLE public.social_accounts ENABLE ROW LEVEL SECURITY;

-- Create RLS Policies
-- Allow authenticated users to read their own broker's social accounts
CREATE POLICY "Allow authenticated read access"
    ON public.social_accounts
    FOR SELECT
    TO authenticated
    USING (
        broker_id IN (
            SELECT broker_id FROM public.users WHERE id = auth.uid()
        )
    );

-- Allow authenticated users to delete their own broker's social accounts
CREATE POLICY "Allow authenticated delete access"
    ON public.social_accounts
    FOR DELETE
    TO authenticated
    USING (
        broker_id IN (
            SELECT broker_id FROM public.users WHERE id = auth.uid()
        )
    );

-- Allow service_role / service scripts full access (required for Edge Functions using service role)
CREATE POLICY "Allow service role full access"
    ON public.social_accounts
    FOR ALL
    TO service_role
    USING (true)
    WITH CHECK (true);

-- Enable Realtime for social_accounts table (required for Flutter client's realtime updates)
ALTER PUBLICATION supabase_realtime ADD TABLE public.social_accounts;
ALTER TABLE public.social_accounts REPLICA IDENTITY FULL;
