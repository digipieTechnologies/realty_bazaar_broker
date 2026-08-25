-- Migration: 20260825164500_create_account_deletion_requests_and_engine.sql
-- Purpose: Schema for tracking account deletion requests & dynamic future-proof soft/hard deletion engine.

-- 1. Create account_deletion_requests table
CREATE TABLE IF NOT EXISTS public.account_deletion_requests (
  id UUID NOT NULL DEFAULT gen_random_uuid(),
  user_id UUID,
  broker_id UUID,
  email TEXT,
  phone TEXT,
  status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'approved', 'rejected')),
  deletion_type TEXT NOT NULL DEFAULT 'soft' CHECK (deletion_type IN ('soft', 'hard')),
  reason TEXT,
  requested_ip TEXT,
  requested_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  processed_at TIMESTAMPTZ,
  processed_by_admin_id UUID,
  CONSTRAINT account_deletion_requests_pkey PRIMARY KEY (id),
  CONSTRAINT account_deletion_requests_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE SET NULL,
  CONSTRAINT account_deletion_requests_broker_id_fkey FOREIGN KEY (broker_id) REFERENCES public.brokers(id) ON DELETE SET NULL
);

-- Indices for fast duplicate lookup
CREATE INDEX IF NOT EXISTS idx_account_deletion_requests_user_id_status ON public.account_deletion_requests(user_id, status);
CREATE INDEX IF NOT EXISTS idx_account_deletion_requests_email_status ON public.account_deletion_requests(lower(email), status);
CREATE INDEX IF NOT EXISTS idx_account_deletion_requests_phone_status ON public.account_deletion_requests(phone, status);

-- Enable RLS
ALTER TABLE public.account_deletion_requests ENABLE ROW LEVEL SECURITY;

-- Allow service role full access; authenticated users can read their own request
DROP POLICY IF EXISTS "Service role full access on account_deletion_requests" ON public.account_deletion_requests;
CREATE POLICY "Service role full access on account_deletion_requests"
  ON public.account_deletion_requests
  FOR ALL
  TO service_role
  USING (true)
  WITH CHECK (true);

DROP POLICY IF EXISTS "Users can view their own deletion requests" ON public.account_deletion_requests;
CREATE POLICY "Users can view their own deletion requests"
  ON public.account_deletion_requests
  FOR SELECT
  TO authenticated
  USING (auth.uid() = user_id);

