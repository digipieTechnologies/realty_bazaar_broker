-- Migration: Create RPC function get_user_profile_details
-- Purpose: Fetches user profile with nested broker_id, address_id, and calls get_broker_active_subscription to include active user_subscription details.

CREATE OR REPLACE FUNCTION public.get_user_profile_details(
    p_user_id uuid
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_user_row public.users%ROWTYPE;
    v_broker_row public.brokers%ROWTYPE;
    v_address_row public.addresses%ROWTYPE;
    v_broker_json jsonb := NULL;
    v_subscription_json jsonb := NULL;
    v_result jsonb;
BEGIN
    -- 1. Fetch user record from users table
    SELECT * INTO v_user_row FROM public.users WHERE id = p_user_id;
    IF v_user_row.id IS NULL THEN
        RETURN NULL;
    END IF;

    -- 2. Fetch broker record if linked
    IF v_user_row.broker_id IS NOT NULL THEN
        SELECT * INTO v_broker_row FROM public.brokers WHERE id = v_user_row.broker_id;
        IF v_broker_row.id IS NOT NULL THEN
            -- 3. Fetch address record if linked
            IF v_broker_row.address_id IS NOT NULL THEN
                SELECT * INTO v_address_row FROM public.addresses WHERE id = v_broker_row.address_id;
            END IF;

            v_broker_json := to_jsonb(v_broker_row);
            IF v_address_row.id IS NOT NULL THEN
                v_broker_json := v_broker_json || jsonb_build_object('address_id', to_jsonb(v_address_row));
            END IF;

            -- 4. Call existing RPC function to get active subscription details!
            v_subscription_json := public.get_broker_active_subscription(v_broker_row.id);
        END IF;
    END IF;

    -- Construct final user profile JSON with broker and active user_subscription
    v_result := to_jsonb(v_user_row);
    IF v_broker_json IS NOT NULL THEN
        v_result := v_result || jsonb_build_object('broker_id', v_broker_json);
    END IF;

    -- Embed active user_subscription (returns object or NULL)
    v_result := v_result || jsonb_build_object('user_subscription', v_subscription_json);

    RETURN v_result;
END;
$$;
