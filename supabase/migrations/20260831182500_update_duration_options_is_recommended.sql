-- Migration: 20260831182500_update_duration_options_is_recommended.sql
-- Description: Updates duration_options JSONB column in public.subscription_plans table to include explicit "is_recommended" boolean flag for each duration option.

-- 1. Ensure `duration_options` column exists on public.subscription_plans
ALTER TABLE public.subscription_plans
ADD COLUMN IF NOT EXISTS duration_options jsonb NOT NULL DEFAULT '[]'::jsonb;

-- 2. Update Starter Broker plan with low-to-high ordered duration options & `is_recommended` boolean
UPDATE public.subscription_plans
SET duration_options = '[
  {"code": "STARTER07DAYS", "amount": 3799, "days": 7, "title": "7 Days", "is_recommended": false},
  {"code": "STARTER15DAYS", "amount": 7499, "days": 15, "title": "15 Days", "is_recommended": false},
  {"code": "STARTER30DAYS", "amount": 14999, "days": 30, "title": "30 Days", "is_recommended": true}
]'::jsonb
WHERE title ILIKE '%Starter%';

-- 3. Update Growth Pro plan with low-to-high ordered duration options & `is_recommended` boolean
UPDATE public.subscription_plans
SET duration_options = '[
  {"code": "GROWTH07DAYS", "amount": 4999, "days": 7, "title": "7 Days", "is_recommended": false},
  {"code": "GROWTH15DAYS", "amount": 9499, "days": 15, "title": "15 Days", "is_recommended": false},
  {"code": "GROWTH30DAYS", "amount": 18999, "days": 30, "title": "30 Days", "is_recommended": true}
]'::jsonb
WHERE title ILIKE '%Growth%';

-- 4. Update High-Volume Elite plan with low-to-high ordered duration options & `is_recommended` boolean
UPDATE public.subscription_plans
SET duration_options = '[
  {"code": "ELITE07DAYS", "amount": 6299, "days": 7, "title": "7 Days", "is_recommended": false},
  {"code": "ELITE15DAYS", "amount": 12499, "days": 15, "title": "15 Days", "is_recommended": false},
  {"code": "ELITE30DAYS", "amount": 24999, "days": 30, "title": "30 Days", "is_recommended": true}
]'::jsonb
WHERE title ILIKE '%Elite%' OR title ILIKE '%High-Volume%';
