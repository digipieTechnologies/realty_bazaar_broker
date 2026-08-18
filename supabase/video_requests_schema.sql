-- Supabase Schema for Video Requests

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

-- 2. Create the video_requests table
CREATE TABLE IF NOT EXISTS public.video_requests (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  property_id UUID NOT NULL REFERENCES public.properties(id) ON DELETE CASCADE,
  broker_id UUID NOT NULL REFERENCES public.brokers(id) ON DELETE CASCADE,
  status public.video_request_status DEFAULT 'pending'::public.video_request_status NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
  notes TEXT, -- Any special instructions or notes from the broker
  admin_approval_status public.video_request_approval_status DEFAULT 'pending'::public.video_request_approval_status NOT NULL,
  completed_at TIMESTAMP WITH TIME ZONE -- The timestamp when the shoot was completed and uploaded
);

-- 3. Create Indexes
CREATE INDEX IF NOT EXISTS idx_video_requests_broker_id ON public.video_requests USING btree (broker_id);
CREATE INDEX IF NOT EXISTS idx_video_requests_property_id ON public.video_requests USING btree (property_id);

-- 4. Enable RLS
ALTER TABLE public.video_requests ENABLE ROW LEVEL SECURITY;

-- 5. Create RLS Policies
-- Allow public inserts (anyone can submit a request)
DROP POLICY IF EXISTS "Allow public inserts" ON public.video_requests;
CREATE POLICY "Allow public inserts" ON public.video_requests
  FOR INSERT TO public WITH CHECK (true);

-- Allow public selects (anyone can read requests)
DROP POLICY IF EXISTS "Allow public selects" ON public.video_requests;
CREATE POLICY "Allow public selects" ON public.video_requests
  FOR SELECT TO public USING (true);

-- Allow public updates (anyone can update requests)
DROP POLICY IF EXISTS "Allow public updates" ON public.video_requests;
CREATE POLICY "Allow public updates" ON public.video_requests
  FOR UPDATE TO public USING (true) WITH CHECK (true);

-- 6. Trigger for updated_at column
DROP TRIGGER IF EXISTS trg_set_updated_at ON public.video_requests;
CREATE TRIGGER trg_set_updated_at BEFORE UPDATE ON public.video_requests 
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- 7. Trigger for auto-approving video requests
DROP TRIGGER IF EXISTS trg_video_requests_auto_approve ON public.video_requests;
CREATE TRIGGER trg_video_requests_auto_approve BEFORE INSERT ON public.video_requests 
  FOR EACH ROW EXECUTE FUNCTION public.trg_fn_video_requests_auto_approve();

-- 8. Trigger to set completed_at automatically when status transitions to completed
CREATE OR REPLACE FUNCTION public.set_video_request_completed_at()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.status = 'completed' AND OLD.status IS DISTINCT FROM 'completed' THEN
    NEW.completed_at = timezone('utc'::text, now());
  ELSIF NEW.status IS DISTINCT FROM 'completed' THEN
    NEW.completed_at = NULL;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_set_video_request_completed_at ON public.video_requests;
CREATE TRIGGER trg_set_video_request_completed_at
  BEFORE UPDATE ON public.video_requests
  FOR EACH ROW
  EXECUTE FUNCTION public.set_video_request_completed_at();

-- 9. Enable Realtime for the table
ALTER PUBLICATION supabase_realtime ADD TABLE public.video_requests;
