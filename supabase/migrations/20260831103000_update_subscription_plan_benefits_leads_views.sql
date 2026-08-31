-- Migration: 20260831103000_update_subscription_plan_benefits_leads_views.sql
-- Description: Separates leads and view count into two distinct bullet points per plan, ensuring a maximum of 6 benefits per plan by removing redundant basic social publishing features.

-- 1. STARTER BROKER (₹14,999/month | ~₹12,000 Meta Ad Spend)
UPDATE public.subscription_plans
SET benefits = '[
  "Unlimited property uploads",
  "Get up to 75+ buyer leads",
  "Get up to 75k+ views on reels",
  "Integrated CRM & lead tracker",
  "AI property descriptions & captions",
  "Verified website property listings"
]'::jsonb
WHERE id = '4436621c-f936-4686-bd6c-140ddea4c74c' OR title = 'STARTER BROKER';

-- 2. GROWTH PRO (₹18,999/month | ~₹15,200 Meta Ad Spend)
UPDATE public.subscription_plans
SET benefits = '[
  "Everything in Starter",
  "Managed Meta & Google property ads",
  "Get up to 100+ buyer leads",
  "Get up to 100k+ views on reels",
  "Campaign analytics & lead scoring",
  "Dedicated account manager"
]'::jsonb
WHERE id = '6adf650d-5449-49ad-9d7f-0d383252182c' OR title = 'GROWTH PRO';

-- 3. HIGH-VOLUME ELITE (₹24,999/month | ~₹20,000 Meta Ad Spend)
UPDATE public.subscription_plans
SET benefits = '[
  "Everything in Growth Pro",
  "Get up to 135+ buyer leads",
  "Get up to 130k+ views on reels",
  "Video content campaigns & reels",
  "Advanced AI property matching",
  "Priority WhatsApp & phone support"
]'::jsonb
WHERE id = '8e8d6679-5ddb-4c10-93bb-879a85a89d9d' OR title = 'HIGH-VOLUME ELITE';

-- 4. TRIAL PLAN (₹2,499 one-time | ~₹2,000 Meta Ad Spend)
UPDATE public.subscription_plans
SET benefits = '[
  "Full CRM & lead management",
  "Get up to 15+ buyer leads",
  "Get up to 13k+ views on reels",
  "AI marketing content generation",
  "Up to 10 active property listings",
  "30-day full access trial"
]'::jsonb
WHERE id = 'c8842e5e-6ddc-4ee8-a1ae-f8909023ea6f' OR title = 'TRIAL PLAN';

-- 5. AGENCY & TEAMS (Custom Price | Custom Ad Allocation)
UPDATE public.subscription_plans
SET benefits = '[
  "Custom buyer lead volume",
  "Custom reel reach & video views",
  "Multiple sub-broker & agent logins",
  "Custom campaign strategy & creative",
  "Dedicated agency account director",
  "API & team performance dashboard"
]'::jsonb
WHERE id = 'b3bf9876-4505-439a-8681-1f233c73b6ce' OR title = 'AGENCY & TEAMS';

-- 6. LISTING PASS (₹299.00 one-time | Single listing post without ad campaign)
UPDATE public.subscription_plans
SET benefits = '[
  "Single property post upload",
  "Direct DM lead & buyer contact access",
  "Unlimited social post publishing",
  "Lead view & contact management",
  "One-time payment with instant access"
]'::jsonb
WHERE id = '539e4da1-35ef-4cb3-8977-11c1feba2dd0' OR title = 'LISTING PASS';