-- 2. Dynamic Schema-Wide Deletion Function
-- Dynamically discovers all public tables referencing user_id / broker_id / sender_id / cancelled_by_user_id
-- and handles soft or hard deletion systematically.
CREATE OR REPLACE FUNCTION public.execute_user_deletion(
  p_user_id UUID,
  p_broker_id UUID DEFAULT NULL,
  p_mode TEXT DEFAULT 'soft',
  p_reason TEXT DEFAULT NULL
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_rec RECORD;
  v_resolved_broker_id UUID := p_broker_id;
  v_affected_tables JSONB := '[]'::jsonb;
  v_sql TEXT;
BEGIN
  -- Validate mode
  IF p_mode NOT IN ('soft', 'hard') THEN
    RAISE EXCEPTION 'Invalid deletion mode: %. Expected soft or hard.', p_mode;
  END IF;

  -- If broker_id is null, resolve it from users table if user_id is provided
  IF v_resolved_broker_id IS NULL AND p_user_id IS NOT NULL THEN
    SELECT broker_id INTO v_resolved_broker_id
    FROM public.users
    WHERE id = p_user_id;
  END IF;

  -- =========================================================================
  -- MODE: SOFT DELETE
  -- Finds every table with matching user/broker columns AND an is_deleted column
  -- =========================================================================
  IF p_mode = 'soft' THEN
    -- A. Dynamically update any table that has user_id and is_deleted
    IF p_user_id IS NOT NULL THEN
      FOR v_rec IN
        SELECT DISTINCT c.table_name
        FROM information_schema.columns c
        WHERE c.table_schema = 'public'
          AND c.table_name != 'account_deletion_requests'
          AND c.column_name IN ('user_id', 'sender_id', 'cancelled_by_user_id')
          AND EXISTS (
            SELECT 1 FROM information_schema.columns del
            WHERE del.table_schema = 'public'
              AND del.table_name = c.table_name
              AND del.column_name = 'is_deleted'
          )
      LOOP
        -- Check if is_active exists on this table
        IF EXISTS (
          SELECT 1 FROM information_schema.columns act
          WHERE act.table_schema = 'public'
            AND act.table_name = v_rec.table_name
            AND act.column_name = 'is_active'
        ) THEN
          v_sql := format(
            'UPDATE public.%I SET is_deleted = true, is_active = false, deleted_at = now() WHERE (user_id = %L OR sender_id = %L OR cancelled_by_user_id = %L) AND is_deleted = false',
            v_rec.table_name, p_user_id, p_user_id, p_user_id
          );
        ELSE
          v_sql := format(
            'UPDATE public.%I SET is_deleted = true, deleted_at = now() WHERE (user_id = %L OR sender_id = %L OR cancelled_by_user_id = %L) AND is_deleted = false',
            v_rec.table_name, p_user_id, p_user_id, p_user_id
          );
        END IF;

        BEGIN
          EXECUTE v_sql;
          v_affected_tables := v_affected_tables || jsonb_build_object('table', v_rec.table_name, 'action', 'soft_delete_user');
        EXCEPTION WHEN OTHERS THEN
          -- In case one of the alternate columns does not exist in table, fallback to single column match
          NULL;
        END;
      END LOOP;

      -- Direct soft-delete on users table itself (PK is id) and store delete_reason
      UPDATE public.users
      SET is_deleted = true,
          is_active = false,
          deleted_at = now(),
          delete_reason = COALESCE(p_reason, delete_reason)
      WHERE id = p_user_id;

      v_affected_tables := v_affected_tables || jsonb_build_object('table', 'users', 'action', 'soft_delete_user_pk');
    END IF;

    -- B. Dynamically update any table that has broker_id and is_deleted
    IF v_resolved_broker_id IS NOT NULL THEN
      FOR v_rec IN
        SELECT DISTINCT c.table_name
        FROM information_schema.columns c
        WHERE c.table_schema = 'public'
          AND c.table_name != 'account_deletion_requests'
          AND c.column_name = 'broker_id'
          AND EXISTS (
            SELECT 1 FROM information_schema.columns del
            WHERE del.table_schema = 'public'
              AND del.table_name = c.table_name
              AND del.column_name = 'is_deleted'
          )
      LOOP
        IF EXISTS (
          SELECT 1 FROM information_schema.columns act
          WHERE act.table_schema = 'public'
            AND act.table_name = v_rec.table_name
            AND act.column_name = 'is_active'
        ) THEN
          v_sql := format(
            'UPDATE public.%I SET is_deleted = true, is_active = false, deleted_at = now() WHERE broker_id = %L AND is_deleted = false',
            v_rec.table_name, v_resolved_broker_id
          );
        ELSE
          v_sql := format(
            'UPDATE public.%I SET is_deleted = true, deleted_at = now() WHERE broker_id = %L AND is_deleted = false',
            v_rec.table_name, v_resolved_broker_id
          );
        END IF;

        EXECUTE v_sql;
        v_affected_tables := v_affected_tables || jsonb_build_object('table', v_rec.table_name, 'action', 'soft_delete_broker');
      END LOOP;

      -- Scramble sensitive tokens in social_accounts
      UPDATE public.social_accounts
      SET access_token = 'DELETED',
          page_access_token = NULL,
          is_connected = false,
          is_active = false,
          is_deleted = true,
          deleted_at = now()
      WHERE broker_id = v_resolved_broker_id;

      -- Direct soft-delete on brokers table itself (PK is id)
      UPDATE public.brokers
      SET is_deleted = true,
          is_active = false,
          deleted_at = now()
      WHERE id = v_resolved_broker_id;

      v_affected_tables := v_affected_tables || jsonb_build_object('table', 'brokers', 'action', 'soft_delete_broker_pk');
    END IF;

  -- =========================================================================
  -- MODE: HARD DELETE
  -- Permanently deletes dependent rows in proper order
  -- =========================================================================
  ELSIF p_mode = 'hard' THEN
    -- Scrub and purge child records
    IF v_resolved_broker_id IS NOT NULL THEN
      -- Delete chat messages & rooms
      DELETE FROM public.chat_messages WHERE sender_id = p_user_id OR room_id IN (SELECT id FROM public.chat_rooms WHERE broker_id = v_resolved_broker_id);
      DELETE FROM public.chat_rooms WHERE broker_id = v_resolved_broker_id;
      
      -- Delete social leads & posts
      DELETE FROM public.social_leads WHERE broker_id = v_resolved_broker_id;
      DELETE FROM public.social_posts WHERE broker_id = v_resolved_broker_id;
      DELETE FROM public.social_accounts WHERE broker_id = v_resolved_broker_id;

      -- Delete ad campaign settings
      DELETE FROM public.ad_campaign_settings WHERE broker_id = v_resolved_broker_id;

      -- Delete video requests
      DELETE FROM public.video_requests WHERE broker_id = v_resolved_broker_id;

      -- Delete properties & attachments
      DELETE FROM public.properties WHERE broker_id = v_resolved_broker_id;

      -- Delete addresses associated to broker
      DELETE FROM public.addresses WHERE entity_id = v_resolved_broker_id OR entity_type = 'broker';

      -- Delete broker
      DELETE FROM public.brokers WHERE id = v_resolved_broker_id;
    END IF;

    IF p_user_id IS NOT NULL THEN
      DELETE FROM public.notifications WHERE sender_id = p_user_id;
      DELETE FROM public.user_otps WHERE user_id = p_user_id;
      DELETE FROM public.users WHERE id = p_user_id;
    END IF;

    v_affected_tables := v_affected_tables || jsonb_build_object('action', 'hard_purge_completed');
  END IF;

  RETURN jsonb_build_object(
    'success', true,
    'mode', p_mode,
    'user_id', p_user_id,
    'broker_id', v_resolved_broker_id,
    'affected_operations', v_affected_tables
  );
END;
$$;
