-- Migration: 20260810200000_fix_video_request_notification_trigger.sql
-- Purpose: Fix video_requests notification trigger for enum casting, broker_id user lookup, and guaranteed notification insertion.

CREATE OR REPLACE FUNCTION public.fn_video_requests_notification_handler()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_auto_approve BOOLEAN := FALSE;
    v_sender_user_id UUID := NULL;
    v_target_user_ids UUID[];
BEGIN
    -- 1. Fetch auto_approve setting for the requesting broker from public.brokers
    IF NEW.broker_id IS NOT NULL THEN
        SELECT COALESCE(auto_approve_video_requests, FALSE) INTO v_auto_approve
        FROM public.brokers
        WHERE id = NEW.broker_id;

        -- 2. Resolve sender_id (user linked to this broker_id)
        SELECT id INTO v_sender_user_id
        FROM public.users
        WHERE broker_id = NEW.broker_id OR id = NEW.broker_id
        LIMIT 1;
    END IF;

    ----------------------------------------------------------------------------
    -- SCENARIO 1: NEW VIDEO REQUEST CREATED (INSERT)
    ----------------------------------------------------------------------------
    IF TG_OP = 'INSERT' THEN

        -- CASE 1A: Auto Approve is TRUE or status is 'approved'
        IF v_auto_approve IS TRUE OR LOWER(COALESCE(NEW.admin_approval_status::text, '')) = 'approved' THEN
            -- Target all Marketing / Ads users
            SELECT ARRAY_AGG(id) INTO v_target_user_ids
            FROM public.users
            WHERE LOWER(role::text) IN ('marketing', 'ads');

            -- Fallback: Target all users if specific role array is empty
            IF v_target_user_ids IS NULL OR ARRAY_LENGTH(v_target_user_ids, 1) IS NULL THEN
                SELECT ARRAY_AGG(id) INTO v_target_user_ids
                FROM public.users;
            END IF;

            INSERT INTO public.notifications (
                receiver_ids,
                video_request_id,
                sender_id,
                title,
                description,
                notification_type,
                data
            ) VALUES (
                v_target_user_ids,
                NEW.id,
                v_sender_user_id,
                'New Approved Video Request',
                'A new video request has been submitted and approved. Ready for production!',
                'video_request'::public.notification_type,
                jsonb_build_object(
                    'video_request_id', NEW.id,
                    'property_id', NEW.property_id,
                    'broker_id', NEW.broker_id,
                    'status', NEW.admin_approval_status::text
                )
            );

        -- CASE 1B: Auto Approve is FALSE (admin_approval_status is 'pending')
        ELSE
            -- Target all Super Admin / Admin users
            SELECT ARRAY_AGG(id) INTO v_target_user_ids
            FROM public.users
            WHERE LOWER(role::text) IN ('super_admin', 'superadmin', 'admin');

            -- Fallback: Target all users if specific role array is empty
            IF v_target_user_ids IS NULL OR ARRAY_LENGTH(v_target_user_ids, 1) IS NULL THEN
                SELECT ARRAY_AGG(id) INTO v_target_user_ids
                FROM public.users;
            END IF;

            INSERT INTO public.notifications (
                receiver_ids,
                video_request_id,
                sender_id,
                title,
                description,
                notification_type,
                data
            ) VALUES (
                v_target_user_ids,
                NEW.id,
                v_sender_user_id,
                'Pending Video Request Review',
                'A new video request requires review and approval.',
                'video_request'::public.notification_type,
                jsonb_build_object(
                    'video_request_id', NEW.id,
                    'property_id', NEW.property_id,
                    'broker_id', NEW.broker_id,
                    'status', NEW.admin_approval_status::text
                )
            );
        END IF;

    ----------------------------------------------------------------------------
    -- SCENARIO 2: EXISTING VIDEO REQUEST UPDATED (UPDATE)
    ----------------------------------------------------------------------------
    ELSIF TG_OP = 'UPDATE' THEN

        -- CASE 2A: Status changed to 'approved'
        IF (LOWER(COALESCE(OLD.admin_approval_status::text, '')) IS DISTINCT FROM 'approved') 
           AND LOWER(COALESCE(NEW.admin_approval_status::text, '')) = 'approved' THEN
            
            SELECT ARRAY_AGG(id) INTO v_target_user_ids
            FROM public.users
            WHERE LOWER(role::text) IN ('marketing', 'ads');

            IF v_target_user_ids IS NULL OR ARRAY_LENGTH(v_target_user_ids, 1) IS NULL THEN
                SELECT ARRAY_AGG(id) INTO v_target_user_ids
                FROM public.users;
            END IF;

            INSERT INTO public.notifications (
                receiver_ids,
                video_request_id,
                sender_id,
                title,
                description,
                notification_type,
                data
            ) VALUES (
                v_target_user_ids,
                NEW.id,
                v_sender_user_id,
                'New Approved Video Request',
                'A pending video request was approved and is now ready for production!',
                'video_request'::public.notification_type,
                jsonb_build_object(
                    'video_request_id', NEW.id,
                    'property_id', NEW.property_id,
                    'broker_id', NEW.broker_id,
                    'status', NEW.admin_approval_status::text
                )
            );

        -- CASE 2B: Status changed to 'rejected'
        ELSIF (LOWER(COALESCE(OLD.admin_approval_status::text, '')) IS DISTINCT FROM 'rejected')
           AND LOWER(COALESCE(NEW.admin_approval_status::text, '')) = 'rejected' THEN

            IF v_sender_user_id IS NOT NULL THEN
                INSERT INTO public.notifications (
                    receiver_ids,
                    video_request_id,
                    sender_id,
                    title,
                    description,
                    notification_type,
                    data
                ) VALUES (
                    ARRAY[v_sender_user_id],
                    NEW.id,
                    NULL,
                    'Video Request Rejected',
                    CASE 
                        WHEN NEW.admin_cancel_reason IS NOT NULL AND NEW.admin_cancel_reason != '' THEN 'Your video request was rejected: ' || NEW.admin_cancel_reason
                        WHEN NEW.cancel_reason IS NOT NULL AND NEW.cancel_reason != '' THEN 'Your video request was rejected: ' || NEW.cancel_reason
                        ELSE 'Your video request was rejected.'
                    END,
                    'video_request'::public.notification_type,
                    jsonb_build_object(
                        'video_request_id', NEW.id,
                        'property_id', NEW.property_id,
                        'broker_id', NEW.broker_id,
                        'status', NEW.admin_approval_status::text,
                        'reason', COALESCE(NEW.admin_cancel_reason, NEW.cancel_reason, '')
                    )
                );
            END IF;

        END IF;

    END IF;

    RETURN NEW;
EXCEPTION WHEN OTHERS THEN
    RAISE WARNING 'fn_video_requests_notification_handler warning: %', SQLERRM;
    RETURN NEW;
END;
$$;

-- Re-attach video_requests trigger
DROP TRIGGER IF EXISTS trg_video_requests_notification ON public.video_requests;

CREATE TRIGGER trg_video_requests_notification
AFTER INSERT OR UPDATE ON public.video_requests
FOR EACH ROW
EXECUTE FUNCTION public.fn_video_requests_notification_handler();
