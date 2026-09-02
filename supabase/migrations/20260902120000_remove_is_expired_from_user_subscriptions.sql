-- Migration: Remove is_expired column from user_subscriptions table
-- Purpose: Expiration is dynamically managed via end_date to avoid data inconsistency.

-- 1. Drop is_expired column from user_subscriptions
ALTER TABLE public.user_subscriptions 
DROP COLUMN IF EXISTS is_expired;

-- 2. Update process_subscription_payment RPC function to exclude is_expired column
CREATE OR REPLACE FUNCTION public.process_subscription_payment(
    p_broker_id uuid,
    p_subscription_plan_id uuid,
    p_amount numeric,
    p_payment_id text,
    p_payment_provider public.payment_provider_type,
    p_total_days integer,
    p_plan_code text
)
RETURNS json
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_payment_record public.user_payments%ROWTYPE;
    v_subscription_record public.user_subscriptions%ROWTYPE;
    v_start_date timestamp with time zone := now();
    v_end_date timestamp with time zone := now() + (p_total_days || ' days')::interval;
BEGIN
    -- 1. Insert into user_payments
    INSERT INTO public.user_payments (
        broker_id,
        subscription_plan_id,
        amount,
        purpose,
        status,
        payment_provider,
        payment_id
    ) VALUES (
        p_broker_id,
        p_subscription_plan_id,
        p_amount,
        'buy_subscription'::payment_purpose_type,
        'completed'::payment_status_type,
        p_payment_provider,
        p_payment_id
    )
    RETURNING * INTO v_payment_record;

    -- 2. Insert into user_subscriptions (without is_expired column)
    INSERT INTO public.user_subscriptions (
        broker_id,
        payment_id,
        subscription_plan_id,
        start_date,
        end_date,
        total_days,
        amount,
        plan_code
    ) VALUES (
        p_broker_id,
        v_payment_record.id,
        p_subscription_plan_id,
        v_start_date,
        v_end_date,
        p_total_days,
        p_amount,
        p_plan_code
    )
    RETURNING * INTO v_subscription_record;

    -- Return success JSON
    RETURN json_build_object(
        'success', true,
        'payment_id', v_payment_record.id,
        'subscription_id', v_subscription_record.id
    );
EXCEPTION WHEN OTHERS THEN
    -- Return error JSON
    RETURN json_build_object(
        'success', false,
        'error', SQLERRM
    );
END;
$$;
