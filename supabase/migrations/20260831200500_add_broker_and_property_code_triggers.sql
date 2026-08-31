-- Migration: 20260831200500_add_broker_and_property_code_triggers.sql
-- Description: Adds broker_code to public.brokers and property_code to public.properties
-- with automated trigger generation (3-6 char alphanumeric for brokers, BROKER_CODE-XYZ for properties),
-- backfilling existing rows, and applying UNIQUE and UPPERCASE constraints.

-- 1. Helper function: generate random uppercase alphanumeric string of given length
CREATE OR REPLACE FUNCTION public.generate_random_alphanumeric(p_length INTEGER)
RETURNS TEXT
LANGUAGE plpgsql
AS $$
DECLARE
  v_chars TEXT := 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789'; -- Excluding easily confused chars like 0, O, 1, I
  v_result TEXT := '';
  v_i INTEGER;
BEGIN
  IF p_length IS NULL OR p_length < 1 THEN
    p_length := 3;
  END IF;
  FOR v_i IN 1..p_length LOOP
    v_result := v_result || substr(v_chars, floor(random() * length(v_chars) + 1)::integer, 1);
  END LOOP;
  RETURN v_result;
END;
$$;

-- 2. Add columns if not already existing
ALTER TABLE public.brokers
ADD COLUMN IF NOT EXISTS broker_code TEXT;

ALTER TABLE public.properties
ADD COLUMN IF NOT EXISTS property_code TEXT;

-- 3. Stored function to generate unique broker code (3 to 6 chars, name-derived first, then random)
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
  v_candidate TEXT;
  v_name_to_use TEXT;
  v_cleaned_name TEXT;
  v_words TEXT[];
  v_initials TEXT := '';
  v_first_word TEXT := '';
  v_second_word TEXT := '';
  v_len INTEGER;
  v_attempt INTEGER;
  v_max_attempts_per_len CONSTANT INTEGER := 50;
  v_exists BOOLEAN;
  v_w TEXT;
BEGIN
  -- Determine base text (prefer user_name if provided, otherwise business_name)
  v_name_to_use := COALESCE(NULLIF(TRIM(p_user_name), ''), NULLIF(TRIM(p_business_name), ''));

  IF v_name_to_use IS NOT NULL THEN
    -- Extract words and initials
    v_words := regexp_split_to_array(UPPER(regexp_replace(v_name_to_use, '[^a-zA-Z0-9\s]', ' ', 'g')), '\s+');
    
    FOREACH v_w IN ARRAY v_words LOOP
      IF length(v_w) > 0 THEN
        IF length(v_first_word) = 0 THEN
          v_first_word := v_w;
        ELSIF length(v_second_word) = 0 THEN
          v_second_word := v_w;
        END IF;
        v_initials := v_initials || substr(v_w, 1, 1);
      END IF;
    END LOOP;
    
    v_cleaned_name := UPPER(regexp_replace(v_name_to_use, '[^a-zA-Z0-9]', '', 'g'));
  END IF;

  -- Iterate through target lengths: 3 -> 4 -> 5 -> 6
  FOR v_len IN 3..6 LOOP

    -- Strategy A: Name-based combinations
    IF length(v_initials) >= 2 THEN
      -- Try Initials + digits (e.g. for len 3: ZS1..ZS9; for len 4: ZS01..ZS99)
      IF v_len = 3 AND length(v_initials) = 2 THEN
        FOR v_attempt IN 1..9 LOOP
          v_candidate := v_initials || v_attempt::TEXT;
          SELECT EXISTS(SELECT 1 FROM public.brokers WHERE broker_code = v_candidate) INTO v_exists;
          IF NOT v_exists THEN
            RETURN v_candidate;
          END IF;
        END LOOP;
      ELSIF v_len = 3 AND length(v_initials) >= 3 THEN
        v_candidate := substr(v_initials, 1, 3);
        SELECT EXISTS(SELECT 1 FROM public.brokers WHERE broker_code = v_candidate) INTO v_exists;
        IF NOT v_exists THEN
          RETURN v_candidate;
        END IF;
      ELSIF v_len = 4 AND length(v_initials) = 2 THEN
        FOR v_attempt IN 10..99 LOOP
          v_candidate := v_initials || v_attempt::TEXT;
          SELECT EXISTS(SELECT 1 FROM public.brokers WHERE broker_code = v_candidate) INTO v_exists;
          IF NOT v_exists THEN
            RETURN v_candidate;
          END IF;
        END LOOP;
      END IF;

      -- Try Initials + letters from first/second word
      IF v_len = 3 AND length(v_first_word) >= 2 AND length(v_second_word) >= 1 THEN
        v_candidate := substr(v_first_word, 1, 2) || substr(v_second_word, 1, 1);
        SELECT EXISTS(SELECT 1 FROM public.brokers WHERE broker_code = v_candidate) INTO v_exists;
        IF NOT v_exists THEN
          RETURN v_candidate;
        END IF;
        
        v_candidate := substr(v_first_word, 1, 1) || substr(v_second_word, 1, 2);
        SELECT EXISTS(SELECT 1 FROM public.brokers WHERE broker_code = v_candidate) INTO v_exists;
        IF NOT v_exists THEN
          RETURN v_candidate;
        END IF;
      END IF;
    END IF;

    -- Strategy B: Substring from cleaned name
    IF length(v_cleaned_name) >= v_len THEN
      v_candidate := substr(v_cleaned_name, 1, v_len);
      SELECT EXISTS(SELECT 1 FROM public.brokers WHERE broker_code = v_candidate) INTO v_exists;
      IF NOT v_exists THEN
        RETURN v_candidate;
      END IF;
    END IF;

    -- Strategy C: Random alphanumeric of current length (3..6)
    FOR v_attempt IN 1..v_max_attempts_per_len LOOP
      v_candidate := public.generate_random_alphanumeric(v_len);
      SELECT EXISTS(SELECT 1 FROM public.brokers WHERE broker_code = v_candidate) INTO v_exists;
      IF NOT v_exists THEN
        RETURN v_candidate;
      END IF;
    END LOOP;

  END LOOP;

  -- Absolute fallback (timestamp hex)
  RETURN UPPER(substr(md5(random()::text || clock_timestamp()::text), 1, 6));
