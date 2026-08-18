-- Migration: Add is_email_verified column to users table and create user_otps schema.

-- 1. Add is_email_verified column to users table if not exists
ALTER TABLE public.users ADD COLUMN IF NOT EXISTS is_email_verified BOOLEAN DEFAULT FALSE;

-- Update existing users to TRUE if they were created before OTP verification was enforced
UPDATE public.users SET is_email_verified = TRUE WHERE is_email_verified IS NULL;

-- 2. Create enum for OTP types if not exists
DO $$ 
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'otp_type_enum') THEN
        CREATE TYPE otp_type_enum AS ENUM ('email_verify', 'forgot_password', 'change_password');
    END IF;
END $$;

-- 3. Create user_otps table
CREATE TABLE IF NOT EXISTS public.user_otps (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES public.users(id) ON DELETE CASCADE NULL,
    email TEXT NULL,
    otp TEXT NOT NULL,
    otp_type otp_type_enum NOT NULL,
    expiry_at TIMESTAMPTZ NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 4. Add performance indices
CREATE INDEX IF NOT EXISTS idx_user_otps_user_id ON public.user_otps(user_id);
CREATE INDEX IF NOT EXISTS idx_user_otps_email ON public.user_otps(email);
CREATE INDEX IF NOT EXISTS idx_user_otps_otp_type ON public.user_otps(otp_type);
CREATE INDEX IF NOT EXISTS idx_user_otps_expiry ON public.user_otps(expiry_at);

-- 5. Enable Row Level Security (RLS)
ALTER TABLE public.user_otps ENABLE ROW LEVEL SECURITY;

-- 6. RLS Policies
DROP POLICY IF EXISTS "Allow anon and authenticated to insert user_otps" ON public.user_otps;
CREATE POLICY "Allow anon and authenticated to insert user_otps" 
ON public.user_otps FOR INSERT 
WITH CHECK (true);

DROP POLICY IF EXISTS "Allow users to read their own OTPs" ON public.user_otps;
CREATE POLICY "Allow users to read their own OTPs" 
ON public.user_otps FOR SELECT 
USING (
    user_id = auth.uid() 
    OR (auth.jwt() ->> 'email') = email 
    OR auth.role() = 'anon' 
    OR auth.role() = 'service_role'
);

DROP POLICY IF EXISTS "Allow users to delete their own OTPs" ON public.user_otps;
CREATE POLICY "Allow users to delete their own OTPs" 
ON public.user_otps FOR DELETE 
USING (
    user_id = auth.uid() 
    OR (auth.jwt() ->> 'email') = email 
    OR auth.role() = 'anon' 
    OR auth.role() = 'service_role'
);
