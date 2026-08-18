-- Migration: Enable Realtime postgres change notifications for the video_requests table

ALTER PUBLICATION supabase_realtime ADD TABLE public.video_requests;
