-- Migration: 20260810190000_drop_receiver_id_and_update_all_triggers.sql
-- Description: Master migration with guaranteed notification insertion for video_requests INSERT and UPDATE.

-- 1. Drop existing RLS policy dependent on receiver_id
DROP POLICY IF EXISTS "Users can view relevant notifications" ON public.notifications;

-- 2. Drop receiver_id column with CASCADE
ALTER TABLE public.notifications DROP COLUMN IF EXISTS receiver_id CASCADE;

-- 3. Ensure receiver_ids array and video_request_id columns exist
ALTER TABLE public.notifications 
ADD COLUMN IF NOT EXISTS video_request_id UUID NULL REFERENCES public.video_requests(id) ON DELETE CASCADE,
ADD COLUMN IF NOT EXISTS receiver_ids UUID[] NULL;

-- 4. Create performance indexes
CREATE INDEX IF NOT EXISTS idx_notifications_video_request_id ON public.notifications(video_request_id);
CREATE INDEX IF NOT EXISTS idx_notifications_receiver_ids ON public.notifications USING GIN (receiver_ids);

-- 5. Re-create clean RLS Policy using receiver_ids array
CREATE POLICY "Users can view relevant notifications"
ON public.notifications
FOR SELECT
USING (
    auth.role() = 'authenticated' AND (
        auth.uid() = ANY(receiver_ids)
    )
);

