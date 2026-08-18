-- Migration: Update fetch_video_request_counts to include cancelled requests in total count and return a separate cancelled count.

CREATE OR REPLACE FUNCTION public.fetch_video_request_counts(
  p_broker_id UUID DEFAULT NULL,
  p_admin_approved_status public.video_request_approval_status DEFAULT NULL,
  p_status public.video_request_status DEFAULT NULL
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_total INT;
  v_pending INT;
  v_in_progress INT;
  v_completed INT;
  v_cancelled INT;
BEGIN
  -- Total count includes all matching requests (including cancelled)
  SELECT COUNT(*) INTO v_total
  FROM public.video_requests
  WHERE (p_broker_id IS NULL OR broker_id = p_broker_id)
    AND (p_admin_approved_status IS NULL OR admin_approval_status = p_admin_approved_status)
    AND (p_status IS NULL OR status = p_status);

  -- Pending count
  SELECT COUNT(*) INTO v_pending
  FROM public.video_requests
  WHERE (p_broker_id IS NULL OR broker_id = p_broker_id)
    AND (p_admin_approved_status IS NULL OR admin_approval_status = p_admin_approved_status)
    AND (p_status IS NULL OR status = p_status)
    AND status = 'pending'::public.video_request_status;

  -- In-progress count
  SELECT COUNT(*) INTO v_in_progress
  FROM public.video_requests
  WHERE (p_broker_id IS NULL OR broker_id = p_broker_id)
    AND (p_admin_approved_status IS NULL OR admin_approval_status = p_admin_approved_status)
    AND (p_status IS NULL OR status = p_status)
    AND status IN ('assigned'::public.video_request_status, 'in_progress'::public.video_request_status);

  -- Completed count
  SELECT COUNT(*) INTO v_completed
  FROM public.video_requests
  WHERE (p_broker_id IS NULL OR broker_id = p_broker_id)
    AND (p_admin_approved_status IS NULL OR admin_approval_status = p_admin_approved_status)
    AND (p_status IS NULL OR status = p_status)
    AND status = 'completed'::public.video_request_status;

  -- Cancelled count
  SELECT COUNT(*) INTO v_cancelled
  FROM public.video_requests
  WHERE (p_broker_id IS NULL OR broker_id = p_broker_id)
    AND (p_admin_approved_status IS NULL OR admin_approval_status = p_admin_approved_status)
    AND (p_status IS NULL OR status = p_status)
    AND status = 'cancelled'::public.video_request_status;

  RETURN jsonb_build_object(
    'total', v_total,
    'pending', v_pending,
    'in_progress', v_in_progress,
    'completed', v_completed,
    'cancelled', v_cancelled
  );
END;
$$;
