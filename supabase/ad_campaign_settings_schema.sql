-- Create the ad_campaign_settings table to store campaign preferences per broker
CREATE TABLE IF NOT EXISTS public.ad_campaign_settings (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    broker_id UUID NOT NULL UNIQUE REFERENCES public.brokers(id) ON DELETE CASCADE,
    gender TEXT NOT NULL DEFAULT 'all' CHECK (gender IN ('all', 'male', 'female')),
    area_details JSONB DEFAULT '[]'::jsonb, -- Array of target area maps [{full_area, area, city, state, county, pincode, latitude, longitude}]
    targeting_suggestions JSONB DEFAULT '[]'::jsonb, -- Array of string suggestions ["Businessmen", "Parents"]
    start_age_range INTEGER NOT NULL DEFAULT 18 CHECK (start_age_range >= 13 AND start_age_range <= 100),
    end_age_range INTEGER NOT NULL DEFAULT 65 CHECK (end_age_range >= start_age_range AND end_age_range <= 100),
    campaign_start_time TEXT DEFAULT NULL, -- Null if campaign_is_all_day is true
    campaign_end_time TEXT DEFAULT NULL, -- Null if campaign_is_all_day is true
    campaign_is_all_day BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Index for fast lookup by broker_id
CREATE INDEX IF NOT EXISTS idx_ad_campaign_settings_broker ON public.ad_campaign_settings (broker_id);

-- Trigger to automatically update updated_at timestamp
CREATE OR REPLACE FUNCTION public.handle_ad_campaign_settings_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_ad_campaign_settings_updated_at ON public.ad_campaign_settings;
CREATE TRIGGER trg_ad_campaign_settings_updated_at
    BEFORE UPDATE ON public.ad_campaign_settings
    FOR EACH ROW
    EXECUTE FUNCTION public.handle_ad_campaign_settings_updated_at();

-- Enable Row Level Security (RLS)
ALTER TABLE public.ad_campaign_settings ENABLE ROW LEVEL SECURITY;

-- Create RLS Policies
CREATE POLICY "Allow authenticated read access"
    ON public.ad_campaign_settings
    FOR SELECT
    TO authenticated
    USING (true);

CREATE POLICY "Allow authenticated write access"
    ON public.ad_campaign_settings
    FOR ALL
    TO authenticated
    USING (true)
    WITH CHECK (true);

CREATE POLICY "Allow service role full access"
    ON public.ad_campaign_settings
    FOR ALL
    TO service_role
    USING (true)
    WITH CHECK (true);
