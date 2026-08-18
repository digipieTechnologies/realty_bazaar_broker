-- Migration: Add phone country code and iso to users, strip +91 from existing user phones, and set automatic updated_at trigger for all tables.

-- 1. Add phone_country_code and phone_country_iso to users table
ALTER TABLE users ADD COLUMN IF NOT EXISTS phone_country_code TEXT DEFAULT '91';
ALTER TABLE users ADD COLUMN IF NOT EXISTS phone_country_iso TEXT DEFAULT 'IN';

-- 2. Migrate existing phone numbers (remove leading +91 or 91 and trim) & set default country code/iso
UPDATE users
SET phone = TRIM(REGEXP_REPLACE(phone, '^\+?91', '')),
    phone_country_code = COALESCE(phone_country_code, '91'),
    phone_country_iso = COALESCE(phone_country_iso, 'IN')
WHERE phone IS NOT NULL;

UPDATE users
SET phone_country_code = '91',
    phone_country_iso = 'IN'
WHERE phone_country_code IS NULL OR phone_country_iso IS NULL;

-- 3. Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 4. Apply updated_at trigger automatically to all public tables with an updated_at column
DO $$
DECLARE
    t text;
BEGIN
    FOR t IN
        SELECT table_name 
        FROM information_schema.columns 
        WHERE table_schema = 'public' 
          AND column_name = 'updated_at'
    LOOP
        EXECUTE format('DROP TRIGGER IF EXISTS trg_set_updated_at ON %I;', t);
        EXECUTE format('CREATE TRIGGER trg_set_updated_at BEFORE UPDATE ON %I FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();', t);
    END LOOP;
END;
$$;
