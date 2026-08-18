-- Migration: Add completed_at column and trigger to video_requests table

ALTER TABLE public.video_requests 
ADD COLUMN completed_at TIMESTAMP WITH TIME ZONE NULL;

-- Trigger function to automatically set completed_at when status transitions to 'completed'
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
