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
