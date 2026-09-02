-- Migration: Create RPC function to fetch active subscription details for a broker
-- Purpose: Returns full user_subscriptions row merged with nested payment_id and subscription_plan_id objects.

CREATE OR REPLACE FUNCTION public.get_broker_active_subscription(
    p_broker_id uuid
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_result jsonb;
BEGIN
    SELECT to_jsonb(us.*) || 
           jsonb_build_object(
               'payment_id', to_jsonb(up.*),
               'subscription_plan_id', to_jsonb(sp.*),
               'is_expired', (us.end_date < NOW())
           )
    INTO v_result
    FROM public.user_subscriptions us
    LEFT JOIN public.user_payments up ON us.payment_id = up.id
    LEFT JOIN public.subscription_plans sp ON us.subscription_plan_id = sp.id
    WHERE us.broker_id = p_broker_id
      AND us.end_date >= NOW()
    ORDER BY us.created_at DESC
    LIMIT 1;

    -- Return result (or NULL if no active subscription exists)
    RETURN v_result;
END;
$$;
