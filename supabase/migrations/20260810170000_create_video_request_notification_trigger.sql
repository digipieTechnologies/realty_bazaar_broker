-- Migration: 20260810170000_create_video_request_notification_trigger.sql
-- Purpose: Efficient 1-row notification insert trigger for video_requests events.

-- 1. Add video_request_id and target_role columns to public.notifications if not present
ALTER TABLE public.notifications 
ADD COLUMN IF NOT EXISTS video_request_id UUID NULL REFERENCES public.video_requests(id) ON DELETE CASCADE,
ADD COLUMN IF NOT EXISTS target_role VARCHAR(50) NULL;

-- Index for target_role and video_request_id
CREATE INDEX IF NOT EXISTS idx_notifications_video_request_id ON public.notifications(video_request_id);
CREATE INDEX IF NOT EXISTS idx_notifications_target_role ON public.notifications(target_role);

-- Update RLS Policy to allow viewing role-targeted notifications
DROP POLICY IF EXISTS "Users can view relevant notifications" ON public.notifications;
CREATE POLICY "Users can view relevant notifications"
ON public.notifications
FOR SELECT
USING (
    auth.role() = 'authenticated' AND (
        receiver_id IS NULL 
        OR auth.uid() = receiver_id
        OR target_role = (SELECT role FROM public.users WHERE id = auth.uid() LIMIT 1)
    )
);

-- 2. Trigger Function inserting EXACTLY 1 notification row per event
CREATE OR REPLACE FUNCTION public.fn_video_requests_notification_handler()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_auto_approve BOOLEAN := FALSE;
    v_target_broker_user_id UUID;
BEGIN
    -- 1. Fetch auto_approve setting for the requesting broker
    IF NEW.broker_id IS NOT NULL THEN
        SELECT COALESCE(auto_approve_video_requests, FALSE) INTO v_auto_approve
        FROM public.brokers
        WHERE id = NEW.broker_id;
    END IF;

    -- 2. Resolve target broker user ID
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
            INSERT INTO public.notifications (
                receiver_id,
                target_role,
                video_request_id,
                sender_id,
                title,
                description,
                notification_type,
                data
            ) VALUES (
                NULL,
                'marketing',
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
            INSERT INTO public.notifications (
                receiver_id,
                target_role,
                video_request_id,
                sender_id,
                title,
                description,
                notification_type,
                data
            ) VALUES (
                NULL,
                'super_admin',
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
        IF (OLD.admin_approval_status IS DISTINCT FROM 'approved') 
           AND NEW.admin_approval_status = 'approved' THEN
            
            INSERT INTO public.notifications (
                receiver_id,
                target_role,
                video_request_id,
                sender_id,
                title,
                description,
                notification_type,
                data
            ) VALUES (
                NULL,
                'marketing',
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
        ELSIF (OLD.admin_approval_status IS DISTINCT FROM 'rejected')
           AND NEW.admin_approval_status = 'rejected' THEN

            IF v_target_broker_user_id IS NOT NULL THEN
                INSERT INTO public.notifications (
                    receiver_id,
                    target_role,
                    video_request_id,
                    sender_id,
                    title,
                    description,
                    notification_type,
                    data
                ) VALUES (
                    v_target_broker_user_id,
                    NULL,
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
