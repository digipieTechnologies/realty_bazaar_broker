-- =========================================================
-- COMPLETE RECONSTRUCTED SCHEMA & MIGRATIONS FOR NEW PROJECT
-- Generated at: 2026-08-31T12:44:46.798Z
-- =========================================================

-- >>> Migration: 20260724175500_add_user_phone_columns_and_updated_at_triggers.sql <<<
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


-- >>> Migration: 20260725143500_add_admin_approval_for_video_requests.sql <<<
-- Migration: Add intermediate admin approval flow for broker video shoot requests.

-- 1. Add auto_approve_video_requests column to brokers table
ALTER TABLE public.brokers ADD COLUMN IF NOT EXISTS auto_approve_video_requests BOOLEAN DEFAULT false NOT NULL;

-- 2. Add admin_approval_status column to video_requests table (pending, approved, rejected)
ALTER TABLE public.video_requests ADD COLUMN IF NOT EXISTS admin_approval_status VARCHAR(20) DEFAULT 'pending' NOT NULL;

-- 3. Create or replace the auto-approval trigger function
CREATE OR REPLACE FUNCTION public.trg_fn_video_requests_auto_approve()
RETURNS TRIGGER AS $$
DECLARE
  v_auto_approve BOOLEAN;
BEGIN
  -- Fetch the auto-approval flag for the requesting broker
  SELECT auto_approve_video_requests INTO v_auto_approve
  FROM public.brokers
  WHERE id = NEW.broker_id;

  -- Set admin approval status depending on the broker's auto-approval flag
  IF v_auto_approve IS TRUE THEN
    NEW.admin_approval_status := 'approved';
  ELSE
    NEW.admin_approval_status := 'pending';
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 4. Attach the BEFORE INSERT trigger to the video_requests table
DROP TRIGGER IF EXISTS trg_video_requests_auto_approve ON public.video_requests;
CREATE TRIGGER trg_video_requests_auto_approve
  BEFORE INSERT ON public.video_requests
  FOR EACH ROW
  EXECUTE FUNCTION public.trg_fn_video_requests_auto_approve();


-- >>> Migration: 20260727101500_convert_video_request_statuses_to_enums.sql <<<
-- Migration: Convert status and admin_approval_status columns in public.video_requests to custom ENUM types

-- 1. Create the custom ENUM types if they do not already exist
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'video_request_status') THEN
    CREATE TYPE public.video_request_status AS ENUM ('pending', 'assigned', 'in_progress', 'completed', 'cancelled');
  END IF;
  
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'video_request_approval_status') THEN
    CREATE TYPE public.video_request_approval_status AS ENUM ('pending', 'approved', 'rejected');
  END IF;
END$$;

-- 2. Drop the current column defaults to allow type alteration
ALTER TABLE public.video_requests ALTER COLUMN status DROP DEFAULT;
ALTER TABLE public.video_requests ALTER COLUMN admin_approval_status DROP DEFAULT;

-- 3. Convert the columns to the new ENUM types, casting the existing VARCHAR values
ALTER TABLE public.video_requests 
  ALTER COLUMN status TYPE public.video_request_status 
    USING status::public.video_request_status,
  ALTER COLUMN admin_approval_status TYPE public.video_request_approval_status 
    USING admin_approval_status::public.video_request_approval_status;

-- 4. Re-apply the defaults using the ENUM types
ALTER TABLE public.video_requests ALTER COLUMN status SET DEFAULT 'pending'::public.video_request_status;
ALTER TABLE public.video_requests ALTER COLUMN admin_approval_status SET DEFAULT 'pending'::public.video_request_approval_status;

-- 5. Re-create the auto-approval trigger function to use the correct type assignments
CREATE OR REPLACE FUNCTION public.trg_fn_video_requests_auto_approve()
RETURNS TRIGGER AS $$
DECLARE
  v_auto_approve BOOLEAN;
BEGIN
  -- Fetch the auto-approval flag for the requesting broker
  SELECT auto_approve_video_requests INTO v_auto_approve
  FROM public.brokers
  WHERE id = NEW.broker_id;

  -- Set admin approval status depending on the broker's auto-approval flag
  IF v_auto_approve IS TRUE THEN
    NEW.admin_approval_status := 'approved'::public.video_request_approval_status;
  ELSE
    NEW.admin_approval_status := 'pending'::public.video_request_approval_status;
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;


-- >>> Migration: 20260727105700_create_fetch_properties_rpc.sql <<<
-- Migration: Create RPC function for fetching properties with pagination, search, and nested address objects.

