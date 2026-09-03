-- Migration: Create get_broker_subscription_plans RPC function
-- Purpose: Returns full details (*) of active subscription plans for brokers.
-- Enriches each item in duration_options with 3 status flags:
-- 1. is_trial (boolean): True if duration option represents a trial/free option.
-- 2. is_already_used (boolean): True if the broker has previously purchased/activated this duration option or trial plan.
-- 3. can_purchase (boolean): False if trial has already been used or option cannot be purchased again.

CREATE OR REPLACE FUNCTION public.get_broker_subscription_plans(
    p_broker_id uuid DEFAULT NULL
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_has_used_trial boolean := false;
    v_purchased_codes text[] := ARRAY[]::text[];
    v_result jsonb;
BEGIN
    -- 1. Check if the specified broker has ever purchased or activated any TRIAL plan or subscription codes
    IF p_broker_id IS NOT NULL THEN
        SELECT EXISTS (
            SELECT 1
            FROM public.user_subscriptions us
            LEFT JOIN public.subscription_plans sp ON us.subscription_plan_id = sp.id
            WHERE us.broker_id = p_broker_id
              AND (
                  us.plan_code ILIKE '%TRIAL%'
                  OR us.plan_code = 'TRIAL15DAYS'
                  OR sp.title ILIKE '%TRIAL%'
                  OR sp.duration_options::text ILIKE '%TRIAL15DAYS%'
                  OR sp.duration_options::text ILIKE '%TRIAL%'
                  OR us.amount = 0
              )
        ) INTO v_has_used_trial;

        SELECT COALESCE(array_agg(LOWER(us.plan_code)), ARRAY[]::text[])
        INTO v_purchased_codes
        FROM public.user_subscriptions us
        WHERE us.broker_id = p_broker_id;
    END IF;

    -- 2. Query active subscription plans (* columns) and enrich duration_options with 3 flags:
    --    is_trial (boolean), is_already_used (boolean), can_purchase (boolean)
    SELECT COALESCE(jsonb_agg(plan_obj), '[]'::jsonb)
    INTO v_result
    FROM (
        SELECT 
            to_jsonb(sp.*) || jsonb_build_object(
                'duration_options', (
                    SELECT COALESCE(
                        jsonb_agg(
                            opt || jsonb_build_object(
                                'is_trial', (
                                    opt->>'code' ILIKE '%TRIAL%'
                                    OR opt->>'code' = 'TRIAL15DAYS'
                                    OR (COALESCE(opt->>'amount', '0'))::numeric = 0
                                ),
                                'is_already_used', (
                                    (
                                        (opt->>'code' ILIKE '%TRIAL%' OR opt->>'code' = 'TRIAL15DAYS' OR (COALESCE(opt->>'amount', '0'))::numeric = 0)
                                        AND v_has_used_trial
                                    ) OR (
                                        LOWER(opt->>'code') = ANY(v_purchased_codes)
                                    )
                                ),
                                'can_purchase', NOT (
                                    (
                                        (opt->>'code' ILIKE '%TRIAL%' OR opt->>'code' = 'TRIAL15DAYS' OR (COALESCE(opt->>'amount', '0'))::numeric = 0)
                                        AND v_has_used_trial
                                    )
                                )
                            )
                        ),
                        '[]'::jsonb
                    )
                    FROM jsonb_array_elements(
                        CASE 
                            WHEN jsonb_typeof(sp.duration_options) = 'array' THEN sp.duration_options 
                            ELSE '[]'::jsonb 
                        END
                    ) opt
                )
            ) AS plan_obj
        FROM public.subscription_plans sp
        WHERE sp.is_active = true
        ORDER BY sp.created_at ASC
    ) sub;

    RETURN v_result;
END;
$$;
