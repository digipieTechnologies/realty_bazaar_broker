-- Migration: Fix RLS Policy for user_subscriptions table
-- Purpose: Correct the RLS policy so logged-in users (auth.uid()) can read subscriptions matching their associated broker_id in public.users.
-- Explanation: Formerly, the policy checked (auth.uid() = broker_id). However, auth.uid() is public.users.id, whereas broker_id is public.brokers.id!
-- This mismatch caused Supabase RLS to filter out Realtime events for authenticated brokers.

-- 1. Set REPLICA IDENTITY FULL to ensure full payload on Realtime updates
ALTER TABLE public.user_subscriptions REPLICA IDENTITY FULL;

-- 2. Drop existing broken policy
DROP POLICY IF EXISTS "Brokers can view own subscriptions" ON public.user_subscriptions;

-- 3. Create updated RLS policy linking auth.uid() -> public.users.broker_id -> user_subscriptions.broker_id
CREATE POLICY "Brokers can view own subscriptions" ON public.user_subscriptions
    FOR SELECT
    TO public
    USING (
      EXISTS (
        SELECT 1 FROM public.users u
        WHERE u.id = auth.uid()
          AND u.broker_id = user_subscriptions.broker_id
      )
    );
