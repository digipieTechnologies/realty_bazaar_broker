-- Migration: 20260901120000_refactor_broker_and_property_code_generation.sql
-- Description: Refactors broker_code generation (2-letter name base + 1 digit, e.g. RB1, ZS1)
-- and property_code generation (broker_code + 3-digit zero-padded sequence, e.g. RB1-001, RB1-002).
-- Includes backfill of all existing brokers and properties.

-- 1. Ensure columns exist
ALTER TABLE public.brokers ADD COLUMN IF NOT EXISTS broker_code TEXT;
ALTER TABLE public.properties ADD COLUMN IF NOT EXISTS property_code TEXT;

-- 2. Helper function: generate random uppercase alphanumeric string
CREATE OR REPLACE FUNCTION public.generate_random_alphanumeric(p_length INTEGER)
RETURNS TEXT
LANGUAGE plpgsql
AS $$
DECLARE
  v_chars TEXT := 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789'; -- Excluding ambiguous characters (0, O, 1, I)
  v_result TEXT := '';
  v_i INTEGER;
BEGIN
  IF p_length IS NULL OR p_length < 1 THEN
    p_length := 2;
  END IF;
  FOR v_i IN 1..p_length LOOP
    v_result := v_result || substr(v_chars, floor(random() * length(v_chars) + 1)::integer, 1);
  END LOOP;
  RETURN v_result;
END;
$$;

-- 3. Stored function: generate unique broker code (2-letter base + digit, e.g. RB1, ZS1)
CREATE OR REPLACE FUNCTION public.generate_unique_broker_code(
  p_business_name TEXT DEFAULT NULL,
  p_user_name TEXT DEFAULT NULL
)
RETURNS TEXT
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_name_to_use TEXT;
  v_words TEXT[];
  v_clean_words TEXT[] := ARRAY[]::TEXT[];
  v_cleaned_full TEXT := '';
  v_w TEXT;
  v_bases TEXT[] := ARRAY[]::TEXT[];
  v_base TEXT;
  v_candidate TEXT;
  v_digit INTEGER;
  v_exists BOOLEAN;
  v_i INTEGER;
