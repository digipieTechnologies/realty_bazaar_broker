-- Migration: 20260831161500_rename_duration_to_billing_type.sql
-- Description: Replaces subscription_duration enum with plan_billing_type enum ('recurring', 'one_time', 'custom'), renames duration column to billing_type in public.subscription_plans, and drops old enum.

-- 1. Create new enum type `plan_billing_type`
CREATE TYPE public.plan_billing_type AS ENUM ('recurring', 'one_time', 'custom');

-- 2. Add temporary column `billing_type` to subscription_plans table
ALTER TABLE public.subscription_plans
ADD COLUMN IF NOT EXISTS billing_type public.plan_billing_type;

-- 3. Populate new `billing_type` column from existing `duration` data
UPDATE public.subscription_plans
SET billing_type = CASE
  WHEN duration::text IN ('month', 'year', 'monthly', 'yearly', 'recurring') THEN 'recurring'::public.plan_billing_type
  WHEN duration::text IN ('one_time', 'onetime', 'one-time') THEN 'one_time'::public.plan_billing_type
  WHEN duration::text = 'custom' THEN 'custom'::public.plan_billing_type
  ELSE 'recurring'::public.plan_billing_type
END;

-- 4. Enforce NOT NULL constraint on `billing_type`
ALTER TABLE public.subscription_plans
ALTER COLUMN billing_type SET NOT NULL;

-- 5. Drop old `duration` column
ALTER TABLE public.subscription_plans
DROP COLUMN IF EXISTS duration;

-- 6. Drop old `subscription_duration` enum type
DROP TYPE IF EXISTS public.subscription_duration;
