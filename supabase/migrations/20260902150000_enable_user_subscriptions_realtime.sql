-- Migration: Enable Realtime for user_subscriptions table
-- Purpose: Allows Supabase clients to receive realtime INSERT/UPDATE events when a broker purchases or updates a subscription.

ALTER PUBLICATION supabase_realtime ADD TABLE public.user_subscriptions;
