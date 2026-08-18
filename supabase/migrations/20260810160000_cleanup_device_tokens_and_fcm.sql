-- Migration: 20260810160000_cleanup_device_tokens_and_fcm.sql
-- Purpose: Permanently drop public.user_device_tokens table and legacy FCM RPC functions.

-- 1. Drop legacy FCM trigger and function if exists
DROP TRIGGER IF EXISTS trg_notifications_send_fcm ON public.notifications;
DROP FUNCTION IF EXISTS public.fn_trigger_send_fcm_notification();

-- 2. Drop device token RPC functions
DROP FUNCTION IF EXISTS public.rpc_upsert_device_token(UUID, TEXT, TEXT, TEXT, TEXT, INT);
DROP FUNCTION IF EXISTS public.rpc_get_user_device_tokens(UUID);

-- 3. Drop user_device_tokens table
DROP TABLE IF EXISTS public.user_device_tokens CASCADE;