BEGIN
  -- Priority 1: Business Name, Priority 2: User Name
  v_name_to_use := COALESCE(NULLIF(TRIM(p_business_name), ''), NULLIF(TRIM(p_user_name), ''));

  IF v_name_to_use IS NOT NULL AND TRIM(v_name_to_use) != '' THEN
    -- Extract alphanumeric words
    v_words := regexp_split_to_array(UPPER(regexp_replace(v_name_to_use, '[^a-zA-Z0-9\s]', ' ', 'g')), '\s+');
    FOREACH v_w IN ARRAY v_words LOOP
      IF length(v_w) > 0 THEN
        v_clean_words := array_append(v_clean_words, v_w);
        v_cleaned_full := v_cleaned_full || v_w;
      END IF;
    END LOOP;

    -- Candidate Base 1: Initials (e.g. "Realty Bazaar" -> "RB", "VTP Realty" -> "VR")
    IF array_length(v_clean_words, 1) >= 2 THEN
      v_base := substr(v_clean_words[1], 1, 1) || substr(v_clean_words[2], 1, 1);
      IF NOT (v_base = ANY(v_bases)) THEN
        v_bases := array_append(v_bases, v_base);
      END IF;
    END IF;

    -- Candidate Base 2: First 2 letters of first word (e.g. "Realty" -> "RE")
    IF array_length(v_clean_words, 1) >= 1 AND length(v_clean_words[1]) >= 2 THEN
      v_base := substr(v_clean_words[1], 1, 2);
      IF NOT (v_base = ANY(v_bases)) THEN
        v_bases := array_append(v_bases, v_base);
      END IF;
    END IF;

    -- Candidate Base 3: First letter of word 1 + First letter of word 3 (if 3+ words)
    IF array_length(v_clean_words, 1) >= 3 THEN
      v_base := substr(v_clean_words[1], 1, 1) || substr(v_clean_words[3], 1, 1);
      IF NOT (v_base = ANY(v_bases)) THEN
        v_bases := array_append(v_bases, v_base);
      END IF;
    END IF;

    -- Candidate Base 4: First letter of word 1 + Second letter of word 2
    IF array_length(v_clean_words, 1) >= 2 AND length(v_clean_words[2]) >= 2 THEN
      v_base := substr(v_clean_words[1], 1, 1) || substr(v_clean_words[2], 2, 1);
      IF NOT (v_base = ANY(v_bases)) THEN
        v_bases := array_append(v_bases, v_base);
      END IF;
    END IF;

    -- Candidate Base 5: First 2 letters of second word
    IF array_length(v_clean_words, 1) >= 2 AND length(v_clean_words[2]) >= 2 THEN
      v_base := substr(v_clean_words[2], 1, 2);
      IF NOT (v_base = ANY(v_bases)) THEN
        v_bases := array_append(v_bases, v_base);
      END IF;
    END IF;

    -- Candidate Base 6: Consecutive pairs from cleaned full name
    IF length(v_cleaned_full) >= 2 THEN
      FOR v_i IN 1..LEAST(length(v_cleaned_full) - 1, 6) LOOP
        v_base := substr(v_cleaned_full, v_i, 2);
        IF NOT (v_base = ANY(v_bases)) THEN
          v_bases := array_append(v_bases, v_base);
        END IF;
      END LOOP;
    END IF;
  END IF;

  -- Default fallback base if none found
  IF array_length(v_bases, 1) IS NULL OR array_length(v_bases, 1) = 0 THEN
    v_bases := ARRAY['RB'];
  ELSE
    IF NOT ('RB' = ANY(v_bases)) THEN
      v_bases := array_append(v_bases, 'RB');
    END IF;
  END IF;

  -- Phase 1: Try 2-letter base + single digit (1 to 9) across candidate bases
  FOREACH v_base IN ARRAY v_bases LOOP
    FOR v_digit IN 1..9 LOOP
      v_candidate := v_base || v_digit::TEXT;
      SELECT EXISTS(SELECT 1 FROM public.brokers WHERE broker_code = v_candidate) INTO v_exists;
      IF NOT v_exists THEN
        RETURN v_candidate;
      END IF;
    END LOOP;
  END LOOP;

  -- Phase 2: If all 1-9 are taken across all name combinations, try 2 digits (10 to 99)
  FOREACH v_base IN ARRAY v_bases LOOP
    FOR v_digit IN 10..99 LOOP
      v_candidate := v_base || v_digit::TEXT;
      SELECT EXISTS(SELECT 1 FROM public.brokers WHERE broker_code = v_candidate) INTO v_exists;
      IF NOT v_exists THEN
        RETURN v_candidate;
      END IF;
    END LOOP;
  END LOOP;

  -- Phase 3: Absolute fallback: 2 random letters + digit (1..9)
  FOR v_i IN 1..50 LOOP
    v_candidate := public.generate_random_alphanumeric(2) || (floor(random() * 9 + 1))::TEXT;
    SELECT EXISTS(SELECT 1 FROM public.brokers WHERE broker_code = v_candidate) INTO v_exists;
    IF NOT v_exists THEN
      RETURN v_candidate;
    END IF;
  END LOOP;

  -- Emergency fallback
  RETURN UPPER(substr(md5(random()::text || clock_timestamp()::text), 1, 3));
END;
$$;

-- 4. Stored function: generate unique property code (e.g. RB1-001, RB1-002)
CREATE OR REPLACE FUNCTION public.generate_unique_property_code(
  p_broker_id UUID,
  p_property_title TEXT DEFAULT NULL
)
RETURNS TEXT
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_broker_code TEXT;
  v_max_num INTEGER := 0;
  v_next_num INTEGER := 1;
  v_suffix TEXT;
  v_candidate TEXT;
  v_exists BOOLEAN;
