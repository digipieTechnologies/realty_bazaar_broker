-- Migration: Convert user role and gender columns to PostgreSQL ENUMs
-- File: supabase/migrations/20260804120000_convert_user_role_and_gender_to_enums.sql

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'user_role') THEN
    CREATE TYPE user_role AS ENUM ('super_admin', 'broker', 'marketing');
  END IF;
END $$;

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'user_gender') THEN
    CREATE TYPE user_gender AS ENUM ('male', 'female', 'other');
  END IF;
END $$;

ALTER TABLE public.users 
  ALTER COLUMN role DROP DEFAULT,
  ALTER COLUMN role TYPE user_role USING (
    CASE 
      WHEN role::text = 'super_admin' THEN 'super_admin'::user_role
      WHEN role::text = 'broker' THEN 'broker'::user_role
      WHEN role::text = 'marketing' THEN 'marketing'::user_role
      ELSE 'broker'::user_role
    END
  ),
  ALTER COLUMN role SET DEFAULT 'broker'::user_role;

ALTER TABLE public.users 
  ALTER COLUMN gender DROP DEFAULT,
  ALTER COLUMN gender TYPE user_gender USING (
    CASE 
      WHEN gender::text = 'male' THEN 'male'::user_gender
      WHEN gender::text = 'female' THEN 'female'::user_gender
      WHEN gender::text = 'other' THEN 'other'::user_gender
      ELSE NULL
    END
  );
