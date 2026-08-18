-- Migration: Convert status and admin_approval_status columns in public.video_requests to custom ENUM types

-- 1. Create the custom ENUM types if they do not already exist
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'video_request_status') THEN
    CREATE TYPE public.video_request_status AS ENUM ('pending', 'assigned', 'in_progress', 'completed', 'cancelled');
  END IF;
  
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'video_request_approval_status') THEN
    CREATE TYPE public.video_request_approval_status AS ENUM ('pending', 'approved', 'rejected');
  END IF;
END$$;

-- 2. Drop the current column defaults to allow type alteration
ALTER TABLE public.video_requests ALTER COLUMN status DROP DEFAULT;
ALTER TABLE public.video_requests ALTER COLUMN admin_approval_status DROP DEFAULT;

-- 3. Convert the columns to the new ENUM types, casting the existing VARCHAR values
ALTER TABLE public.video_requests 
  ALTER COLUMN status TYPE public.video_request_status 
    USING status::public.video_request_status,
  ALTER COLUMN admin_approval_status TYPE public.video_request_approval_status 
    USING admin_approval_status::public.video_request_approval_status;

-- 4. Re-apply the defaults using the ENUM types
ALTER TABLE public.video_requests ALTER COLUMN status SET DEFAULT 'pending'::public.video_request_status;
ALTER TABLE public.video_requests ALTER COLUMN admin_approval_status SET DEFAULT 'pending'::public.video_request_approval_status;

-- 5. Re-create the auto-approval trigger function to use the correct type assignments
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
    NEW.admin_approval_status := 'approved'::public.video_request_approval_status;
  ELSE
    NEW.admin_approval_status := 'pending'::public.video_request_approval_status;
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
