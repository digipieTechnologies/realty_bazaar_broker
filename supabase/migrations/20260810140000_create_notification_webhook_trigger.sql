-- Migration: 20260810140000_create_notification_webhook_trigger.sql
-- Description: Create database trigger to invoke send-fcm-notification Edge Function on every insert to public.notifications.

-- 1. Enable pg_net extension for async HTTP calls
CREATE EXTENSION IF NOT EXISTS pg_net WITH SCHEMA extensions;

-- 2. Function: fn_trigger_send_fcm_notification
CREATE OR REPLACE FUNCTION public.fn_trigger_send_fcm_notification()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_payload JSONB;
BEGIN
    -- Build payload for Edge Function
    v_payload := jsonb_build_object(
        'type', TG_OP,
        'table', TG_TABLE_NAME,
        'schema', TG_TABLE_SCHEMA,
        'record', row_to_json(NEW)
    );

    -- Invoke send-fcm-notification Edge Function asynchronously via pg_net
    PERFORM extensions.http_post(
        url := 'https://oibpptznppqlwvgytngj.supabase.co/functions/v1/send-fcm-notification',
        headers := jsonb_build_object(
            'Content-Type', 'application/json'
        ),
        body := v_payload
    );

    RETURN NEW;
EXCEPTION WHEN OTHERS THEN
    -- Prevent trigger network warnings from rolling back the notifications table insert
    RAISE WARNING 'FCM Notification Trigger warning: %', SQLERRM;
    RETURN NEW;
END;
$$;

-- 3. Trigger: trg_notifications_send_fcm
DROP TRIGGER IF EXISTS trg_notifications_send_fcm ON public.notifications;

CREATE TRIGGER trg_notifications_send_fcm
AFTER INSERT ON public.notifications
FOR EACH ROW
EXECUTE FUNCTION public.fn_trigger_send_fcm_notification();
