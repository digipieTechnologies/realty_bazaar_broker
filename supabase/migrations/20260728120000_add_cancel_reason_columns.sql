-- Migration: Add cancel_reason and admin_cancel_reason columns to video_requests table.
-- cancel_reason: Reason provided by the broker when they cancel their own request.
-- admin_cancel_reason: Reason provided by the marketing admin when they decline/cancel a request.

ALTER TABLE public.video_requests
  ADD COLUMN IF NOT EXISTS cancel_reason TEXT DEFAULT NULL,
  ADD COLUMN IF NOT EXISTS admin_cancel_reason TEXT DEFAULT NULL;
