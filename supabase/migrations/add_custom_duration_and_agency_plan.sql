-- Migration: add_custom_duration_and_agency_plan.sql
-- Note: In PostgreSQL, ALTER TYPE ADD VALUE must be executed & committed in a separate transaction BEFORE using the new enum value.

-- ==========================================
-- STEP 1: Run and Execute this command FIRST
-- ==========================================
ALTER TYPE subscription_duration ADD VALUE IF NOT EXISTS 'custom';


-- ==========================================
-- STEP 2: Run and Execute this query AFTER Step 1
-- ==========================================
INSERT INTO public.subscription_plans (
    title,
    amount,
    duration,
    description,
    benefits,
    is_active,
    is_popular
) VALUES (
    'AGENCY & TEAMS',
    0.00,
    'custom',
    'For real-estate agencies and multi-broker channel teams.',
    '[
      "Custom advertising budget allocation",
      "Multiple sub-broker & agent logins",
      "Custom campaign strategy & creative",
      "Dedicated agency account director",
      "API & custom CRM integrations",
      "Team performance dashboard"
    ]'::jsonb,
    true,
    false
);
