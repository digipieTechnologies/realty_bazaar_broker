-- Migration: 20260812113000_add_cancelled_by_user_id_and_update_notification_trigger.sql
-- Purpose:
-- 1. Add cancelled_by_user_id column to video_requests table.
-- 2. Update fn_video_requests_notification_handler trigger function to route cancellation notifications based on cancelled_by_user_id role (broker vs marketing/admin).
-- 3. Update fetch_video_requests RPC to serialize cancelled_by_user_id object (UserModel) in nested JSON output.

-- 1. Add cancelled_by_user_id column to video_requests
ALTER TABLE public.video_requests
ADD COLUMN IF NOT EXISTS cancelled_by_user_id UUID NULL REFERENCES public.users(id) ON DELETE SET NULL;

CREATE INDEX IF NOT EXISTS idx_video_requests_cancelled_by_user_id ON public.video_requests USING btree (cancelled_by_user_id);

-- 2. Update fn_video_requests_notification_handler trigger function
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
    v_canceller_role TEXT := NULL;
    v_canceller_name TEXT := '';
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

    -- Build rich property description string
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

        -- CASE 2B: Request Cancelled or Rejected -> Route based on cancelled_by_user_id role
        ELSIF ((LOWER(COALESCE(OLD.admin_approval_status::text, '')) IS DISTINCT FROM 'rejected')
               AND LOWER(COALESCE(NEW.admin_approval_status::text, '')) = 'rejected')
           OR ((LOWER(COALESCE(OLD.status::text, '')) IS DISTINCT FROM 'cancelled')
               AND LOWER(COALESCE(NEW.status::text, '')) = 'cancelled') THEN

            -- Resolve role of the user who cancelled/rejected
            IF NEW.cancelled_by_user_id IS NOT NULL THEN
                SELECT LOWER(COALESCE(role::text, 'broker')), COALESCE(name, 'User')
                INTO v_canceller_role, v_canceller_name
                FROM public.users
                WHERE id = NEW.cancelled_by_user_id
                LIMIT 1;
            END IF;

            -- IF CANCELLED BY BROKER -> Fire notification to Marketing/Admin Team ONLY (DO NOT notify broker)
            IF v_canceller_role = 'broker' OR (v_canceller_role IS NULL AND auth.uid() = v_sender_user_id) THEN
                SELECT ARRAY_AGG(id) INTO v_target_user_ids
                FROM public.users
                WHERE LOWER(role::text) IN ('marketing', 'ads', 'super_admin', 'superadmin', 'admin');

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
                        NEW.cancelled_by_user_id,
                        'Video request cancelled by user',
                        v_broker_name || ' cancelled the video request for ' || v_property_desc,
                        'video_request'::public.notification_type,
                        jsonb_build_object(
                            'video_request_id', NEW.id,
                            'property_id', NEW.property_id,
                            'broker_id', NEW.broker_id,
                            'admin_approval_status', NEW.admin_approval_status::text,
                            'status', NEW.status::text,
                            'cancelled_by_user_id', NEW.cancelled_by_user_id,
                            'reason', COALESCE(NEW.cancel_reason, NEW.admin_cancel_reason, '')
                        )
                    );
                END IF;

            -- IF REJECTED/CANCELLED BY MARKETING OR ADMIN -> Fire notification to Broker ONLY
            ELSE
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
                        NEW.cancelled_by_user_id,
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
                            'cancelled_by_user_id', NEW.cancelled_by_user_id,
                            'reason', COALESCE(NEW.admin_cancel_reason, NEW.cancel_reason, '')
                        )
                    );
                END IF;
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