END;
$$;

-- 4. Stored function to generate unique property code (BROKER_CODE-SUFFIX)
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
  v_candidate TEXT;
  v_suffix TEXT;
  v_cleaned_title TEXT;
  v_words TEXT[];
  v_initials TEXT := '';
  v_w TEXT;
  v_attempt INTEGER;
  v_exists BOOLEAN;
BEGIN
  -- 1. Fetch broker code
  SELECT broker_code INTO v_broker_code
  FROM public.brokers
  WHERE id = p_broker_id;

  -- Fallback if broker code is somehow missing
  IF v_broker_code IS NULL OR TRIM(v_broker_code) = '' THEN
    v_broker_code := 'RB';
  END IF;

  -- 2. Clean property title
  IF p_property_title IS NOT NULL AND TRIM(p_property_title) != '' THEN
    v_words := regexp_split_to_array(UPPER(regexp_replace(p_property_title, '[^a-zA-Z0-9\s]', ' ', 'g')), '\s+');
    FOREACH v_w IN ARRAY v_words LOOP
      IF length(v_w) > 0 THEN
        v_initials := v_initials || substr(v_w, 1, 1);
      END IF;
    END LOOP;
    v_cleaned_title := UPPER(regexp_replace(p_property_title, '[^a-zA-Z0-9]', '', 'g'));
  END IF;

  -- Strategy A: 3-character prefix from title
  IF length(v_cleaned_title) >= 3 THEN
    v_suffix := substr(v_cleaned_title, 1, 3);
    v_candidate := v_broker_code || '-' || v_suffix;
    SELECT EXISTS(SELECT 1 FROM public.properties WHERE property_code = v_candidate) INTO v_exists;
    IF NOT v_exists THEN
      RETURN v_candidate;
    END IF;
  END IF;

  -- Strategy B: Initials + digit (e.g. SV1..SV9)
  IF length(v_initials) >= 2 THEN
    FOR v_attempt IN 1..9 LOOP
      v_suffix := substr(v_initials, 1, 2) || v_attempt::TEXT;
      v_candidate := v_broker_code || '-' || v_suffix;
      SELECT EXISTS(SELECT 1 FROM public.properties WHERE property_code = v_candidate) INTO v_exists;
      IF NOT v_exists THEN
        RETURN v_candidate;
      END IF;
    END LOOP;
  END IF;

  -- Strategy C: Random 3-character alphanumeric suffix
  FOR v_attempt IN 1..50 LOOP
    v_suffix := public.generate_random_alphanumeric(3);
    v_candidate := v_broker_code || '-' || v_suffix;
    SELECT EXISTS(SELECT 1 FROM public.properties WHERE property_code = v_candidate) INTO v_exists;
    IF NOT v_exists THEN
      RETURN v_candidate;
    END IF;
  END LOOP;

  -- Strategy D: Random 4-character alphanumeric suffix
  FOR v_attempt IN 1..50 LOOP
    v_suffix := public.generate_random_alphanumeric(4);
    v_candidate := v_broker_code || '-' || v_suffix;
    SELECT EXISTS(SELECT 1 FROM public.properties WHERE property_code = v_candidate) INTO v_exists;
    IF NOT v_exists THEN
      RETURN v_candidate;
    END IF;
  END LOOP;

  -- Fallback
  RETURN v_broker_code || '-' || UPPER(substr(md5(random()::text || clock_timestamp()::text), 1, 4));
