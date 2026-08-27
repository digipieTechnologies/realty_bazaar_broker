-- Migration: add_is_popular_and_plans.sql
-- Description: Adds is_popular boolean column to subscription_plans table and inserts Starter, Growth Pro, and High-Volume Elite plans.

-- 1. Add is_popular column to subscription_plans table
ALTER TABLE public.subscription_plans
ADD COLUMN IF NOT EXISTS is_popular BOOLEAN NOT NULL DEFAULT false;

-- 2. Insert Starter Broker Plan
INSERT INTO public.subscription_plans (
    title,
    amount,
    duration,
    description,
    benefits,
    is_active,
    is_popular
) VALUES (
    'STARTER BROKER',
    999.00,
    'month',
    'Essential tools for independent brokers managing local listings.',
    '[
      "Unlimited property uploads",
      "Integrated CRM & lead tracker",
      "AI property descriptions & captions",
      "Instagram & Facebook publishing",
      "Verified website property listings",
      "Instant WhatsApp inquiry capture"
    ]'::jsonb,
    true,
    false
);

-- 3. Insert Growth Pro Plan (Most Popular)
INSERT INTO public.subscription_plans (
    title,
    amount,
    duration,
    description,
    benefits,
    is_active,
    is_popular
) VALUES (
    'GROWTH PRO',
    14999.00,
    'month',
    'Full marketing + automated Meta Ads campaigns for serious brokers.',
    '[
      "Everything in Starter",
      "Managed Meta & Google property ads",
      "Up to ₹350/day advertising allocation",
      "Campaign analytics & lead scoring",
      "Automated follow-ups & reminders",
      "Dedicated account manager"
    ]'::jsonb,
    true,
    true
);

-- 4. Insert High-Volume Elite Plan
INSERT INTO public.subscription_plans (
    title,
    amount,
    duration,
    description,
    benefits,
    is_active,
    is_popular
) VALUES (
    'HIGH-VOLUME ELITE',
    19999.00,
    'month',
    'Aggressive advertising & high-speed deal pipeline for top producers.',
    '[
      "Everything in Growth Pro",
      "Up to ₹500/day advertising allocation",
      "Video content campaigns & reels",
      "Advanced AI property match recommendations",
      "Priority WhatsApp & phone support",
      "Custom branding on listing flyers"
    ]'::jsonb,
    true,
    false
);
