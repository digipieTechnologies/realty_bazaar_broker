-- Migration: Add update policy for video_requests table to allow updating status (e.g. cancelling requests).

DROP POLICY IF EXISTS "Allow public updates" ON public.video_requests;
CREATE POLICY "Allow public updates" ON public.video_requests
  FOR UPDATE TO public USING (true) WITH CHECK (true);