-- 3. Update fetch_video_requests RPC to include nested cancelled_by_user_id object (UserModel)
CREATE OR REPLACE FUNCTION public.fetch_video_requests(
  p_broker_id UUID DEFAULT NULL,
  p_page INT DEFAULT 1,
  p_limit INT DEFAULT 10,
  p_search_query TEXT DEFAULT '',
  p_admin_approved_status public.video_request_approval_status DEFAULT NULL,
  p_status public.video_request_status DEFAULT NULL,
  p_statuses TEXT[] DEFAULT NULL
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_offset INT;
  v_total_items INT;
  v_total_pages INT;
  v_has_more BOOLEAN;
  v_requests_json JSONB;
BEGIN
  v_offset := (p_page - 1) * p_limit;

  -- 1. Calculate total items
  SELECT COUNT(*)
  INTO v_total_items
  FROM public.video_requests vr
  JOIN public.properties p ON vr.property_id = p.id
  JOIN public.brokers b ON vr.broker_id = b.id
  LEFT JOIN public.addresses a ON p.address_id = a.id
  WHERE (p_broker_id IS NULL OR vr.broker_id = p_broker_id)
    AND (vr.is_deleted IS FALSE OR vr.is_deleted IS NULL)
    AND (p.is_deleted IS FALSE OR p.is_deleted IS NULL)
    AND (p_admin_approved_status IS NULL OR vr.admin_approval_status = p_admin_approved_status)
    AND (p_status IS NULL OR vr.status = p_status)
    AND (p_statuses IS NULL OR array_length(p_statuses, 1) IS NULL OR vr.status::text = ANY(p_statuses))
    AND (
      p_search_query = '' OR
      p.property_title ILIKE '%' || p_search_query || '%' OR
      b.business_name ILIKE '%' || p_search_query || '%' OR
      vr.notes ILIKE '%' || p_search_query || '%' OR
      (a.id IS NOT NULL AND (
         a.full_address ILIKE '%' || p_search_query || '%' OR
         a.city ILIKE '%' || p_search_query || '%' OR
         a.state ILIKE '%' || p_search_query || '%'
      ))
    );

  IF v_total_items = 0 THEN
    v_total_pages := 1;
    v_has_more := false;
  ELSE
    v_total_pages := CEIL(v_total_items::NUMERIC / p_limit)::INT;
    v_has_more := (p_page * p_limit) < v_total_items;
  END IF;

  -- 2. Fetch video requests with nested property, broker, and cancelled_by_user_id (UserModel)
  SELECT COALESCE(jsonb_agg(
    to_jsonb(vr_data) ||
    jsonb_build_object(
      'property', 
      to_jsonb(p_data) || jsonb_build_object(
        'address',
        CASE 
          WHEN p_data.address_id IS NOT NULL THEN to_jsonb(pa_data)
          ELSE NULL
        END
      ),
      'broker',
      to_jsonb(b_data) || jsonb_build_object(
        'address',
        CASE 
          WHEN b_data.address_id IS NOT NULL THEN to_jsonb(ba_data)
          ELSE NULL
        END
      ),
      'cancelled_by_user_id',
      CASE
        WHEN u_data.id IS NOT NULL THEN to_jsonb(u_data)
        ELSE NULL
      END
    )
  ), '[]'::jsonb)
  INTO v_requests_json
  FROM (
    SELECT vr.*
    FROM public.video_requests vr
    JOIN public.properties p ON vr.property_id = p.id
    JOIN public.brokers b ON vr.broker_id = b.id
    LEFT JOIN public.addresses a ON p.address_id = a.id
    WHERE (p_broker_id IS NULL OR vr.broker_id = p_broker_id)
      AND (vr.is_deleted IS FALSE OR vr.is_deleted IS NULL)
      AND (p.is_deleted IS FALSE OR p.is_deleted IS NULL)
      AND (p_admin_approved_status IS NULL OR vr.admin_approval_status = p_admin_approved_status)
      AND (p_status IS NULL OR vr.status = p_status)
      AND (p_statuses IS NULL OR array_length(p_statuses, 1) IS NULL OR vr.status::text = ANY(p_statuses))
      AND (
        p_search_query = '' OR
        p.property_title ILIKE '%' || p_search_query || '%' OR
        b.business_name ILIKE '%' || p_search_query || '%' OR
        vr.notes ILIKE '%' || p_search_query || '%' OR
        (a.id IS NOT NULL AND (
           a.full_address ILIKE '%' || p_search_query || '%' OR
           a.city ILIKE '%' || p_search_query || '%' OR
           a.state ILIKE '%' || p_search_query || '%'
        ))
      )
    ORDER BY COALESCE(vr.updated_at, vr.completed_at, vr.created_at) DESC, vr.created_at DESC
    LIMIT p_limit OFFSET v_offset
  ) vr_data
  JOIN public.properties p_data ON vr_data.property_id = p_data.id
  JOIN public.brokers b_data ON vr_data.broker_id = b_data.id
  LEFT JOIN public.users u_data ON vr_data.cancelled_by_user_id = u_data.id
  LEFT JOIN public.addresses pa_data ON p_data.address_id = pa_data.id
  LEFT JOIN public.addresses ba_data ON b_data.address_id = ba_data.id;

  RETURN jsonb_build_object(
    'success', true,
    'data', v_requests_json,
    'pagination', jsonb_build_object(
      'current_page', p_page,
      'limit', p_limit,
      'total_items', v_total_items,
      'total_pages', v_total_pages,
      'has_more', v_has_more
    )
  );
EXCEPTION WHEN OTHERS THEN
  RETURN jsonb_build_object(
    'success', false,
    'message', SQLERRM
  );
END;
$$;

GRANT EXECUTE ON FUNCTION public.fetch_video_requests(UUID, INT, INT, TEXT, public.video_request_approval_status, public.video_request_status, TEXT[]) TO authenticated;
GRANT EXECUTE ON FUNCTION public.fetch_video_requests(UUID, INT, INT, TEXT, public.video_request_approval_status, public.video_request_status, TEXT[]) TO service_role;
