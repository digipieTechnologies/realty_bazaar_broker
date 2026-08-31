-- Migration: 20260831171500_add_duration_options_to_subscription_plans.sql
-- Description: Adds duration_options JSONB column to public.subscription_plans and populates 7, 15, and 30 day pricing options for Starter, Growth, and Elite plans.

-- 1. Add `duration_options` JSONB column to `public.subscription_plans`
ALTER TABLE public.subscription_plans
ADD COLUMN IF NOT EXISTS duration_options jsonb NOT NULL DEFAULT '[]'::jsonb;

-- 2. Update Starter Broker plan with 30, 15, and 7 days duration options
UPDATE public.subscription_plans
SET duration_options = '[
  {"code": "STARTER30DAYS", "amount": 14999, "days": 30, "title": "30 Days"},
  {"code": "STARTER15DAYS", "amount": 7499, "days": 15, "title": "15 Days"},
  {"code": "STARTER07DAYS", "amount": 3799, "days": 7, "title": "7 Days"}
]'::jsonb
WHERE title ILIKE '%Starter%';

-- 3. Update Growth Pro plan with 30, 15, and 7 days duration options
UPDATE public.subscription_plans
SET duration_options = '[
  {"code": "GROWTH30DAYS", "amount": 18999, "days": 30, "title": "30 Days"},
  {"code": "GROWTH15DAYS", "amount": 9499, "days": 15, "title": "15 Days"},
  {"code": "GROWTH07DAYS", "amount": 4999, "days": 7, "title": "7 Days"}
]'::jsonb
WHERE title ILIKE '%Growth%';

-- 4. Update High-Volume Elite plan with 30, 15, and 7 days duration options
UPDATE public.subscription_plans
SET duration_options = '[
  {"code": "ELITE30DAYS", "amount": 24999, "days": 30, "title": "30 Days"},
  {"code": "ELITE15DAYS", "amount": 12499, "days": 15, "title": "15 Days"},
  {"code": "ELITE07DAYS", "amount": 6299, "days": 7, "title": "7 Days"}
]'::jsonb
WHERE title ILIKE '%Elite%' OR title ILIKE '%High-Volume%';
