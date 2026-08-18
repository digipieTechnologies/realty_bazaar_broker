-- Migration: 20260810180000_update_notifications_receiver_ids_and_trigger.sql
-- Purpose: Add receiver_ids array and video_request_id to public.notifications and create 1-row notification insert trigger.

-- 1. Add video_request_id and receiver_ids columns to public.notifications
ALTER TABLE public.notifications 
ADD COLUMN IF NOT EXISTS video_request_id UUID NULL REFERENCES public.video_requests(id) ON DELETE CASCADE,
ADD COLUMN IF NOT EXISTS receiver_ids UUID[] NULL;

-- 2. Performance indexes
CREATE INDEX IF NOT EXISTS idx_notifications_video_request_id ON public.notifications(video_request_id);
CREATE INDEX IF NOT EXISTS idx_notifications_receiver_ids ON public.notifications USING GIN (receiver_ids);

-- 3. RLS Policy supporting receiver_ids array
DROP POLICY IF EXISTS "Users can view relevant notifications" ON public.notifications;
CREATE POLICY "Users can view relevant notifications"
ON public.notifications
FOR SELECT
USING (
    auth.role() = 'authenticated' AND (
        receiver_id IS NULL 
        OR auth.uid() = receiver_id
        OR auth.uid() = ANY(receiver_ids)
    )
);

-- 4. Trigger Function inserting EXACTLY 1 notification row containing receiver_ids array
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
        IF v_auto_approve IS TRUE OR NEW.admin_approval_status = 'approved' THEN
            -- Fetch array of active marketing user IDs
            SELECT ARRAY_AGG(id) INTO v_target_user_ids
            FROM public.users
            WHERE role IN ('marketing', 'ads') AND (is_active IS TRUE OR is_active IS NULL);

            IF v_target_user_ids IS NOT NULL AND ARRAY_LENGTH(v_target_user_ids, 1) > 0 THEN
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
            END IF;

        -- CASE 1B: Auto Approve is FALSE (admin_approval_status is 'pending')
        ELSE
            -- Fetch array of active reviewer user IDs
            SELECT ARRAY_AGG(id) INTO v_target_user_ids
            FROM public.users
            WHERE role IN ('super_admin', 'superadmin', 'admin') AND (is_active IS TRUE OR is_active IS NULL);

            IF v_target_user_ids IS NOT NULL AND ARRAY_LENGTH(v_target_user_ids, 1) > 0 THEN
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
        END IF;

    ----------------------------------------------------------------------------
    -- SCENARIO 2: EXISTING VIDEO REQUEST UPDATED (UPDATE)
    ----------------------------------------------------------------------------
    ELSIF TG_OP = 'UPDATE' THEN

        -- CASE 2A: Status changed to 'approved'
        IF (OLD.admin_approval_status IS DISTINCT FROM 'approved') 
           AND NEW.admin_approval_status = 'approved' THEN
            
            -- Fetch array of active marketing user IDs
            SELECT ARRAY_AGG(id) INTO v_target_user_ids
            FROM public.users
            WHERE role IN ('marketing', 'ads') AND (is_active IS TRUE OR is_active IS NULL);

            IF v_target_user_ids IS NOT NULL AND ARRAY_LENGTH(v_target_user_ids, 1) > 0 THEN
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
            END IF;

        -- CASE 2B: Status changed to 'rejected'
        ELSIF (OLD.admin_approval_status IS DISTINCT FROM 'rejected')
           AND NEW.admin_approval_status = 'rejected' THEN

            IF v_target_broker_user_id IS NOT NULL THEN
                INSERT INTO public.notifications (
                    receiver_id,
                    receiver_ids,
                    video_request_id,
                    sender_id,
                    title,
                    description,
                    notification_type,
                    data
                ) VALUES (
                    v_target_broker_user_id,
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

-- Attach AFTER INSERT OR UPDATE trigger to public.video_requests
DROP TRIGGER IF EXISTS trg_video_requests_notification ON public.video_requests;

CREATE TRIGGER trg_video_requests_notification
AFTER INSERT OR UPDATE ON public.video_requests
FOR EACH ROW
EXECUTE FUNCTION public.fn_video_requests_notification_handler();