CREATE OR REPLACE FUNCTION public.fetch_properties(
  p_broker_id UUID,
  p_page INT DEFAULT 1,
  p_limit INT DEFAULT 10,
  p_search_query TEXT DEFAULT ''
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_offset INT;
  v_total_items INT;
  v_total_pages INT;
  v_has_more BOOLEAN;
  v_properties_json JSONB;
BEGIN
  -- Calculate offset for pagination
  v_offset := (p_page - 1) * p_limit;

  -- 1. Calculate total items matching the filter (excluding deleted items)
  SELECT COUNT(*)
  INTO v_total_items
  FROM public.properties p
  LEFT JOIN public.addresses a ON p.address_id = a.id
  WHERE p.broker_id = p_broker_id
    AND p.is_deleted = false
    AND (
      p_search_query = '' OR
      p.property_title ILIKE '%' || p_search_query || '%' OR
      p.property_description ILIKE '%' || p_search_query || '%' OR
      (a.id IS NOT NULL AND (
         a.full_address ILIKE '%' || p_search_query || '%' OR
         a.city ILIKE '%' || p_search_query || '%' OR
         a.state ILIKE '%' || p_search_query || '%'
      ))
    );

  -- Calculate pagination details
  IF v_total_items = 0 THEN
    v_total_pages := 1;
    v_has_more := false;
  ELSE
    v_total_pages := CEIL(v_total_items::NUMERIC / p_limit)::INT;
    v_has_more := (p_page * p_limit) < v_total_items;
  END IF;

  -- 2. Fetch the properties with pagination, ordering by latest first, and nested address serialization
  SELECT COALESCE(jsonb_agg(
    to_jsonb(p_data) || 
    jsonb_build_object(
      'address', 
      CASE 
        WHEN p_data.address_id IS NOT NULL THEN to_jsonb(a_data)
        ELSE NULL
      END
    )
  ), '[]'::jsonb)
  INTO v_properties_json
  FROM (
    SELECT p.*
    FROM public.properties p
    LEFT JOIN public.addresses a ON p.address_id = a.id
    WHERE p.broker_id = p_broker_id
      AND p.is_deleted = false
      AND (
        p_search_query = '' OR
        p.property_title ILIKE '%' || p_search_query || '%' OR
        p.property_description ILIKE '%' || p_search_query || '%' OR
        (a.id IS NOT NULL AND (
           a.full_address ILIKE '%' || p_search_query || '%' OR
           a.city ILIKE '%' || p_search_query || '%' OR
           a.state ILIKE '%' || p_search_query || '%'
        ))
      )
    ORDER BY p.created_at DESC
    LIMIT p_limit
    OFFSET v_offset
  ) p_data
  LEFT JOIN public.addresses a_data ON p_data.address_id = a_data.id;

  -- Return the final combined JSON structure
  RETURN jsonb_build_object(
    'success', true,
    'data', v_properties_json,
    'pagination', jsonb_build_object(
      'total_items', v_total_items,
      'total_pages', v_total_pages,
      'has_more', v_has_more
    )
  );
END;
$$;


-- >>> Migration: 20260727111500_create_publish_property_rpc.sql <<<
-- Migration: Create RPC function for publishing (creating/editing) a property and its nested address details.

CREATE OR REPLACE FUNCTION public.publish_property(
  p_property JSONB,
  p_is_edit BOOLEAN
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_property_id UUID;
  v_address_id UUID;
  v_address_data JSONB;
  v_property_data JSONB;
  v_returned_property JSONB;
  v_broker_id UUID;
BEGIN
  -- Extract address data from the property JSON
  v_address_data := p_property->'address';

  -- Extract property data (excluding keys we don't want to overwrite directly during insert/update)
  v_property_data := p_property - 'address' - 'id' - 'created_at' - 'updated_at';

  IF p_is_edit IS TRUE THEN
    -- 1. Edit existing property logic
    v_property_id := (p_property->>'id')::UUID;
    IF v_property_id IS NULL THEN
      RETURN jsonb_build_object(
        'success', false,
        'error', 'Missing property ID for update'
      );
    END IF;

    -- Update nested address if provided
    IF v_address_data IS NOT NULL AND v_address_data <> 'null'::jsonb THEN
      -- Resolve address ID to update
      v_address_id := COALESCE(
        (p_property->>'address_id')::UUID, 
        (v_address_data->>'id')::UUID
      );

      IF v_address_id IS NOT NULL THEN
        UPDATE public.addresses
        SET
          full_address = COALESCE(v_address_data->>'full_address', full_address),
          latitude = (v_address_data->>'latitude')::NUMERIC,
          longitude = (v_address_data->>'longitude')::NUMERIC,
          city = COALESCE(v_address_data->>'city', city),
          pincode = COALESCE(v_address_data->>'pincode', pincode),
          state = COALESCE(v_address_data->>'state', state),
          country = COALESCE(v_address_data->>'country', country),
          landmark = COALESCE(v_address_data->>'landmark', landmark),
          entity_id = v_property_id,
          entity_type = 'property',
          updated_at = NOW()
        WHERE id = v_address_id;
      END IF;
    END IF;

    -- Update property details
    UPDATE public.properties
    SET
      broker_id = COALESCE((v_property_data->>'broker_id')::UUID, broker_id),
      address_id = COALESCE((v_property_data->>'address_id')::UUID, address_id),
      property_title = COALESCE(v_property_data->>'property_title', property_title),
      property_description = COALESCE(v_property_data->>'property_description', property_description),
      property_type = COALESCE((v_property_data->>'property_type')::public.property_type_enum, property_type),
      listing_type = COALESCE((v_property_data->>'listing_type')::public.listing_type_enum, listing_type),
      price = COALESCE((v_property_data->>'price')::NUMERIC, price),
      area = COALESCE((v_property_data->>'area')::NUMERIC, area),
      area_unit = COALESCE((v_property_data->>'area_unit')::public.area_unit_enum, area_unit),
      bedrooms = COALESCE((v_property_data->>'bedrooms')::INTEGER, bedrooms),
      bathrooms = COALESCE((v_property_data->>'bathrooms')::INTEGER, bathrooms),
      balconies = COALESCE((v_property_data->>'balconies')::INTEGER, balconies),
      parking = COALESCE((v_property_data->>'parking')::INTEGER, parking),
      floor_number = (v_property_data->>'floor_number')::INTEGER,
      total_floors = (v_property_data->>'total_floors')::INTEGER,
      furnishing_status = COALESCE((v_property_data->>'furnishing_status')::public.furnishing_status_enum, furnishing_status),
      property_status = COALESCE((v_property_data->>'property_status')::public.property_status_enum, property_status),
      construction_status = COALESCE((v_property_data->>'construction_status')::public.construction_status_enum, construction_status),
      facing = (v_property_data->>'facing')::public.facing_direction_enum,
      amenities = COALESCE(v_property_data->'amenities', amenities),
      medias = COALESCE(v_property_data->'medias', medias),
      is_active = COALESCE((v_property_data->>'is_active')::BOOLEAN, is_active),
      is_deleted = COALESCE((v_property_data->>'is_deleted')::BOOLEAN, is_deleted),
      updated_at = NOW()
    WHERE id = v_property_id;

  ELSE
    -- 2. Create new property logic
    -- Insert property with address_id = NULL first to get property UUID
    INSERT INTO public.properties (
      broker_id,
      address_id,
      property_title,
      property_description,
      property_type,
      listing_type,
      price,
      area,
      area_unit,
      bedrooms,
      bathrooms,
      balconies,
      parking,
      floor_number,
      total_floors,
      furnishing_status,
      property_status,
      construction_status,
      facing,
      amenities,
      medias,
      is_active
    ) VALUES (
      (v_property_data->>'broker_id')::UUID,
      NULL,
      v_property_data->>'property_title',
      v_property_data->>'property_description',
      COALESCE((v_property_data->>'property_type')::public.property_type_enum, 'apartment'::public.property_type_enum),
      COALESCE((v_property_data->>'listing_type')::public.listing_type_enum, 'sale'::public.listing_type_enum),
      (v_property_data->>'price')::NUMERIC,
      (v_property_data->>'area')::NUMERIC,
      COALESCE((v_property_data->>'area_unit')::public.area_unit_enum, 'sqft'::public.area_unit_enum),
      COALESCE((v_property_data->>'bedrooms')::INTEGER, 0),
      COALESCE((v_property_data->>'bathrooms')::INTEGER, 0),
      COALESCE((v_property_data->>'balconies')::INTEGER, 0),
      COALESCE((v_property_data->>'parking')::INTEGER, 0),
      (v_property_data->>'floor_number')::INTEGER,
      (v_property_data->>'total_floors')::INTEGER,
      COALESCE((v_property_data->>'furnishing_status')::public.furnishing_status_enum, 'unfurnished'::public.furnishing_status_enum),
      COALESCE((v_property_data->>'property_status')::public.property_status_enum, 'available'::public.property_status_enum),
      COALESCE((v_property_data->>'construction_status')::public.construction_status_enum, 'ready_to_move'::public.construction_status_enum),
      (v_property_data->>'facing')::public.facing_direction_enum,
      COALESCE(v_property_data->'amenities', '[]'::jsonb),
      COALESCE(v_property_data->'medias', '[]'::jsonb),
      COALESCE((v_property_data->>'is_active')::BOOLEAN, TRUE)
    ) RETURNING id INTO v_property_id;

    -- Insert address referencing the new property ID
    IF v_address_data IS NOT NULL AND v_address_data <> 'null'::jsonb THEN
      INSERT INTO public.addresses (
        full_address,
        latitude,
        longitude,
        city,
        pincode,
        state,
        country,
        landmark,
        entity_id,
        entity_type
      ) VALUES (
        COALESCE(v_address_data->>'full_address', ''),
        (v_address_data->>'latitude')::NUMERIC,
        (v_address_data->>'longitude')::NUMERIC,
        v_address_data->>'city',
        v_address_data->>'pincode',
        v_address_data->>'state',
        v_address_data->>'country',
        v_address_data->>'landmark',
        v_property_id,
        'property'
      ) RETURNING id INTO v_address_id;

      -- Update the properties record to reference the newly created address
      UPDATE public.properties
      SET address_id = v_address_id
      WHERE id = v_property_id;
    END IF;
  END IF;

  -- 3. Resolve broker_id and update broker setup_details if properties_imported is not true
  v_broker_id := COALESCE(
    (v_property_data->>'broker_id')::UUID,
    (SELECT broker_id FROM public.properties WHERE id = v_property_id)
  );

  IF v_broker_id IS NOT NULL THEN
    UPDATE public.brokers
    SET setup_details = jsonb_set(
      COALESCE(setup_details, '{}'::jsonb),
      '{properties_imported}',
      'true'::jsonb
    )
    WHERE id = v_broker_id
      AND (setup_details IS NULL OR (setup_details->>'properties_imported')::BOOLEAN IS NOT TRUE);
  END IF;

  -- Select and serialize the finalized property row to return to the client
  SELECT to_jsonb(p) INTO v_returned_property
  FROM public.properties p
  WHERE p.id = v_property_id;

  RETURN jsonb_build_object(
    'success', true,
    'property', v_returned_property
  );

EXCEPTION WHEN OTHERS THEN
  RETURN jsonb_build_object(
    'success', false,
    'error', SQLERRM
  );
END;
$$;


-- >>> Migration: 20260727115500_add_video_requests_update_policy.sql <<<
-- Migration: Add update policy for video_requests table to allow updating status (e.g. cancelling requests).

DROP POLICY IF EXISTS "Allow public updates" ON public.video_requests;
CREATE POLICY "Allow public updates" ON public.video_requests
  FOR UPDATE TO public USING (true) WITH CHECK (true);


-- >>> Migration: 20260727144000_add_completed_at_to_video_requests.sql <<<
-- Migration: Add completed_at column and trigger to video_requests table

ALTER TABLE public.video_requests 
ADD COLUMN completed_at TIMESTAMP WITH TIME ZONE NULL;

-- Trigger function to automatically set completed_at when status transitions to 'completed'
CREATE OR REPLACE FUNCTION public.set_video_request_completed_at()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.status = 'completed' AND OLD.status IS DISTINCT FROM 'completed' THEN
    NEW.completed_at = timezone('utc'::text, now());
  ELSIF NEW.status IS DISTINCT FROM 'completed' THEN
    NEW.completed_at = NULL;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_set_video_request_completed_at ON public.video_requests;
CREATE TRIGGER trg_set_video_request_completed_at
  BEFORE UPDATE ON public.video_requests
  FOR EACH ROW
  EXECUTE FUNCTION public.set_video_request_completed_at();


-- >>> Migration: 20260727153000_create_marketing_video_requests_rpcs.sql <<<
-- Migration: Create RPC functions for video request dashboard and pagination in the marketing application

-- 1. RPC for fetching summarized request counts
CREATE OR REPLACE FUNCTION public.fetch_video_request_counts()
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_total INT;
  v_pending INT;
  v_in_progress INT;
  v_completed INT;
BEGIN
  -- Count only requests that have been admin-approved
  SELECT COUNT(*) INTO v_total
  FROM public.video_requests
  WHERE admin_approval_status = 'approved'::public.video_request_approval_status
    AND status != 'cancelled'::public.video_request_status;

  SELECT COUNT(*) INTO v_pending
  FROM public.video_requests
  WHERE admin_approval_status = 'approved'::public.video_request_approval_status
    AND status = 'pending'::public.video_request_status;

  SELECT COUNT(*) INTO v_in_progress
  FROM public.video_requests
  WHERE admin_approval_status = 'approved'::public.video_request_approval_status
    AND status IN ('assigned'::public.video_request_status, 'in_progress'::public.video_request_status);

  SELECT COUNT(*) INTO v_completed
  FROM public.video_requests
  WHERE admin_approval_status = 'approved'::public.video_request_approval_status
    AND status = 'completed'::public.video_request_status;

  RETURN jsonb_build_object(
    'total', v_total,
    'pending', v_pending,
    'in_progress', v_in_progress,
    'completed', v_completed
  );
END;
$$;

-- 2. RPC for fetching nested paginated video requests with search
CREATE OR REPLACE FUNCTION public.fetch_marketing_video_requests(
  p_page INT DEFAULT 1,
  p_limit INT DEFAULT 10,
  p_search_query TEXT DEFAULT ''
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_offset INT;
  v_total_items INT;
  v_total_pages INT;
  v_has_more BOOLEAN;
  v_requests_json JSONB;
BEGIN
  -- Calculate offset
  v_offset := (p_page - 1) * p_limit;

  -- Count matching rows
  SELECT COUNT(*)
  INTO v_total_items
  FROM public.video_requests vr
  JOIN public.properties p ON vr.property_id = p.id
  JOIN public.brokers b ON vr.broker_id = b.id
  LEFT JOIN public.addresses a ON p.address_id = a.id
  WHERE vr.admin_approval_status = 'approved'::public.video_request_approval_status
    AND vr.status != 'cancelled'::public.video_request_status
    AND (
      p_search_query = '' OR
      p.property_title ILIKE '%' || p_search_query || '%' OR
      b.business_name ILIKE '%' || p_search_query || '%' OR
      vr.notes ILIKE '%' || p_search_query || '%' OR
      (a.id IS NOT NULL AND (
         a.full_address ILIKE '%' || p_search_query || '%' OR
         a.city ILIKE '%' || p_search_query || '%' OR
         a.state ILIKE '%' || p_search_query || '%'
      ))
    );

  -- Calculate pagination details
  IF v_total_items = 0 THEN
    v_total_pages := 1;
    v_has_more := false;
  ELSE
    v_total_pages := CEIL(v_total_items::NUMERIC / p_limit)::INT;
    v_has_more := (p_page * p_limit) < v_total_items;
  END IF;

  -- Aggregate JSON results with nested structures (property + address, broker + address)
  SELECT COALESCE(jsonb_agg(
    to_jsonb(vr_data) ||
    jsonb_build_object(
      'property', 
      to_jsonb(p_data) || jsonb_build_object(
        'address',
        CASE 
          WHEN p_data.address_id IS NOT NULL THEN to_jsonb(pa_data)
          ELSE NULL
        END
      ),
      'broker',
      to_jsonb(b_data) || jsonb_build_object(
        'address',
        CASE 
          WHEN b_data.address_id IS NOT NULL THEN to_jsonb(ba_data)
          ELSE NULL
        END
      )
    )
  ), '[]'::jsonb)
  INTO v_requests_json
  FROM (
    SELECT vr.*
    FROM public.video_requests vr
    JOIN public.properties p ON vr.property_id = p.id
    JOIN public.brokers b ON vr.broker_id = b.id
    LEFT JOIN public.addresses a ON p.address_id = a.id
    WHERE vr.admin_approval_status = 'approved'::public.video_request_approval_status
      AND vr.status != 'cancelled'::public.video_request_status
      AND (
        p_search_query = '' OR
        p.property_title ILIKE '%' || p_search_query || '%' OR
        b.business_name ILIKE '%' || p_search_query || '%' OR
        vr.notes ILIKE '%' || p_search_query || '%' OR
        (a.id IS NOT NULL AND (
           a.full_address ILIKE '%' || p_search_query || '%' OR
           a.city ILIKE '%' || p_search_query || '%' OR
           a.state ILIKE '%' || p_search_query || '%'
        ))
      )
    ORDER BY vr.created_at DESC
    LIMIT p_limit
    OFFSET v_offset
  ) vr_data
  JOIN public.properties p_data ON vr_data.property_id = p_data.id
  JOIN public.brokers b_data ON vr_data.broker_id = b_data.id
  LEFT JOIN public.addresses pa_data ON p_data.address_id = pa_data.id
  LEFT JOIN public.addresses ba_data ON b_data.address_id = ba_data.id;

  RETURN jsonb_build_object(
    'success', true,
    'data', v_requests_json,
    'pagination', jsonb_build_object(
      'total_items', v_total_items,
      'total_pages', v_total_pages,
      'has_more', v_has_more
    )
  );
END;
$$;


-- >>> Migration: 20260727160200_enable_video_requests_realtime.sql <<<
-- Migration: Enable Realtime postgres change notifications for the video_requests table

ALTER PUBLICATION supabase_realtime ADD TABLE public.video_requests;


-- >>> Migration: 20260727170000_create_update_property_media_rpc.sql <<<
-- Migration: Create public.update_property_media RPC function
-- Purpose: Atomically update property media and complete the video request in a single transaction.

CREATE OR REPLACE FUNCTION public.update_property_media(
  p_property_id UUID,
  p_medias JSONB,
  p_request_id UUID
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  -- 1. Update the property media column
  UPDATE public.properties
  SET
    medias = p_medias,
    updated_at = NOW()
  WHERE id = p_property_id;

  -- 2. Update the video request status to completed
  UPDATE public.video_requests
  SET
    status = 'completed',
    completed_at = NOW(),
    updated_at = NOW()
  WHERE id = p_request_id;

  RETURN jsonb_build_object(
    'success', true,
    'message', 'Property media updated and request completed successfully'
  );
EXCEPTION WHEN OTHERS THEN
  RETURN jsonb_build_object(
    'success', false,
    'error', SQLERRM
  );
END;
$$;


-- >>> Migration: 20260728103000_consolidate_video_requests_rpcs.sql <<<
-- Migration: Consolidate Video Request fetching and counting RPC functions for both Marketing and Broker applications.

-- Drop old marketing-specific and single-purpose RPC functions to avoid duplication
DROP FUNCTION IF EXISTS public.fetch_marketing_video_requests(int, int, text);
DROP FUNCTION IF EXISTS public.fetch_video_request_counts();
DROP FUNCTION IF EXISTS public.fetch_video_requests(uuid, int, int, text);
DROP FUNCTION IF EXISTS public.fetch_video_request_counts(uuid);
DROP FUNCTION IF EXISTS public.fetch_video_requests(uuid, int, int, text, boolean);
DROP FUNCTION IF EXISTS public.fetch_video_request_counts(uuid, boolean);

-- 1. Create a unified fetch_video_requests function
CREATE OR REPLACE FUNCTION public.fetch_video_requests(
  p_broker_id UUID DEFAULT NULL,
  p_page INT DEFAULT 1,
  p_limit INT DEFAULT 10,
  p_search_query TEXT DEFAULT '',
  p_admin_approved_status public.video_request_approval_status DEFAULT NULL,
  p_status public.video_request_status DEFAULT NULL
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_offset INT;
  v_total_items INT;
  v_total_pages INT;
  v_has_more BOOLEAN;
  v_requests_json JSONB;
BEGIN
  -- Calculate offset for pagination
  v_offset := (p_page - 1) * p_limit;

  -- 1. Calculate total items matching the filter
  SELECT COUNT(*)
  INTO v_total_items
  FROM public.video_requests vr
  JOIN public.properties p ON vr.property_id = p.id
  JOIN public.brokers b ON vr.broker_id = b.id
  LEFT JOIN public.addresses a ON p.address_id = a.id
  WHERE (p_broker_id IS NULL OR vr.broker_id = p_broker_id)
    AND (p_admin_approved_status IS NULL OR vr.admin_approval_status = p_admin_approved_status)
    AND (p_status IS NULL OR vr.status = p_status)
    AND (
      p_search_query = '' OR
      p.property_title ILIKE '%' || p_search_query || '%' OR
      b.business_name ILIKE '%' || p_search_query || '%' OR
      vr.notes ILIKE '%' || p_search_query || '%' OR
      (a.id IS NOT NULL AND (
         a.full_address ILIKE '%' || p_search_query || '%' OR
         a.city ILIKE '%' || p_search_query || '%' OR
         a.state ILIKE '%' || p_search_query || '%'
      ))
    );

  -- Calculate pagination details
  IF v_total_items = 0 THEN
    v_total_pages := 1;
    v_has_more := false;
  ELSE
    v_total_pages := CEIL(v_total_items::NUMERIC / p_limit)::INT;
    v_has_more := (p_page * p_limit) < v_total_items;
  END IF;

  -- 2. Fetch the video requests with pagination, ordering by latest first, and nested serialization
  SELECT COALESCE(jsonb_agg(
    to_jsonb(vr_data) ||
    jsonb_build_object(
      'property', 
      to_jsonb(p_data) || jsonb_build_object(
        'address',
        CASE 
          WHEN p_data.address_id IS NOT NULL THEN to_jsonb(pa_data)
          ELSE NULL
        END
      ),
      'broker',
      to_jsonb(b_data) || jsonb_build_object(
        'address',
        CASE 
          WHEN b_data.address_id IS NOT NULL THEN to_jsonb(ba_data)
          ELSE NULL
        END
      )
    )
  ), '[]'::jsonb)
  INTO v_requests_json
  FROM (
    SELECT vr.*
    FROM public.video_requests vr
    JOIN public.properties p ON vr.property_id = p.id
    JOIN public.brokers b ON vr.broker_id = b.id
    LEFT JOIN public.addresses a ON p.address_id = a.id
    WHERE (p_broker_id IS NULL OR vr.broker_id = p_broker_id)
      AND (p_admin_approved_status IS NULL OR vr.admin_approval_status = p_admin_approved_status)
      AND (p_status IS NULL OR vr.status = p_status)
      AND (
        p_search_query = '' OR
        p.property_title ILIKE '%' || p_search_query || '%' OR
        b.business_name ILIKE '%' || p_search_query || '%' OR
        vr.notes ILIKE '%' || p_search_query || '%' OR
        (a.id IS NOT NULL AND (
           a.full_address ILIKE '%' || p_search_query || '%' OR
           a.city ILIKE '%' || p_search_query || '%' OR
           a.state ILIKE '%' || p_search_query || '%'
        ))
      )
    ORDER BY vr.created_at DESC
    LIMIT p_limit
    OFFSET v_offset
  ) vr_data
  JOIN public.properties p_data ON vr_data.property_id = p_data.id
  JOIN public.brokers b_data ON vr_data.broker_id = b_data.id
  LEFT JOIN public.addresses pa_data ON p_data.address_id = pa_data.id
  LEFT JOIN public.addresses ba_data ON b_data.address_id = ba_data.id;

  -- Return the final combined JSON structure
  RETURN jsonb_build_object(
    'success', true,
    'data', v_requests_json,
    'pagination', jsonb_build_object(
      'total_items', v_total_items,
      'total_pages', v_total_pages,
      'has_more', v_has_more
    )
  );
END;
$$;


-- 2. Create a unified fetch_video_request_counts function
CREATE OR REPLACE FUNCTION public.fetch_video_request_counts(
  p_broker_id UUID DEFAULT NULL,
  p_admin_approved_status public.video_request_approval_status DEFAULT NULL,
  p_status public.video_request_status DEFAULT NULL
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_total INT;
  v_pending INT;
  v_in_progress INT;
  v_completed INT;
BEGIN
  -- Count total requests matching the filters (excluding cancelled from total count by default)
  SELECT COUNT(*) INTO v_total
  FROM public.video_requests
  WHERE (p_broker_id IS NULL OR broker_id = p_broker_id)
    AND (p_admin_approved_status IS NULL OR admin_approval_status = p_admin_approved_status)
    AND (p_status IS NULL OR status = p_status)
    AND status != 'cancelled'::public.video_request_status;

  SELECT COUNT(*) INTO v_pending
  FROM public.video_requests
  WHERE (p_broker_id IS NULL OR broker_id = p_broker_id)
    AND (p_admin_approved_status IS NULL OR admin_approval_status = p_admin_approved_status)
    AND (p_status IS NULL OR status = p_status)
    AND status = 'pending'::public.video_request_status;

  SELECT COUNT(*) INTO v_in_progress
  FROM public.video_requests
  WHERE (p_broker_id IS NULL OR broker_id = p_broker_id)
    AND (p_admin_approved_status IS NULL OR admin_approval_status = p_admin_approved_status)
    AND (p_status IS NULL OR status = p_status)
    AND status IN ('assigned'::public.video_request_status, 'in_progress'::public.video_request_status);

  SELECT COUNT(*) INTO v_completed
  FROM public.video_requests
  WHERE (p_broker_id IS NULL OR broker_id = p_broker_id)
    AND (p_admin_approved_status IS NULL OR admin_approval_status = p_admin_approved_status)
    AND (p_status IS NULL OR status = p_status)
    AND status = 'completed'::public.video_request_status;

  RETURN jsonb_build_object(
    'total', v_total,
    'pending', v_pending,
    'in_progress', v_in_progress,
    'completed', v_completed
  );
END;
$$;


-- >>> Migration: 20260728104500_update_video_request_total_count_rpc.sql <<<
-- Migration: Update fetch_video_request_counts to include cancelled requests in total count and return a separate cancelled count.

CREATE OR REPLACE FUNCTION public.fetch_video_request_counts(
  p_broker_id UUID DEFAULT NULL,
  p_admin_approved_status public.video_request_approval_status DEFAULT NULL,
  p_status public.video_request_status DEFAULT NULL
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_total INT;
  v_pending INT;
  v_in_progress INT;
  v_completed INT;
  v_cancelled INT;
BEGIN
  -- Total count includes all matching requests (including cancelled)
  SELECT COUNT(*) INTO v_total
  FROM public.video_requests
  WHERE (p_broker_id IS NULL OR broker_id = p_broker_id)
    AND (p_admin_approved_status IS NULL OR admin_approval_status = p_admin_approved_status)
    AND (p_status IS NULL OR status = p_status);

  -- Pending count
  SELECT COUNT(*) INTO v_pending
  FROM public.video_requests
  WHERE (p_broker_id IS NULL OR broker_id = p_broker_id)
    AND (p_admin_approved_status IS NULL OR admin_approval_status = p_admin_approved_status)
    AND (p_status IS NULL OR status = p_status)
    AND status = 'pending'::public.video_request_status;

  -- In-progress count
  SELECT COUNT(*) INTO v_in_progress
  FROM public.video_requests
  WHERE (p_broker_id IS NULL OR broker_id = p_broker_id)
    AND (p_admin_approved_status IS NULL OR admin_approval_status = p_admin_approved_status)
    AND (p_status IS NULL OR status = p_status)
    AND status IN ('assigned'::public.video_request_status, 'in_progress'::public.video_request_status);

  -- Completed count
  SELECT COUNT(*) INTO v_completed
  FROM public.video_requests
  WHERE (p_broker_id IS NULL OR broker_id = p_broker_id)
    AND (p_admin_approved_status IS NULL OR admin_approval_status = p_admin_approved_status)
    AND (p_status IS NULL OR status = p_status)
    AND status = 'completed'::public.video_request_status;

  -- Cancelled count
  SELECT COUNT(*) INTO v_cancelled
  FROM public.video_requests
  WHERE (p_broker_id IS NULL OR broker_id = p_broker_id)
    AND (p_admin_approved_status IS NULL OR admin_approval_status = p_admin_approved_status)
    AND (p_status IS NULL OR status = p_status)
    AND status = 'cancelled'::public.video_request_status;

  RETURN jsonb_build_object(
    'total', v_total,
    'pending', v_pending,
    'in_progress', v_in_progress,
    'completed', v_completed,
    'cancelled', v_cancelled
  );
END;
$$;


-- >>> Migration: 20260728110000_update_fetch_video_requests_status_list.sql <<<
-- Migration: Update fetch_video_requests RPC to support multiple status filter array.

CREATE OR REPLACE FUNCTION public.fetch_video_requests(
  p_broker_id UUID DEFAULT NULL,
  p_page INT DEFAULT 1,
  p_limit INT DEFAULT 10,
  p_search_query TEXT DEFAULT '',
  p_admin_approved_status public.video_request_approval_status DEFAULT NULL,
  p_status public.video_request_status DEFAULT NULL,
  p_statuses TEXT[] DEFAULT NULL
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_offset INT;
  v_total_items INT;
  v_total_pages INT;
  v_has_more BOOLEAN;
  v_requests_json JSONB;
BEGIN
  -- Calculate offset for pagination
  v_offset := (p_page - 1) * p_limit;

  -- 1. Calculate total items matching the filter
  SELECT COUNT(*)
  INTO v_total_items
  FROM public.video_requests vr
  JOIN public.properties p ON vr.property_id = p.id
  JOIN public.brokers b ON vr.broker_id = b.id
  LEFT JOIN public.addresses a ON p.address_id = a.id
  WHERE (p_broker_id IS NULL OR vr.broker_id = p_broker_id)
    AND (p_admin_approved_status IS NULL OR vr.admin_approval_status = p_admin_approved_status)
    AND (p_status IS NULL OR vr.status = p_status)
    AND (p_statuses IS NULL OR array_length(p_statuses, 1) IS NULL OR vr.status::text = ANY(p_statuses))
    AND (
      p_search_query = '' OR
      p.property_title ILIKE '%' || p_search_query || '%' OR
      b.business_name ILIKE '%' || p_search_query || '%' OR
      vr.notes ILIKE '%' || p_search_query || '%' OR
      (a.id IS NOT NULL AND (
         a.full_address ILIKE '%' || p_search_query || '%' OR
         a.city ILIKE '%' || p_search_query || '%' OR
         a.state ILIKE '%' || p_search_query || '%'
      ))
    );

  -- Calculate pagination details
  IF v_total_items = 0 THEN
    v_total_pages := 1;
    v_has_more := false;
  ELSE
    v_total_pages := CEIL(v_total_items::NUMERIC / p_limit)::INT;
    v_has_more := (p_page * p_limit) < v_total_items;
  END IF;

  -- 2. Fetch the video requests with pagination, ordering by latest first, and nested serialization
  SELECT COALESCE(jsonb_agg(
    to_jsonb(vr_data) ||
    jsonb_build_object(
      'property', 
      to_jsonb(p_data) || jsonb_build_object(
        'address',
        CASE 
          WHEN p_data.address_id IS NOT NULL THEN to_jsonb(pa_data)
          ELSE NULL
        END
      ),
      'broker',
      to_jsonb(b_data) || jsonb_build_object(
        'address',
        CASE 
          WHEN b_data.address_id IS NOT NULL THEN to_jsonb(ba_data)
          ELSE NULL
        END
      )
    )
  ), '[]'::jsonb)
  INTO v_requests_json
  FROM (
    SELECT vr.*
    FROM public.video_requests vr
    JOIN public.properties p ON vr.property_id = p.id
    JOIN public.brokers b ON vr.broker_id = b.id
    LEFT JOIN public.addresses a ON p.address_id = a.id
    WHERE (p_broker_id IS NULL OR vr.broker_id = p_broker_id)
      AND (p_admin_approved_status IS NULL OR vr.admin_approval_status = p_admin_approved_status)
      AND (p_status IS NULL OR vr.status = p_status)
      AND (p_statuses IS NULL OR array_length(p_statuses, 1) IS NULL OR vr.status::text = ANY(p_statuses))
      AND (
        p_search_query = '' OR
        p.property_title ILIKE '%' || p_search_query || '%' OR
        b.business_name ILIKE '%' || p_search_query || '%' OR
        vr.notes ILIKE '%' || p_search_query || '%' OR
        (a.id IS NOT NULL AND (
           a.full_address ILIKE '%' || p_search_query || '%' OR
           a.city ILIKE '%' || p_search_query || '%' OR
           a.state ILIKE '%' || p_search_query || '%'
        ))
      )
    ORDER BY vr.created_at DESC
    LIMIT p_limit OFFSET v_offset
  ) vr_data
  JOIN public.properties p_data ON vr_data.property_id = p_data.id
  JOIN public.brokers b_data ON vr_data.broker_id = b_data.id
  LEFT JOIN public.addresses pa_data ON p_data.address_id = pa_data.id
  LEFT JOIN public.addresses ba_data ON b_data.address_id = ba_data.id;

  RETURN jsonb_build_object(
    'success', true,
    'data', v_requests_json,
    'pagination', jsonb_build_object(
      'current_page', p_page,
      'limit', p_limit,
      'total_items', v_total_items,
      'total_pages', v_total_pages,
      'has_more', v_has_more
    )
  );
EXCEPTION WHEN OTHERS THEN
  RETURN jsonb_build_object(
    'success', false,
    'message', SQLERRM
  );
END;
$$;


-- >>> Migration: 20260728120000_add_cancel_reason_columns.sql <<<
-- Migration: Add cancel_reason and admin_cancel_reason columns to video_requests table.
-- cancel_reason: Reason provided by the broker when they cancel their own request.
-- admin_cancel_reason: Reason provided by the marketing admin when they decline/cancel a request.

ALTER TABLE public.video_requests
  ADD COLUMN IF NOT EXISTS cancel_reason TEXT DEFAULT NULL,
  ADD COLUMN IF NOT EXISTS admin_cancel_reason TEXT DEFAULT NULL;


-- >>> Migration: 20260728130000_update_fetch_properties_media_empty.sql <<<
-- Migration: Update fetch_properties RPC function to support p_for_video_request boolean flag.
-- When p_for_video_request is TRUE, filters for properties where medias is empty AND no active video request exists in video_requests.

CREATE OR REPLACE FUNCTION public.fetch_properties(
  p_broker_id UUID,
  p_page INT DEFAULT 1,
  p_limit INT DEFAULT 10,
  p_search_query TEXT DEFAULT '',
  p_for_video_request BOOLEAN DEFAULT false
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_offset INT;
  v_total_items INT;
  v_total_pages INT;
  v_has_more BOOLEAN;
  v_properties_json JSONB;
BEGIN
  -- Calculate offset for pagination
  v_offset := (p_page - 1) * p_limit;

  -- 1. Calculate total items matching the filter (excluding deleted items)
  SELECT COUNT(*)
  INTO v_total_items
  FROM public.properties p
  LEFT JOIN public.addresses a ON p.address_id = a.id
  WHERE p.broker_id = p_broker_id
    AND p.is_deleted = false
    AND (
      p_for_video_request IS FALSE OR (
        (p.medias IS NULL OR p.medias = '[]'::jsonb OR p.medias::text = '[]' OR p.medias::text = 'null')
        AND NOT EXISTS (
          SELECT 1 FROM public.video_requests vr
          WHERE vr.property_id = p.id
            AND vr.status::text IN ('pending', 'in_progress', 'completed')
        )
      )
    )
    AND (
      p_search_query = '' OR
      p.property_title ILIKE '%' || p_search_query || '%' OR
      p.property_description ILIKE '%' || p_search_query || '%' OR
      (a.id IS NOT NULL AND (
         a.full_address ILIKE '%' || p_search_query || '%' OR
         a.city ILIKE '%' || p_search_query || '%' OR
         a.state ILIKE '%' || p_search_query || '%'
      ))
    );

  -- Calculate pagination details
  IF v_total_items = 0 THEN
    v_total_pages := 1;
    v_has_more := false;
  ELSE
    v_total_pages := CEIL(v_total_items::NUMERIC / p_limit)::INT;
    v_has_more := (p_page * p_limit) < v_total_items;
  END IF;

  -- 2. Fetch properties with pagination, ordering by latest first, and nested address serialization
  SELECT COALESCE(jsonb_agg(
    to_jsonb(p_data) || 
    jsonb_build_object(
      'address', 
      CASE 
        WHEN p_data.address_id IS NOT NULL THEN to_jsonb(a_data)
        ELSE NULL
      END
    )
  ), '[]'::jsonb)
  INTO v_properties_json
  FROM (
    SELECT p.*
    FROM public.properties p
    LEFT JOIN public.addresses a ON p.address_id = a.id
    WHERE p.broker_id = p_broker_id
      AND p.is_deleted = false
      AND (
        p_for_video_request IS FALSE OR (
          (p.medias IS NULL OR p.medias = '[]'::jsonb OR p.medias::text = '[]' OR p.medias::text = 'null')
          AND NOT EXISTS (
            SELECT 1 FROM public.video_requests vr
            WHERE vr.property_id = p.id
              AND vr.status::text IN ('pending', 'in_progress', 'completed')
          )
        )
      )
      AND (
        p_search_query = '' OR
        p.property_title ILIKE '%' || p_search_query || '%' OR
        p.property_description ILIKE '%' || p_search_query || '%' OR
        (a.id IS NOT NULL AND (
           a.full_address ILIKE '%' || p_search_query || '%' OR
           a.city ILIKE '%' || p_search_query || '%' OR
           a.state ILIKE '%' || p_search_query || '%'
        ))
      )
    ORDER BY p.created_at DESC
    LIMIT p_limit
    OFFSET v_offset
  ) p_data
  LEFT JOIN public.addresses a_data ON p_data.address_id = a_data.id;

  -- Return the final combined JSON structure
  RETURN jsonb_build_object(
    'success', true,
    'data', v_properties_json,
    'pagination', jsonb_build_object(
      'total_items', v_total_items,
      'total_pages', v_total_pages,
      'has_more', v_has_more
    )
  );
END;
$$;


-- >>> Migration: 20260728140000_create_fetch_video_request_details_rpc.sql <<<
-- Migration: Create public.fetch_video_request_details RPC function
-- Purpose: Atomically fetch the latest video_request record and property details for a given property in a single call.

CREATE OR REPLACE FUNCTION public.fetch_video_request_details(
  p_property_id UUID
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_video_request_json JSONB := NULL;
  v_property_json JSONB := NULL;
BEGIN
  -- 1. Fetch latest video_request record with nested property and address
  SELECT to_jsonb(vr_data) || jsonb_build_object(
    'property',
    CASE
      WHEN p_data.id IS NOT NULL THEN to_jsonb(p_data) || jsonb_build_object(
        'address',
        CASE
          WHEN a_data.id IS NOT NULL THEN to_jsonb(a_data)
          ELSE NULL
        END
      )
      ELSE NULL
    END
  )
  INTO v_video_request_json
  FROM (
    SELECT *
    FROM public.video_requests
    WHERE property_id = p_property_id
    ORDER BY created_at DESC
    LIMIT 1
  ) vr_data
  LEFT JOIN public.properties p_data ON vr_data.property_id = p_data.id
  LEFT JOIN public.addresses a_data ON p_data.address_id = a_data.id;

  -- 2. Fetch property details with nested address
  SELECT to_jsonb(p) || jsonb_build_object(
    'address',
    CASE
      WHEN a.id IS NOT NULL THEN to_jsonb(a)
      ELSE NULL
    END
  )
  INTO v_property_json
  FROM public.properties p
  LEFT JOIN public.addresses a ON p.address_id = a.id
  WHERE p.id = p_property_id;

  RETURN jsonb_build_object(
    'success', true,
    'video_request', v_video_request_json,
    'property', v_property_json
  );
END;
$$;


-- >>> Migration: 20260730130000_create_get_social_leads_rpc.sql <<<
-- Migration: Update get_social_leads RPC function to support p_platforms array filter and nested to_jsonb serialization.

CREATE OR REPLACE FUNCTION public.get_social_leads(
  p_broker_id UUID DEFAULT NULL,
  p_page INT DEFAULT 1,
  p_limit INT DEFAULT 10,
  p_search_query TEXT DEFAULT '',
  p_platforms TEXT[] DEFAULT NULL
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_offset INT;
  v_total_items INT;
  v_total_pages INT;
  v_has_more BOOLEAN;
  v_leads_json JSONB;
BEGIN
  -- Calculate offset for pagination
  v_offset := (p_page - 1) * p_limit;

  -- 1. Calculate total items matching the filter
  SELECT COUNT(*)
  INTO v_total_items
  FROM public.social_leads sl
  LEFT JOIN public.social_posts sp ON sl.social_post_id = sp.id
  LEFT JOIN public.properties p ON sp.property_id = p.id
  LEFT JOIN public.addresses a ON p.address_id = a.id
  WHERE (p_broker_id IS NULL OR sl.broker_id = p_broker_id)
    AND (
      p_platforms IS NULL 
      OR array_length(p_platforms, 1) IS NULL 
      OR array_length(p_platforms, 1) = 0
      OR (
        'other' = ANY(ARRAY(SELECT LOWER(unnest(p_platforms)))) AND (
          sl.social_post_id IS NULL OR LOWER(COALESCE(sp.platform::text, '')) NOT IN ('facebook', 'instagram')
        )
      )
      OR LOWER(COALESCE(sp.platform::text, '')) = ANY(ARRAY(SELECT LOWER(unnest(p_platforms))))
    )
    AND (
      p_search_query = '' OR
      sl.user_name ILIKE '%' || p_search_query || '%' OR
      sl.phone ILIKE '%' || p_search_query || '%' OR
      sl.property_details ILIKE '%' || p_search_query || '%' OR
      sl.notes ILIKE '%' || p_search_query || '%' OR
      (sp.id IS NOT NULL AND sp.caption ILIKE '%' || p_search_query || '%') OR
      (p.id IS NOT NULL AND p.property_title ILIKE '%' || p_search_query || '%')
    );

  -- Calculate pagination details
  IF v_total_items = 0 THEN
    v_total_pages := 1;
    v_has_more := false;
  ELSE
    v_total_pages := CEIL(v_total_items::NUMERIC / p_limit)::INT;
    v_has_more := (p_page * p_limit) < v_total_items;
  END IF;

  -- 2. Fetch leads with pagination, ordering by latest first, and nested serialization
  SELECT COALESCE(jsonb_agg(
    to_jsonb(sl_data) ||
    jsonb_build_object(
      'social_posts',
      CASE 
        WHEN sp_data.id IS NOT NULL THEN
          to_jsonb(sp_data) || jsonb_build_object(
            'properties',
            CASE 
              WHEN p_data.id IS NOT NULL THEN
                to_jsonb(p_data) || jsonb_build_object(
                  'address',
                  CASE 
                    WHEN a_data.id IS NOT NULL THEN to_jsonb(a_data)
                    ELSE NULL
                  END
                )
              ELSE NULL
            END
          )
        ELSE NULL
      END,
      'broker',
      CASE 
        WHEN b_data.id IS NOT NULL THEN to_jsonb(b_data)
        ELSE NULL
      END
    )
  ), '[]'::jsonb)
  INTO v_leads_json
  FROM (
    SELECT sl.*
    FROM public.social_leads sl
    LEFT JOIN public.social_posts sp ON sl.social_post_id = sp.id
    LEFT JOIN public.properties p ON sp.property_id = p.id
    LEFT JOIN public.addresses a ON p.address_id = a.id
    WHERE (p_broker_id IS NULL OR sl.broker_id = p_broker_id)
      AND (
        p_platforms IS NULL 
        OR array_length(p_platforms, 1) IS NULL 
        OR array_length(p_platforms, 1) = 0
        OR (
          'other' = ANY(ARRAY(SELECT LOWER(unnest(p_platforms)))) AND (
            sl.social_post_id IS NULL OR LOWER(COALESCE(sp.platform::text, '')) NOT IN ('facebook', 'instagram')
          )
        )
        OR LOWER(COALESCE(sp.platform::text, '')) = ANY(ARRAY(SELECT LOWER(unnest(p_platforms))))
      )
      AND (
        p_search_query = '' OR
        sl.user_name ILIKE '%' || p_search_query || '%' OR
        sl.phone ILIKE '%' || p_search_query || '%' OR
        sl.property_details ILIKE '%' || p_search_query || '%' OR
        sl.notes ILIKE '%' || p_search_query || '%' OR
        (sp.id IS NOT NULL AND sp.caption ILIKE '%' || p_search_query || '%') OR
        (p.id IS NOT NULL AND p.property_title ILIKE '%' || p_search_query || '%')
      )
    ORDER BY sl.created_at DESC
    LIMIT p_limit OFFSET v_offset
  ) sl_data
  LEFT JOIN public.social_posts sp_data ON sl_data.social_post_id = sp_data.id
  LEFT JOIN public.properties p_data ON sp_data.property_id = p_data.id
  LEFT JOIN public.brokers b_data ON sl_data.broker_id = b_data.id
  LEFT JOIN public.addresses a_data ON p_data.address_id = a_data.id;

  RETURN jsonb_build_object(
    'success', true,
    'data', v_leads_json,
    'pagination', jsonb_build_object(
      'current_page', p_page,
      'limit', p_limit,
      'total_items', v_total_items,
      'total_pages', v_total_pages,
      'has_more', v_has_more
    )
  );
EXCEPTION WHEN OTHERS THEN
  RETURN jsonb_build_object(
    'success', false,
    'message', SQLERRM
  );
END;
$$;


-- >>> Migration: 20260730143000_convert_social_platform_to_enum.sql <<<
-- Migration: Convert platform column in social_posts and social_accounts tables to public.social_platform enum type

-- 1. Create social_platform enum type if not exists
DO $$ 
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'social_platform') THEN
    CREATE TYPE public.social_platform AS ENUM ('facebook', 'instagram');
  END IF;
END $$;

-- 2. Update social_posts.platform column from TEXT to public.social_platform enum
ALTER TABLE public.social_posts DROP CONSTRAINT IF EXISTS social_posts_platform_check;
ALTER TABLE public.social_posts 
  ALTER COLUMN platform TYPE public.social_platform 
  USING LOWER(platform)::public.social_platform;

-- 3. Update social_accounts.platform column from TEXT to public.social_platform enum
ALTER TABLE public.social_accounts DROP CONSTRAINT IF EXISTS social_accounts_platform_check;
ALTER TABLE public.social_accounts 
  ALTER COLUMN platform TYPE public.social_platform 
  USING LOWER(platform)::public.social_platform;


-- >>> Migration: 20260730190000_add_social_posts_unique_constraint.sql <<<
-- Migration: Add unique constraint on social_posts table for (broker_id, platform, post_id) to ensure Supabase upsert operations succeed.

ALTER TABLE public.social_posts 
  DROP CONSTRAINT IF EXISTS social_posts_broker_platform_post_id_key;

ALTER TABLE public.social_posts 
  ADD CONSTRAINT social_posts_broker_platform_post_id_key UNIQUE (broker_id, platform, post_id);


-- >>> Migration: 20260730193000_fix_social_posts_search_text_trigger.sql <<<
-- Migration: Safely cast platform to text in generate_social_posts_search_text trigger function to prevent enum casting errors on INSERT/UPDATE.

CREATE OR REPLACE FUNCTION public.generate_social_posts_search_text()
RETURNS TRIGGER AS $$
BEGIN
  NEW.search_text := COALESCE(NEW.caption, '') || ' ' || COALESCE(NEW.platform::text, '');
  NEW.fts := to_tsvector('english', COALESCE(NEW.search_text, ''));
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Re-create trigger on social_posts
DROP TRIGGER IF EXISTS trg_social_posts_search_text ON public.social_posts;

CREATE TRIGGER trg_social_posts_search_text
BEFORE INSERT OR UPDATE ON public.social_posts
FOR EACH ROW
EXECUTE FUNCTION public.generate_social_posts_search_text();


-- >>> Migration: 20260804120000_convert_user_role_and_gender_to_enums.sql <<<
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


-- >>> Migration: 20260804130000_create_fetch_brokers_rpc.sql <<<
-- Migration: Create fetch_brokers RPC function using dynamic to_jsonb(*) row serialization in subquery
-- File: supabase/migrations/20260804130000_create_fetch_brokers_rpc.sql

CREATE OR REPLACE FUNCTION public.fetch_brokers(
  p_search_query text DEFAULT NULL,
  p_page integer DEFAULT 1,
  p_limit integer DEFAULT 10
)
RETURNS json
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_offset integer;
  v_total_items integer;
  v_total_pages integer;
  v_has_more boolean;
  v_data jsonb;
BEGIN
  -- Ensure valid page & limit values
  IF p_page < 1 THEN p_page := 1; END IF;
  IF p_limit < 1 THEN p_limit := 10; END IF;
  v_offset := (p_page - 1) * p_limit;

  -- 1. Total count of brokers matching search query on user name or business name
  SELECT COUNT(*)
  INTO v_total_items
  FROM public.users u
  LEFT JOIN public.brokers b ON u.broker_id = b.id
  WHERE u.role = 'broker'::user_role
    AND (u.is_deleted IS NOT TRUE)
    AND (
      p_search_query IS NULL OR TRIM(p_search_query) = '' OR
      u.name ILIKE '%' || TRIM(p_search_query) || '%' OR
      b.business_name ILIKE '%' || TRIM(p_search_query) || '%'
    );

  v_total_pages := CEIL(v_total_items::decimal / p_limit::decimal);
  IF v_total_pages < 1 THEN v_total_pages := 1; END IF;
  v_has_more := (p_page < v_total_pages);

  -- 2. Fetch brokers using subquery for sorting/pagination, then jsonb_agg
  SELECT COALESCE(jsonb_agg(t.broker_json), '[]'::jsonb)
  INTO v_data
  FROM (
    SELECT 
      to_jsonb(u.*)
      || jsonb_build_object(
        'broker_id', CASE 
          WHEN b.id IS NOT NULL THEN 
            to_jsonb(b.*) || jsonb_build_object(
              'address_id', (
                SELECT to_jsonb(a.*) 
                FROM public.addresses a 
                WHERE a.id = b.address_id
              )
            )
          ELSE NULL 
        END,
        'social_accounts', (
          SELECT COALESCE(jsonb_agg(to_jsonb(sa.*)), '[]'::jsonb)
          FROM public.social_accounts sa
          WHERE b.id IS NOT NULL AND sa.broker_id = b.id
        )
      ) AS broker_json
    FROM public.users u
    LEFT JOIN public.brokers b ON u.broker_id = b.id
    WHERE u.role = 'broker'::user_role
      AND (u.is_deleted IS NOT TRUE)
      AND (
        p_search_query IS NULL OR TRIM(p_search_query) = '' OR
        u.name ILIKE '%' || TRIM(p_search_query) || '%' OR
        b.business_name ILIKE '%' || TRIM(p_search_query) || '%'
      )
    ORDER BY u.created_at DESC
    OFFSET v_offset
    LIMIT p_limit
  ) t;

  -- 3. Return structured response
  RETURN json_build_object(
    'success', true,
    'data', v_data,
    'pagination', json_build_object(
      'current_page', p_page,
      'items_per_page', p_limit,
      'total_items', v_total_items,
      'total_pages', v_total_pages,
      'has_more', v_has_more
    )
  );
END;
$$;


-- >>> Migration: 20260805165800_fix_social_accounts_enum_trigger.sql <<<
-- Migration: Fix generate_social_accounts_search_text and generate_social_posts_search_text trigger functions
-- Root Cause: coalesce(NEW.platform, '') tried to cast the fallback '' to public.social_platform enum, throwing invalid input value for enum social_platform: ""

CREATE OR REPLACE FUNCTION generate_social_accounts_search_text()
RETURNS trigger AS $$
DECLARE
  combined_text text;
BEGIN
  combined_text := lower(
    coalesce(NEW.id::text, '') || ' ' ||
    coalesce(NEW.page_name, '') || ' ' ||
    coalesce(NEW.platform::text, '') || ' ' ||
    coalesce(NEW.page_id, '') || ' ' ||
    coalesce(NEW.instagram_username, '')
  );
  NEW.search_text := combined_text;
  NEW.fts := to_tsvector('simple', combined_text);
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION generate_social_posts_search_text()
RETURNS trigger AS $$
DECLARE
  combined_text text;
BEGIN
  combined_text := lower(
    coalesce(NEW.id::text, '') || ' ' ||
    coalesce(NEW.caption, '') || ' ' ||
    coalesce(NEW.platform::text, '') || ' ' ||
    coalesce(NEW.post_id, '') || ' ' ||
    coalesce(NEW.page_id, '')
  );
  NEW.search_text := combined_text;
  NEW.fts := to_tsvector('simple', combined_text);
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;


-- >>> Migration: 20260806163000_fix_users_enum_search_text_trigger.sql <<<
-- Migration: Fix generate_users_search_text trigger function for user_role and user_gender enums
-- File: supabase/migrations/20260806163000_fix_users_enum_search_text_trigger.sql
-- Root Cause: coalesce(NEW.role, '') tried to cast fallback '' to public.user_role enum, throwing invalid input value for enum user_role: ""

CREATE OR REPLACE FUNCTION generate_users_search_text()
RETURNS trigger AS $$
DECLARE
  combined_text text;
BEGIN
  combined_text := lower(
    coalesce(NEW.id::text, '') || ' ' ||
    coalesce(NEW.name, '') || ' ' ||
    coalesce(NEW.email, '') || ' ' ||
    coalesce(NEW.phone, '') || ' ' ||
    coalesce(NEW.phone_country_code, '') || ' ' ||
    coalesce(NEW.phone_country_iso, '') || ' ' ||
    coalesce(NEW.role::text, '') || ' ' ||
    coalesce(NEW.gender::text, '')
  );
  NEW.search_text := combined_text;
  NEW.fts := to_tsvector('simple', combined_text);
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_users_search_text ON public.users;
CREATE TRIGGER trg_users_search_text
BEFORE INSERT OR UPDATE ON public.users
FOR EACH ROW EXECUTE FUNCTION generate_users_search_text();


-- >>> Migration: 20260810120000_create_notifications_schema.sql <<<
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


-- >>> Migration: 20260810130000_fix_device_token_rpcs.sql <<<
-- Migration: 20260810130000_fix_device_token_rpcs.sql
-- Description: Unified single RPC function for FCM device token sync, old device token purging, and auto-cleanup.

CREATE OR REPLACE FUNCTION public.rpc_upsert_device_token(
    p_user_id UUID,
    p_fcm_token TEXT,
    p_device_id TEXT DEFAULT NULL,
    p_device_name TEXT DEFAULT NULL,
    p_platform TEXT DEFAULT NULL,
    p_ttl_days INTEGER DEFAULT 30
)
RETURNS public.user_device_tokens
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_result public.user_device_tokens;
    v_expires_at TIMESTAMPTZ;
BEGIN
    -- 1. Auto-purge all expired tokens across the database
    DELETE FROM public.user_device_tokens WHERE expires_at < NOW();

    -- 2. If device_id is provided, purge any old token records for this physical device
    IF p_device_id IS NOT NULL AND TRIM(p_device_id) <> '' THEN
        DELETE FROM public.user_device_tokens 
        WHERE (device_id = p_device_id AND fcm_token <> p_fcm_token);
    END IF;

    -- 3. Calculate expiration timestamp
    v_expires_at := NOW() + (p_ttl_days || ' days')::INTERVAL;

    -- 4. Insert or update current device token record
    INSERT INTO public.user_device_tokens (
        user_id,
        fcm_token,
        device_id,
        device_name,
        platform,
        expires_at,
        created_at,
        updated_at
    )
    VALUES (
        p_user_id,
        p_fcm_token,
        p_device_id,
        p_device_name,
        p_platform,
        v_expires_at,
        NOW(),
        NOW()
    )
    ON CONFLICT (fcm_token) DO UPDATE
    SET
        user_id = EXCLUDED.user_id,
        device_id = COALESCE(EXCLUDED.device_id, public.user_device_tokens.device_id),
        device_name = COALESCE(EXCLUDED.device_name, public.user_device_tokens.device_name),
        platform = COALESCE(EXCLUDED.platform, public.user_device_tokens.platform),
        expires_at = EXCLUDED.expires_at,
        updated_at = NOW()
    RETURNING * INTO v_result;

    RETURN v_result;
END;
$$;


-- >>> Migration: 20260810140000_create_notification_webhook_trigger.sql <<<
-- Migration: 20260810140000_create_notification_webhook_trigger.sql
-- Description: Create database trigger to invoke send-fcm-notification Edge Function on every insert to public.notifications.

-- 1. Enable pg_net extension for async HTTP calls
CREATE EXTENSION IF NOT EXISTS pg_net WITH SCHEMA extensions;

-- 2. Function: fn_trigger_send_fcm_notification
CREATE OR REPLACE FUNCTION public.fn_trigger_send_fcm_notification()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_payload JSONB;
BEGIN
    -- Build payload for Edge Function
    v_payload := jsonb_build_object(
        'type', TG_OP,
        'table', TG_TABLE_NAME,
        'schema', TG_TABLE_SCHEMA,
        'record', row_to_json(NEW)
    );

    -- Invoke send-fcm-notification Edge Function asynchronously via pg_net
    PERFORM extensions.http_post(
        url := 'https://btjzesvlexcvpqwisyet.supabase.co/functions/v1/send-fcm-notification',
        headers := jsonb_build_object(
            'Content-Type', 'application/json'
        ),
        body := v_payload
    );

    RETURN NEW;
EXCEPTION WHEN OTHERS THEN
    -- Prevent trigger network warnings from rolling back the notifications table insert
    RAISE WARNING 'FCM Notification Trigger warning: %', SQLERRM;
    RETURN NEW;
END;
$$;

-- 3. Trigger: trg_notifications_send_fcm
DROP TRIGGER IF EXISTS trg_notifications_send_fcm ON public.notifications;

CREATE TRIGGER trg_notifications_send_fcm
AFTER INSERT ON public.notifications
FOR EACH ROW
EXECUTE FUNCTION public.fn_trigger_send_fcm_notification();


-- >>> Migration: 20260810150000_create_lead_notification_trigger.sql <<<
-- Migration: 20260810150000_create_lead_notification_trigger.sql
-- Description: Create trigger on public.social_leads to automatically insert a notification row on new lead creation.

-- 1. Function: fn_on_social_lead_inserted
CREATE OR REPLACE FUNCTION public.fn_on_social_lead_inserted()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_receiver_user_id UUID;
    v_lead_name TEXT;
    v_title TEXT;
    v_description TEXT;
BEGIN
    -- Determine receiver_id: Look up user linked to this broker_id
    IF NEW.broker_id IS NOT NULL THEN
        SELECT id INTO v_receiver_user_id
        FROM public.users
        WHERE broker_id = NEW.broker_id OR id = NEW.broker_id
        LIMIT 1;
    END IF;

    -- Format title and description
    v_lead_name := COALESCE(NULLIF(TRIM(NEW.user_name), ''), 'Client');
    v_title := 'New Lead Received';
    v_description := 'You received a new lead from ' || v_lead_name || '.';

    -- Insert row into public.notifications
    -- (This automatically triggers trg_notifications_send_fcm to dispatch FCM push notifications)
    INSERT INTO public.notifications (
        sender_id,
        receiver_id,
        notification_type,
        title,
        description,
        data,
        created_at
    )
    VALUES (
        NULL,
        v_receiver_user_id,
        'lead'::public.notification_type,
        v_title,
        v_description,
        jsonb_build_object(
            'lead_id', NEW.id,
            'user_name', v_lead_name,
            'phone', COALESCE(NEW.phone, ''),
            'property_details', COALESCE(NEW.property_details, '')
        ),
        NOW()
    );

    RETURN NEW;
EXCEPTION WHEN OTHERS THEN
    -- Log warning without blocking the social_leads insertion
    RAISE WARNING 'fn_on_social_lead_inserted warning: %', SQLERRM;
    RETURN NEW;
END;
$$;

-- 2. Trigger: trg_on_social_lead_inserted
DROP TRIGGER IF EXISTS trg_on_social_lead_inserted ON public.social_leads;

CREATE TRIGGER trg_on_social_lead_inserted
AFTER INSERT ON public.social_leads
FOR EACH ROW
EXECUTE FUNCTION public.fn_on_social_lead_inserted();


-- >>> Migration: 20260810160000_cleanup_device_tokens_and_fcm.sql <<<
-- Migration: 20260810160000_cleanup_device_tokens_and_fcm.sql
-- Purpose: Permanently drop public.user_device_tokens table and legacy FCM RPC functions.

-- 1. Drop legacy FCM trigger and function if exists
DROP TRIGGER IF EXISTS trg_notifications_send_fcm ON public.notifications;
DROP FUNCTION IF EXISTS public.fn_trigger_send_fcm_notification();

-- 2. Drop device token RPC functions
DROP FUNCTION IF EXISTS public.rpc_upsert_device_token(UUID, TEXT, TEXT, TEXT, TEXT, INT);
DROP FUNCTION IF EXISTS public.rpc_get_user_device_tokens(UUID);

-- 3. Drop user_device_tokens table
DROP TABLE IF EXISTS public.user_device_tokens CASCADE;


-- >>> Migration: 20260810170000_create_video_request_notification_trigger.sql <<<
-- Migration: 20260810170000_create_video_request_notification_trigger.sql
-- Purpose: Efficient 1-row notification insert trigger for video_requests events.

-- 1. Add video_request_id and target_role columns to public.notifications if not present
ALTER TABLE public.notifications 
ADD COLUMN IF NOT EXISTS video_request_id UUID NULL REFERENCES public.video_requests(id) ON DELETE CASCADE,
ADD COLUMN IF NOT EXISTS target_role VARCHAR(50) NULL;

-- Index for target_role and video_request_id
CREATE INDEX IF NOT EXISTS idx_notifications_video_request_id ON public.notifications(video_request_id);
CREATE INDEX IF NOT EXISTS idx_notifications_target_role ON public.notifications(target_role);

-- Update RLS Policy to allow viewing role-targeted notifications
DROP POLICY IF EXISTS "Users can view relevant notifications" ON public.notifications;
CREATE POLICY "Users can view relevant notifications"
ON public.notifications
FOR SELECT
USING (
    auth.role() = 'authenticated' AND (
        receiver_id IS NULL 
        OR auth.uid() = receiver_id
        OR target_role = (SELECT role FROM public.users WHERE id = auth.uid() LIMIT 1)
    )
);

-- 2. Trigger Function inserting EXACTLY 1 notification row per event
CREATE OR REPLACE FUNCTION public.fn_video_requests_notification_handler()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_auto_approve BOOLEAN := FALSE;
    v_target_broker_user_id UUID;
BEGIN
    -- 1. Fetch auto_approve setting for the requesting broker
    IF NEW.broker_id IS NOT NULL THEN
        SELECT COALESCE(auto_approve_video_requests, FALSE) INTO v_auto_approve
        FROM public.brokers
        WHERE id = NEW.broker_id;
    END IF;

    -- 2. Resolve target broker user ID
    v_target_broker_user_id := NEW.user_id;
    IF v_target_broker_user_id IS NULL AND NEW.broker_id IS NOT NULL THEN
        SELECT id INTO v_target_broker_user_id
        FROM public.users
        WHERE broker_id = NEW.broker_id
        LIMIT 1;
    END IF;

    ----------------------------------------------------------------------------
    -- SCENARIO 1: NEW VIDEO REQUEST CREATED (INSERT)
    ----------------------------------------------------------------------------
    IF TG_OP = 'INSERT' THEN

        -- CASE 1A: Auto Approve is TRUE (or admin_approval_status is 'approved')
        IF v_auto_approve IS TRUE OR NEW.admin_approval_status = 'approved' THEN
            INSERT INTO public.notifications (
                receiver_id,
                target_role,
                video_request_id,
                sender_id,
                title,
                description,
                notification_type,
                data
            ) VALUES (
                NULL,
                'marketing',
                NEW.id,
                v_target_broker_user_id,
                'New Approved Video Request',
                'A new video request has been submitted and approved. Ready for production!',
                'video_request'::public.notification_type,
                jsonb_build_object(
                    'video_request_id', NEW.id,
                    'property_id', NEW.property_id,
                    'broker_id', NEW.broker_id,
                    'status', NEW.admin_approval_status
                )
            );

        -- CASE 1B: Auto Approve is FALSE (admin_approval_status is 'pending')
        ELSE
            INSERT INTO public.notifications (
                receiver_id,
                target_role,
                video_request_id,
                sender_id,
                title,
                description,
                notification_type,
                data
            ) VALUES (
                NULL,
                'super_admin',
                NEW.id,
                v_target_broker_user_id,
                'Pending Video Request Review',
                'A new video request requires review and approval.',
                'video_request'::public.notification_type,
                jsonb_build_object(
                    'video_request_id', NEW.id,
                    'property_id', NEW.property_id,
                    'broker_id', NEW.broker_id,
                    'status', NEW.admin_approval_status
                )
            );
        END IF;

    ----------------------------------------------------------------------------
    -- SCENARIO 2: EXISTING VIDEO REQUEST UPDATED (UPDATE)
    ----------------------------------------------------------------------------
    ELSIF TG_OP = 'UPDATE' THEN

        -- CASE 2A: Status changed to 'approved'
        IF (OLD.admin_approval_status IS DISTINCT FROM 'approved') 
           AND NEW.admin_approval_status = 'approved' THEN
            
            INSERT INTO public.notifications (
                receiver_id,
                target_role,
                video_request_id,
                sender_id,
                title,
                description,
                notification_type,
                data
            ) VALUES (
                NULL,
                'marketing',
                NEW.id,
                v_target_broker_user_id,
                'New Approved Video Request',
                'A pending video request was approved and is now ready for production!',
                'video_request'::public.notification_type,
                jsonb_build_object(
                    'video_request_id', NEW.id,
                    'property_id', NEW.property_id,
                    'broker_id', NEW.broker_id,
                    'status', NEW.admin_approval_status
                )
            );

        -- CASE 2B: Status changed to 'rejected'
        ELSIF (OLD.admin_approval_status IS DISTINCT FROM 'rejected')
           AND NEW.admin_approval_status = 'rejected' THEN

            IF v_target_broker_user_id IS NOT NULL THEN
                INSERT INTO public.notifications (
                    receiver_id,
                    target_role,
                    video_request_id,
                    sender_id,
                    title,
                    description,
                    notification_type,
                    data
                ) VALUES (
                    v_target_broker_user_id,
                    NULL,
                    NEW.id,
                    NULL,
                    'Video Request Rejected',
                    CASE 
                        WHEN NEW.admin_cancel_reason IS NOT NULL AND NEW.admin_cancel_reason != '' THEN 'Your video request was rejected: ' || NEW.admin_cancel_reason
                        WHEN NEW.cancel_reason IS NOT NULL AND NEW.cancel_reason != '' THEN 'Your video request was rejected: ' || NEW.cancel_reason
                        ELSE 'Your video request was rejected.'
                    END,
                    'video_request'::public.notification_type,
                    jsonb_build_object(
                        'video_request_id', NEW.id,
                        'property_id', NEW.property_id,
                        'broker_id', NEW.broker_id,
                        'status', NEW.admin_approval_status,
                        'reason', COALESCE(NEW.admin_cancel_reason, NEW.cancel_reason, '')
                    )
                );
            END IF;

        END IF;

    END IF;

    RETURN NEW;
EXCEPTION WHEN OTHERS THEN
    RAISE WARNING 'fn_video_requests_notification_handler warning: %', SQLERRM;
    RETURN NEW;
END;
$$;

-- Attach AFTER INSERT OR UPDATE trigger to public.video_requests
DROP TRIGGER IF EXISTS trg_video_requests_notification ON public.video_requests;

CREATE TRIGGER trg_video_requests_notification
AFTER INSERT OR UPDATE ON public.video_requests
FOR EACH ROW
EXECUTE FUNCTION public.fn_video_requests_notification_handler();


-- >>> Migration: 20260810180000_update_notifications_receiver_ids_and_trigger.sql <<<
-- Migration: 20260810180000_update_notifications_receiver_ids_and_trigger.sql
-- Purpose: Add receiver_ids array and video_request_id to public.notifications and create 1-row notification insert trigger.

-- 1. Add video_request_id and receiver_ids columns to public.notifications
ALTER TABLE public.notifications 
ADD COLUMN IF NOT EXISTS video_request_id UUID NULL REFERENCES public.video_requests(id) ON DELETE CASCADE,
ADD COLUMN IF NOT EXISTS receiver_ids UUID[] NULL;

-- 2. Performance indexes
CREATE INDEX IF NOT EXISTS idx_notifications_video_request_id ON public.notifications(video_request_id);
CREATE INDEX IF NOT EXISTS idx_notifications_receiver_ids ON public.notifications USING GIN (receiver_ids);

-- 3. RLS Policy supporting receiver_ids array
DROP POLICY IF EXISTS "Users can view relevant notifications" ON public.notifications;
CREATE POLICY "Users can view relevant notifications"
ON public.notifications
FOR SELECT
USING (
    auth.role() = 'authenticated' AND (
        receiver_id IS NULL 
        OR auth.uid() = receiver_id
        OR auth.uid() = ANY(receiver_ids)
    )
);

-- 4. Trigger Function inserting EXACTLY 1 notification row containing receiver_ids array
CREATE OR REPLACE FUNCTION public.fn_video_requests_notification_handler()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_auto_approve BOOLEAN := FALSE;
    v_target_broker_user_id UUID;
    v_target_user_ids UUID[];
BEGIN
    -- Fetch auto_approve setting for the requesting broker
    IF NEW.broker_id IS NOT NULL THEN
        SELECT COALESCE(auto_approve_video_requests, FALSE) INTO v_auto_approve
        FROM public.brokers
        WHERE id = NEW.broker_id;
    END IF;

    -- Resolve target broker user ID
    v_target_broker_user_id := NEW.user_id;
    IF v_target_broker_user_id IS NULL AND NEW.broker_id IS NOT NULL THEN
        SELECT id INTO v_target_broker_user_id
        FROM public.users
        WHERE broker_id = NEW.broker_id
        LIMIT 1;
    END IF;

    ----------------------------------------------------------------------------
    -- SCENARIO 1: NEW VIDEO REQUEST CREATED (INSERT)
    ----------------------------------------------------------------------------
    IF TG_OP = 'INSERT' THEN

        -- CASE 1A: Auto Approve is TRUE (or admin_approval_status is 'approved')
        IF v_auto_approve IS TRUE OR NEW.admin_approval_status = 'approved' THEN
            -- Fetch array of active marketing user IDs
            SELECT ARRAY_AGG(id) INTO v_target_user_ids
            FROM public.users
            WHERE role IN ('marketing', 'ads') AND (is_active IS TRUE OR is_active IS NULL);

            IF v_target_user_ids IS NOT NULL AND ARRAY_LENGTH(v_target_user_ids, 1) > 0 THEN
                INSERT INTO public.notifications (
                    receiver_ids,
                    video_request_id,
                    sender_id,
                    title,
                    description,
                    notification_type,
                    data
                ) VALUES (
                    v_target_user_ids,
                    NEW.id,
                    v_target_broker_user_id,
                    'New Approved Video Request',
                    'A new video request has been submitted and approved. Ready for production!',
                    'video_request'::public.notification_type,
                    jsonb_build_object(
                        'video_request_id', NEW.id,
                        'property_id', NEW.property_id,
                        'broker_id', NEW.broker_id,
                        'status', NEW.admin_approval_status
                    )
                );
            END IF;

        -- CASE 1B: Auto Approve is FALSE (admin_approval_status is 'pending')
        ELSE
            -- Fetch array of active reviewer user IDs
            SELECT ARRAY_AGG(id) INTO v_target_user_ids
            FROM public.users
            WHERE role IN ('super_admin', 'superadmin', 'admin') AND (is_active IS TRUE OR is_active IS NULL);

            IF v_target_user_ids IS NOT NULL AND ARRAY_LENGTH(v_target_user_ids, 1) > 0 THEN
                INSERT INTO public.notifications (
                    receiver_ids,
                    video_request_id,
                    sender_id,
                    title,
                    description,
                    notification_type,
                    data
                ) VALUES (
                    v_target_user_ids,
                    NEW.id,
                    v_target_broker_user_id,
                    'Pending Video Request Review',
                    'A new video request requires review and approval.',
                    'video_request'::public.notification_type,
                    jsonb_build_object(
                        'video_request_id', NEW.id,
                        'property_id', NEW.property_id,
                        'broker_id', NEW.broker_id,
                        'status', NEW.admin_approval_status
                    )
                );
            END IF;
        END IF;

    ----------------------------------------------------------------------------
    -- SCENARIO 2: EXISTING VIDEO REQUEST UPDATED (UPDATE)
    ----------------------------------------------------------------------------
    ELSIF TG_OP = 'UPDATE' THEN

        -- CASE 2A: Status changed to 'approved'
        IF (OLD.admin_approval_status IS DISTINCT FROM 'approved') 
           AND NEW.admin_approval_status = 'approved' THEN
            
            -- Fetch array of active marketing user IDs
            SELECT ARRAY_AGG(id) INTO v_target_user_ids
            FROM public.users
            WHERE role IN ('marketing', 'ads') AND (is_active IS TRUE OR is_active IS NULL);

            IF v_target_user_ids IS NOT NULL AND ARRAY_LENGTH(v_target_user_ids, 1) > 0 THEN
                INSERT INTO public.notifications (
                    receiver_ids,
                    video_request_id,
                    sender_id,
                    title,
                    description,
                    notification_type,
                    data
                ) VALUES (
                    v_target_user_ids,
                    NEW.id,
                    v_target_broker_user_id,
                    'New Approved Video Request',
                    'A pending video request was approved and is now ready for production!',
                    'video_request'::public.notification_type,
                    jsonb_build_object(
                        'video_request_id', NEW.id,
                        'property_id', NEW.property_id,
                        'broker_id', NEW.broker_id,
                        'status', NEW.admin_approval_status
                    )
                );
            END IF;

        -- CASE 2B: Status changed to 'rejected'
        ELSIF (OLD.admin_approval_status IS DISTINCT FROM 'rejected')
           AND NEW.admin_approval_status = 'rejected' THEN

            IF v_target_broker_user_id IS NOT NULL THEN
                INSERT INTO public.notifications (
                    receiver_id,
                    receiver_ids,
                    video_request_id,
                    sender_id,
                    title,
                    description,
                    notification_type,
                    data
                ) VALUES (
                    v_target_broker_user_id,
                    ARRAY[v_target_broker_user_id],
                    NEW.id,
                    NULL,
                    'Video Request Rejected',
                    CASE 
                        WHEN NEW.admin_cancel_reason IS NOT NULL AND NEW.admin_cancel_reason != '' THEN 'Your video request was rejected: ' || NEW.admin_cancel_reason
                        WHEN NEW.cancel_reason IS NOT NULL AND NEW.cancel_reason != '' THEN 'Your video request was rejected: ' || NEW.cancel_reason
                        ELSE 'Your video request was rejected.'
                    END,
                    'video_request'::public.notification_type,
                    jsonb_build_object(
                        'video_request_id', NEW.id,
                        'property_id', NEW.property_id,
                        'broker_id', NEW.broker_id,
                        'status', NEW.admin_approval_status,
                        'reason', COALESCE(NEW.admin_cancel_reason, NEW.cancel_reason, '')
                    )
                );
            END IF;

        END IF;

    END IF;

    RETURN NEW;
EXCEPTION WHEN OTHERS THEN
    RAISE WARNING 'fn_video_requests_notification_handler warning: %', SQLERRM;
    RETURN NEW;
END;
$$;

-- Attach AFTER INSERT OR UPDATE trigger to public.video_requests
DROP TRIGGER IF EXISTS trg_video_requests_notification ON public.video_requests;

CREATE TRIGGER trg_video_requests_notification
AFTER INSERT OR UPDATE ON public.video_requests
FOR EACH ROW
EXECUTE FUNCTION public.fn_video_requests_notification_handler();


-- >>> Migration: 20260810190000_drop_receiver_id_and_update_all_triggers.sql <<<
-- Migration: 20260810190000_drop_receiver_id_and_update_all_triggers.sql
-- Description: Master migration with guaranteed notification insertion for video_requests INSERT and UPDATE.

-- 1. Drop existing RLS policy dependent on receiver_id
DROP POLICY IF EXISTS "Users can view relevant notifications" ON public.notifications;

-- 2. Drop receiver_id column with CASCADE
ALTER TABLE public.notifications DROP COLUMN IF EXISTS receiver_id CASCADE;

-- 3. Ensure receiver_ids array and video_request_id columns exist
ALTER TABLE public.notifications 
ADD COLUMN IF NOT EXISTS video_request_id UUID NULL REFERENCES public.video_requests(id) ON DELETE CASCADE,
ADD COLUMN IF NOT EXISTS receiver_ids UUID[] NULL;

-- 4. Create performance indexes
CREATE INDEX IF NOT EXISTS idx_notifications_video_request_id ON public.notifications(video_request_id);
CREATE INDEX IF NOT EXISTS idx_notifications_receiver_ids ON public.notifications USING GIN (receiver_ids);

-- 5. Re-create clean RLS Policy using receiver_ids array
CREATE POLICY "Users can view relevant notifications"
ON public.notifications
FOR SELECT
USING (
    auth.role() = 'authenticated' AND (
        auth.uid() = ANY(receiver_ids)
    )
);

--------------------------------------------------------------------------------
-- 6. Update Social Lead Notification Trigger Function (social_leads INSERT)
--------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.fn_on_social_lead_inserted()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_receiver_user_id UUID;
    v_lead_name TEXT;
    v_title TEXT;
    v_description TEXT;
BEGIN
    IF NEW.broker_id IS NOT NULL THEN
        SELECT id INTO v_receiver_user_id
        FROM public.users
        WHERE broker_id = NEW.broker_id OR id = NEW.broker_id
        LIMIT 1;
    END IF;

    v_lead_name := COALESCE(NULLIF(TRIM(NEW.user_name), ''), 'Client');
    v_title := 'New Lead Received';
    v_description := 'You received a new lead from ' || v_lead_name || '.';

    IF v_receiver_user_id IS NOT NULL THEN
        INSERT INTO public.notifications (
            sender_id,
            receiver_ids,
            notification_type,
            title,
            description,
            data,
            created_at
        )
        VALUES (
            NULL,
            ARRAY[v_receiver_user_id],
            'lead'::public.notification_type,
            v_title,
            v_description,
            jsonb_build_object(
                'lead_id', NEW.id,
                'user_name', v_lead_name,
                'phone', COALESCE(NEW.phone, ''),
                'property_details', COALESCE(NEW.property_details, '')
            ),
            NOW()
        );
    END IF;

    RETURN NEW;
EXCEPTION WHEN OTHERS THEN
    RAISE WARNING 'fn_on_social_lead_inserted warning: %', SQLERRM;
    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_on_social_lead_inserted ON public.social_leads;
CREATE TRIGGER trg_on_social_lead_inserted
AFTER INSERT ON public.social_leads
FOR EACH ROW
EXECUTE FUNCTION public.fn_on_social_lead_inserted();

--------------------------------------------------------------------------------
-- 7. Update Video Request Notification Trigger Function (video_requests INSERT/UPDATE)
--------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.fn_video_requests_notification_handler()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_auto_approve BOOLEAN := FALSE;
    v_target_broker_user_id UUID;
    v_target_user_ids UUID[];
BEGIN
    -- Fetch auto_approve setting for the requesting broker
    IF NEW.broker_id IS NOT NULL THEN
        SELECT COALESCE(auto_approve_video_requests, FALSE) INTO v_auto_approve
        FROM public.brokers
        WHERE id = NEW.broker_id;
    END IF;

    -- Resolve target broker user ID
    v_target_broker_user_id := NEW.user_id;
    IF v_target_broker_user_id IS NULL AND NEW.broker_id IS NOT NULL THEN
        SELECT id INTO v_target_broker_user_id
        FROM public.users
        WHERE broker_id = NEW.broker_id
        LIMIT 1;
    END IF;

    ----------------------------------------------------------------------------
    -- SCENARIO 1: NEW VIDEO REQUEST CREATED (INSERT)
    ----------------------------------------------------------------------------
    IF TG_OP = 'INSERT' THEN

        -- CASE 1A: Auto Approve is TRUE (or admin_approval_status is 'approved')
        IF v_auto_approve IS TRUE OR LOWER(COALESCE(NEW.admin_approval_status, '')) = 'approved' THEN
            SELECT ARRAY_AGG(id) INTO v_target_user_ids
            FROM public.users
            WHERE LOWER(role) IN ('marketing', 'ads');

            IF v_target_user_ids IS NULL OR ARRAY_LENGTH(v_target_user_ids, 1) IS NULL THEN
                SELECT ARRAY_AGG(id) INTO v_target_user_ids
                FROM public.users
                WHERE LOWER(role) NOT IN ('broker');
            END IF;

            INSERT INTO public.notifications (
                receiver_ids,
                video_request_id,
                sender_id,
                title,
                description,
                notification_type,
                data
            ) VALUES (
                v_target_user_ids,
                NEW.id,
                v_target_broker_user_id,
                'New Approved Video Request',
                'A new video request has been submitted and approved. Ready for production!',
                'video_request'::public.notification_type,
                jsonb_build_object(
                    'video_request_id', NEW.id,
                    'property_id', NEW.property_id,
                    'broker_id', NEW.broker_id,
                    'status', NEW.admin_approval_status
                )
            );

        -- CASE 1B: Auto Approve is FALSE (admin_approval_status is 'pending')
        ELSE
            SELECT ARRAY_AGG(id) INTO v_target_user_ids
            FROM public.users
            WHERE LOWER(role) IN ('super_admin', 'superadmin', 'admin');

            IF v_target_user_ids IS NULL OR ARRAY_LENGTH(v_target_user_ids, 1) IS NULL THEN
                SELECT ARRAY_AGG(id) INTO v_target_user_ids
                FROM public.users
                WHERE LOWER(role) NOT IN ('broker');
            END IF;

            INSERT INTO public.notifications (
                receiver_ids,
                video_request_id,
                sender_id,
                title,
                description,
                notification_type,
                data
            ) VALUES (
                v_target_user_ids,
                NEW.id,
                v_target_broker_user_id,
                'Pending Video Request Review',
                'A new video request requires review and approval.',
                'video_request'::public.notification_type,
                jsonb_build_object(
                    'video_request_id', NEW.id,
                    'property_id', NEW.property_id,
                    'broker_id', NEW.broker_id,
                    'status', NEW.admin_approval_status
                )
            );
        END IF;

    ----------------------------------------------------------------------------
    -- SCENARIO 2: EXISTING VIDEO REQUEST UPDATED (UPDATE)
    ----------------------------------------------------------------------------
    ELSIF TG_OP = 'UPDATE' THEN

        -- CASE 2A: Status changed to 'approved'
        IF (LOWER(COALESCE(OLD.admin_approval_status, '')) IS DISTINCT FROM 'approved') 
           AND LOWER(COALESCE(NEW.admin_approval_status, '')) = 'approved' THEN
            
            SELECT ARRAY_AGG(id) INTO v_target_user_ids
            FROM public.users
            WHERE LOWER(role) IN ('marketing', 'ads');

            IF v_target_user_ids IS NULL OR ARRAY_LENGTH(v_target_user_ids, 1) IS NULL THEN
                SELECT ARRAY_AGG(id) INTO v_target_user_ids
                FROM public.users
                WHERE LOWER(role) NOT IN ('broker');
            END IF;

            INSERT INTO public.notifications (
                receiver_ids,
                video_request_id,
                sender_id,
                title,
                description,
                notification_type,
                data
            ) VALUES (
                v_target_user_ids,
                NEW.id,
                v_target_broker_user_id,
                'New Approved Video Request',
                'A pending video request was approved and is now ready for production!',
                'video_request'::public.notification_type,
                jsonb_build_object(
                    'video_request_id', NEW.id,
                    'property_id', NEW.property_id,
                    'broker_id', NEW.broker_id,
                    'status', NEW.admin_approval_status
                )
            );

        -- CASE 2B: Status changed to 'rejected'
        ELSIF (LOWER(COALESCE(OLD.admin_approval_status, '')) IS DISTINCT FROM 'rejected')
           AND LOWER(COALESCE(NEW.admin_approval_status, '')) = 'rejected' THEN

            IF v_target_broker_user_id IS NOT NULL THEN
                INSERT INTO public.notifications (
                    receiver_ids,
                    video_request_id,
                    sender_id,
                    title,
                    description,
                    notification_type,
                    data
                ) VALUES (
                    ARRAY[v_target_broker_user_id],
                    NEW.id,
                    NULL,
                    'Video Request Rejected',
                    CASE 
                        WHEN NEW.admin_cancel_reason IS NOT NULL AND NEW.admin_cancel_reason != '' THEN 'Your video request was rejected: ' || NEW.admin_cancel_reason
                        WHEN NEW.cancel_reason IS NOT NULL AND NEW.cancel_reason != '' THEN 'Your video request was rejected: ' || NEW.cancel_reason
                        ELSE 'Your video request was rejected.'
                    END,
                    'video_request'::public.notification_type,
                    jsonb_build_object(
                        'video_request_id', NEW.id,
                        'property_id', NEW.property_id,
                        'broker_id', NEW.broker_id,
                        'status', NEW.admin_approval_status,
                        'reason', COALESCE(NEW.admin_cancel_reason, NEW.cancel_reason, '')
                    )
                );
            END IF;

        END IF;

    END IF;

    RETURN NEW;
EXCEPTION WHEN OTHERS THEN
    RAISE WARNING 'fn_video_requests_notification_handler warning: %', SQLERRM;
    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_video_requests_notification ON public.video_requests;
CREATE TRIGGER trg_video_requests_notification
AFTER INSERT OR UPDATE ON public.video_requests
FOR EACH ROW
EXECUTE FUNCTION public.fn_video_requests_notification_handler();


-- >>> Migration: 20260810200000_fix_video_request_notification_trigger.sql <<<
-- Migration: 20260810200000_fix_video_request_notification_trigger.sql
-- Purpose: Fix video_requests notification trigger for enum casting, broker_id user lookup, and guaranteed notification insertion.

CREATE OR REPLACE FUNCTION public.fn_video_requests_notification_handler()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_auto_approve BOOLEAN := FALSE;
    v_sender_user_id UUID := NULL;
    v_target_user_ids UUID[];
BEGIN
    -- 1. Fetch auto_approve setting for the requesting broker from public.brokers
    IF NEW.broker_id IS NOT NULL THEN
        SELECT COALESCE(auto_approve_video_requests, FALSE) INTO v_auto_approve
        FROM public.brokers
        WHERE id = NEW.broker_id;

        -- 2. Resolve sender_id (user linked to this broker_id)
        SELECT id INTO v_sender_user_id
        FROM public.users
        WHERE broker_id = NEW.broker_id OR id = NEW.broker_id
        LIMIT 1;
    END IF;

    ----------------------------------------------------------------------------
    -- SCENARIO 1: NEW VIDEO REQUEST CREATED (INSERT)
    ----------------------------------------------------------------------------
    IF TG_OP = 'INSERT' THEN

        -- CASE 1A: Auto Approve is TRUE or status is 'approved'
        IF v_auto_approve IS TRUE OR LOWER(COALESCE(NEW.admin_approval_status::text, '')) = 'approved' THEN
            -- Target all Marketing / Ads users
            SELECT ARRAY_AGG(id) INTO v_target_user_ids
            FROM public.users
            WHERE LOWER(role::text) IN ('marketing', 'ads');

            -- Fallback: Target all users if specific role array is empty
            IF v_target_user_ids IS NULL OR ARRAY_LENGTH(v_target_user_ids, 1) IS NULL THEN
                SELECT ARRAY_AGG(id) INTO v_target_user_ids
                FROM public.users;
            END IF;

            INSERT INTO public.notifications (
                receiver_ids,
                video_request_id,
                sender_id,
                title,
                description,
                notification_type,
                data
            ) VALUES (
                v_target_user_ids,
                NEW.id,
                v_sender_user_id,
                'New Approved Video Request',
                'A new video request has been submitted and approved. Ready for production!',
                'video_request'::public.notification_type,
                jsonb_build_object(
                    'video_request_id', NEW.id,
                    'property_id', NEW.property_id,
                    'broker_id', NEW.broker_id,
                    'status', NEW.admin_approval_status::text
                )
            );

        -- CASE 1B: Auto Approve is FALSE (admin_approval_status is 'pending')
        ELSE
            -- Target all Super Admin / Admin users
            SELECT ARRAY_AGG(id) INTO v_target_user_ids
            FROM public.users
            WHERE LOWER(role::text) IN ('super_admin', 'superadmin', 'admin');

            -- Fallback: Target all users if specific role array is empty
            IF v_target_user_ids IS NULL OR ARRAY_LENGTH(v_target_user_ids, 1) IS NULL THEN
                SELECT ARRAY_AGG(id) INTO v_target_user_ids
                FROM public.users;
            END IF;

            INSERT INTO public.notifications (
                receiver_ids,
                video_request_id,
                sender_id,
                title,
                description,
                notification_type,
                data
            ) VALUES (
                v_target_user_ids,
                NEW.id,
                v_sender_user_id,
                'Pending Video Request Review',
                'A new video request requires review and approval.',
                'video_request'::public.notification_type,
                jsonb_build_object(
                    'video_request_id', NEW.id,
                    'property_id', NEW.property_id,
                    'broker_id', NEW.broker_id,
                    'status', NEW.admin_approval_status::text
                )
            );
        END IF;

    ----------------------------------------------------------------------------
    -- SCENARIO 2: EXISTING VIDEO REQUEST UPDATED (UPDATE)
    ----------------------------------------------------------------------------
    ELSIF TG_OP = 'UPDATE' THEN

        -- CASE 2A: Status changed to 'approved'
        IF (LOWER(COALESCE(OLD.admin_approval_status::text, '')) IS DISTINCT FROM 'approved') 
           AND LOWER(COALESCE(NEW.admin_approval_status::text, '')) = 'approved' THEN
            
            SELECT ARRAY_AGG(id) INTO v_target_user_ids
            FROM public.users
            WHERE LOWER(role::text) IN ('marketing', 'ads');

            IF v_target_user_ids IS NULL OR ARRAY_LENGTH(v_target_user_ids, 1) IS NULL THEN
                SELECT ARRAY_AGG(id) INTO v_target_user_ids
                FROM public.users;
            END IF;

            INSERT INTO public.notifications (
                receiver_ids,
                video_request_id,
                sender_id,
                title,
                description,
                notification_type,
                data
            ) VALUES (
                v_target_user_ids,
                NEW.id,
                v_sender_user_id,
                'New Approved Video Request',
                'A pending video request was approved and is now ready for production!',
                'video_request'::public.notification_type,
                jsonb_build_object(
                    'video_request_id', NEW.id,
                    'property_id', NEW.property_id,
                    'broker_id', NEW.broker_id,
                    'status', NEW.admin_approval_status::text
                )
            );

        -- CASE 2B: Status changed to 'rejected'
        ELSIF (LOWER(COALESCE(OLD.admin_approval_status::text, '')) IS DISTINCT FROM 'rejected')
           AND LOWER(COALESCE(NEW.admin_approval_status::text, '')) = 'rejected' THEN

            IF v_sender_user_id IS NOT NULL THEN
                INSERT INTO public.notifications (
                    receiver_ids,
                    video_request_id,
                    sender_id,
                    title,
                    description,
                    notification_type,
                    data
                ) VALUES (
                    ARRAY[v_sender_user_id],
                    NEW.id,
                    NULL,
                    'Video Request Rejected',
                    CASE 
                        WHEN NEW.admin_cancel_reason IS NOT NULL AND NEW.admin_cancel_reason != '' THEN 'Your video request was rejected: ' || NEW.admin_cancel_reason
                        WHEN NEW.cancel_reason IS NOT NULL AND NEW.cancel_reason != '' THEN 'Your video request was rejected: ' || NEW.cancel_reason
                        ELSE 'Your video request was rejected.'
                    END,
                    'video_request'::public.notification_type,
                    jsonb_build_object(
                        'video_request_id', NEW.id,
                        'property_id', NEW.property_id,
                        'broker_id', NEW.broker_id,
                        'status', NEW.admin_approval_status::text,
                        'reason', COALESCE(NEW.admin_cancel_reason, NEW.cancel_reason, '')
                    )
                );
            END IF;

        END IF;

    END IF;

    RETURN NEW;
EXCEPTION WHEN OTHERS THEN
    RAISE WARNING 'fn_video_requests_notification_handler warning: %', SQLERRM;
    RETURN NEW;
END;
$$;

-- Re-attach video_requests trigger
DROP TRIGGER IF EXISTS trg_video_requests_notification ON public.video_requests;

CREATE TRIGGER trg_video_requests_notification
AFTER INSERT OR UPDATE ON public.video_requests
FOR EACH ROW
EXECUTE FUNCTION public.fn_video_requests_notification_handler();


-- >>> Migration: 20260811120000_update_video_request_notification_handler.sql <<<
-- Migration: 20260811120000_update_video_request_notification_handler.sql
-- Purpose: Update video_requests notification trigger handler to include detailed society name, flat number, landmark, and full address in descriptions, with role targeting and dual status data keys.

CREATE OR REPLACE FUNCTION public.fn_video_requests_notification_handler()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_auto_approve BOOLEAN := FALSE;
    v_sender_user_id UUID := NULL;
    v_target_user_ids UUID[];
    v_broker_name TEXT := 'Broker';
    v_property_title TEXT := '';
    v_property_location TEXT := 'Property Location';
    v_property_desc TEXT := '';
BEGIN
    -- 1. Fetch auto_approve setting & broker name for the requesting broker
    IF NEW.broker_id IS NOT NULL THEN
        SELECT COALESCE(b.auto_approve_video_requests, FALSE),
               COALESCE(NULLIF(TRIM(b.business_name), ''), NULLIF(TRIM(u.name), ''), 'Broker')
        INTO v_auto_approve, v_broker_name
        FROM public.brokers b
        LEFT JOIN public.users u ON (u.broker_id = b.id OR u.id = b.id)
        WHERE b.id = NEW.broker_id
        LIMIT 1;

        -- 2. Resolve sender_id (user linked to this broker_id)
        SELECT id INTO v_sender_user_id
        FROM public.users
        WHERE broker_id = NEW.broker_id OR id = NEW.broker_id
        LIMIT 1;
    END IF;

    -- 3. Resolve detailed property address & society/building location
    IF NEW.property_id IS NOT NULL THEN
        SELECT 
            COALESCE(TRIM(p.property_title), ''),
            COALESCE(
                NULLIF(TRIM(a.full_address), ''),
                NULLIF(TRIM(CONCAT_WS(', ', a.landmark, a.city, a.state)), ''),
                NULLIF(TRIM(CONCAT_WS(', ', a.city, a.state)), ''),
                NULLIF(TRIM(p.property_title), ''),
                'Property Location'
            )
        INTO v_property_title, v_property_location
        FROM public.properties p
        LEFT JOIN public.addresses a ON a.id = p.address_id
        WHERE p.id = NEW.property_id
        LIMIT 1;
    END IF;

    -- Build rich property description string (e.g., "3 BHK Apartment (Flat 402, Sunshine Heights, Bandra, Mumbai)")
    IF v_property_title IS NOT NULL AND v_property_title != '' THEN
        IF v_property_location IS NOT NULL AND v_property_location != '' AND v_property_location != v_property_title THEN
            v_property_desc := v_property_title || ' (' || v_property_location || ')';
        ELSE
            v_property_desc := v_property_title;
        END IF;
    ELSE
        v_property_desc := COALESCE(v_property_location, 'Property');
    END IF;

    ----------------------------------------------------------------------------
    -- SCENARIO 1: NEW VIDEO REQUEST CREATED (INSERT)
    ----------------------------------------------------------------------------
    IF TG_OP = 'INSERT' THEN

        -- CASE 1A: Auto Approve is TRUE or admin_approval_status is 'approved' -> Target Marketing Team ONLY
        IF v_auto_approve IS TRUE OR LOWER(COALESCE(NEW.admin_approval_status::text, '')) = 'approved' THEN
            SELECT ARRAY_AGG(id) INTO v_target_user_ids
            FROM public.users
            WHERE LOWER(role::text) IN ('marketing', 'ads');

            -- Fallback if no specific marketing users found
            IF v_target_user_ids IS NULL OR ARRAY_LENGTH(v_target_user_ids, 1) IS NULL THEN
                SELECT ARRAY_AGG(id) INTO v_target_user_ids
                FROM public.users;
            END IF;

            INSERT INTO public.notifications (
                receiver_ids,
                video_request_id,
                sender_id,
                title,
                description,
                notification_type,
                data
            ) VALUES (
                v_target_user_ids,
                NEW.id,
                v_sender_user_id,
                'New video request received',
                v_broker_name || ': ' || v_property_desc,
                'video_request'::public.notification_type,
                jsonb_build_object(
                    'video_request_id', NEW.id,
                    'property_id', NEW.property_id,
                    'broker_id', NEW.broker_id,
                    'admin_approval_status', COALESCE(NEW.admin_approval_status::text, 'approved'),
                    'status', COALESCE(NEW.status::text, 'pending')
                )
            );

        -- CASE 1B: Auto Approve is FALSE -> Target Admin Team ONLY for review
        ELSE
            SELECT ARRAY_AGG(id) INTO v_target_user_ids
            FROM public.users
            WHERE LOWER(role::text) IN ('super_admin', 'superadmin', 'admin');

            IF v_target_user_ids IS NULL OR ARRAY_LENGTH(v_target_user_ids, 1) IS NULL THEN
                SELECT ARRAY_AGG(id) INTO v_target_user_ids
                FROM public.users;
            END IF;

            INSERT INTO public.notifications (
                receiver_ids,
                video_request_id,
                sender_id,
                title,
                description,
                notification_type,
                data
            ) VALUES (
                v_target_user_ids,
                NEW.id,
                v_sender_user_id,
                'New video request received',
                v_broker_name || ': ' || v_property_desc,
                'video_request'::public.notification_type,
                jsonb_build_object(
                    'video_request_id', NEW.id,
                    'property_id', NEW.property_id,
                    'broker_id', NEW.broker_id,
                    'admin_approval_status', COALESCE(NEW.admin_approval_status::text, 'pending'),
                    'status', COALESCE(NEW.status::text, 'pending')
                )
            );
        END IF;

    ----------------------------------------------------------------------------
    -- SCENARIO 2: EXISTING VIDEO REQUEST UPDATED (UPDATE)
    ----------------------------------------------------------------------------
    ELSIF TG_OP = 'UPDATE' THEN

        -- CASE 2A: Admin Approval status changed to 'approved' -> Fire notification to Marketing Team ONLY
        IF (LOWER(COALESCE(OLD.admin_approval_status::text, '')) IS DISTINCT FROM 'approved') 
           AND LOWER(COALESCE(NEW.admin_approval_status::text, '')) = 'approved' THEN
            
            SELECT ARRAY_AGG(id) INTO v_target_user_ids
            FROM public.users
            WHERE LOWER(role::text) IN ('marketing', 'ads');

            IF v_target_user_ids IS NULL OR ARRAY_LENGTH(v_target_user_ids, 1) IS NULL THEN
                SELECT ARRAY_AGG(id) INTO v_target_user_ids
                FROM public.users;
            END IF;

            INSERT INTO public.notifications (
                receiver_ids,
                video_request_id,
                sender_id,
                title,
                description,
                notification_type,
                data
            ) VALUES (
                v_target_user_ids,
                NEW.id,
                v_sender_user_id,
                'New video request received',
                v_broker_name || ': ' || v_property_desc,
                'video_request'::public.notification_type,
                jsonb_build_object(
                    'video_request_id', NEW.id,
                    'property_id', NEW.property_id,
                    'broker_id', NEW.broker_id,
                    'admin_approval_status', NEW.admin_approval_status::text,
                    'status', NEW.status::text
                )
            );

        -- CASE 2B: Request Rejected by Admin OR Marketing Team -> Fire notification ONLY to Broker
        ELSIF ((LOWER(COALESCE(OLD.admin_approval_status::text, '')) IS DISTINCT FROM 'rejected')
               AND LOWER(COALESCE(NEW.admin_approval_status::text, '')) = 'rejected')
           OR ((LOWER(COALESCE(OLD.status::text, '')) IS DISTINCT FROM 'cancelled')
               AND LOWER(COALESCE(NEW.status::text, '')) = 'cancelled') THEN

            IF v_sender_user_id IS NOT NULL THEN
                INSERT INTO public.notifications (
                    receiver_ids,
                    video_request_id,
                    sender_id,
                    title,
                    description,
                    notification_type,
                    data
                ) VALUES (
                    ARRAY[v_sender_user_id],
                    NEW.id,
                    NULL,
                    'Video request is rejected',
                    CASE 
                        WHEN NEW.admin_cancel_reason IS NOT NULL AND TRIM(NEW.admin_cancel_reason) != '' THEN 'Reason: ' || TRIM(NEW.admin_cancel_reason)
                        WHEN NEW.cancel_reason IS NOT NULL AND TRIM(NEW.cancel_reason) != '' THEN 'Reason: ' || TRIM(NEW.cancel_reason)
                        ELSE 'Your video request for ' || v_property_desc || ' has been rejected.'
                    END,
                    'video_request'::public.notification_type,
                    jsonb_build_object(
                        'video_request_id', NEW.id,
                        'property_id', NEW.property_id,
                        'broker_id', NEW.broker_id,
                        'admin_approval_status', NEW.admin_approval_status::text,
                        'status', NEW.status::text,
                        'reason', COALESCE(NEW.admin_cancel_reason, NEW.cancel_reason, '')
                    )
                );
            END IF;

        -- CASE 2C: Status changed to 'in_progress' -> Fire notification ONLY to Broker
        ELSIF (LOWER(COALESCE(OLD.status::text, '')) IS DISTINCT FROM 'in_progress')
           AND LOWER(COALESCE(NEW.status::text, '')) = 'in_progress' THEN

            IF v_sender_user_id IS NOT NULL THEN
                INSERT INTO public.notifications (
                    receiver_ids,
                    video_request_id,
                    sender_id,
                    title,
                    description,
                    notification_type,
                    data
                ) VALUES (
                    ARRAY[v_sender_user_id],
                    NEW.id,
                    NULL,
                    'Video shoot in progress',
                    'Your video shoot for ' || v_property_desc || ' has started and is now in progress.',
                    'video_request'::public.notification_type,
                    jsonb_build_object(
                        'video_request_id', NEW.id,
                        'property_id', NEW.property_id,
                        'broker_id', NEW.broker_id,
                        'admin_approval_status', NEW.admin_approval_status::text,
                        'status', NEW.status::text
                    )
                );
            END IF;

        -- CASE 2D: Status changed to 'completed' -> Fire notification ONLY to Broker
        ELSIF (LOWER(COALESCE(OLD.status::text, '')) IS DISTINCT FROM 'completed')
           AND LOWER(COALESCE(NEW.status::text, '')) = 'completed' THEN

            IF v_sender_user_id IS NOT NULL THEN
                INSERT INTO public.notifications (
                    receiver_ids,
                    video_request_id,
                    sender_id,
                    title,
                    description,
                    notification_type,
                    data
                ) VALUES (
                    ARRAY[v_sender_user_id],
                    NEW.id,
                    NULL,
                    'Video request completed',
                    'Your video request for ' || v_property_desc || ' is ready! Check your dashboard.',
                    'video_request'::public.notification_type,
                    jsonb_build_object(
                        'video_request_id', NEW.id,
                        'property_id', NEW.property_id,
                        'broker_id', NEW.broker_id,
                        'admin_approval_status', NEW.admin_approval_status::text,
                        'status', NEW.status::text
                    )
                );
            END IF;

        -- CASE 2E: Status changed to 'assigned' -> Fire notification ONLY to Broker
        ELSIF (LOWER(COALESCE(OLD.status::text, '')) IS DISTINCT FROM 'assigned')
           AND LOWER(COALESCE(NEW.status::text, '')) = 'assigned' THEN

            IF v_sender_user_id IS NOT NULL THEN
                INSERT INTO public.notifications (
                    receiver_ids,
                    video_request_id,
                    sender_id,
                    title,
                    description,
                    notification_type,
                    data
                ) VALUES (
                    ARRAY[v_sender_user_id],
                    NEW.id,
                    NULL,
                    'Video request assigned',
                    'Your video request for ' || v_property_desc || ' has been assigned to our marketing team.',
                    'video_request'::public.notification_type,
                    jsonb_build_object(
                        'video_request_id', NEW.id,
                        'property_id', NEW.property_id,
                        'broker_id', NEW.broker_id,
                        'admin_approval_status', NEW.admin_approval_status::text,
                        'status', NEW.status::text
                    )
                );
            END IF;

        END IF;

    END IF;

    RETURN NEW;
EXCEPTION WHEN OTHERS THEN
    RAISE WARNING 'fn_video_requests_notification_handler warning: %', SQLERRM;
    RETURN NEW;
END;
$$;

-- Re-attach video_requests trigger
DROP TRIGGER IF EXISTS trg_video_requests_notification ON public.video_requests;

CREATE TRIGGER trg_video_requests_notification
AFTER INSERT OR UPDATE ON public.video_requests
FOR EACH ROW
EXECUTE FUNCTION public.fn_video_requests_notification_handler();


-- >>> Migration: 20260811130000_update_fetch_video_requests_ordering.sql <<<
-- Migration: 20260811130000_update_fetch_video_requests_ordering.sql
-- Purpose: Update fetch_video_requests RPC to order records by updated_at > completed_at > created_at DESC instead of created_at only.

CREATE OR REPLACE FUNCTION public.fetch_video_requests(
  p_broker_id UUID DEFAULT NULL,
  p_page INT DEFAULT 1,
  p_limit INT DEFAULT 10,
  p_search_query TEXT DEFAULT '',
  p_admin_approved_status public.video_request_approval_status DEFAULT NULL,
  p_status public.video_request_status DEFAULT NULL,
  p_statuses TEXT[] DEFAULT NULL
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_offset INT;
  v_total_items INT;
  v_total_pages INT;
  v_has_more BOOLEAN;
  v_requests_json JSONB;
BEGIN
  -- Calculate offset for pagination
  v_offset := (p_page - 1) * p_limit;

  -- 1. Calculate total items matching the filter
  SELECT COUNT(*)
  INTO v_total_items
  FROM public.video_requests vr
  JOIN public.properties p ON vr.property_id = p.id
  JOIN public.brokers b ON vr.broker_id = b.id
  LEFT JOIN public.addresses a ON p.address_id = a.id
  WHERE (p_broker_id IS NULL OR vr.broker_id = p_broker_id)
    AND (p_admin_approved_status IS NULL OR vr.admin_approval_status = p_admin_approved_status)
    AND (p_status IS NULL OR vr.status = p_status)
    AND (p_statuses IS NULL OR array_length(p_statuses, 1) IS NULL OR vr.status::text = ANY(p_statuses))
    AND (
      p_search_query = '' OR
      p.property_title ILIKE '%' || p_search_query || '%' OR
      b.business_name ILIKE '%' || p_search_query || '%' OR
      vr.notes ILIKE '%' || p_search_query || '%' OR
      (a.id IS NOT NULL AND (
         a.full_address ILIKE '%' || p_search_query || '%' OR
         a.city ILIKE '%' || p_search_query || '%' OR
         a.state ILIKE '%' || p_search_query || '%'
      ))
    );

  -- Calculate pagination details
  IF v_total_items = 0 THEN
    v_total_pages := 1;
    v_has_more := false;
  ELSE
    v_total_pages := CEIL(v_total_items::NUMERIC / p_limit)::INT;
    v_has_more := (p_page * p_limit) < v_total_items;
  END IF;

  -- 2. Fetch the video requests with pagination, ordering by updated_at > completed_at > created_at DESC, and nested serialization
  SELECT COALESCE(jsonb_agg(
    to_jsonb(vr_data) ||
    jsonb_build_object(
      'property', 
      to_jsonb(p_data) || jsonb_build_object(
        'address',
        CASE 
          WHEN p_data.address_id IS NOT NULL THEN to_jsonb(pa_data)
          ELSE NULL
        END
      ),
      'broker',
      to_jsonb(b_data) || jsonb_build_object(
        'address',
        CASE 
          WHEN b_data.address_id IS NOT NULL THEN to_jsonb(ba_data)
          ELSE NULL
        END
      )
    )
  ), '[]'::jsonb)
  INTO v_requests_json
  FROM (
    SELECT vr.*
    FROM public.video_requests vr
    JOIN public.properties p ON vr.property_id = p.id
    JOIN public.brokers b ON vr.broker_id = b.id
    LEFT JOIN public.addresses a ON p.address_id = a.id
    WHERE (p_broker_id IS NULL OR vr.broker_id = p_broker_id)
      AND (p_admin_approved_status IS NULL OR vr.admin_approval_status = p_admin_approved_status)
      AND (p_status IS NULL OR vr.status = p_status)
      AND (p_statuses IS NULL OR array_length(p_statuses, 1) IS NULL OR vr.status::text = ANY(p_statuses))
      AND (
        p_search_query = '' OR
        p.property_title ILIKE '%' || p_search_query || '%' OR
        b.business_name ILIKE '%' || p_search_query || '%' OR
        vr.notes ILIKE '%' || p_search_query || '%' OR
        (a.id IS NOT NULL AND (
           a.full_address ILIKE '%' || p_search_query || '%' OR
           a.city ILIKE '%' || p_search_query || '%' OR
           a.state ILIKE '%' || p_search_query || '%'
        ))
      )
    ORDER BY COALESCE(vr.updated_at, vr.completed_at, vr.created_at) DESC, vr.created_at DESC
    LIMIT p_limit OFFSET v_offset
  ) vr_data
  JOIN public.properties p_data ON vr_data.property_id = p_data.id
  JOIN public.brokers b_data ON vr_data.broker_id = b_data.id
  LEFT JOIN public.addresses pa_data ON p_data.address_id = pa_data.id
  LEFT JOIN public.addresses ba_data ON b_data.address_id = ba_data.id;

  RETURN jsonb_build_object(
    'success', true,
    'data', v_requests_json,
    'pagination', jsonb_build_object(
      'current_page', p_page,
      'limit', p_limit,
      'total_items', v_total_items,
      'total_pages', v_total_pages,
      'has_more', v_has_more
    )
  );
EXCEPTION WHEN OTHERS THEN
  RETURN jsonb_build_object(
    'success', false,
    'message', SQLERRM
  );
END;
$$;


-- >>> Migration: 20260811140000_create_fetch_dashboard_summary.sql <<<
-- Migration: Create fetch_dashboard_summary RPC function
-- Purpose: Compute & return JSONB summary metrics (todays_leads, todays_leads_growth, total_leads, total_properties, video_requests) for a broker.

CREATE OR REPLACE FUNCTION public.fetch_dashboard_summary(p_broker_id UUID)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_todays_leads INT := 0;
  v_yesterdays_leads INT := 0;
  v_growth_str TEXT := '+0%';
  v_total_leads INT := 0;
  v_total_properties INT := 0;
  v_video_requests INT := 0;
BEGIN
  -- 1. Today's leads count for broker
  SELECT COUNT(*)
  INTO v_todays_leads
  FROM public.social_leads
  WHERE broker_id = p_broker_id
    AND DATE(created_at AT TIME ZONE 'UTC') = CURRENT_DATE;

  -- 2. Yesterday's leads count for broker (to calculate growth)
  SELECT COUNT(*)
  INTO v_yesterdays_leads
  FROM public.social_leads
  WHERE broker_id = p_broker_id
    AND DATE(created_at AT TIME ZONE 'UTC') = CURRENT_DATE - INTERVAL '1 day';

  IF v_yesterdays_leads = 0 THEN
    IF v_todays_leads > 0 THEN
      v_growth_str := '+' || (v_todays_leads * 100)::TEXT || '%';
    ELSE
      v_growth_str := '+0%';
    END IF;
  ELSE
    DECLARE
      v_diff NUMERIC;
    BEGIN
      v_diff := ((v_todays_leads - v_yesterdays_leads)::NUMERIC / v_yesterdays_leads::NUMERIC) * 100.0;
      IF v_diff >= 0 THEN
        v_growth_str := '+' || ROUND(v_diff, 0)::TEXT || '%';
      ELSE
        v_growth_str := ROUND(v_diff, 0)::TEXT || '%';
      END IF;
    END;
  END IF;

  -- 3. Total leads count for broker
  SELECT COUNT(*)
  INTO v_total_leads
  FROM public.social_leads
  WHERE broker_id = p_broker_id;

  -- 4. Active properties count for broker
  SELECT COUNT(*)
  INTO v_total_properties
  FROM public.properties
  WHERE broker_id = p_broker_id
    AND LOWER(status) != 'deleted';

  -- 5. Active video requests count for broker
  SELECT COUNT(*)
  INTO v_video_requests
  FROM public.video_requests
  WHERE broker_id = p_broker_id
    AND LOWER(status) IN ('pending', 'accepted', 'in_progress');

  RETURN jsonb_build_object(
    'todays_leads', v_todays_leads,
    'todays_leads_growth', v_growth_str,
    'total_leads', v_total_leads,
    'total_properties', v_total_properties,
    'video_requests', v_video_requests
  );
END;
$$;

GRANT EXECUTE ON FUNCTION public.fetch_dashboard_summary(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION public.fetch_dashboard_summary(UUID) TO service_role;


-- >>> Migration: 20260812110000_update_all_rpcs_and_soft_delete_policies.sql <<<
-- Migration: 20260812110000_update_all_rpcs_and_soft_delete_policies.sql
-- Purpose: 
-- 1. Create/Update RLS policies on properties, social_leads, and video_requests so soft-deleted (is_deleted = true) rows are hidden from regular queries unless requested by an admin role.
-- 2. Update RPC functions (fetch_dashboard_summary, get_social_leads, fetch_properties, fetch_video_requests, fetch_video_request_counts) to cleanly handle column schemas and exclude soft-deleted records.

-- =============================================================================
-- PART 1: RLS POLICIES FOR SOFT-DELETED RECORDS
-- =============================================================================

ALTER TABLE public.properties ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.social_leads ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.video_requests ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Hide soft-deleted properties for non-admins" ON public.properties;
CREATE POLICY "Hide soft-deleted properties for non-admins" ON public.properties
  FOR SELECT
  USING (
    (is_deleted IS FALSE OR is_deleted IS NULL)
    OR EXISTS (
      SELECT 1 FROM public.users u
      WHERE u.id = auth.uid()
        AND LOWER(u.role::text) IN ('super_admin', 'superadmin', 'admin')
    )
  );

DROP POLICY IF EXISTS "Hide soft-deleted social leads for non-admins" ON public.social_leads;
CREATE POLICY "Hide soft-deleted social leads for non-admins" ON public.social_leads
  FOR SELECT
  USING (
    (is_deleted IS FALSE OR is_deleted IS NULL)
    OR EXISTS (
      SELECT 1 FROM public.users u
      WHERE u.id = auth.uid()
        AND LOWER(u.role::text) IN ('super_admin', 'superadmin', 'admin')
    )
  );

DROP POLICY IF EXISTS "Hide soft-deleted video requests for non-admins" ON public.video_requests;
CREATE POLICY "Hide soft-deleted video requests for non-admins" ON public.video_requests
  FOR SELECT
  USING (
    (is_deleted IS FALSE OR is_deleted IS NULL)
    OR EXISTS (
      SELECT 1 FROM public.users u
      WHERE u.id = auth.uid()
        AND LOWER(u.role::text) IN ('super_admin', 'superadmin', 'admin')
    )
  );

-- =============================================================================
-- PART 2: RPC FUNCTION 1 - fetch_dashboard_summary
-- =============================================================================

CREATE OR REPLACE FUNCTION public.fetch_dashboard_summary(p_broker_id UUID)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_todays_leads INT := 0;
  v_yesterdays_leads INT := 0;
  v_growth_str TEXT := '+0%';
  v_total_leads INT := 0;
  v_total_properties INT := 0;
  v_video_requests INT := 0;
BEGIN
  -- 1. Today's leads count for broker
  SELECT COUNT(*)
  INTO v_todays_leads
  FROM public.social_leads
  WHERE broker_id = p_broker_id
    AND (is_deleted IS FALSE OR is_deleted IS NULL)
    AND DATE(created_at AT TIME ZONE 'UTC') = CURRENT_DATE;

  -- 2. Yesterday's leads count for broker (to calculate growth)
  SELECT COUNT(*)
  INTO v_yesterdays_leads
  FROM public.social_leads
  WHERE broker_id = p_broker_id
    AND (is_deleted IS FALSE OR is_deleted IS NULL)
    AND DATE(created_at AT TIME ZONE 'UTC') = CURRENT_DATE - INTERVAL '1 day';

  IF v_yesterdays_leads = 0 THEN
    IF v_todays_leads > 0 THEN
      v_growth_str := '+' || (v_todays_leads * 100)::TEXT || '%';
    ELSE
      v_growth_str := '+0%';
    END IF;
  ELSE
    DECLARE
      v_diff NUMERIC;
    BEGIN
      v_diff := ((v_todays_leads - v_yesterdays_leads)::NUMERIC / v_yesterdays_leads::NUMERIC) * 100.0;
      IF v_diff >= 0 THEN
        v_growth_str := '+' || ROUND(v_diff, 0)::TEXT || '%';
      ELSE
        v_growth_str := ROUND(v_diff, 0)::TEXT || '%';
      END IF;
    END;
  END IF;

  -- 3. Total leads count for broker
  SELECT COUNT(*)
  INTO v_total_leads
  FROM public.social_leads
  WHERE broker_id = p_broker_id
    AND (is_deleted IS FALSE OR is_deleted IS NULL);

  -- 4. Total non-deleted properties count for broker
  SELECT COUNT(*)
  INTO v_total_properties
  FROM public.properties
  WHERE broker_id = p_broker_id
    AND (is_deleted IS FALSE OR is_deleted IS NULL);

  -- 5. Active video requests count for broker (pending or in_progress)
  SELECT COUNT(*)
  INTO v_video_requests
  FROM public.video_requests
  WHERE broker_id = p_broker_id
    AND (is_deleted IS FALSE OR is_deleted IS NULL)
    AND LOWER(status::text) IN ('pending', 'assigned', 'in_progress');

  RETURN jsonb_build_object(
    'todays_leads', v_todays_leads,
    'todays_leads_growth', v_growth_str,
    'total_leads', v_total_leads,
    'total_properties', v_total_properties,
    'video_requests', v_video_requests
  );
END;
$$;

GRANT EXECUTE ON FUNCTION public.fetch_dashboard_summary(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION public.fetch_dashboard_summary(UUID) TO service_role;

-- =============================================================================
-- PART 3: RPC FUNCTION 2 - get_social_leads
-- =============================================================================

CREATE OR REPLACE FUNCTION public.get_social_leads(
  p_broker_id UUID DEFAULT NULL,
  p_page INT DEFAULT 1,
  p_limit INT DEFAULT 10,
  p_search_query TEXT DEFAULT '',
  p_platforms TEXT[] DEFAULT NULL
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_offset INT;
  v_total_items INT;
  v_total_pages INT;
  v_has_more BOOLEAN;
  v_leads_json JSONB;
BEGIN
  v_offset := (p_page - 1) * p_limit;

  -- 1. Calculate total items matching the filter (excluding deleted leads)
  SELECT COUNT(*)
  INTO v_total_items
  FROM public.social_leads sl
  LEFT JOIN public.social_posts sp ON sl.social_post_id = sp.id
  LEFT JOIN public.properties p ON sp.property_id = p.id
  LEFT JOIN public.addresses a ON p.address_id = a.id
  WHERE (p_broker_id IS NULL OR sl.broker_id = p_broker_id)
    AND (sl.is_deleted IS FALSE OR sl.is_deleted IS NULL)
    AND (
      p_platforms IS NULL 
      OR array_length(p_platforms, 1) IS NULL 
      OR array_length(p_platforms, 1) = 0
      OR (
        'other' = ANY(ARRAY(SELECT LOWER(unnest(p_platforms)))) AND (
          sl.social_post_id IS NULL OR LOWER(COALESCE(sp.platform::text, '')) NOT IN ('facebook', 'instagram')
        )
      )
      OR LOWER(COALESCE(sp.platform::text, '')) = ANY(ARRAY(SELECT LOWER(unnest(p_platforms))))
    )
    AND (
      p_search_query = '' OR
      sl.user_name ILIKE '%' || p_search_query || '%' OR
      sl.phone ILIKE '%' || p_search_query || '%' OR
      sl.property_details ILIKE '%' || p_search_query || '%' OR
      sl.notes ILIKE '%' || p_search_query || '%' OR
      (sp.id IS NOT NULL AND sp.caption ILIKE '%' || p_search_query || '%') OR
      (p.id IS NOT NULL AND p.property_title ILIKE '%' || p_search_query || '%')
    );

  IF v_total_items = 0 THEN
    v_total_pages := 1;
    v_has_more := false;
  ELSE
    v_total_pages := CEIL(v_total_items::NUMERIC / p_limit)::INT;
    v_has_more := (p_page * p_limit) < v_total_items;
  END IF;

  -- 2. Fetch leads with pagination
  SELECT COALESCE(jsonb_agg(
    to_jsonb(sl_data) ||
    jsonb_build_object(
      'social_posts',
      CASE 
        WHEN sp_data.id IS NOT NULL THEN
          to_jsonb(sp_data) || jsonb_build_object(
            'properties',
            CASE 
              WHEN p_data.id IS NOT NULL THEN
                to_jsonb(p_data) || jsonb_build_object(
                  'address',
                  CASE 
                    WHEN a_data.id IS NOT NULL THEN to_jsonb(a_data)
                    ELSE NULL
                  END
                )
              ELSE NULL
            END
          )
        ELSE NULL
      END,
      'broker',
      CASE 
        WHEN b_data.id IS NOT NULL THEN to_jsonb(b_data)
        ELSE NULL
      END
    )
  ), '[]'::jsonb)
  INTO v_leads_json
  FROM (
    SELECT sl.*
    FROM public.social_leads sl
    LEFT JOIN public.social_posts sp ON sl.social_post_id = sp.id
    LEFT JOIN public.properties p ON sp.property_id = p.id
    LEFT JOIN public.addresses a ON p.address_id = a.id
    WHERE (p_broker_id IS NULL OR sl.broker_id = p_broker_id)
      AND (sl.is_deleted IS FALSE OR sl.is_deleted IS NULL)
      AND (
        p_platforms IS NULL 
        OR array_length(p_platforms, 1) IS NULL 
        OR array_length(p_platforms, 1) = 0
        OR (
          'other' = ANY(ARRAY(SELECT LOWER(unnest(p_platforms)))) AND (
            sl.social_post_id IS NULL OR LOWER(COALESCE(sp.platform::text, '')) NOT IN ('facebook', 'instagram')
          )
        )
        OR LOWER(COALESCE(sp.platform::text, '')) = ANY(ARRAY(SELECT LOWER(unnest(p_platforms))))
      )
      AND (
        p_search_query = '' OR
        sl.user_name ILIKE '%' || p_search_query || '%' OR
        sl.phone ILIKE '%' || p_search_query || '%' OR
        sl.property_details ILIKE '%' || p_search_query || '%' OR
        sl.notes ILIKE '%' || p_search_query || '%' OR
        (sp.id IS NOT NULL AND sp.caption ILIKE '%' || p_search_query || '%') OR
        (p.id IS NOT NULL AND p.property_title ILIKE '%' || p_search_query || '%')
      )
    ORDER BY sl.created_at DESC
    LIMIT p_limit OFFSET v_offset
  ) sl_data
  LEFT JOIN public.social_posts sp_data ON sl_data.social_post_id = sp_data.id
  LEFT JOIN public.properties p_data ON sp_data.property_id = p_data.id
  LEFT JOIN public.brokers b_data ON sl_data.broker_id = b_data.id
  LEFT JOIN public.addresses a_data ON p_data.address_id = a_data.id;

  RETURN jsonb_build_object(
    'success', true,
    'data', v_leads_json,
    'pagination', jsonb_build_object(
      'current_page', p_page,
      'limit', p_limit,
      'total_items', v_total_items,
      'total_pages', v_total_pages,
      'has_more', v_has_more
    )
  );
EXCEPTION WHEN OTHERS THEN
  RETURN jsonb_build_object(
    'success', false,
    'message', SQLERRM
  );
END;
$$;

GRANT EXECUTE ON FUNCTION public.get_social_leads(UUID, INT, INT, TEXT, TEXT[]) TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_social_leads(UUID, INT, INT, TEXT, TEXT[]) TO service_role;

-- =============================================================================
-- PART 4: RPC FUNCTION 3 - fetch_video_requests
-- =============================================================================

CREATE OR REPLACE FUNCTION public.fetch_video_requests(
  p_broker_id UUID DEFAULT NULL,
  p_page INT DEFAULT 1,
  p_limit INT DEFAULT 10,
  p_search_query TEXT DEFAULT '',
  p_admin_approved_status public.video_request_approval_status DEFAULT NULL,
  p_status public.video_request_status DEFAULT NULL,
  p_statuses TEXT[] DEFAULT NULL
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_offset INT;
  v_total_items INT;
  v_total_pages INT;
  v_has_more BOOLEAN;
  v_requests_json JSONB;
BEGIN
  v_offset := (p_page - 1) * p_limit;

  -- 1. Calculate total items matching the filter (excluding deleted video_requests & properties)
  SELECT COUNT(*)
  INTO v_total_items
  FROM public.video_requests vr
  JOIN public.properties p ON vr.property_id = p.id
  JOIN public.brokers b ON vr.broker_id = b.id
  LEFT JOIN public.addresses a ON p.address_id = a.id
  WHERE (p_broker_id IS NULL OR vr.broker_id = p_broker_id)
    AND (vr.is_deleted IS FALSE OR vr.is_deleted IS NULL)
    AND (p.is_deleted IS FALSE OR p.is_deleted IS NULL)
    AND (p_admin_approved_status IS NULL OR vr.admin_approval_status = p_admin_approved_status)
    AND (p_status IS NULL OR vr.status = p_status)
    AND (p_statuses IS NULL OR array_length(p_statuses, 1) IS NULL OR vr.status::text = ANY(p_statuses))
    AND (
      p_search_query = '' OR
      p.property_title ILIKE '%' || p_search_query || '%' OR
      b.business_name ILIKE '%' || p_search_query || '%' OR
      vr.notes ILIKE '%' || p_search_query || '%' OR
      (a.id IS NOT NULL AND (
         a.full_address ILIKE '%' || p_search_query || '%' OR
         a.city ILIKE '%' || p_search_query || '%' OR
         a.state ILIKE '%' || p_search_query || '%'
      ))
    );

  IF v_total_items = 0 THEN
    v_total_pages := 1;
    v_has_more := false;
  ELSE
    v_total_pages := CEIL(v_total_items::NUMERIC / p_limit)::INT;
    v_has_more := (p_page * p_limit) < v_total_items;
  END IF;

  -- 2. Fetch the video requests with pagination
  SELECT COALESCE(jsonb_agg(
    to_jsonb(vr_data) ||
    jsonb_build_object(
      'property', 
      to_jsonb(p_data) || jsonb_build_object(
        'address',
        CASE 
          WHEN p_data.address_id IS NOT NULL THEN to_jsonb(pa_data)
          ELSE NULL
        END
      ),
      'broker',
      to_jsonb(b_data) || jsonb_build_object(
        'address',
        CASE 
          WHEN b_data.address_id IS NOT NULL THEN to_jsonb(ba_data)
          ELSE NULL
        END
      )
    )
  ), '[]'::jsonb)
  INTO v_requests_json
  FROM (
    SELECT vr.*
    FROM public.video_requests vr
    JOIN public.properties p ON vr.property_id = p.id
    JOIN public.brokers b ON vr.broker_id = b.id
    LEFT JOIN public.addresses a ON p.address_id = a.id
    WHERE (p_broker_id IS NULL OR vr.broker_id = p_broker_id)
      AND (vr.is_deleted IS FALSE OR vr.is_deleted IS NULL)
      AND (p.is_deleted IS FALSE OR p.is_deleted IS NULL)
      AND (p_admin_approved_status IS NULL OR vr.admin_approval_status = p_admin_approved_status)
      AND (p_status IS NULL OR vr.status = p_status)
      AND (p_statuses IS NULL OR array_length(p_statuses, 1) IS NULL OR vr.status::text = ANY(p_statuses))
      AND (
        p_search_query = '' OR
        p.property_title ILIKE '%' || p_search_query || '%' OR
        b.business_name ILIKE '%' || p_search_query || '%' OR
        vr.notes ILIKE '%' || p_search_query || '%' OR
        (a.id IS NOT NULL AND (
           a.full_address ILIKE '%' || p_search_query || '%' OR
           a.city ILIKE '%' || p_search_query || '%' OR
           a.state ILIKE '%' || p_search_query || '%'
        ))
      )
    ORDER BY COALESCE(vr.updated_at, vr.completed_at, vr.created_at) DESC, vr.created_at DESC
    LIMIT p_limit OFFSET v_offset
  ) vr_data
  JOIN public.properties p_data ON vr_data.property_id = p_data.id
  JOIN public.brokers b_data ON vr_data.broker_id = b_data.id
  LEFT JOIN public.addresses pa_data ON p_data.address_id = pa_data.id
  LEFT JOIN public.addresses ba_data ON b_data.address_id = ba_data.id;

  RETURN jsonb_build_object(
    'success', true,
    'data', v_requests_json,
    'pagination', jsonb_build_object(
      'current_page', p_page,
      'limit', p_limit,
      'total_items', v_total_items,
      'total_pages', v_total_pages,
      'has_more', v_has_more
    )
  );
EXCEPTION WHEN OTHERS THEN
  RETURN jsonb_build_object(
    'success', false,
    'message', SQLERRM
  );
END;
$$;

GRANT EXECUTE ON FUNCTION public.fetch_video_requests(UUID, INT, INT, TEXT, public.video_request_approval_status, public.video_request_status, TEXT[]) TO authenticated;
GRANT EXECUTE ON FUNCTION public.fetch_video_requests(UUID, INT, INT, TEXT, public.video_request_approval_status, public.video_request_status, TEXT[]) TO service_role;

-- =============================================================================
-- PART 5: RPC FUNCTION 4 - fetch_video_request_counts
-- =============================================================================

CREATE OR REPLACE FUNCTION public.fetch_video_request_counts(
  p_broker_id UUID DEFAULT NULL,
  p_admin_approved_status public.video_request_approval_status DEFAULT NULL,
  p_status public.video_request_status DEFAULT NULL
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_total INT;
  v_pending INT;
  v_in_progress INT;
  v_completed INT;
  v_cancelled INT;
BEGIN
  -- Total count includes all non-deleted matching requests
  SELECT COUNT(*) INTO v_total
  FROM public.video_requests
  WHERE (p_broker_id IS NULL OR broker_id = p_broker_id)
    AND (is_deleted IS FALSE OR is_deleted IS NULL)
    AND (p_admin_approved_status IS NULL OR admin_approval_status = p_admin_approved_status)
    AND (p_status IS NULL OR status = p_status);

  -- Pending count
  SELECT COUNT(*) INTO v_pending
  FROM public.video_requests
  WHERE (p_broker_id IS NULL OR broker_id = p_broker_id)
    AND (is_deleted IS FALSE OR is_deleted IS NULL)
    AND (p_admin_approved_status IS NULL OR admin_approval_status = p_admin_approved_status)
    AND (p_status IS NULL OR status = p_status)
    AND status = 'pending'::public.video_request_status;

  -- In-progress count
  SELECT COUNT(*) INTO v_in_progress
  FROM public.video_requests
  WHERE (p_broker_id IS NULL OR broker_id = p_broker_id)
    AND (is_deleted IS FALSE OR is_deleted IS NULL)
    AND (p_admin_approved_status IS NULL OR admin_approval_status = p_admin_approved_status)
    AND (p_status IS NULL OR status = p_status)
    AND status IN ('assigned'::public.video_request_status, 'in_progress'::public.video_request_status);

  -- Completed count
  SELECT COUNT(*) INTO v_completed
  FROM public.video_requests
  WHERE (p_broker_id IS NULL OR broker_id = p_broker_id)
    AND (is_deleted IS FALSE OR is_deleted IS NULL)
    AND (p_admin_approved_status IS NULL OR admin_approval_status = p_admin_approved_status)
    AND (p_status IS NULL OR status = p_status)
    AND status = 'completed'::public.video_request_status;

  -- Cancelled count
  SELECT COUNT(*) INTO v_cancelled
  FROM public.video_requests
  WHERE (p_broker_id IS NULL OR broker_id = p_broker_id)
    AND (is_deleted IS FALSE OR is_deleted IS NULL)
    AND (p_admin_approved_status IS NULL OR admin_approval_status = p_admin_approved_status)
    AND (p_status IS NULL OR status = p_status)
    AND status = 'cancelled'::public.video_request_status;

  RETURN jsonb_build_object(
    'total', v_total,
    'pending', v_pending,
    'in_progress', v_in_progress,
    'completed', v_completed,
    'cancelled', v_cancelled
  );
END;
$$;

GRANT EXECUTE ON FUNCTION public.fetch_video_request_counts(UUID, public.video_request_approval_status, public.video_request_status) TO authenticated;
GRANT EXECUTE ON FUNCTION public.fetch_video_request_counts(UUID, public.video_request_approval_status, public.video_request_status) TO service_role;


-- >>> Migration: 20260812113000_add_cancelled_by_user_id_and_update_notification_trigger.sql <<<
-- Migration: 20260812113000_add_cancelled_by_user_id_and_update_notification_trigger.sql
-- Purpose:
-- 1. Add cancelled_by_user_id column to video_requests table.
-- 2. Update fn_video_requests_notification_handler trigger function to route cancellation notifications based on cancelled_by_user_id role (broker vs marketing/admin).
-- 3. Update fetch_video_requests RPC to serialize cancelled_by_user_id object (UserModel) in nested JSON output.

-- 1. Add cancelled_by_user_id column to video_requests
ALTER TABLE public.video_requests
ADD COLUMN IF NOT EXISTS cancelled_by_user_id UUID NULL REFERENCES public.users(id) ON DELETE SET NULL;

CREATE INDEX IF NOT EXISTS idx_video_requests_cancelled_by_user_id ON public.video_requests USING btree (cancelled_by_user_id);

-- 2. Update fn_video_requests_notification_handler trigger function
CREATE OR REPLACE FUNCTION public.fn_video_requests_notification_handler()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_auto_approve BOOLEAN := FALSE;
    v_sender_user_id UUID := NULL;
    v_target_user_ids UUID[];
    v_broker_name TEXT := 'Broker';
    v_property_title TEXT := '';
    v_property_location TEXT := 'Property Location';
    v_property_desc TEXT := '';
    v_canceller_role TEXT := NULL;
    v_canceller_name TEXT := '';
BEGIN
    -- 1. Fetch auto_approve setting & broker name for the requesting broker
    IF NEW.broker_id IS NOT NULL THEN
        SELECT COALESCE(b.auto_approve_video_requests, FALSE),
               COALESCE(NULLIF(TRIM(b.business_name), ''), NULLIF(TRIM(u.name), ''), 'Broker')
        INTO v_auto_approve, v_broker_name
        FROM public.brokers b
        LEFT JOIN public.users u ON (u.broker_id = b.id OR u.id = b.id)
        WHERE b.id = NEW.broker_id
        LIMIT 1;

        -- 2. Resolve sender_id (user linked to this broker_id)
        SELECT id INTO v_sender_user_id
        FROM public.users
        WHERE broker_id = NEW.broker_id OR id = NEW.broker_id
        LIMIT 1;
    END IF;

    -- 3. Resolve detailed property address & society/building location
    IF NEW.property_id IS NOT NULL THEN
        SELECT 
            COALESCE(TRIM(p.property_title), ''),
            COALESCE(
                NULLIF(TRIM(a.full_address), ''),
                NULLIF(TRIM(CONCAT_WS(', ', a.landmark, a.city, a.state)), ''),
                NULLIF(TRIM(CONCAT_WS(', ', a.city, a.state)), ''),
                NULLIF(TRIM(p.property_title), ''),
                'Property Location'
            )
        INTO v_property_title, v_property_location
        FROM public.properties p
        LEFT JOIN public.addresses a ON a.id = p.address_id
        WHERE p.id = NEW.property_id
        LIMIT 1;
    END IF;

    -- Build rich property description string
    IF v_property_title IS NOT NULL AND v_property_title != '' THEN
        IF v_property_location IS NOT NULL AND v_property_location != '' AND v_property_location != v_property_title THEN
            v_property_desc := v_property_title || ' (' || v_property_location || ')';
        ELSE
            v_property_desc := v_property_title;
        END IF;
    ELSE
        v_property_desc := COALESCE(v_property_location, 'Property');
    END IF;

    ----------------------------------------------------------------------------
    -- SCENARIO 1: NEW VIDEO REQUEST CREATED (INSERT)
    ----------------------------------------------------------------------------
    IF TG_OP = 'INSERT' THEN

        -- CASE 1A: Auto Approve is TRUE or admin_approval_status is 'approved' -> Target Marketing Team ONLY
        IF v_auto_approve IS TRUE OR LOWER(COALESCE(NEW.admin_approval_status::text, '')) = 'approved' THEN
            SELECT ARRAY_AGG(id) INTO v_target_user_ids
            FROM public.users
            WHERE LOWER(role::text) IN ('marketing', 'ads');

            -- Fallback if no specific marketing users found
            IF v_target_user_ids IS NULL OR ARRAY_LENGTH(v_target_user_ids, 1) IS NULL THEN
                SELECT ARRAY_AGG(id) INTO v_target_user_ids
                FROM public.users;
            END IF;

            INSERT INTO public.notifications (
                receiver_ids,
                video_request_id,
                sender_id,
                title,
                description,
                notification_type,
                data
            ) VALUES (
                v_target_user_ids,
                NEW.id,
                v_sender_user_id,
                'New video request received',
                v_broker_name || ': ' || v_property_desc,
                'video_request'::public.notification_type,
                jsonb_build_object(
                    'video_request_id', NEW.id,
                    'property_id', NEW.property_id,
                    'broker_id', NEW.broker_id,
                    'admin_approval_status', COALESCE(NEW.admin_approval_status::text, 'approved'),
                    'status', COALESCE(NEW.status::text, 'pending')
                )
            );

        -- CASE 1B: Auto Approve is FALSE -> Target Admin Team ONLY for review
        ELSE
            SELECT ARRAY_AGG(id) INTO v_target_user_ids
            FROM public.users
            WHERE LOWER(role::text) IN ('super_admin', 'superadmin', 'admin');

            IF v_target_user_ids IS NULL OR ARRAY_LENGTH(v_target_user_ids, 1) IS NULL THEN
                SELECT ARRAY_AGG(id) INTO v_target_user_ids
                FROM public.users;
            END IF;

            INSERT INTO public.notifications (
                receiver_ids,
                video_request_id,
                sender_id,
                title,
                description,
                notification_type,
                data
            ) VALUES (
                v_target_user_ids,
                NEW.id,
                v_sender_user_id,
                'New video request received',
                v_broker_name || ': ' || v_property_desc,
                'video_request'::public.notification_type,
                jsonb_build_object(
                    'video_request_id', NEW.id,
                    'property_id', NEW.property_id,
                    'broker_id', NEW.broker_id,
                    'admin_approval_status', COALESCE(NEW.admin_approval_status::text, 'pending'),
                    'status', COALESCE(NEW.status::text, 'pending')
                )
            );
        END IF;

    ----------------------------------------------------------------------------
    -- SCENARIO 2: EXISTING VIDEO REQUEST UPDATED (UPDATE)
    ----------------------------------------------------------------------------
    ELSIF TG_OP = 'UPDATE' THEN

        -- CASE 2A: Admin Approval status changed to 'approved' -> Fire notification to Marketing Team ONLY
        IF (LOWER(COALESCE(OLD.admin_approval_status::text, '')) IS DISTINCT FROM 'approved') 
           AND LOWER(COALESCE(NEW.admin_approval_status::text, '')) = 'approved' THEN
            
            SELECT ARRAY_AGG(id) INTO v_target_user_ids
            FROM public.users
            WHERE LOWER(role::text) IN ('marketing', 'ads');

            IF v_target_user_ids IS NULL OR ARRAY_LENGTH(v_target_user_ids, 1) IS NULL THEN
                SELECT ARRAY_AGG(id) INTO v_target_user_ids
                FROM public.users;
            END IF;

            INSERT INTO public.notifications (
                receiver_ids,
                video_request_id,
                sender_id,
                title,
                description,
                notification_type,
                data
            ) VALUES (
                v_target_user_ids,
                NEW.id,
                v_sender_user_id,
                'New video request received',
                v_broker_name || ': ' || v_property_desc,
                'video_request'::public.notification_type,
                jsonb_build_object(
                    'video_request_id', NEW.id,
                    'property_id', NEW.property_id,
                    'broker_id', NEW.broker_id,
                    'admin_approval_status', NEW.admin_approval_status::text,
                    'status', NEW.status::text
                )
            );

        -- CASE 2B: Request Cancelled or Rejected -> Route based on cancelled_by_user_id role
        ELSIF ((LOWER(COALESCE(OLD.admin_approval_status::text, '')) IS DISTINCT FROM 'rejected')
               AND LOWER(COALESCE(NEW.admin_approval_status::text, '')) = 'rejected')
           OR ((LOWER(COALESCE(OLD.status::text, '')) IS DISTINCT FROM 'cancelled')
               AND LOWER(COALESCE(NEW.status::text, '')) = 'cancelled') THEN

            -- Resolve role of the user who cancelled/rejected
            IF NEW.cancelled_by_user_id IS NOT NULL THEN
                SELECT LOWER(COALESCE(role::text, 'broker')), COALESCE(name, 'User')
                INTO v_canceller_role, v_canceller_name
                FROM public.users
                WHERE id = NEW.cancelled_by_user_id
                LIMIT 1;
            END IF;

            -- IF CANCELLED BY BROKER -> Fire notification to Marketing/Admin Team ONLY (DO NOT notify broker)
            IF v_canceller_role = 'broker' OR (v_canceller_role IS NULL AND auth.uid() = v_sender_user_id) THEN
                SELECT ARRAY_AGG(id) INTO v_target_user_ids
                FROM public.users
                WHERE LOWER(role::text) IN ('marketing', 'ads', 'super_admin', 'superadmin', 'admin');

                IF v_target_user_ids IS NOT NULL AND ARRAY_LENGTH(v_target_user_ids, 1) > 0 THEN
                    INSERT INTO public.notifications (
                        receiver_ids,
                        video_request_id,
                        sender_id,
                        title,
                        description,
                        notification_type,
                        data
                    ) VALUES (
                        v_target_user_ids,
                        NEW.id,
                        NEW.cancelled_by_user_id,
                        'Video request cancelled by user',
                        v_broker_name || ' cancelled the video request for ' || v_property_desc,
                        'video_request'::public.notification_type,
                        jsonb_build_object(
                            'video_request_id', NEW.id,
                            'property_id', NEW.property_id,
                            'broker_id', NEW.broker_id,
                            'admin_approval_status', NEW.admin_approval_status::text,
                            'status', NEW.status::text,
                            'cancelled_by_user_id', NEW.cancelled_by_user_id,
                            'reason', COALESCE(NEW.cancel_reason, NEW.admin_cancel_reason, '')
                        )
                    );
                END IF;

            -- IF REJECTED/CANCELLED BY MARKETING OR ADMIN -> Fire notification to Broker ONLY
            ELSE
                IF v_sender_user_id IS NOT NULL THEN
                    INSERT INTO public.notifications (
                        receiver_ids,
                        video_request_id,
                        sender_id,
                        title,
                        description,
                        notification_type,
                        data
                    ) VALUES (
                        ARRAY[v_sender_user_id],
                        NEW.id,
                        NEW.cancelled_by_user_id,
                        'Video request is rejected',
                        CASE 
                            WHEN NEW.admin_cancel_reason IS NOT NULL AND TRIM(NEW.admin_cancel_reason) != '' THEN 'Reason: ' || TRIM(NEW.admin_cancel_reason)
                            WHEN NEW.cancel_reason IS NOT NULL AND TRIM(NEW.cancel_reason) != '' THEN 'Reason: ' || TRIM(NEW.cancel_reason)
                            ELSE 'Your video request for ' || v_property_desc || ' has been rejected.'
                        END,
                        'video_request'::public.notification_type,
                        jsonb_build_object(
                            'video_request_id', NEW.id,
                            'property_id', NEW.property_id,
                            'broker_id', NEW.broker_id,
                            'admin_approval_status', NEW.admin_approval_status::text,
                            'status', NEW.status::text,
                            'cancelled_by_user_id', NEW.cancelled_by_user_id,
                            'reason', COALESCE(NEW.admin_cancel_reason, NEW.cancel_reason, '')
                        )
                    );
                END IF;
            END IF;

        -- CASE 2C: Status changed to 'in_progress' -> Fire notification ONLY to Broker
        ELSIF (LOWER(COALESCE(OLD.status::text, '')) IS DISTINCT FROM 'in_progress')
           AND LOWER(COALESCE(NEW.status::text, '')) = 'in_progress' THEN

            IF v_sender_user_id IS NOT NULL THEN
                INSERT INTO public.notifications (
                    receiver_ids,
                    video_request_id,
                    sender_id,
                    title,
                    description,
                    notification_type,
                    data
                ) VALUES (
                    ARRAY[v_sender_user_id],
                    NEW.id,
                    NULL,
                    'Video shoot in progress',
                    'Your video shoot for ' || v_property_desc || ' has started and is now in progress.',
                    'video_request'::public.notification_type,
                    jsonb_build_object(
                        'video_request_id', NEW.id,
                        'property_id', NEW.property_id,
                        'broker_id', NEW.broker_id,
                        'admin_approval_status', NEW.admin_approval_status::text,
                        'status', NEW.status::text
                    )
                );
            END IF;

        -- CASE 2D: Status changed to 'completed' -> Fire notification ONLY to Broker
        ELSIF (LOWER(COALESCE(OLD.status::text, '')) IS DISTINCT FROM 'completed')
           AND LOWER(COALESCE(NEW.status::text, '')) = 'completed' THEN

            IF v_sender_user_id IS NOT NULL THEN
                INSERT INTO public.notifications (
                    receiver_ids,
                    video_request_id,
                    sender_id,
                    title,
                    description,
                    notification_type,
                    data
                ) VALUES (
                    ARRAY[v_sender_user_id],
                    NEW.id,
                    NULL,
                    'Video request completed',
                    'Your video request for ' || v_property_desc || ' is ready! Check your dashboard.',
                    'video_request'::public.notification_type,
                    jsonb_build_object(
                        'video_request_id', NEW.id,
                        'property_id', NEW.property_id,
                        'broker_id', NEW.broker_id,
                        'admin_approval_status', NEW.admin_approval_status::text,
                        'status', NEW.status::text
                    )
                );
            END IF;

        -- CASE 2E: Status changed to 'assigned' -> Fire notification ONLY to Broker
        ELSIF (LOWER(COALESCE(OLD.status::text, '')) IS DISTINCT FROM 'assigned')
           AND LOWER(COALESCE(NEW.status::text, '')) = 'assigned' THEN

            IF v_sender_user_id IS NOT NULL THEN
                INSERT INTO public.notifications (
                    receiver_ids,
                    video_request_id,
                    sender_id,
                    title,
                    description,
                    notification_type,
                    data
                ) VALUES (
                    ARRAY[v_sender_user_id],
                    NEW.id,
                    NULL,
                    'Video request assigned',
                    'Your video request for ' || v_property_desc || ' has been assigned to our marketing team.',
                    'video_request'::public.notification_type,
                    jsonb_build_object(
                        'video_request_id', NEW.id,
                        'property_id', NEW.property_id,
                        'broker_id', NEW.broker_id,
                        'admin_approval_status', NEW.admin_approval_status::text,
                        'status', NEW.status::text
                    )
                );
            END IF;

        END IF;

    END IF;

    RETURN NEW;
EXCEPTION WHEN OTHERS THEN
    RAISE WARNING 'fn_video_requests_notification_handler warning: %', SQLERRM;
    RETURN NEW;
END;
$$;

-- Re-attach video_requests trigger
DROP TRIGGER IF EXISTS trg_video_requests_notification ON public.video_requests;
CREATE TRIGGER trg_video_requests_notification
AFTER INSERT OR UPDATE ON public.video_requests
FOR EACH ROW
EXECUTE FUNCTION public.fn_video_requests_notification_handler();

-- 3. Update fetch_video_requests RPC to include nested cancelled_by_user_id object (UserModel)
CREATE OR REPLACE FUNCTION public.fetch_video_requests(
  p_broker_id UUID DEFAULT NULL,
  p_page INT DEFAULT 1,
  p_limit INT DEFAULT 10,
  p_search_query TEXT DEFAULT '',
  p_admin_approved_status public.video_request_approval_status DEFAULT NULL,
  p_status public.video_request_status DEFAULT NULL,
  p_statuses TEXT[] DEFAULT NULL
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_offset INT;
  v_total_items INT;
  v_total_pages INT;
  v_has_more BOOLEAN;
  v_requests_json JSONB;
BEGIN
  v_offset := (p_page - 1) * p_limit;

  -- 1. Calculate total items
  SELECT COUNT(*)
  INTO v_total_items
  FROM public.video_requests vr
  JOIN public.properties p ON vr.property_id = p.id
  JOIN public.brokers b ON vr.broker_id = b.id
  LEFT JOIN public.addresses a ON p.address_id = a.id
  WHERE (p_broker_id IS NULL OR vr.broker_id = p_broker_id)
    AND (vr.is_deleted IS FALSE OR vr.is_deleted IS NULL)
    AND (p.is_deleted IS FALSE OR p.is_deleted IS NULL)
    AND (p_admin_approved_status IS NULL OR vr.admin_approval_status = p_admin_approved_status)
    AND (p_status IS NULL OR vr.status = p_status)
    AND (p_statuses IS NULL OR array_length(p_statuses, 1) IS NULL OR vr.status::text = ANY(p_statuses))
    AND (
      p_search_query = '' OR
      p.property_title ILIKE '%' || p_search_query || '%' OR
      b.business_name ILIKE '%' || p_search_query || '%' OR
      vr.notes ILIKE '%' || p_search_query || '%' OR
      (a.id IS NOT NULL AND (
         a.full_address ILIKE '%' || p_search_query || '%' OR
         a.city ILIKE '%' || p_search_query || '%' OR
         a.state ILIKE '%' || p_search_query || '%'
      ))
    );

  IF v_total_items = 0 THEN
    v_total_pages := 1;
    v_has_more := false;
  ELSE
    v_total_pages := CEIL(v_total_items::NUMERIC / p_limit)::INT;
    v_has_more := (p_page * p_limit) < v_total_items;
  END IF;

  -- 2. Fetch video requests with nested property, broker, and cancelled_by_user_id (UserModel)
  SELECT COALESCE(jsonb_agg(
    to_jsonb(vr_data) ||
    jsonb_build_object(
      'property', 
      to_jsonb(p_data) || jsonb_build_object(
        'address',
        CASE 
          WHEN p_data.address_id IS NOT NULL THEN to_jsonb(pa_data)
          ELSE NULL
        END
      ),
      'broker',
      to_jsonb(b_data) || jsonb_build_object(
        'address',
        CASE 
          WHEN b_data.address_id IS NOT NULL THEN to_jsonb(ba_data)
          ELSE NULL
        END
      ),
      'cancelled_by_user_id',
      CASE
        WHEN u_data.id IS NOT NULL THEN to_jsonb(u_data)
        ELSE NULL
      END
    )
  ), '[]'::jsonb)
  INTO v_requests_json
  FROM (
    SELECT vr.*
    FROM public.video_requests vr
    JOIN public.properties p ON vr.property_id = p.id
    JOIN public.brokers b ON vr.broker_id = b.id
    LEFT JOIN public.addresses a ON p.address_id = a.id
    WHERE (p_broker_id IS NULL OR vr.broker_id = p_broker_id)
      AND (vr.is_deleted IS FALSE OR vr.is_deleted IS NULL)
      AND (p.is_deleted IS FALSE OR p.is_deleted IS NULL)
      AND (p_admin_approved_status IS NULL OR vr.admin_approval_status = p_admin_approved_status)
      AND (p_status IS NULL OR vr.status = p_status)
      AND (p_statuses IS NULL OR array_length(p_statuses, 1) IS NULL OR vr.status::text = ANY(p_statuses))
      AND (
        p_search_query = '' OR
        p.property_title ILIKE '%' || p_search_query || '%' OR
        b.business_name ILIKE '%' || p_search_query || '%' OR
        vr.notes ILIKE '%' || p_search_query || '%' OR
        (a.id IS NOT NULL AND (
           a.full_address ILIKE '%' || p_search_query || '%' OR
           a.city ILIKE '%' || p_search_query || '%' OR
           a.state ILIKE '%' || p_search_query || '%'
        ))
      )
    ORDER BY COALESCE(vr.updated_at, vr.completed_at, vr.created_at) DESC, vr.created_at DESC
    LIMIT p_limit OFFSET v_offset
  ) vr_data
  JOIN public.properties p_data ON vr_data.property_id = p_data.id
  JOIN public.brokers b_data ON vr_data.broker_id = b_data.id
  LEFT JOIN public.users u_data ON vr_data.cancelled_by_user_id = u_data.id
  LEFT JOIN public.addresses pa_data ON p_data.address_id = pa_data.id
  LEFT JOIN public.addresses ba_data ON b_data.address_id = ba_data.id;

  RETURN jsonb_build_object(
    'success', true,
    'data', v_requests_json,
    'pagination', jsonb_build_object(
      'current_page', p_page,
      'limit', p_limit,
      'total_items', v_total_items,
      'total_pages', v_total_pages,
      'has_more', v_has_more
    )
  );
EXCEPTION WHEN OTHERS THEN
  RETURN jsonb_build_object(
    'success', false,
    'message', SQLERRM
  );
END;
$$;

GRANT EXECUTE ON FUNCTION public.fetch_video_requests(UUID, INT, INT, TEXT, public.video_request_approval_status, public.video_request_status, TEXT[]) TO authenticated;
GRANT EXECUTE ON FUNCTION public.fetch_video_requests(UUID, INT, INT, TEXT, public.video_request_approval_status, public.video_request_status, TEXT[]) TO service_role;


-- >>> Migration: 20260812130000_create_soft_delete_property_rpc_and_fix_rls.sql <<<
-- Migration: 20260812130000_create_soft_delete_property_rpc_and_fix_rls.sql
-- Purpose:
-- 1. Drop conflicting SELECT RLS policy ("Enforce non-deleted on SELECT") that blocks soft-delete UPDATE returning rows.
-- 2. Create RPC function public.soft_delete_property(p_property_id UUID) to safely soft delete properties along with associated video requests and social leads.

-- Drop conflicting old policies if present
DROP POLICY IF EXISTS "Enforce non-deleted on SELECT" ON public.properties;
DROP POLICY IF EXISTS "Hide soft-deleted properties for non-admins" ON public.properties;

-- Re-create SELECT policy for properties
CREATE POLICY "Hide soft-deleted properties for non-admins" ON public.properties
  FOR SELECT
  USING (
    (is_deleted IS FALSE OR is_deleted IS NULL)
    OR EXISTS (
      SELECT 1 FROM public.users u
      WHERE u.id = auth.uid()
        AND LOWER(u.role::text) IN ('super_admin', 'superadmin', 'admin')
    )
  );

-- Create or Replace soft_delete_property RPC function with cascading soft deletion
CREATE OR REPLACE FUNCTION public.soft_delete_property(p_property_id UUID)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_updated_video_requests INT := 0;
  v_updated_social_leads INT := 0;
BEGIN
  -- 1. Soft delete property
  UPDATE public.properties
  SET is_deleted = TRUE,
      deleted_at = NOW(),
      updated_at = NOW()
  WHERE id = p_property_id;

  -- 2. Soft delete associated video requests
  UPDATE public.video_requests
  SET is_deleted = TRUE,
      deleted_at = NOW(),
      updated_at = NOW()
  WHERE property_id = p_property_id
    AND (is_deleted IS FALSE OR is_deleted IS NULL);
  GET DIAGNOSTICS v_updated_video_requests = ROW_COUNT;

  -- 3. Soft delete associated social leads (if referenced directly or via social_posts)
  BEGIN
    UPDATE public.social_leads
    SET is_deleted = TRUE,
        deleted_at = NOW(),
        updated_at = NOW()
    WHERE (
      property_id = p_property_id
      OR social_post_id IN (SELECT id FROM public.social_posts WHERE property_id = p_property_id)
    )
    AND (is_deleted IS FALSE OR is_deleted IS NULL);
    GET DIAGNOSTICS v_updated_social_leads = ROW_COUNT;
  EXCEPTION WHEN OTHERS THEN
    -- Fallback: Soft delete social leads directly by property_id if social_posts table is absent
    BEGIN
      UPDATE public.social_leads
      SET is_deleted = TRUE,
          deleted_at = NOW(),
          updated_at = NOW()
      WHERE property_id = p_property_id
        AND (is_deleted IS FALSE OR is_deleted IS NULL);
      GET DIAGNOSTICS v_updated_social_leads = ROW_COUNT;
    EXCEPTION WHEN OTHERS THEN
      NULL;
    END;
  END;

  RETURN jsonb_build_object(
    'success', true,
    'deleted_property_id', p_property_id,
    'deleted_video_requests', v_updated_video_requests,
    'deleted_social_leads', v_updated_social_leads
  );
END;
$$;

GRANT EXECUTE ON FUNCTION public.soft_delete_property(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION public.soft_delete_property(UUID) TO service_role;


-- >>> Migration: 20260813130000_add_email_verified_and_user_otps.sql <<<
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


-- >>> Migration: 20260813160000_create_generate_user_otp_rpc.sql <<<
-- Migration: Create generate_user_otp RPC function with dynamic subject & description for email_verify, forgot_password, change_password.
-- Anon key sourced from config.json for Supabase API Gateway authentication.

CREATE OR REPLACE FUNCTION public.generate_user_otp(
  p_email TEXT,
  p_otp_type TEXT
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_otp TEXT;
  v_expiry TIMESTAMPTZ;
  v_clean_email TEXT;
  v_clean_otp_type TEXT;
  v_request_id BIGINT;
  v_subject TEXT;
  v_description TEXT;
BEGIN
  v_clean_email := LOWER(TRIM(p_email));
  v_clean_otp_type := LOWER(TRIM(p_otp_type));

  IF v_clean_email IS NULL OR v_clean_email = '' THEN
    RAISE EXCEPTION 'Email address is required to generate OTP.';
  END IF;

  IF v_clean_otp_type IS NULL OR v_clean_otp_type = '' THEN
    RAISE EXCEPTION 'OTP type is required to generate OTP.';
  END IF;

  -- Dynamic subject & description based on otp_type
  IF v_clean_otp_type = 'forgot_password' THEN
    v_subject := 'Reset Your Password - The Realty Bazaar';
    v_description := 'We received a request to reset your password. Please use the verification code below to proceed with updating your password.';
  ELSIF v_clean_otp_type = 'change_password' THEN
    v_subject := 'Change Password Code - The Realty Bazaar';
    v_description := 'We received a request to change your password. Please use the verification code below to proceed with updating your password.';
  ELSE
    v_subject := 'Your The Realty Bazaar Verification Code';
    v_description := 'We received a request to verify your email address. Please use the verification code below to complete the process.';
  END IF;

  -- Generate 6 digit OTP
  v_otp := lpad(floor(random() * 900000 + 100000)::text, 6, '0');
  v_expiry := NOW() + INTERVAL '2 minutes';

  -- Delete any existing unverified OTP for this email and otp_type
  DELETE FROM public.user_otps
  WHERE LOWER(email) = v_clean_email
    AND (otp_type::text = v_clean_otp_type OR otp_type = v_clean_otp_type::otp_type_enum);

  -- Insert new OTP into public.user_otps table
  INSERT INTO public.user_otps (
    email,
    otp,
    otp_type,
    expiry_at,
    created_at
  )
  VALUES (
    v_clean_email,
    v_otp,
    v_clean_otp_type::otp_type_enum,
    v_expiry,
    NOW()
  );

  -- Fire send-email Edge Function via pg_net
  SELECT net.http_post(
    url := 'https://btjzesvlexcvpqwisyet.supabase.co/functions/v1/send-email',
    headers := jsonb_build_object(
      'Content-Type', 'application/json',
      'apikey', 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im9pYnBwdHpucHBxbHd2Z3l0bmdqIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODMzMjY5MzIsImV4cCI6MjA5ODkwMjkzMn0.f_wO4Wg75KB_XdapcLQBzQ_Uljel7jyI5ZnSkX4v8FA',
      'Authorization', 'Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im9pYnBwdHpucHBxbHd2Z3l0bmdqIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODMzMjY5MzIsImV4cCI6MjA5ODkwMjkzMn0.f_wO4Wg75KB_XdapcLQBzQ_Uljel7jyI5ZnSkX4v8FA'
    ),
    body := jsonb_build_object(
      'to', v_clean_email,
      'subject', v_subject,
      'html',
        '<!DOCTYPE html>'
        || '<html lang="en"><head><meta charset="UTF-8"><meta name="viewport" content="width=device-width,initial-scale=1.0">'
        || '<style>'
        || 'body{margin:0;padding:0;font-family:-apple-system,BlinkMacSystemFont,''Segoe UI'',Roboto,''Helvetica Neue'',Arial,sans-serif;background-color:#f0f2f5;}'
        || '.wrapper{width:100%;background-color:#f0f2f5;padding:40px 0;}'
        || '.container{max-width:520px;margin:0 auto;background:#ffffff;border-radius:16px;overflow:hidden;box-shadow:0 4px 24px rgba(0,0,0,0.08);}'
        || '.header{background:linear-gradient(135deg,#1a73e8 0%,#0d47a1 100%);padding:36px 32px;text-align:center;}'
        || '.header h1{color:#ffffff;font-size:26px;font-weight:700;margin:0;letter-spacing:-0.5px;}'
        || '.header p{color:rgba(255,255,255,0.85);font-size:14px;margin:8px 0 0;font-weight:400;}'
        || '.body-content{padding:36px 32px;}'
        || '.greeting{font-size:16px;color:#1a1a2e;margin:0 0 16px;font-weight:500;}'
        || '.message{font-size:14px;color:#555770;line-height:1.6;margin:0 0 28px;}'
        || '.otp-box{background:linear-gradient(135deg,#e8f0fe 0%,#d2e3fc 100%);border:2px solid #1a73e8;border-radius:12px;padding:24px;text-align:center;margin:0 0 28px;}'
        || '.otp-label{font-size:12px;color:#555770;text-transform:uppercase;letter-spacing:2px;font-weight:600;margin:0 0 12px;}'
        || '.otp-code{font-size:36px;font-weight:800;color:#1a73e8;letter-spacing:8px;margin:0;font-family:''SF Mono'',''Fira Code'',''Courier New'',monospace;}'
        || '.expiry-badge{display:inline-block;background:#fff3e0;color:#e65100;font-size:12px;font-weight:600;padding:6px 14px;border-radius:20px;margin:16px 0 0;}'
        || '.divider{height:1px;background:#e8eaed;margin:0 0 24px;}'
        || '.security-note{font-size:13px;color:#888;line-height:1.5;margin:0 0 8px;}'
        || '.security-note strong{color:#555;}'
        || '.footer{background:#f8f9fa;padding:24px 32px;text-align:center;border-top:1px solid #e8eaed;}'
        || '.footer p{font-size:12px;color:#999;margin:0 0 4px;}'
        || '.footer a{color:#1a73e8;text-decoration:none;}'
        || '</style></head><body>'
        || '<div class="wrapper"><div class="container">'
        || '<div class="header">'
        || '<h1>The Realty Bazaar</h1>'
        || '<p>Real Estate Brokerage Platform</p>'
        || '</div>'
        || '<div class="body-content">'
        || '<p class="greeting">Hello,</p>'
        || '<p class="message">' || v_description || '</p>'
        || '<div class="otp-box">'
        || '<p class="otp-label">Verification Code</p>'
        || '<p class="otp-code">' || v_otp || '</p>'
        || '<span class="expiry-badge">⏱ Expires in 2 minutes</span>'
        || '</div>'
        || '<div class="divider"></div>'
        || '<p class="security-note"><strong>🔒 Security Notice:</strong> If you did not request this code, please ignore this email. Never share this code with anyone.</p>'
        || '<p class="security-note">This is an automated message from The Realty Bazaar — your trusted real estate brokerage management platform for managing leads, properties, and client relationships.</p>'
        || '</div>'
        || '<div class="footer">'
        || '<p>&copy; ' || EXTRACT(YEAR FROM NOW())::text || ' The Realty Bazaar. All rights reserved.</p>'
        || '<p>Powered by <a href="#">The Realty Bazaar Platform</a></p>'
        || '</div>'
        || '</div></div>'
        || '</body></html>'
    )
  ) INTO v_request_id;

  -- Return status metadata only, never expose raw OTP
  RETURN jsonb_build_object(
    'success', true,
    'message', 'OTP generated and email dispatch requested.',
    'email', v_clean_email,
    'otp_type', v_clean_otp_type,
    'request_id', v_request_id,
    'expiry_at', v_expiry
  );
END;
$$;

-- Grant execute permissions
GRANT EXECUTE ON FUNCTION public.generate_user_otp(TEXT, TEXT) TO anon, authenticated, service_role;

-- Migration: Create reset_user_password RPC function to update auth.users encrypted_password securely.
CREATE OR REPLACE FUNCTION public.reset_user_password(
  p_email TEXT,
  p_new_password TEXT
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_clean_email TEXT;
  v_user_id UUID;
BEGIN
  v_clean_email := LOWER(TRIM(p_email));

  IF v_clean_email IS NULL OR v_clean_email = '' THEN
    RAISE EXCEPTION 'Email address is required to reset password.';
  END IF;

  IF p_new_password IS NULL OR length(p_new_password) < 6 THEN
    RAISE EXCEPTION 'Password must be at least 6 characters long.';
  END IF;

  -- Find user ID in auth.users
  SELECT id INTO v_user_id
  FROM auth.users
  WHERE LOWER(email) = v_clean_email;

  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'No user found with the specified email address.';
  END IF;

  -- Update encrypted_password in auth.users using pgcrypto crypt
  UPDATE auth.users
  SET encrypted_password = extensions.crypt(p_new_password, extensions.gen_salt('bf')),
      updated_at = NOW()
  WHERE id = v_user_id;

  RETURN jsonb_build_object(
    'success', true,
    'message', 'Password updated successfully.',
    'email', v_clean_email
  );
END;
$$;

-- Grant execute permissions for reset_user_password
GRANT EXECUTE ON FUNCTION public.reset_user_password(TEXT, TEXT) TO anon, authenticated, service_role;


-- >>> Migration: 20260817111000_update_generate_user_otp_from_address.sql <<<
-- Migration: Update generate_user_otp RPC function to include verified domain sender address in email payload.

CREATE OR REPLACE FUNCTION public.generate_user_otp(
  p_email TEXT,
  p_otp_type TEXT
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_otp TEXT;
  v_expiry TIMESTAMPTZ;
  v_clean_email TEXT;
  v_clean_otp_type TEXT;
  v_request_id BIGINT;
  v_subject TEXT;
  v_description TEXT;
BEGIN
  v_clean_email := LOWER(TRIM(p_email));
  v_clean_otp_type := LOWER(TRIM(p_otp_type));

  IF v_clean_email IS NULL OR v_clean_email = '' THEN
    RAISE EXCEPTION 'Email address is required to generate OTP.';
  END IF;

  IF v_clean_otp_type IS NULL OR v_clean_otp_type = '' THEN
    RAISE EXCEPTION 'OTP type is required to generate OTP.';
  END IF;

  -- Dynamic subject & description based on otp_type
  IF v_clean_otp_type = 'forgot_password' THEN
    v_subject := 'Reset Your Password - The Realty Bazaar';
    v_description := 'We received a request to reset your password. Please use the verification code below to proceed with updating your password.';
  ELSIF v_clean_otp_type = 'change_password' THEN
    v_subject := 'Change Password Code - The Realty Bazaar';
    v_description := 'We received a request to change your password. Please use the verification code below to proceed with updating your password.';
  ELSE
    v_subject := 'Your The Realty Bazaar Verification Code';
    v_description := 'We received a request to verify your email address. Please use the verification code below to complete the process.';
  END IF;

  -- Generate 6 digit OTP
  v_otp := lpad(floor(random() * 900000 + 100000)::text, 6, '0');
  v_expiry := NOW() + INTERVAL '2 minutes';

  -- Delete any existing unverified OTP for this email and otp_type
  DELETE FROM public.user_otps
  WHERE LOWER(email) = v_clean_email
    AND (otp_type::text = v_clean_otp_type OR otp_type = v_clean_otp_type::otp_type_enum);

  -- Insert new OTP into public.user_otps table
  INSERT INTO public.user_otps (
    email,
    otp,
    otp_type,
    expiry_at,
    created_at
  )
  VALUES (
    v_clean_email,
    v_otp,
    v_clean_otp_type::otp_type_enum,
    v_expiry,
    NOW()
  );

  -- Fire send-email Edge Function via pg_net with verified domain sender
  SELECT net.http_post(
    url := 'https://btjzesvlexcvpqwisyet.supabase.co/functions/v1/send-email',
    headers := jsonb_build_object(
      'Content-Type', 'application/json',
      'apikey', 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im9pYnBwdHpucHBxbHd2Z3l0bmdqIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODMzMjY5MzIsImV4cCI6MjA5ODkwMjkzMn0.f_wO4Wg75KB_XdapcLQBzQ_Uljel7jyI5ZnSkX4v8FA',
      'Authorization', 'Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im9pYnBwdHpucHBxbHd2Z3l0bmdqIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODMzMjY5MzIsImV4cCI6MjA5ODkwMjkzMn0.f_wO4Wg75KB_XdapcLQBzQ_Uljel7jyI5ZnSkX4v8FA'
    ),
    body := jsonb_build_object(
      'to', v_clean_email,
      'from', 'The Realty Bazaar <no-reply@therealtybazaar.com>',
      'subject', v_subject,
      'text', 'Your The Realty Bazaar verification code is: ' || v_otp || '. This code will expire in 2 minutes.',
      'html',
        '<!DOCTYPE html>'
        || '<html lang="en"><head><meta charset="UTF-8"><meta name="viewport" content="width=device-width,initial-scale=1.0">'
        || '<style>'
        || 'body{margin:0;padding:0;font-family:-apple-system,BlinkMacSystemFont,''Segoe UI'',Roboto,''Helvetica Neue'',Arial,sans-serif;background-color:#f0f2f5;}'
        || '.wrapper{width:100%;background-color:#f0f2f5;padding:40px 0;}'
        || '.container{max-width:520px;margin:0 auto;background:#ffffff;border-radius:16px;overflow:hidden;box-shadow:0 4px 24px rgba(0,0,0,0.08);}'
        || '.header{background:linear-gradient(135deg,#1a73e8 0%,#0d47a1 100%);padding:36px 32px;text-align:center;}'
        || '.header h1{color:#ffffff;font-size:26px;font-weight:700;margin:0;letter-spacing:-0.5px;}'
        || '.header p{color:rgba(255,255,255,0.85);font-size:14px;margin:8px 0 0;font-weight:400;}'
        || '.body-content{padding:36px 32px;}'
        || '.greeting{font-size:16px;color:#1a1a2e;margin:0 0 16px;font-weight:500;}'
        || '.message{font-size:14px;color:#555770;line-height:1.6;margin:0 0 28px;}'
        || '.otp-box{background:linear-gradient(135deg,#e8f0fe 0%,#d2e3fc 100%);border:2px solid #1a73e8;border-radius:12px;padding:24px;text-align:center;margin:0 0 28px;}'
        || '.otp-label{font-size:12px;color:#555770;text-transform:uppercase;letter-spacing:2px;font-weight:600;margin:0 0 12px;}'
        || '.otp-code{font-size:36px;font-weight:800;color:#1a73e8;letter-spacing:8px;margin:0;font-family:''SF Mono'',''Fira Code'',''Courier New'',monospace;}'
        || '.expiry-badge{display:inline-block;background:#fff3e0;color:#e65100;font-size:12px;font-weight:600;padding:6px 14px;border-radius:20px;margin:16px 0 0;}'
        || '.divider{height:1px;background:#e8eaed;margin:0 0 24px;}'
        || '.security-note{font-size:13px;color:#888;line-height:1.5;margin:0 0 8px;}'
        || '.security-note strong{color:#555;}'
        || '.footer{background:#f8f9fa;padding:24px 32px;text-align:center;border-top:1px solid #e8eaed;}'
        || '.footer p{font-size:12px;color:#999;margin:0 0 4px;}'
        || '.footer a{color:#1a73e8;text-decoration:none;}'
        || '</style></head><body>'
        || '<div class="wrapper"><div class="container">'
        || '<div class="header">'
        || '<h1>The Realty Bazaar</h1>'
        || '<p>Real Estate Brokerage Platform</p>'
        || '</div>'
        || '<div class="body-content">'
        || '<p class="greeting">Hello,</p>'
        || '<p class="message">' || v_description || '</p>'
        || '<div class="otp-box">'
        || '<p class="otp-label">Verification Code</p>'
        || '<p class="otp-code">' || v_otp || '</p>'
        || '<span class="expiry-badge">⏱ Expires in 2 minutes</span>'
        || '</div>'
        || '<div class="divider"></div>'
        || '<p class="security-note"><strong>🔒 Security Notice:</strong> If you did not request this code, please ignore this email. Never share this code with anyone.</p>'
        || '<p class="security-note">This is an automated message from The Realty Bazaar — your trusted real estate brokerage management platform for managing leads, properties, and client relationships.</p>'
        || '</div>'
        || '<div class="footer">'
        || '<p>&copy; ' || EXTRACT(YEAR FROM NOW())::text || ' The Realty Bazaar. All rights reserved.</p>'
        || '<p>Powered by <a href="#">The Realty Bazaar Platform</a></p>'
        || '</div>'
        || '</div></div>'
        || '</body></html>'
    )
  ) INTO v_request_id;

  -- Return status metadata only, never expose raw OTP
  RETURN jsonb_build_object(
    'success', true,
    'message', 'OTP generated and email dispatch requested.',
    'email', v_clean_email,
    'otp_type', v_clean_otp_type,
    'request_id', v_request_id,
    'expiry_at', v_expiry
  );
END;
$$;

-- Grant execute permissions
GRANT EXECUTE ON FUNCTION public.generate_user_otp(TEXT, TEXT) TO anon, authenticated, service_role;


-- >>> Migration: 20260824160000_convert_campaign_gender_to_enum.sql <<<
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


-- >>> Migration: 20260824170000_update_otp_expiry_and_branding.sql <<<
-- Migration: Update generate_user_otp RPC function with 30-second expiry and The Realty Bazaar branding.
-- File: supabase/migrations/20260824170000_update_otp_expiry_and_branding.sql

CREATE OR REPLACE FUNCTION public.generate_user_otp(
  p_email TEXT,
  p_otp_type TEXT
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_otp TEXT;
  v_expiry TIMESTAMPTZ;
  v_clean_email TEXT;
  v_clean_otp_type TEXT;
  v_request_id BIGINT;
  v_subject TEXT;
  v_description TEXT;
BEGIN
  v_clean_email := LOWER(TRIM(p_email));
  v_clean_otp_type := LOWER(TRIM(p_otp_type));

  IF v_clean_email IS NULL OR v_clean_email = '' THEN
    RAISE EXCEPTION 'Email address is required to generate OTP.';
  END IF;

  IF v_clean_otp_type IS NULL OR v_clean_otp_type = '' THEN
    RAISE EXCEPTION 'OTP type is required to generate OTP.';
  END IF;

  -- Dynamic subject & description based on otp_type (The Realty Bazaar branding)
  IF v_clean_otp_type = 'forgot_password' THEN
    v_subject := 'Reset Your Password - The Realty Bazaar';
    v_description := 'We received a request to reset your password. Please use the verification code below to proceed with updating your password.';
  ELSIF v_clean_otp_type = 'change_password' THEN
    v_subject := 'Change Password Code - The Realty Bazaar';
    v_description := 'We received a request to change your password. Please use the verification code below to proceed with updating your password.';
  ELSE
    v_subject := 'Your The Realty Bazaar Verification Code';
    v_description := 'We received a request to verify your email address. Please use the verification code below to complete the process.';
  END IF;

  -- Generate 6 digit OTP & set 30-second expiry
  v_otp := lpad(floor(random() * 900000 + 100000)::text, 6, '0');
  v_expiry := NOW() + INTERVAL '30 seconds';

  -- Delete any existing unverified OTP for this email and otp_type
  DELETE FROM public.user_otps
  WHERE LOWER(email) = v_clean_email
    AND (otp_type::text = v_clean_otp_type OR otp_type = v_clean_otp_type::otp_type_enum);

  -- Insert new OTP into public.user_otps table
  INSERT INTO public.user_otps (
    email,
    otp,
    otp_type,
    expiry_at,
    created_at
  )
  VALUES (
    v_clean_email,
    v_otp,
    v_clean_otp_type::otp_type_enum,
    v_expiry,
    NOW()
  );

  -- Fire send-email Edge Function via pg_net with verified domain sender
  SELECT net.http_post(
    url := 'https://btjzesvlexcvpqwisyet.supabase.co/functions/v1/send-email',
    headers := jsonb_build_object(
      'Content-Type', 'application/json',
      'apikey', 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im9pYnBwdHpucHBxbHd2Z3l0bmdqIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODMzMjY5MzIsImV4cCI6MjA5ODkwMjkzMn0.f_wO4Wg75KB_XdapcLQBzQ_Uljel7jyI5ZnSkX4v8FA',
      'Authorization', 'Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im9pYnBwdHpucHBxbHd2Z3l0bmdqIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODMzMjY5MzIsImV4cCI6MjA5ODkwMjkzMn0.f_wO4Wg75KB_XdapcLQBzQ_Uljel7jyI5ZnSkX4v8FA'
    ),
    body := jsonb_build_object(
      'to', v_clean_email,
      'from', 'The Realty Bazaar <no-reply@therealtybazaar.com>',
      'subject', v_subject,
      'text', 'Your The Realty Bazaar verification code is: ' || v_otp || '. This code will expire in 30 seconds.',
      'html',
        '<!DOCTYPE html>'
        || '<html lang="en"><head><meta charset="UTF-8"><meta name="viewport" content="width=device-width,initial-scale=1.0">'
        || '<style>'
        || 'body{margin:0;padding:0;font-family:-apple-system,BlinkMacSystemFont,''Segoe UI'',Roboto,''Helvetica Neue'',Arial,sans-serif;background-color:#f0f2f5;}'
        || '.wrapper{width:100%;background-color:#f0f2f5;padding:40px 0;}'
        || '.container{max-width:520px;margin:0 auto;background:#ffffff;border-radius:16px;overflow:hidden;box-shadow:0 4px 24px rgba(0,0,0,0.08);}'
        || '.header{background:linear-gradient(135deg,#1a73e8 0%,#0d47a1 100%);padding:36px 32px;text-align:center;}'
        || '.header h1{color:#ffffff;font-size:26px;font-weight:700;margin:0;letter-spacing:-0.5px;}'
        || '.header p{color:rgba(255,255,255,0.85);font-size:14px;margin:8px 0 0;font-weight:400;}'
        || '.body-content{padding:36px 32px;}'
        || '.greeting{font-size:16px;color:#1a1a2e;margin:0 0 16px;font-weight:500;}'
        || '.message{font-size:14px;color:#555770;line-height:1.6;margin:0 0 28px;}'
        || '.otp-box{background:linear-gradient(135deg,#e8f0fe 0%,#d2e3fc 100%);border:2px solid #1a73e8;border-radius:12px;padding:24px;text-align:center;margin:0 0 28px;}'
        || '.otp-label{font-size:12px;color:#555770;text-transform:uppercase;letter-spacing:2px;font-weight:600;margin:0 0 12px;}'
        || '.otp-code{font-size:36px;font-weight:800;color:#1a73e8;letter-spacing:8px;margin:0;font-family:''SF Mono'',''Fira Code'',''Courier New'',monospace;}'
        || '.expiry-badge{display:inline-block;background:#fff3e0;color:#e65100;font-size:12px;font-weight:600;padding:6px 14px;border-radius:20px;margin:16px 0 0;}'
        || '.divider{height:1px;background:#e8eaed;margin:0 0 24px;}'
        || '.security-note{font-size:13px;color:#888;line-height:1.5;margin:0 0 8px;}'
        || '.security-note strong{color:#555;}'
        || '.footer{background:#f8f9fa;padding:24px 32px;text-align:center;border-top:1px solid #e8eaed;}'
        || '.footer p{font-size:12px;color:#999;margin:0 0 4px;}'
        || '.footer a{color:#1a73e8;text-decoration:none;}'
        || '</style></head><body>'
        || '<div class="wrapper"><div class="container">'
        || '<div class="header">'
        || '<h1>The Realty Bazaar</h1>'
        || '<p>Real Estate Brokerage Platform</p>'
        || '</div>'
        || '<div class="body-content">'
        || '<p class="greeting">Hello,</p>'
        || '<p class="message">' || v_description || '</p>'
        || '<div class="otp-box">'
        || '<p class="otp-label">Verification Code</p>'
        || '<p class="otp-code">' || v_otp || '</p>'
        || '<span class="expiry-badge">⏱ Expires in 30 seconds</span>'
        || '</div>'
        || '<div class="divider"></div>'
        || '<p class="security-note"><strong>🔒 Security Notice:</strong> If you did not request this code, please ignore this email. Never share this code with anyone.</p>'
        || '<p class="security-note">This is an automated message from The Realty Bazaar — your trusted real estate brokerage management platform for managing leads, properties, and client relationships.</p>'
        || '</div>'
        || '<div class="footer">'
        || '<p>&copy; ' || EXTRACT(YEAR FROM NOW())::text || ' The Realty Bazaar. All rights reserved.</p>'
        || '<p>Powered by <a href="#">The Realty Bazaar Platform</a></p>'
        || '</div>'
        || '</div></div>'
        || '</body></html>'
    )
  ) INTO v_request_id;

  -- Return status metadata only, never expose raw OTP
  RETURN jsonb_build_object(
    'success', true,
    'message', 'OTP generated and email dispatch requested.',
    'email', v_clean_email,
    'otp_type', v_clean_otp_type,
    'request_id', v_request_id,
    'expiry_at', v_expiry
  );
END;
$$;

-- Grant execute permissions
GRANT EXECUTE ON FUNCTION public.generate_user_otp(TEXT, TEXT) TO anon, authenticated, service_role;


-- >>> Migration: 20260825164500_create_account_deletion_requests_and_engine.sql <<<
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


-- >>> Migration: 20260827131500_update_publish_property_setup_details.sql <<<
-- Migration: Update publish_property RPC to set setup_details.properties_imported = true upon property publishing

CREATE OR REPLACE FUNCTION public.publish_property(
  p_property JSONB,
  p_is_edit BOOLEAN
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_property_id UUID;
  v_address_id UUID;
  v_address_data JSONB;
  v_property_data JSONB;
  v_returned_property JSONB;
  v_broker_id UUID;
BEGIN
  -- Extract address data from the property JSON
  v_address_data := p_property->'address';

  -- Extract property data (excluding keys we don't want to overwrite directly during insert/update)
  v_property_data := p_property - 'address' - 'id' - 'created_at' - 'updated_at';

  IF p_is_edit IS TRUE THEN
    -- 1. Edit existing property logic
    v_property_id := (p_property->>'id')::UUID;
    IF v_property_id IS NULL THEN
      RETURN jsonb_build_object(
        'success', false,
        'error', 'Missing property ID for update'
      );
    END IF;

    -- Update nested address if provided
    IF v_address_data IS NOT NULL AND v_address_data <> 'null'::jsonb THEN
      -- Resolve address ID to update
      v_address_id := COALESCE(
        (p_property->>'address_id')::UUID, 
        (v_address_data->>'id')::UUID
      );

      IF v_address_id IS NOT NULL THEN
        UPDATE public.addresses
        SET
          full_address = COALESCE(v_address_data->>'full_address', full_address),
          latitude = (v_address_data->>'latitude')::NUMERIC,
          longitude = (v_address_data->>'longitude')::NUMERIC,
          city = COALESCE(v_address_data->>'city', city),
          pincode = COALESCE(v_address_data->>'pincode', pincode),
          state = COALESCE(v_address_data->>'state', state),
          country = COALESCE(v_address_data->>'country', country),
          landmark = COALESCE(v_address_data->>'landmark', landmark),
          entity_id = v_property_id,
          entity_type = 'property',
          updated_at = NOW()
        WHERE id = v_address_id;
      END IF;
    END IF;

    -- Update property details
    UPDATE public.properties
    SET
      broker_id = COALESCE((v_property_data->>'broker_id')::UUID, broker_id),
      address_id = COALESCE((v_property_data->>'address_id')::UUID, address_id),
      property_title = COALESCE(v_property_data->>'property_title', property_title),
      property_description = COALESCE(v_property_data->>'property_description', property_description),
      property_type = COALESCE((v_property_data->>'property_type')::public.property_type_enum, property_type),
      listing_type = COALESCE((v_property_data->>'listing_type')::public.listing_type_enum, listing_type),
      price = COALESCE((v_property_data->>'price')::NUMERIC, price),
      area = COALESCE((v_property_data->>'area')::NUMERIC, area),
      area_unit = COALESCE((v_property_data->>'area_unit')::public.area_unit_enum, area_unit),
      bedrooms = COALESCE((v_property_data->>'bedrooms')::INTEGER, bedrooms),
      bathrooms = COALESCE((v_property_data->>'bathrooms')::INTEGER, bathrooms),
      balconies = COALESCE((v_property_data->>'balconies')::INTEGER, balconies),
      parking = COALESCE((v_property_data->>'parking')::INTEGER, parking),
      floor_number = (v_property_data->>'floor_number')::INTEGER,
      total_floors = (v_property_data->>'total_floors')::INTEGER,
      furnishing_status = COALESCE((v_property_data->>'furnishing_status')::public.furnishing_status_enum, furnishing_status),
      property_status = COALESCE((v_property_data->>'property_status')::public.property_status_enum, property_status),
      construction_status = COALESCE((v_property_data->>'construction_status')::public.construction_status_enum, construction_status),
      facing = (v_property_data->>'facing')::public.facing_direction_enum,
      amenities = COALESCE(v_property_data->'amenities', amenities),
      medias = COALESCE(v_property_data->'medias', medias),
      is_active = COALESCE((v_property_data->>'is_active')::BOOLEAN, is_active),
      is_deleted = COALESCE((v_property_data->>'is_deleted')::BOOLEAN, is_deleted),
      updated_at = NOW()
    WHERE id = v_property_id;

  ELSE
    -- 2. Create new property logic
    -- Insert property with address_id = NULL first to get property UUID
    INSERT INTO public.properties (
      broker_id,
      address_id,
      property_title,
      property_description,
      property_type,
      listing_type,
      price,
      area,
      area_unit,
      bedrooms,
      bathrooms,
      balconies,
      parking,
      floor_number,
      total_floors,
      furnishing_status,
      property_status,
      construction_status,
      facing,
      amenities,
      medias,
      is_active
    ) VALUES (
      (v_property_data->>'broker_id')::UUID,
      NULL,
      v_property_data->>'property_title',
      v_property_data->>'property_description',
      COALESCE((v_property_data->>'property_type')::public.property_type_enum, 'apartment'::public.property_type_enum),
      COALESCE((v_property_data->>'listing_type')::public.listing_type_enum, 'sale'::public.listing_type_enum),
      (v_property_data->>'price')::NUMERIC,
      (v_property_data->>'area')::NUMERIC,
      COALESCE((v_property_data->>'area_unit')::public.area_unit_enum, 'sqft'::public.area_unit_enum),
      COALESCE((v_property_data->>'bedrooms')::INTEGER, 0),
      COALESCE((v_property_data->>'bathrooms')::INTEGER, 0),
      COALESCE((v_property_data->>'balconies')::INTEGER, 0),
      COALESCE((v_property_data->>'parking')::INTEGER, 0),
      (v_property_data->>'floor_number')::INTEGER,
      (v_property_data->>'total_floors')::INTEGER,
      COALESCE((v_property_data->>'furnishing_status')::public.furnishing_status_enum, 'unfurnished'::public.furnishing_status_enum),
      COALESCE((v_property_data->>'property_status')::public.property_status_enum, 'available'::public.property_status_enum),
      COALESCE((v_property_data->>'construction_status')::public.construction_status_enum, 'ready_to_move'::public.construction_status_enum),
      (v_property_data->>'facing')::public.facing_direction_enum,
      COALESCE(v_property_data->'amenities', '[]'::jsonb),
      COALESCE(v_property_data->'medias', '[]'::jsonb),
      COALESCE((v_property_data->>'is_active')::BOOLEAN, TRUE)
    ) RETURNING id INTO v_property_id;

    -- Insert address referencing the new property ID
    IF v_address_data IS NOT NULL AND v_address_data <> 'null'::jsonb THEN
      INSERT INTO public.addresses (
        full_address,
        latitude,
        longitude,
        city,
        pincode,
        state,
        country,
        landmark,
        entity_id,
        entity_type
      ) VALUES (
        COALESCE(v_address_data->>'full_address', ''),
        (v_address_data->>'latitude')::NUMERIC,
        (v_address_data->>'longitude')::NUMERIC,
        v_address_data->>'city',
        v_address_data->>'pincode',
        v_address_data->>'state',
        v_address_data->>'country',
        v_address_data->>'landmark',
        v_property_id,
        'property'
      ) RETURNING id INTO v_address_id;

      -- Update the properties record to reference the newly created address
      UPDATE public.properties
      SET address_id = v_address_id
      WHERE id = v_property_id;
    END IF;
  END IF;

  -- 3. Resolve broker_id and update broker setup_details if properties_imported is not true
  v_broker_id := COALESCE(
    (v_property_data->>'broker_id')::UUID,
    (SELECT broker_id FROM public.properties WHERE id = v_property_id)
  );

  IF v_broker_id IS NOT NULL THEN
    UPDATE public.brokers
    SET setup_details = jsonb_set(
      COALESCE(setup_details, '{}'::jsonb),
      '{properties_imported}',
      'true'::jsonb
    )
    WHERE id = v_broker_id
      AND (setup_details IS NULL OR (setup_details->>'properties_imported')::BOOLEAN IS NOT TRUE);
  END IF;

  -- Select and serialize the finalized property row to return to the client
  SELECT to_jsonb(p) INTO v_returned_property
  FROM public.properties p
  WHERE p.id = v_property_id;

  RETURN jsonb_build_object(
    'success', true,
    'property', v_returned_property
  );

EXCEPTION WHEN OTHERS THEN
  RETURN jsonb_build_object(
    'success', false,
    'error', SQLERRM
  );
END;
$$;


-- >>> Migration: 20260831103000_update_subscription_plan_benefits_leads_views.sql <<<
-- Migration: 20260831103000_update_subscription_plan_benefits_leads_views.sql
-- Description: Separates leads and view count into two distinct bullet points per plan, ensuring a maximum of 6 benefits per plan by removing redundant basic social publishing features.

-- 1. STARTER BROKER (₹14,999/month | ~₹12,000 Meta Ad Spend)
UPDATE public.subscription_plans
SET benefits = '[
  "Unlimited property uploads",
  "Get up to 75+ buyer leads",
  "Get up to 75k+ views on reels",
  "Integrated CRM & lead tracker",
  "AI property descriptions & captions",
  "Verified website property listings"
]'::jsonb
WHERE id = '4436621c-f936-4686-bd6c-140ddea4c74c' OR title = 'STARTER BROKER';

-- 2. GROWTH PRO (₹18,999/month | ~₹15,200 Meta Ad Spend)
UPDATE public.subscription_plans
SET benefits = '[
  "Everything in Starter",
  "Managed Meta & Google property ads",
  "Get up to 100+ buyer leads",
  "Get up to 100k+ views on reels",
  "Campaign analytics & lead scoring",
  "Dedicated account manager"
]'::jsonb
WHERE id = '6adf650d-5449-49ad-9d7f-0d383252182c' OR title = 'GROWTH PRO';

-- 3. HIGH-VOLUME ELITE (₹24,999/month | ~₹20,000 Meta Ad Spend)
UPDATE public.subscription_plans
SET benefits = '[
  "Everything in Growth Pro",
  "Get up to 135+ buyer leads",
  "Get up to 130k+ views on reels",
  "Video content campaigns & reels",
  "Advanced AI property matching",
  "Priority WhatsApp & phone support"
]'::jsonb
WHERE id = '8e8d6679-5ddb-4c10-93bb-879a85a89d9d' OR title = 'HIGH-VOLUME ELITE';

-- 4. TRIAL PLAN (₹2,499 one-time | ~₹2,000 Meta Ad Spend)
UPDATE public.subscription_plans
SET benefits = '[
  "Full CRM & lead management",
  "Get up to 15+ buyer leads",
  "Get up to 13k+ views on reels",
  "AI marketing content generation",
  "Up to 10 active property listings",
  "30-day full access trial"
]'::jsonb
WHERE id = 'c8842e5e-6ddc-4ee8-a1ae-f8909023ea6f' OR title = 'TRIAL PLAN';

-- 5. AGENCY & TEAMS (Custom Price | Custom Ad Allocation)
UPDATE public.subscription_plans
SET benefits = '[
  "Custom buyer lead volume",
  "Custom reel reach & video views",
  "Multiple sub-broker & agent logins",
  "Custom campaign strategy & creative",
  "Dedicated agency account director",
  "API & team performance dashboard"
]'::jsonb
WHERE id = 'b3bf9876-4505-439a-8681-1f233c73b6ce' OR title = 'AGENCY & TEAMS';

-- 6. LISTING PASS (₹299.00 one-time | Single listing post without ad campaign)
UPDATE public.subscription_plans
SET benefits = '[
  "Single property post upload",
  "Direct DM lead & buyer contact access",
  "Unlimited social post publishing",
  "Lead view & contact management",
  "One-time payment with instant access"
]'::jsonb
WHERE id = '539e4da1-35ef-4cb3-8977-11c1feba2dd0' OR title = 'LISTING PASS';


-- >>> Migration: add_custom_duration_and_agency_plan.sql <<<
-- Migration: add_custom_duration_and_agency_plan.sql
-- Note: In PostgreSQL, ALTER TYPE ADD VALUE must be executed & committed in a separate transaction BEFORE using the new enum value.

-- ==========================================
-- STEP 1: Run and Execute this command FIRST
-- ==========================================
ALTER TYPE subscription_duration ADD VALUE IF NOT EXISTS 'custom';


-- ==========================================
-- STEP 2: Run and Execute this query AFTER Step 1
-- ==========================================
INSERT INTO public.subscription_plans (
    title,
    amount,
    duration,
    description,
    benefits,
    is_active,
    is_popular
) VALUES (
    'AGENCY & TEAMS',
    0.00,
    'custom',
    'For real-estate agencies and multi-broker channel teams.',
    '[
      "Custom advertising budget allocation",
      "Multiple sub-broker & agent logins",
      "Custom campaign strategy & creative",
      "Dedicated agency account director",
      "API & custom CRM integrations",
      "Team performance dashboard"
    ]'::jsonb,
    true,
    false
);


-- >>> Migration: add_is_popular_and_plans.sql <<<
-- Migration: add_is_popular_and_plans.sql
-- Description: Adds is_popular boolean column to subscription_plans table and inserts Starter, Growth Pro, and High-Volume Elite plans.

-- 1. Add is_popular column to subscription_plans table
ALTER TABLE public.subscription_plans
ADD COLUMN IF NOT EXISTS is_popular BOOLEAN NOT NULL DEFAULT false;

-- 2. Insert Starter Broker Plan
INSERT INTO public.subscription_plans (
    title,
    amount,
    duration,
    description,
    benefits,
    is_active,
    is_popular
) VALUES (
    'STARTER BROKER',
    999.00,
    'month',
    'Essential tools for independent brokers managing local listings.',
    '[
      "Unlimited property uploads",
      "Integrated CRM & lead tracker",
      "AI property descriptions & captions",
      "Instagram & Facebook publishing",
      "Verified website property listings",
      "Instant WhatsApp inquiry capture"
    ]'::jsonb,
    true,
    false
);

-- 3. Insert Growth Pro Plan (Most Popular)
INSERT INTO public.subscription_plans (
    title,
    amount,
    duration,
    description,
    benefits,
    is_active,
    is_popular
) VALUES (
    'GROWTH PRO',
    14999.00,
    'month',
    'Full marketing + automated Meta Ads campaigns for serious brokers.',
    '[
      "Everything in Starter",
      "Managed Meta & Google property ads",
      "Up to ₹350/day advertising allocation",
      "Campaign analytics & lead scoring",
      "Automated follow-ups & reminders",
      "Dedicated account manager"
    ]'::jsonb,
    true,
    true
);

-- 4. Insert High-Volume Elite Plan
INSERT INTO public.subscription_plans (
    title,
    amount,
    duration,
    description,
    benefits,
    is_active,
    is_popular
) VALUES (
    'HIGH-VOLUME ELITE',
    19999.00,
    'month',
    'Aggressive advertising & high-speed deal pipeline for top producers.',
    '[
      "Everything in Growth Pro",
      "Up to ₹500/day advertising allocation",
      "Video content campaigns & reels",
      "Advanced AI property match recommendations",
      "Priority WhatsApp & phone support",
      "Custom branding on listing flyers"
    ]'::jsonb,
    true,
    false
);


-- >>> Migration: subscription_plans_schema.sql <<<
-- Migration: subscription_plans_schema.sql
-- Description: Creates enum subscription_duration and subscription_plans table for managing subscription packages.

-- 1. Create Enum Type for Subscription Duration
CREATE TYPE subscription_duration AS ENUM ('month', 'year', 'one_time');

-- 2. Create subscription_plans Table
CREATE TABLE IF NOT EXISTS public.subscription_plans (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    title TEXT NOT NULL,
    amount NUMERIC(10, 2) NOT NULL DEFAULT 0.00,
    duration subscription_duration NOT NULL DEFAULT 'month',
    description TEXT NOT NULL DEFAULT '',
    benefits JSONB NOT NULL DEFAULT '[]'::jsonb,
    is_active BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 3. Create Index for active plans lookup
CREATE INDEX IF NOT EXISTS idx_subscription_plans_active ON public.subscription_plans(is_active);

-- 4. Enable Row Level Security (RLS)
ALTER TABLE public.subscription_plans ENABLE ROW LEVEL SECURITY;

-- 5. RLS Policy: Anyone (authenticated & anon) can read active subscription plans
CREATE POLICY "Allow public read access to active subscription plans"
    ON public.subscription_plans
    FOR SELECT
    USING (is_active = true);

-- 6. Trigger to automatically update updated_at timestamp
CREATE OR REPLACE FUNCTION update_subscription_plans_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_subscription_plans_updated_at ON public.subscription_plans;
CREATE TRIGGER trigger_subscription_plans_updated_at
    BEFORE UPDATE ON public.subscription_plans
    FOR EACH ROW
    EXECUTE FUNCTION update_subscription_plans_updated_at();

-- 7. Insert Initial Trial Plan Record (from Screenshot)
INSERT INTO public.subscription_plans (
    title,
    amount,
    duration,
    description,
    benefits,
    is_active
) VALUES (
    'TRIAL PLAN',
    4499.00,
    'one_time',
    'Try the complete platform for 30 days with no recurring commitment.',
    '[
      "Full CRM & lead management",
      "AI marketing content generation",
      "Social media post publishing",
      "Up to 10 active property listings",
      "30-day full access trial",
      "Mobile app access (iOS & Android)"
    ]'::jsonb,
    true
);