BEGIN
  -- 1. Fetch broker code
  SELECT broker_code INTO v_broker_code
  FROM public.brokers
  WHERE id = p_broker_id;

  -- Fallback if broker code is missing
  IF v_broker_code IS NULL OR TRIM(v_broker_code) = '' THEN
    v_broker_code := 'RB1';
  END IF;

  -- 2. Find highest existing sequential property number for this broker
  SELECT COALESCE(
    MAX(
      NULLIF(regexp_replace(property_code, '^' || v_broker_code || '-0*', ''), '')::INTEGER
    ),
    0
  )
  INTO v_max_num
  FROM public.properties
  WHERE broker_id = p_broker_id
    AND property_code ~ ('^' || v_broker_code || '-[0-9]+$');

  v_next_num := v_max_num + 1;

  -- 3. Format candidate with 3-digit zero-padding (e.g. 001, 002... 999, 1000+)
  LOOP
    v_suffix := LPAD(v_next_num::TEXT, 3, '0');
    v_candidate := v_broker_code || '-' || v_suffix;

    -- Verify uniqueness
    SELECT EXISTS(SELECT 1 FROM public.properties WHERE property_code = v_candidate) INTO v_exists;
    IF NOT v_exists THEN
      RETURN v_candidate;
    END IF;

    v_next_num := v_next_num + 1;
  END LOOP;
END;
$$;

-- 5. Trigger functions for automatic generation and update immutability
CREATE OR REPLACE FUNCTION public.trg_broker_code_generator()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_user_name TEXT;
BEGIN
  -- If explicitly updating broker_code, allow it (uppercase trimmed)
  IF TG_OP = 'UPDATE' THEN
    IF NEW.broker_code IS NOT NULL AND TRIM(NEW.broker_code) != '' AND NEW.broker_code IS DISTINCT FROM OLD.broker_code THEN
      NEW.broker_code := UPPER(TRIM(NEW.broker_code));
      RETURN NEW;
    END IF;
    -- If updating other fields and broker_code was already set, keep OLD
    IF OLD.broker_code IS NOT NULL AND TRIM(OLD.broker_code) != '' THEN
      NEW.broker_code := OLD.broker_code;
      RETURN NEW;
    END IF;
  END IF;

  -- Generate on INSERT or if empty
  IF NEW.broker_code IS NULL OR TRIM(NEW.broker_code) = '' THEN
    SELECT name INTO v_user_name
    FROM public.users
    WHERE broker_id = NEW.id
    LIMIT 1;

    NEW.broker_code := public.generate_unique_broker_code(NEW.business_name, v_user_name);
  ELSE
    NEW.broker_code := UPPER(TRIM(NEW.broker_code));
  END IF;

  RETURN NEW;
END;
$$;

CREATE OR REPLACE FUNCTION public.trg_property_code_generator()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  -- If explicitly updating property_code, allow it (uppercase trimmed)
  IF TG_OP = 'UPDATE' THEN
    IF NEW.property_code IS NOT NULL AND TRIM(NEW.property_code) != '' AND NEW.property_code IS DISTINCT FROM OLD.property_code THEN
      NEW.property_code := UPPER(TRIM(NEW.property_code));
      RETURN NEW;
    END IF;
    -- If updating other fields and property_code was already set, keep OLD
    IF OLD.property_code IS NOT NULL AND TRIM(OLD.property_code) != '' THEN
      NEW.property_code := OLD.property_code;
      RETURN NEW;
    END IF;
  END IF;

  -- Generate on INSERT or if empty
  IF NEW.property_code IS NULL OR TRIM(NEW.property_code) = '' THEN
    NEW.property_code := public.generate_unique_property_code(NEW.broker_id, NEW.property_title);
  ELSE
    NEW.property_code := UPPER(TRIM(NEW.property_code));
  END IF;

  RETURN NEW;
END;
$$;