END;
$$;

-- 5. Trigger functions (Generated once upon creation, strictly immutable on update)
CREATE OR REPLACE FUNCTION public.trg_broker_code_generator()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_user_name TEXT;
BEGIN
  -- If updating and code already exists, ensure it is strictly immutable and never modified or regenerated
  IF TG_OP = 'UPDATE' AND OLD.broker_code IS NOT NULL AND TRIM(OLD.broker_code) != '' THEN
    NEW.broker_code := OLD.broker_code;
    RETURN NEW;
  END IF;

  -- On INSERT (or if code is currently null/empty)
  IF NEW.broker_code IS NULL OR TRIM(NEW.broker_code) = '' THEN
    -- Try to find linked user name if existing
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
  -- If updating and code already exists, ensure it is strictly immutable and never modified or regenerated
  IF TG_OP = 'UPDATE' AND OLD.property_code IS NOT NULL AND TRIM(OLD.property_code) != '' THEN
    NEW.property_code := OLD.property_code;
    RETURN NEW;
  END IF;

  -- On INSERT (or if code is currently null/empty)
  IF NEW.property_code IS NULL OR TRIM(NEW.property_code) = '' THEN
    NEW.property_code := public.generate_unique_property_code(NEW.broker_id, NEW.property_title);
  ELSE
    NEW.property_code := UPPER(TRIM(NEW.property_code));
  END IF;

  RETURN NEW;
END;
$$;

-- 6. Attach triggers (Runs on INSERT and UPDATE)
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

-- 7. Backfill existing records
DO $$
DECLARE
  v_rec RECORD;
  v_user_name TEXT;
BEGIN
  -- Backfill brokers
  FOR v_rec IN SELECT id, business_name FROM public.brokers WHERE broker_code IS NULL OR TRIM(broker_code) = '' LOOP
    SELECT name INTO v_user_name FROM public.users WHERE broker_id = v_rec.id LIMIT 1;
    UPDATE public.brokers
    SET broker_code = public.generate_unique_broker_code(v_rec.business_name, v_user_name)
    WHERE id = v_rec.id;
  END LOOP;

  -- Backfill properties
  FOR v_rec IN SELECT id, broker_id, property_title FROM public.properties WHERE property_code IS NULL OR TRIM(property_code) = '' LOOP
    UPDATE public.properties
    SET property_code = public.generate_unique_property_code(v_rec.broker_id, v_rec.property_title)
    WHERE id = v_rec.id;
  END LOOP;
END;
$$;

-- 8. Apply NOT NULL, CHECK, and UNIQUE constraints
ALTER TABLE public.brokers
ALTER COLUMN broker_code SET NOT NULL;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint WHERE conname = 'brokers_broker_code_key'
  ) THEN
    ALTER TABLE public.brokers ADD CONSTRAINT brokers_broker_code_key UNIQUE (broker_code);
  END IF;
  
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint WHERE conname = 'brokers_broker_code_uppercase_chk'
  ) THEN
    ALTER TABLE public.brokers ADD CONSTRAINT brokers_broker_code_uppercase_chk CHECK (broker_code = UPPER(broker_code));
  END IF;
END;
$$;

ALTER TABLE public.properties
ALTER COLUMN property_code SET NOT NULL;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint WHERE conname = 'properties_property_code_key'
  ) THEN
    ALTER TABLE public.properties ADD CONSTRAINT properties_property_code_key UNIQUE (property_code);
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint WHERE conname = 'properties_property_code_uppercase_chk'
  ) THEN
    ALTER TABLE public.properties ADD CONSTRAINT properties_property_code_uppercase_chk CHECK (property_code = UPPER(property_code));
  END IF;
END;
$$;

-- 9. Grant function execution permissions
GRANT EXECUTE ON FUNCTION public.generate_random_alphanumeric(INTEGER) TO anon, authenticated, service_role;
GRANT EXECUTE ON FUNCTION public.generate_unique_broker_code(TEXT, TEXT) TO anon, authenticated, service_role;
GRANT EXECUTE ON FUNCTION public.generate_unique_property_code(UUID, TEXT) TO anon, authenticated, service_role;
