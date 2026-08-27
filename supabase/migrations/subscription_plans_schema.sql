-- Migration: subscription_plans_schema.sql
-- Description: Creates enum subscription_duration and subscription_plans table for managing subscription packages.

-- 1. Create Enum Type for Subscription Duration
CREATE TYPE subscription_duration AS ENUM ('month', 'year', 'one_time');

-- 2. Create subscription_plans Table
CREATE TABLE IF NOT EXISTS public.subscription_plans (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    title TEXT NOT NULL,
    amount NUMERIC(10, 2) NOT NULL DEFAULT 0.00,
    duration subscription_duration NOT NULL DEFAULT 'month',
    description TEXT NOT NULL DEFAULT '',
    benefits JSONB NOT NULL DEFAULT '[]'::jsonb,
    is_active BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 3. Create Index for active plans lookup
CREATE INDEX IF NOT EXISTS idx_subscription_plans_active ON public.subscription_plans(is_active);

-- 4. Enable Row Level Security (RLS)
ALTER TABLE public.subscription_plans ENABLE ROW LEVEL SECURITY;

-- 5. RLS Policy: Anyone (authenticated & anon) can read active subscription plans
CREATE POLICY "Allow public read access to active subscription plans"
    ON public.subscription_plans
    FOR SELECT
    USING (is_active = true);

-- 6. Trigger to automatically update updated_at timestamp
CREATE OR REPLACE FUNCTION update_subscription_plans_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_subscription_plans_updated_at ON public.subscription_plans;
CREATE TRIGGER trigger_subscription_plans_updated_at
    BEFORE UPDATE ON public.subscription_plans
    FOR EACH ROW
    EXECUTE FUNCTION update_subscription_plans_updated_at();

-- 7. Insert Initial Trial Plan Record (from Screenshot)
INSERT INTO public.subscription_plans (
    title,
    amount,
    duration,
    description,
    benefits,
    is_active
) VALUES (
    'TRIAL PLAN',
    4499.00,
    'one_time',
    'Try the complete platform for 30 days with no recurring commitment.',
    '[
      "Full CRM & lead management",
      "AI marketing content generation",
      "Social media post publishing",
      "Up to 10 active property listings",
      "30-day full access trial",
      "Mobile app access (iOS & Android)"
    ]'::jsonb,
    true
);
