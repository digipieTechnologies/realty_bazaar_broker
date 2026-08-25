-- Migration: Convert ad_campaign_settings gender column to PostgreSQL ENUM (campaign_gender) with equality operators
-- File: supabase/migrations/20260824160000_convert_campaign_gender_to_enum.sql

-- 1. Create the campaign_gender ENUM type if it doesn't exist
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'campaign_gender') THEN
    CREATE TYPE public.campaign_gender AS ENUM ('all', 'male', 'female');
  END IF;
END $$;

-- 2. Create helper equality functions between campaign_gender and text
CREATE OR REPLACE FUNCTION public.campaign_gender_eq_text(public.campaign_gender, text)
RETURNS boolean AS $$
  SELECT $1::text = $2;
$$ LANGUAGE sql IMMUTABLE STRICT;

CREATE OR REPLACE FUNCTION public.text_eq_campaign_gender(text, public.campaign_gender)
RETURNS boolean AS $$
  SELECT $1 = $2::text;
$$ LANGUAGE sql IMMUTABLE STRICT;

-- 3. Create equality operators (=) between campaign_gender and text
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_operator 
    WHERE oprname = '=' 
    AND oprleft = 'public.campaign_gender'::regtype 
    AND oprright = 'text'::regtype
  ) THEN
    CREATE OPERATOR = (
      LEFTARG = public.campaign_gender,
      RIGHTARG = text,
      PROCEDURE = public.campaign_gender_eq_text,
      COMMUTATOR = =
    );
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_operator 
    WHERE oprname = '=' 
    AND oprleft = 'text'::regtype 
    AND oprright = 'public.campaign_gender'::regtype
  ) THEN
    CREATE OPERATOR = (
      LEFTARG = text,
      RIGHTARG = public.campaign_gender,
      PROCEDURE = public.text_eq_campaign_gender,
      COMMUTATOR = =
    );
  END IF;
END $$;

-- 4. Create IMPLICIT CAST between campaign_gender and text
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_cast 
    WHERE source = 'public.campaign_gender'::regtype AND target = 'text'::regtype
  ) THEN
    CREATE CAST (public.campaign_gender AS text) WITH INOUT AS IMPLICIT;
  END IF;
EXCEPTION WHEN OTHERS THEN NULL;
END $$;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_cast 
    WHERE source = 'text'::regtype AND target = 'public.campaign_gender'::regtype
  ) THEN
    CREATE CAST (text AS public.campaign_gender) WITH INOUT AS IMPLICIT;
  END IF;
EXCEPTION WHEN OTHERS THEN NULL;
END $$;

-- 5. Alter table column type
ALTER TABLE public.ad_campaign_settings 
  ALTER COLUMN gender DROP DEFAULT,
  ALTER COLUMN gender TYPE public.campaign_gender USING (
    CASE 
      WHEN (gender::text) = 'male' THEN 'male'::public.campaign_gender
      WHEN (gender::text) = 'female' THEN 'female'::public.campaign_gender
      ELSE 'all'::public.campaign_gender
    END
  ),
  ALTER COLUMN gender SET DEFAULT 'all'::public.campaign_gender;
