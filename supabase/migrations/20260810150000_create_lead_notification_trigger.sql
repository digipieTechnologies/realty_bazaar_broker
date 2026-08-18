-- Migration: 20260810150000_create_lead_notification_trigger.sql
-- Description: Create trigger on public.social_leads to automatically insert a notification row on new lead creation.

-- 1. Function: fn_on_social_lead_inserted
CREATE OR REPLACE FUNCTION public.fn_on_social_lead_inserted()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_receiver_user_id UUID;
    v_lead_name TEXT;
    v_title TEXT;
    v_description TEXT;
BEGIN
    -- Determine receiver_id: Look up user linked to this broker_id
    IF NEW.broker_id IS NOT NULL THEN
        SELECT id INTO v_receiver_user_id
        FROM public.users
        WHERE broker_id = NEW.broker_id OR id = NEW.broker_id
        LIMIT 1;
    END IF;

    -- Format title and description
    v_lead_name := COALESCE(NULLIF(TRIM(NEW.user_name), ''), 'Client');
    v_title := 'New Lead Received';
    v_description := 'You received a new lead from ' || v_lead_name || '.';

    -- Insert row into public.notifications
    -- (This automatically triggers trg_notifications_send_fcm to dispatch FCM push notifications)
    INSERT INTO public.notifications (
        sender_id,
        receiver_id,
        notification_type,
        title,
        description,
        data,
        created_at
    )
    VALUES (
        NULL,
        v_receiver_user_id,
        'lead'::public.notification_type,
        v_title,
        v_description,
        jsonb_build_object(
            'lead_id', NEW.id,
            'user_name', v_lead_name,
            'phone', COALESCE(NEW.phone, ''),
            'property_details', COALESCE(NEW.property_details, '')
        ),
        NOW()
    );

    RETURN NEW;
EXCEPTION WHEN OTHERS THEN
    -- Log warning without blocking the social_leads insertion
    RAISE WARNING 'fn_on_social_lead_inserted warning: %', SQLERRM;
    RETURN NEW;
END;
$$;

-- 2. Trigger: trg_on_social_lead_inserted
DROP TRIGGER IF EXISTS trg_on_social_lead_inserted ON public.social_leads;

CREATE TRIGGER trg_on_social_lead_inserted
AFTER INSERT ON public.social_leads
FOR EACH ROW
EXECUTE FUNCTION public.fn_on_social_lead_inserted();
