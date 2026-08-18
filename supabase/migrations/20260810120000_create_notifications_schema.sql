-- Migration: 20260810120000_create_notifications_schema.sql
-- Description: Create notification_type enum and public.notifications table with nullable receiver_id, RLS policies, and performance indexes.

-- 1. Create notification_type ENUM (strictly video_request and lead for now)
DO $$ 
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'notification_type') THEN
        CREATE TYPE public.notification_type AS ENUM (
            'video_request',
            'lead'
        );
    END IF;
END $$;

-- 2. Create public.notifications table
CREATE TABLE IF NOT EXISTS public.notifications (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    sender_id UUID NULL REFERENCES public.users(id) ON DELETE SET NULL,
    receiver_id UUID NULL REFERENCES public.users(id) ON DELETE SET NULL,
    notification_type public.notification_type NOT NULL,
    title TEXT NOT NULL,
    description TEXT NOT NULL,
    data JSONB NOT NULL DEFAULT '{}'::jsonb,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 3. Indexes for fast lookups
CREATE INDEX IF NOT EXISTS idx_notifications_sender_id ON public.notifications(sender_id);
CREATE INDEX IF NOT EXISTS idx_notifications_receiver_id ON public.notifications(receiver_id);
CREATE INDEX IF NOT EXISTS idx_notifications_type ON public.notifications(notification_type);
CREATE INDEX IF NOT EXISTS idx_notifications_created_at ON public.notifications(created_at DESC);

-- 4. Enable Row Level Security (RLS)
ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;

-- 5. RLS Policies
DO $$ 
BEGIN
    -- Policy 1: Authenticated users can view notifications assigned to them or broadcast (receiver_id is null)
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies 
        WHERE tablename = 'notifications' AND policyname = 'Users can view relevant notifications'
    ) THEN
        CREATE POLICY "Users can view relevant notifications"
        ON public.notifications
        FOR SELECT
        USING (
            auth.role() = 'authenticated' AND (receiver_id IS NULL OR auth.uid() = receiver_id)
        );
    END IF;

    -- Policy 2: Authenticated users can insert notifications
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies 
        WHERE tablename = 'notifications' AND policyname = 'Authenticated users can insert notifications'
    ) THEN
        CREATE POLICY "Authenticated users can insert notifications"
        ON public.notifications
        FOR INSERT
        WITH CHECK (auth.role() = 'authenticated');
    END IF;
END $$;
