-- Migration: Add intermediate admin approval flow for broker video shoot requests.

-- 1. Add auto_approve_video_requests column to brokers table
ALTER TABLE public.brokers ADD COLUMN IF NOT EXISTS auto_approve_video_requests BOOLEAN DEFAULT false NOT NULL;

-- 2. Add admin_approval_status column to video_requests table (pending, approved, rejected)
ALTER TABLE public.video_requests ADD COLUMN IF NOT EXISTS admin_approval_status VARCHAR(20) DEFAULT 'pending' NOT NULL;

-- 3. Create or replace the auto-approval trigger function
CREATE OR REPLACE FUNCTION public.trg_fn_video_requests_auto_approve()
RETURNS TRIGGER AS $$
DECLARE
  v_auto_approve BOOLEAN;
BEGIN
  -- Fetch the auto-approval flag for the requesting broker
  SELECT auto_approve_video_requests INTO v_auto_approve
  FROM public.brokers
  WHERE id = NEW.broker_id;

  -- Set admin approval status depending on the broker's auto-approval flag
  IF v_auto_approve IS TRUE THEN
    NEW.admin_approval_status := 'approved';
  ELSE
    NEW.admin_approval_status := 'pending';
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 4. Attach the BEFORE INSERT trigger to the video_requests table
DROP TRIGGER IF EXISTS trg_video_requests_auto_approve ON public.video_requests;
CREATE TRIGGER trg_video_requests_auto_approve
  BEFORE INSERT ON public.video_requests
  FOR EACH ROW
  EXECUTE FUNCTION public.trg_fn_video_requests_auto_approve();
