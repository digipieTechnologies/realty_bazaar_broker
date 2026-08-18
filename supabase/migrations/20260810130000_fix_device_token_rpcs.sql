-- Migration: 20260810130000_fix_device_token_rpcs.sql
-- Description: Unified single RPC function for FCM device token sync, old device token purging, and auto-cleanup.

CREATE OR REPLACE FUNCTION public.rpc_upsert_device_token(
    p_user_id UUID,
    p_fcm_token TEXT,
    p_device_id TEXT DEFAULT NULL,
    p_device_name TEXT DEFAULT NULL,
    p_platform TEXT DEFAULT NULL,
    p_ttl_days INTEGER DEFAULT 30
)
RETURNS public.user_device_tokens
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_result public.user_device_tokens;
    v_expires_at TIMESTAMPTZ;
BEGIN
    -- 1. Auto-purge all expired tokens across the database
    DELETE FROM public.user_device_tokens WHERE expires_at < NOW();

    -- 2. If device_id is provided, purge any old token records for this physical device
    IF p_device_id IS NOT NULL AND TRIM(p_device_id) <> '' THEN
        DELETE FROM public.user_device_tokens 
        WHERE (device_id = p_device_id AND fcm_token <> p_fcm_token);
    END IF;

    -- 3. Calculate expiration timestamp
    v_expires_at := NOW() + (p_ttl_days || ' days')::INTERVAL;

    -- 4. Insert or update current device token record
    INSERT INTO public.user_device_tokens (
        user_id,
        fcm_token,
        device_id,
        device_name,
        platform,
        expires_at,
        created_at,
        updated_at
    )
    VALUES (
        p_user_id,
        p_fcm_token,
        p_device_id,
        p_device_name,
        p_platform,
        v_expires_at,
        NOW(),
        NOW()
    )
    ON CONFLICT (fcm_token) DO UPDATE
    SET
        user_id = EXCLUDED.user_id,
        device_id = COALESCE(EXCLUDED.device_id, public.user_device_tokens.device_id),
        device_name = COALESCE(EXCLUDED.device_name, public.user_device_tokens.device_name),
        platform = COALESCE(EXCLUDED.platform, public.user_device_tokens.platform),
        expires_at = EXCLUDED.expires_at,
        updated_at = NOW()
    RETURNING * INTO v_result;

    RETURN v_result;
END;
$$;
