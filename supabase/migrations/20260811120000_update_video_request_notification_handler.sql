-- Migration: 20260811120000_update_video_request_notification_handler.sql
-- Purpose: Update video_requests notification trigger handler to include detailed society name, flat number, landmark, and full address in descriptions, with role targeting and dual status data keys.

CREATE OR REPLACE FUNCTION public.fn_video_requests_notification_handler()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_auto_approve BOOLEAN := FALSE;
    v_sender_user_id UUID := NULL;
    v_target_user_ids UUID[];
    v_broker_name TEXT := 'Broker';
    v_property_title TEXT := '';
    v_property_location TEXT := 'Property Location';
    v_property_desc TEXT := '';
BEGIN
    -- 1. Fetch auto_approve setting & broker name for the requesting broker
    IF NEW.broker_id IS NOT NULL THEN
        SELECT COALESCE(b.auto_approve_video_requests, FALSE),
               COALESCE(NULLIF(TRIM(b.business_name), ''), NULLIF(TRIM(u.name), ''), 'Broker')
        INTO v_auto_approve, v_broker_name
        FROM public.brokers b
        LEFT JOIN public.users u ON (u.broker_id = b.id OR u.id = b.id)
        WHERE b.id = NEW.broker_id
        LIMIT 1;

        -- 2. Resolve sender_id (user linked to this broker_id)
        SELECT id INTO v_sender_user_id
        FROM public.users
        WHERE broker_id = NEW.broker_id OR id = NEW.broker_id
        LIMIT 1;
    END IF;

    -- 3. Resolve detailed property address & society/building location
    IF NEW.property_id IS NOT NULL THEN
        SELECT 
            COALESCE(TRIM(p.property_title), ''),
            COALESCE(
                NULLIF(TRIM(a.full_address), ''),
                NULLIF(TRIM(CONCAT_WS(', ', a.landmark, a.city, a.state)), ''),
                NULLIF(TRIM(CONCAT_WS(', ', a.city, a.state)), ''),
                NULLIF(TRIM(p.property_title), ''),
                'Property Location'
            )
        INTO v_property_title, v_property_location
        FROM public.properties p
        LEFT JOIN public.addresses a ON a.id = p.address_id
        WHERE p.id = NEW.property_id
        LIMIT 1;
    END IF;

    -- Build rich property description string (e.g., "3 BHK Apartment (Flat 402, Sunshine Heights, Bandra, Mumbai)")
    IF v_property_title IS NOT NULL AND v_property_title != '' THEN
        IF v_property_location IS NOT NULL AND v_property_location != '' AND v_property_location != v_property_title THEN
            v_property_desc := v_property_title || ' (' || v_property_location || ')';
        ELSE
            v_property_desc := v_property_title;
        END IF;
    ELSE
        v_property_desc := COALESCE(v_property_location, 'Property');
    END IF;

    ----------------------------------------------------------------------------
    -- SCENARIO 1: NEW VIDEO REQUEST CREATED (INSERT)
    ----------------------------------------------------------------------------
    IF TG_OP = 'INSERT' THEN

        -- CASE 1A: Auto Approve is TRUE or admin_approval_status is 'approved' -> Target Marketing Team ONLY
        IF v_auto_approve IS TRUE OR LOWER(COALESCE(NEW.admin_approval_status::text, '')) = 'approved' THEN
            SELECT ARRAY_AGG(id) INTO v_target_user_ids
            FROM public.users
            WHERE LOWER(role::text) IN ('marketing', 'ads');

            -- Fallback if no specific marketing users found
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
                'New video request received',
                v_broker_name || ': ' || v_property_desc,
                'video_request'::public.notification_type,
                jsonb_build_object(
                    'video_request_id', NEW.id,
                    'property_id', NEW.property_id,
                    'broker_id', NEW.broker_id,
                    'admin_approval_status', COALESCE(NEW.admin_approval_status::text, 'approved'),
                    'status', COALESCE(NEW.status::text, 'pending')
                )
            );

        -- CASE 1B: Auto Approve is FALSE -> Target Admin Team ONLY for review
        ELSE
            SELECT ARRAY_AGG(id) INTO v_target_user_ids
            FROM public.users
            WHERE LOWER(role::text) IN ('super_admin', 'superadmin', 'admin');

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
                'New video request received',
                v_broker_name || ': ' || v_property_desc,
                'video_request'::public.notification_type,
                jsonb_build_object(
                    'video_request_id', NEW.id,
                    'property_id', NEW.property_id,
                    'broker_id', NEW.broker_id,
                    'admin_approval_status', COALESCE(NEW.admin_approval_status::text, 'pending'),
                    'status', COALESCE(NEW.status::text, 'pending')
                )
            );
        END IF;

    ----------------------------------------------------------------------------
    -- SCENARIO 2: EXISTING VIDEO REQUEST UPDATED (UPDATE)
    ----------------------------------------------------------------------------
    ELSIF TG_OP = 'UPDATE' THEN

        -- CASE 2A: Admin Approval status changed to 'approved' -> Fire notification to Marketing Team ONLY
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
                'New video request received',
                v_broker_name || ': ' || v_property_desc,
                'video_request'::public.notification_type,
                jsonb_build_object(
                    'video_request_id', NEW.id,
                    'property_id', NEW.property_id,
                    'broker_id', NEW.broker_id,
                    'admin_approval_status', NEW.admin_approval_status::text,
                    'status', NEW.status::text
                )
            );

        -- CASE 2B: Request Rejected by Admin OR Marketing Team -> Fire notification ONLY to Broker
        ELSIF ((LOWER(COALESCE(OLD.admin_approval_status::text, '')) IS DISTINCT FROM 'rejected')
               AND LOWER(COALESCE(NEW.admin_approval_status::text, '')) = 'rejected')
           OR ((LOWER(COALESCE(OLD.status::text, '')) IS DISTINCT FROM 'cancelled')
               AND LOWER(COALESCE(NEW.status::text, '')) = 'cancelled') THEN

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
                    'Video request is rejected',
                    CASE 
                        WHEN NEW.admin_cancel_reason IS NOT NULL AND TRIM(NEW.admin_cancel_reason) != '' THEN 'Reason: ' || TRIM(NEW.admin_cancel_reason)
                        WHEN NEW.cancel_reason IS NOT NULL AND TRIM(NEW.cancel_reason) != '' THEN 'Reason: ' || TRIM(NEW.cancel_reason)
                        ELSE 'Your video request for ' || v_property_desc || ' has been rejected.'
                    END,
                    'video_request'::public.notification_type,
                    jsonb_build_object(
                        'video_request_id', NEW.id,
                        'property_id', NEW.property_id,
                        'broker_id', NEW.broker_id,
                        'admin_approval_status', NEW.admin_approval_status::text,
                        'status', NEW.status::text,
                        'reason', COALESCE(NEW.admin_cancel_reason, NEW.cancel_reason, '')
                    )
                );
            END IF;

        -- CASE 2C: Status changed to 'in_progress' -> Fire notification ONLY to Broker
        ELSIF (LOWER(COALESCE(OLD.status::text, '')) IS DISTINCT FROM 'in_progress')
           AND LOWER(COALESCE(NEW.status::text, '')) = 'in_progress' THEN

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
                    'Video shoot in progress',
                    'Your video shoot for ' || v_property_desc || ' has started and is now in progress.',
                    'video_request'::public.notification_type,
                    jsonb_build_object(
                        'video_request_id', NEW.id,
                        'property_id', NEW.property_id,
                        'broker_id', NEW.broker_id,
                        'admin_approval_status', NEW.admin_approval_status::text,
                        'status', NEW.status::text
                    )
                );
            END IF;

        -- CASE 2D: Status changed to 'completed' -> Fire notification ONLY to Broker
        ELSIF (LOWER(COALESCE(OLD.status::text, '')) IS DISTINCT FROM 'completed')
           AND LOWER(COALESCE(NEW.status::text, '')) = 'completed' THEN

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
                    'Video request completed',
                    'Your video request for ' || v_property_desc || ' is ready! Check your dashboard.',
                    'video_request'::public.notification_type,
                    jsonb_build_object(
                        'video_request_id', NEW.id,
                        'property_id', NEW.property_id,
                        'broker_id', NEW.broker_id,
                        'admin_approval_status', NEW.admin_approval_status::text,
                        'status', NEW.status::text
                    )
                );
            END IF;

        -- CASE 2E: Status changed to 'assigned' -> Fire notification ONLY to Broker
        ELSIF (LOWER(COALESCE(OLD.status::text, '')) IS DISTINCT FROM 'assigned')
           AND LOWER(COALESCE(NEW.status::text, '')) = 'assigned' THEN

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
                    'Video request assigned',
                    'Your video request for ' || v_property_desc || ' has been assigned to our marketing team.',
                    'video_request'::public.notification_type,
                    jsonb_build_object(
                        'video_request_id', NEW.id,
                        'property_id', NEW.property_id,
                        'broker_id', NEW.broker_id,
                        'admin_approval_status', NEW.admin_approval_status::text,
                        'status', NEW.status::text
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
