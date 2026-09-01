-- Migration / Seed Script: 20260831202500_seed_10_properties_per_broker.sql
-- Description: Seeds 10 unique, realistic, and meaningful properties with addresses for every registered broker.

DO $$
DECLARE
  v_broker RECORD;
  v_addr_id UUID;
  v_prop_id UUID;
  v_idx INTEGER;

  v_titles TEXT[] := ARRAY[
    'Ultra-Luxurious 3 BHK Sea View Residence',
    'Modern 4 BHK Penthouse with Private Terrace & Plunge Pool',
    'Executive 2 BHK Smart Apartment near IT Corridor',
    'Royal 5 BHK Independent Villa with Private Pool & Home Theatre',
    'Minimalist 2 BHK Urban Loft with Modular Kitchen',
    'State-of-the-Art Grade-A Commercial Workspace',
    'High-ROI Retail Showroom on Main Commercial Boulevard',
    'Sky-High 4 BHK Masterpiece on 42nd Floor',
    'Brand New 3 BHK Gated Community Row House with 40+ Amenities',
    'Prime Residential Gated Community Plot with Clubhouse Privileges'
  ];

  v_descs TEXT[] := ARRAY[
    'Presenting this immaculate, sunlight-flooded residence featuring floor-to-ceiling panoramic glass walls, Italian marble flooring, and expansive sundecks. Situated within a prestigious landmark tower offering private elevator access, 24x7 white-glove concierge, and world-class leisure facilities.',
    'Experience unrivaled sky-living in this grand penthouse with double-height ceilings, private plunge pool, and expansive rooftop entertainment deck. Crafted with custom designer interiors, European sanitary fixtures, and integrated home automation.',
    'Thoughtfully engineered modern smart residence ideally positioned minutes from major corporate campuses and transit interchanges. Features acoustic sound-dampened windows, energy-efficient fixtures, and direct clubhouse entry.',
    'An expansive royal estate surrounded by lush landscaped gardens, private water features, and separate staff quarters. Boasts a climate-controlled 8-seater Dolby Atmos home theatre, private elevator, and 4-car covered parking bay.',
    'Sleek and contemporary urban residence boasting an open-concept layout, custom quartz kitchen island, and designer ambient cove lighting. Perfect for modern professionals seeking effortless luxury and connectivity.',
    'Premium commercial floor plate with efficient column grid layout, high-speed fiber optics, 100% DG power backup, and IGBC Gold rated green building certification. Ideal for enterprise tech firms and financial headquarters.',
    'Prominent corner retail asset with 120-foot glass frontage, exceptional footfall visibility, dedicated customer valet drop-off, and high ceiling height suitable for luxury retail flagship stores.',
    'Perched high above the cityscape, this architectural marvel offers unobstructed 360-degree skyline views. Includes temperature-controlled indoor pool access, private lounge privileges, and biometric security.',
    'A tranquil family sanctuary nestled within an award-winning integrated township. Enjoys immediate access to international academies, multi-specialty wellness centers, and a 5-acre central community park.',
    'Sprawling premium corner plot situated in an exclusive gated villa community with wide 60-ft tree-lined avenue roads, underground cabling, high-speed fiber grid, ready water connection, and full clubhouse access.'
  ];

  v_prop_types public.property_type_enum[] := ARRAY[
    'apartment'::public.property_type_enum,
    'penthouse'::public.property_type_enum,
    'apartment'::public.property_type_enum,
    'villa'::public.property_type_enum,
    'apartment'::public.property_type_enum,
    'commercial'::public.property_type_enum,
    'commercial'::public.property_type_enum,
    'apartment'::public.property_type_enum,
    'row_house'::public.property_type_enum,
    'plot'::public.property_type_enum
  ];

  v_list_types public.listing_type_enum[] := ARRAY[
    'sale'::public.listing_type_enum,
    'sale'::public.listing_type_enum,
    'rent'::public.listing_type_enum,
    'sale'::public.listing_type_enum,
    'rent'::public.listing_type_enum,
    'lease'::public.listing_type_enum,
    'lease'::public.listing_type_enum,
    'sale'::public.listing_type_enum,
    'sale'::public.listing_type_enum,
    'sale'::public.listing_type_enum
  ];

  v_prices NUMERIC[] := ARRAY[
    34500000, 78000000, 85000, 125000000, 62000, 320000, 450000, 56000000, 24000000, 42000000
  ];

  v_areas NUMERIC[] := ARRAY[
    1850, 4200, 1180, 6500, 950, 4800, 3200, 3400, 2650, 5000
  ];

  v_beds INT[] := ARRAY[3, 4, 2, 5, 2, 0, 0, 4, 3, 0];
  v_baths INT[] := ARRAY[3, 5, 2, 6, 2, 4, 2, 4, 3, 0];
  v_balcs INT[] := ARRAY[2, 3, 1, 4, 1, 0, 0, 3, 2, 0];
  v_parks INT[] := ARRAY[2, 3, 1, 4, 1, 4, 3, 2, 2, 0];
  v_floors INT[] := ARRAY[18, 38, 9, 1, 14, 8, 1, 42, 2, 0];
  v_total_fls INT[] := ARRAY[35, 40, 25, 2, 22, 15, 4, 45, 3, 0];

  v_furnishings public.furnishing_status_enum[] := ARRAY[
    'semi_furnished'::public.furnishing_status_enum,
    'fully_furnished'::public.furnishing_status_enum,
    'fully_furnished'::public.furnishing_status_enum,
    'fully_furnished'::public.furnishing_status_enum,
    'semi_furnished'::public.furnishing_status_enum,
    'unfurnished'::public.furnishing_status_enum,
    'unfurnished'::public.furnishing_status_enum,
    'fully_furnished'::public.furnishing_status_enum,
    'semi_furnished'::public.furnishing_status_enum,
    'unfurnished'::public.furnishing_status_enum
  ];

  v_const_statuses public.construction_status_enum[] := ARRAY[
    'ready_to_move'::public.construction_status_enum,
    'ready_to_move'::public.construction_status_enum,
    'ready_to_move'::public.construction_status_enum,
    'ready_to_move'::public.construction_status_enum,
    'under_construction'::public.construction_status_enum,
    'ready_to_move'::public.construction_status_enum,
    'ready_to_move'::public.construction_status_enum,
    'new_launch'::public.construction_status_enum,
    'ready_to_move'::public.construction_status_enum,
    'ready_to_move'::public.construction_status_enum
  ];

  v_facings public.facing_direction_enum[] := ARRAY[
    'east'::public.facing_direction_enum,
    'north_east'::public.facing_direction_enum,
    'north'::public.facing_direction_enum,
    'east'::public.facing_direction_enum,
    'west'::public.facing_direction_enum,
    'north_east'::public.facing_direction_enum,
    'east'::public.facing_direction_enum,
    'north'::public.facing_direction_enum,
    'east'::public.facing_direction_enum,
    'north_east'::public.facing_direction_enum
  ];

  v_gallery_1 JSONB := '[
    {"url":"https://images.unsplash.com/photo-1600596542815-ffad4c1539a9?auto=format&fit=crop&w=1200&q=80","type":"image","title":"Living Room","is_cover":true},
    {"url":"https://images.unsplash.com/photo-1600585154340-be6161a56a0c?auto=format&fit=crop&w=1200&q=80","type":"image","title":"Master Bedroom","is_cover":false},
    {"url":"https://images.unsplash.com/photo-1600566753376-12c8ab7fb75b?auto=format&fit=crop&w=1200&q=80","type":"image","title":"Designer Kitchen","is_cover":false},
    {"url":"https://images.unsplash.com/photo-1512917774080-9991f1c4c750?auto=format&fit=crop&w=1200&q=80","type":"image","title":"Deck & Balcony","is_cover":false}
  ]'::jsonb;

  v_gallery_2 JSONB := '[
    {"url":"https://images.unsplash.com/photo-1613490493576-7fde63acd811?auto=format&fit=crop&w=1200&q=80","type":"image","title":"Penthouse Terrace","is_cover":true},
    {"url":"https://images.unsplash.com/photo-1564013799919-ab600027ffc6?auto=format&fit=crop&w=1200&q=80","type":"image","title":"Grand Foyer","is_cover":false},
    {"url":"https://images.unsplash.com/photo-1580587771525-78b9dba3b914?auto=format&fit=crop&w=1200&q=80","type":"image","title":"Infinity Plunge Pool","is_cover":false}
  ]'::jsonb;

  v_gallery_3 JSONB := '[
    {"url":"https://images.unsplash.com/photo-1522708323590-d24dbb6b0267?auto=format&fit=crop&w=1200&q=80","type":"image","title":"Smart Apartment Interior","is_cover":true},
    {"url":"https://images.unsplash.com/photo-1502672260266-1c1ef2d93688?auto=format&fit=crop&w=1200&q=80","type":"image","title":"Cozy Bedroom","is_cover":false},
    {"url":"https://images.unsplash.com/photo-1486406146926-c627a92ad1ab?auto=format&fit=crop&w=1200&q=80","type":"image","title":"Building Elevation","is_cover":false}
  ]'::jsonb;

  v_gallery_4 JSONB := '[
    {"url":"https://images.unsplash.com/photo-1613977257363-707ba9348227?auto=format&fit=crop&w=1200&q=80","type":"image","title":"Villa Facade","is_cover":true},
    {"url":"https://images.unsplash.com/photo-1570129477492-45c003edd2be?auto=format&fit=crop&w=1200&q=80","type":"image","title":"Private Lawn & Garden","is_cover":false},
    {"url":"https://images.unsplash.com/photo-1600607687939-ce8a6c25118c?auto=format&fit=crop&w=1200&q=80","type":"image","title":"Spacious Dining Room","is_cover":false}
  ]'::jsonb;

  v_gallery_5 JSONB := '[
    {"url":"https://images.unsplash.com/photo-1493809842364-78817add7ffb?auto=format&fit=crop&w=1200&q=80","type":"image","title":"Urban Loft Lounge","is_cover":true},
    {"url":"https://images.unsplash.com/photo-1545324418-cc1a3fa10c00?auto=format&fit=crop&w=1200&q=80","type":"image","title":"Modular Kitchenette","is_cover":false}
  ]'::jsonb;

  v_gallery_6 JSONB := '[
    {"url":"https://images.unsplash.com/photo-1486406146926-c627a92ad1ab?auto=format&fit=crop&w=1200&q=80","type":"image","title":"Commercial Tower","is_cover":true},
    {"url":"https://images.unsplash.com/photo-1497366216548-37526070297c?auto=format&fit=crop&w=1200&q=80","type":"image","title":"Open Office Floor","is_cover":false},
    {"url":"https://images.unsplash.com/photo-1497215728101-856f4ea42174?auto=format&fit=crop&w=1200&q=80","type":"image","title":"Conference Room","is_cover":false}
  ]'::jsonb;

  v_gallery_plot JSONB := '[
    {"url":"https://images.unsplash.com/photo-1500382017468-9049fed747ef?auto=format&fit=crop&w=1200&q=80","type":"image","title":"Plot Front View","is_cover":true},
    {"url":"https://images.unsplash.com/photo-1500076656116-558758c991c1?auto=format&fit=crop&w=1200&q=80","type":"image","title":"Gated Community Boulevard","is_cover":false}
  ]'::jsonb;

  v_galleries JSONB[];

  v_localities TEXT[] := ARRAY[
    'Worli Sea Face, Mumbai',
    'Indiranagar 100 Feet Road, Bengaluru',
    'Golf Course Extension Road, Gurgaon',
    'Banjara Hills Road No 12, Hyderabad',
    'Koregaon Park North Main Road, Pune',
    'Sindhu Bhavan Road, Bodakdev, Ahmedabad',
    'Boat Club Road, R.A. Puram, Chennai',
    'Bandra Kurla Complex (BKC), Mumbai',
    'Whitefield ITPL Main Road, Bengaluru',
    'Jubilee Hills Check Post, Hyderabad'
  ];

  v_cities TEXT[] := ARRAY[
    'Mumbai', 'Bengaluru', 'Gurgaon', 'Hyderabad', 'Pune', 'Ahmedabad', 'Chennai', 'Mumbai', 'Bengaluru', 'Hyderabad'
  ];

  v_states TEXT[] := ARRAY[
    'Maharashtra', 'Karnataka', 'Haryana', 'Telangana', 'Maharashtra', 'Gujarat', 'Tamil Nadu', 'Maharashtra', 'Karnataka', 'Telangana'
  ];

  v_pincodes TEXT[] := ARRAY[
    '400018', '560038', '122018', '500034', '411001', '380054', '600028', '400051', '560066', '500033'
  ];

  v_lats NUMERIC[] := ARRAY[
    19.0176, 12.9784, 28.4112, 17.4156, 18.5362, 23.0396, 13.0245, 19.0657, 12.9855, 17.4319
  ];

  v_lngs NUMERIC[] := ARRAY[
    72.8174, 77.6408, 77.0689, 78.4354, 73.8939, 72.5064, 80.2516, 72.8687, 77.7346, 78.4073
  ];