-- 6. Re-attach triggers
DROP TRIGGER IF EXISTS trg_set_broker_code ON public.brokers;
CREATE TRIGGER trg_set_broker_code
BEFORE INSERT OR UPDATE ON public.brokers
FOR EACH ROW
EXECUTE FUNCTION public.trg_broker_code_generator();

DROP TRIGGER IF EXISTS trg_set_property_code ON public.properties;
CREATE TRIGGER trg_set_property_code
BEFORE INSERT OR UPDATE ON public.properties
FOR EACH ROW
EXECUTE FUNCTION public.trg_property_code_generator();

-- 7. Backfill and regenerate all existing records in database
DO $$
DECLARE
  v_broker RECORD;
  v_property RECORD;
  v_user_name TEXT;
  v_new_broker_code TEXT;
  v_new_prop_code TEXT;
BEGIN
  -- Temporarily disable triggers during deterministic batch backfill
  ALTER TABLE public.brokers DISABLE TRIGGER trg_set_broker_code;
  ALTER TABLE public.properties DISABLE TRIGGER trg_set_property_code;

  -- Assign temporary uppercase placeholder codes to allow clean regeneration without unique collision
  UPDATE public.properties SET property_code = 'TMP_' || UPPER(substr(md5(id::text || clock_timestamp()::text), 1, 20));
  UPDATE public.brokers SET broker_code = 'TMP_' || UPPER(substr(md5(id::text || clock_timestamp()::text), 1, 20));

  -- Regenerate broker codes in deterministic order (by created_at ASC)
  FOR v_broker IN SELECT id, business_name, created_at FROM public.brokers ORDER BY created_at ASC NULLS LAST LOOP
    SELECT name INTO v_user_name FROM public.users WHERE broker_id = v_broker.id LIMIT 1;
    v_new_broker_code := public.generate_unique_broker_code(v_broker.business_name, v_user_name);

    UPDATE public.brokers
    SET broker_code = v_new_broker_code
    WHERE id = v_broker.id;
  END LOOP;

  -- Regenerate property codes per broker in deterministic order (by created_at ASC)
  FOR v_property IN SELECT id, broker_id, property_title, created_at FROM public.properties ORDER BY broker_id, created_at ASC NULLS LAST LOOP
    v_new_prop_code := public.generate_unique_property_code(v_property.broker_id, v_property.property_title);

    UPDATE public.properties
    SET property_code = v_new_prop_code
    WHERE id = v_property.id;
  END LOOP;

  -- Re-enable triggers
  ALTER TABLE public.brokers ENABLE TRIGGER trg_set_broker_code;
  ALTER TABLE public.properties ENABLE TRIGGER trg_set_property_code;
END;
$$;

-- 8. Ensure constraints remain enforced
ALTER TABLE public.brokers ALTER COLUMN broker_code SET NOT NULL;
ALTER TABLE public.properties ALTER COLUMN property_code SET NOT NULL;

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'brokers_broker_code_key') THEN
    ALTER TABLE public.brokers ADD CONSTRAINT brokers_broker_code_key UNIQUE (broker_code);
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'brokers_broker_code_uppercase_chk') THEN
    ALTER TABLE public.brokers ADD CONSTRAINT brokers_broker_code_uppercase_chk CHECK (broker_code = UPPER(broker_code));
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'properties_property_code_key') THEN
    ALTER TABLE public.properties ADD CONSTRAINT properties_property_code_key UNIQUE (property_code);
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'properties_property_code_uppercase_chk') THEN
    ALTER TABLE public.properties ADD CONSTRAINT properties_property_code_uppercase_chk CHECK (property_code = UPPER(property_code));
  END IF;
END;
$$;

-- 9. Grant permissions
GRANT EXECUTE ON FUNCTION public.generate_random_alphanumeric(INTEGER) TO anon, authenticated, service_role;
GRANT EXECUTE ON FUNCTION public.generate_unique_broker_code(TEXT, TEXT) TO anon, authenticated, service_role;
GRANT EXECUTE ON FUNCTION public.generate_unique_property_code(UUID, TEXT) TO anon, authenticated, service_role;