--------------------------------------------------------------------------------
-- 6. Update Social Lead Notification Trigger Function (social_leads INSERT)
--------------------------------------------------------------------------------
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
    IF NEW.broker_id IS NOT NULL THEN
        SELECT id INTO v_receiver_user_id
        FROM public.users
        WHERE broker_id = NEW.broker_id OR id = NEW.broker_id
        LIMIT 1;
    END IF;

    v_lead_name := COALESCE(NULLIF(TRIM(NEW.user_name), ''), 'Client');
    v_title := 'New Lead Received';
    v_description := 'You received a new lead from ' || v_lead_name || '.';

    IF v_receiver_user_id IS NOT NULL THEN
        INSERT INTO public.notifications (
            sender_id,
            receiver_ids,
            notification_type,
            title,
            description,
            data,
            created_at
        )
        VALUES (
            NULL,
            ARRAY[v_receiver_user_id],
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
    END IF;

    RETURN NEW;
EXCEPTION WHEN OTHERS THEN
    RAISE WARNING 'fn_on_social_lead_inserted warning: %', SQLERRM;
    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_on_social_lead_inserted ON public.social_leads;
CREATE TRIGGER trg_on_social_lead_inserted
AFTER INSERT ON public.social_leads
FOR EACH ROW
EXECUTE FUNCTION public.fn_on_social_lead_inserted();

--------------------------------------------------------------------------------
-- 7. Update Video Request Notification Trigger Function (video_requests INSERT/UPDATE)
--------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.fn_video_requests_notification_handler()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_auto_approve BOOLEAN := FALSE;
    v_target_broker_user_id UUID;
    v_target_user_ids UUID[];
BEGIN
    -- Fetch auto_approve setting for the requesting broker
    IF NEW.broker_id IS NOT NULL THEN
        SELECT COALESCE(auto_approve_video_requests, FALSE) INTO v_auto_approve
        FROM public.brokers
        WHERE id = NEW.broker_id;
    END IF;

    -- Resolve target broker user ID
    v_target_broker_user_id := NEW.user_id;
    IF v_target_broker_user_id IS NULL AND NEW.broker_id IS NOT NULL THEN
        SELECT id INTO v_target_broker_user_id
        FROM public.users
        WHERE broker_id = NEW.broker_id
        LIMIT 1;
    END IF;

    ----------------------------------------------------------------------------
    -- SCENARIO 1: NEW VIDEO REQUEST CREATED (INSERT)
    ----------------------------------------------------------------------------
    IF TG_OP = 'INSERT' THEN

        -- CASE 1A: Auto Approve is TRUE (or admin_approval_status is 'approved')
        IF v_auto_approve IS TRUE OR LOWER(COALESCE(NEW.admin_approval_status, '')) = 'approved' THEN
            SELECT ARRAY_AGG(id) INTO v_target_user_ids
            FROM public.users
            WHERE LOWER(role) IN ('marketing', 'ads');

            IF v_target_user_ids IS NULL OR ARRAY_LENGTH(v_target_user_ids, 1) IS NULL THEN
                SELECT ARRAY_AGG(id) INTO v_target_user_ids
                FROM public.users
                WHERE LOWER(role) NOT IN ('broker');
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
                v_target_broker_user_id,
                'New Approved Video Request',
                'A new video request has been submitted and approved. Ready for production!',
                'video_request'::public.notification_type,
                jsonb_build_object(
                    'video_request_id', NEW.id,
                    'property_id', NEW.property_id,
                    'broker_id', NEW.broker_id,
                    'status', NEW.admin_approval_status
                )
            );

        -- CASE 1B: Auto Approve is FALSE (admin_approval_status is 'pending')
        ELSE
            SELECT ARRAY_AGG(id) INTO v_target_user_ids
            FROM public.users
            WHERE LOWER(role) IN ('super_admin', 'superadmin', 'admin');

            IF v_target_user_ids IS NULL OR ARRAY_LENGTH(v_target_user_ids, 1) IS NULL THEN
                SELECT ARRAY_AGG(id) INTO v_target_user_ids
                FROM public.users
                WHERE LOWER(role) NOT IN ('broker');
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
                v_target_broker_user_id,
                'Pending Video Request Review',
                'A new video request requires review and approval.',
                'video_request'::public.notification_type,
                jsonb_build_object(
                    'video_request_id', NEW.id,
                    'property_id', NEW.property_id,
                    'broker_id', NEW.broker_id,
                    'status', NEW.admin_approval_status
                )
            );
        END IF;

    ----------------------------------------------------------------------------
    -- SCENARIO 2: EXISTING VIDEO REQUEST UPDATED (UPDATE)
    ----------------------------------------------------------------------------
    ELSIF TG_OP = 'UPDATE' THEN

        -- CASE 2A: Status changed to 'approved'
        IF (LOWER(COALESCE(OLD.admin_approval_status, '')) IS DISTINCT FROM 'approved') 
           AND LOWER(COALESCE(NEW.admin_approval_status, '')) = 'approved' THEN
            
            SELECT ARRAY_AGG(id) INTO v_target_user_ids
            FROM public.users
            WHERE LOWER(role) IN ('marketing', 'ads');

            IF v_target_user_ids IS NULL OR ARRAY_LENGTH(v_target_user_ids, 1) IS NULL THEN
                SELECT ARRAY_AGG(id) INTO v_target_user_ids
                FROM public.users
                WHERE LOWER(role) NOT IN ('broker');
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
                v_target_broker_user_id,
                'New Approved Video Request',
                'A pending video request was approved and is now ready for production!',
                'video_request'::public.notification_type,
                jsonb_build_object(
                    'video_request_id', NEW.id,
                    'property_id', NEW.property_id,
                    'broker_id', NEW.broker_id,
                    'status', NEW.admin_approval_status
                )
            );

        -- CASE 2B: Status changed to 'rejected'
        ELSIF (LOWER(COALESCE(OLD.admin_approval_status, '')) IS DISTINCT FROM 'rejected')
           AND LOWER(COALESCE(NEW.admin_approval_status, '')) = 'rejected' THEN

            IF v_target_broker_user_id IS NOT NULL THEN
                INSERT INTO public.notifications (
                    receiver_ids,
                    video_request_id,
                    sender_id,
                    title,
                    description,
                    notification_type,
                    data
                ) VALUES (
                    ARRAY[v_target_broker_user_id],
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
                        'status', NEW.admin_approval_status,
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

DROP TRIGGER IF EXISTS trg_video_requests_notification ON public.video_requests;
CREATE TRIGGER trg_video_requests_notification
AFTER INSERT OR UPDATE ON public.video_requests
FOR EACH ROW
EXECUTE FUNCTION public.fn_video_requests_notification_handler();