BEGIN
  v_galleries := ARRAY[v_gallery_1, v_gallery_2, v_gallery_3, v_gallery_4, v_gallery_5, v_gallery_6, v_gallery_6, v_gallery_1, v_gallery_2, v_gallery_plot];

  FOR v_broker IN SELECT id, business_name FROM public.brokers ORDER BY created_at ASC LOOP
    FOR v_idx IN 1..10 LOOP
      v_addr_id := gen_random_uuid();
      v_prop_id := gen_random_uuid();

      -- Insert into public.addresses matching exact live schema
      INSERT INTO public.addresses (
        id,
        full_address,
        landmark,
        city,
        state,
        pincode,
        country,
        latitude,
        longitude,
        entity_type,
        entity_id,
        is_deleted,
        created_at,
        updated_at
      ) VALUES (
        v_addr_id,
        'Tower ' || CHR(64 + v_idx) || ', Suite ' || (v_floors[v_idx] * 100 + v_idx)::text || ', ' || v_localities[v_idx],
        'Opposite Central Boulevard Gardens',
        v_cities[v_idx],
        v_states[v_idx],
        v_pincodes[v_idx],
        'India',
        v_lats[v_idx] + (RANDOM() * 0.008 - 0.004),
        v_lngs[v_idx] + (RANDOM() * 0.008 - 0.004),
        'property',
        v_prop_id,
        false,
        NOW() - (v_idx || ' days')::INTERVAL,
        NOW()
      );

      -- Insert into public.properties (auto-triggers set unique property_code)
      INSERT INTO public.properties (
        id,
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
        is_active,
        is_deleted,
        deleted_at,
        created_at,
        updated_at
      ) VALUES (
        v_prop_id,
        v_broker.id,
        v_addr_id,
        v_titles[v_idx] || ' at ' || v_localities[v_idx],
        v_descs[v_idx],
        v_prop_types[v_idx],
        v_list_types[v_idx],
        v_prices[v_idx],
        v_areas[v_idx],
        'sqft'::public.area_unit_enum,
        v_beds[v_idx],
        v_baths[v_idx],
        v_balcs[v_idx],
        v_parks[v_idx],
        v_floors[v_idx],
        v_total_fls[v_idx],
        v_furnishings[v_idx],
        'available'::public.property_status_enum,
        v_const_statuses[v_idx],
        v_facings[v_idx],
        '["Gymnasium","Swimming Pool","Covered Car Parking","24x7 Security","Club House","Power Backup","Jogging Track","High Speed Elevators","CCTV Surveillance","Smart Home Automation","Yoga Deck","EV Charging Station"]'::jsonb,
        v_galleries[v_idx],
        true,
        false,
        NULL,
        NOW() - (v_idx || ' days')::INTERVAL,
        NOW()
      );

    END LOOP;
  END LOOP;
END;
$$;
