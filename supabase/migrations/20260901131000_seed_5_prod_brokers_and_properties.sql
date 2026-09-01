-- Migration: 20260901131000_seed_5_prod_brokers_and_properties.sql
-- Description: Seeds 5 unique verified broker accounts (with auth.users credentials) and 25 completely distinct properties on Production.

DO $$
DECLARE
  v_encrypted_password TEXT := extensions.crypt('RealtyBazaar@2026', extensions.gen_salt('bf'));

  -- Broker 1 IDs
  v_b1_user_id UUID := gen_random_uuid();
  v_b1_broker_id UUID := gen_random_uuid();
  v_b1_addr_id UUID := gen_random_uuid();

  -- Broker 2 IDs
  v_b2_user_id UUID := gen_random_uuid();
  v_b2_broker_id UUID := gen_random_uuid();
  v_b2_addr_id UUID := gen_random_uuid();

  -- Broker 3 IDs
  v_b3_user_id UUID := gen_random_uuid();
  v_b3_broker_id UUID := gen_random_uuid();
  v_b3_addr_id UUID := gen_random_uuid();

  -- Broker 4 IDs
  v_b4_user_id UUID := gen_random_uuid();
  v_b4_broker_id UUID := gen_random_uuid();
  v_b4_addr_id UUID := gen_random_uuid();

  -- Broker 5 IDs
  v_b5_user_id UUID := gen_random_uuid();
  v_b5_broker_id UUID := gen_random_uuid();
  v_b5_addr_id UUID := gen_random_uuid();

  -- Property loop variables
  v_prop_addr_id UUID;
  v_prop_id UUID;

BEGIN

  -- =========================================================================
  -- 1. CREATE BROKER 1: Singhania Luxury Estates (Mumbai)
  -- =========================================================================
  INSERT INTO public.addresses (id, full_address, landmark, city, state, pincode, country, latitude, longitude, entity_type, entity_id, is_deleted)
  VALUES (v_b1_addr_id, 'Suite 1402, One International Center, Senapati Bapat Marg, Lower Parel', 'Near Palladium Mall', 'Mumbai', 'Maharashtra', '400013', 'India', 18.9986, 72.8258, 'broker', v_b1_broker_id, false);

  INSERT INTO public.brokers (id, business_name, broker_code, plan, onboarding_status, address_id, is_active, is_deleted, auto_approve_video_requests, setup_details)
  VALUES (v_b1_broker_id, 'Singhania Luxury Estates', 'SL1', 'HIGH-VOLUME ELITE', 'completed', v_b1_addr_id, true, false, true, '{"account_created":true,"business_info_added":true,"facebook_connected":true,"instagram_connected":true,"properties_imported":true}'::jsonb);

  INSERT INTO auth.users (id, instance_id, aud, role, email, encrypted_password, email_confirmed_at, raw_app_meta_data, raw_user_meta_data, created_at, updated_at, phone, phone_confirmed_at, confirmation_token, email_change, email_change_token_new, recovery_token)
  VALUES (v_b1_user_id, '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated', 'vikram.singhania@realtybazaar.in', v_encrypted_password, NOW(), '{"provider":"email","providers":["email"]}'::jsonb, '{"name":"Vikram Singhania","role":"broker"}'::jsonb, NOW(), NOW(), '919820111221', NOW(), '', '', '', '');

  INSERT INTO public.users (id, name, email, phone, phone_country_code, phone_country_iso, role, is_active, is_deleted, broker_id, is_email_verified, cover_image, notes)
  VALUES (v_b1_user_id, 'Vikram Singhania', 'vikram.singhania@realtybazaar.in', '9820111221', '91', 'IN', 'broker'::public.user_role, true, false, v_b1_broker_id, true, '{"url":"https://images.unsplash.com/photo-1560518883-ce09059eeffa?auto=format&fit=crop&w=1200&q=80","name":"cover.jpg"}'::jsonb, 'Principal luxury real estate partner specializing in South Mumbai and Sea Face penthouses.');

  -- Properties for Broker 1
  -- SL1-001
  v_prop_addr_id := gen_random_uuid();
  v_prop_id := gen_random_uuid();
  INSERT INTO public.addresses (id, full_address, landmark, city, state, pincode, country, latitude, longitude, entity_type, entity_id, is_deleted)
  VALUES (v_prop_addr_id, 'Tower 1, Sky Penthouse 44, Worli Sea Face', 'Opposite Coastline Promenade', 'Mumbai', 'Maharashtra', '400030', 'India', 19.0176, 72.8174, 'property', v_prop_id, false);

  INSERT INTO public.properties (id, broker_id, address_id, property_title, property_description, property_type, listing_type, price, area, area_unit, bedrooms, bathrooms, balconies, parking, floor_number, total_floors, furnishing_status, property_status, construction_status, facing, amenities, medias, is_active, is_deleted)
  VALUES (v_prop_id, v_b1_broker_id, v_prop_addr_id, 'Ultra-Luxurious 4 BHK Sea View Penthouse with Private Plunge Pool at Worli Sea Face, Mumbai', 'Presenting an uncompromised sky villa offering panoramic Arabian Sea vistas, double-height ceilings, private plunge pool, and Italian marble finishes throughout.', 'penthouse'::public.property_type_enum, 'sale'::public.listing_type_enum, 185000000, 4800, 'sqft'::public.area_unit_enum, 4, 5, 3, 3, 44, 45, 'fully_furnished'::public.furnishing_status_enum, 'available'::public.property_status_enum, 'ready_to_move'::public.construction_status_enum, 'west'::public.facing_direction_enum, '["Private Plunge Pool","Infinity Rooftop Pool","Smart Home Automation","24x7 Concierge","Private Elevator","Gymnasium","Spa & Sauna","Covered Car Parking","High Speed Elevators"]'::jsonb, '[{"url":"https://images.unsplash.com/photo-1600596542815-ffad4c1539a9?auto=format&fit=crop&w=1200&q=80","type":"image","title":"Living Lounge","is_cover":true},{"url":"https://images.unsplash.com/photo-1613490493576-7fde63acd811?auto=format&fit=crop&w=1200&q=80","type":"image","title":"Sea View Deck","is_cover":false},{"url":"https://images.unsplash.com/photo-1600566753376-12c8ab7fb75b?auto=format&fit=crop&w=1200&q=80","type":"image","title":"Gourmet Kitchen","is_cover":false}]'::jsonb, true, false);

  -- SL1-002
  v_prop_addr_id := gen_random_uuid();
  v_prop_id := gen_random_uuid();
  INSERT INTO public.addresses (id, full_address, landmark, city, state, pincode, country, latitude, longitude, entity_type, entity_id, is_deleted)
  VALUES (v_prop_addr_id, 'Residence 802, Turner Road Signature, Bandra West', 'Behind Carter Road Promenade', 'Mumbai', 'Maharashtra', '400050', 'India', 19.0596, 72.8295, 'property', v_prop_id, false);

  INSERT INTO public.properties (id, broker_id, address_id, property_title, property_description, property_type, listing_type, price, area, area_unit, bedrooms, bathrooms, balconies, parking, floor_number, total_floors, furnishing_status, property_status, construction_status, facing, amenities, medias, is_active, is_deleted)
  VALUES (v_prop_id, v_b1_broker_id, v_prop_addr_id, 'Designer 3 BHK Smart Apartment with Italian Marble at Bandra West, Mumbai', 'Exquisitely crafted residence located in upscale Bandra West featuring open-plan layouts, acoustic soundproof glass, and designer lighting fixtures.', 'apartment'::public.property_type_enum, 'sale'::public.listing_type_enum, 72500000, 1950, 'sqft'::public.area_unit_enum, 3, 3, 2, 2, 8, 14, 'fully_furnished'::public.furnishing_status_enum, 'available'::public.property_status_enum, 'ready_to_move'::public.construction_status_enum, 'north_east'::public.facing_direction_enum, '["Gymnasium","Covered Car Parking","Power Backup","24x7 Security","CCTV Surveillance","Club House"]'::jsonb, '[{"url":"https://images.unsplash.com/photo-1522708323590-d24dbb6b0267?auto=format&fit=crop&w=1200&q=80","type":"image","title":"Interior Living","is_cover":true},{"url":"https://images.unsplash.com/photo-1502672260266-1c1ef2d93688?auto=format&fit=crop&w=1200&q=80","type":"image","title":"Master Bedroom","is_cover":false}]'::jsonb, true, false);

  -- SL1-003
  v_prop_addr_id := gen_random_uuid();
  v_prop_id := gen_random_uuid();
  INSERT INTO public.addresses (id, full_address, landmark, city, state, pincode, country, latitude, longitude, entity_type, entity_id, is_deleted)
  VALUES (v_prop_addr_id, 'Level 9, One BKC Commercial Tower, G Block, Bandra Kurla Complex', 'Opposite MCA Club', 'Mumbai', 'Maharashtra', '400051', 'India', 19.0657, 72.8687, 'property', v_prop_id, false);

  INSERT INTO public.properties (id, broker_id, address_id, property_title, property_description, property_type, listing_type, price, area, area_unit, bedrooms, bathrooms, balconies, parking, floor_number, total_floors, furnishing_status, property_status, construction_status, facing, amenities, medias, is_active, is_deleted)
  VALUES (v_prop_id, v_b1_broker_id, v_prop_addr_id, 'Grade-A Enterprise Workspace Floor at One BKC, Bandra Kurla Complex, Mumbai', 'Premium corporate office floor with column-free space, central HVAC, high-speed elevators, and 100% DG backup in Mumbai premier CBD.', 'commercial'::public.property_type_enum, 'lease'::public.listing_type_enum, 650000, 5200, 'sqft'::public.area_unit_enum, 0, 4, 0, 5, 9, 20, 'unfurnished'::public.furnishing_status_enum, 'available'::public.property_status_enum, 'ready_to_move'::public.construction_status_enum, 'east'::public.facing_direction_enum, '["High Speed Elevators","Power Backup","24x7 Security","Covered Car Parking","CCTV Surveillance","Fire Fighting Systems"]'::jsonb, '[{"url":"https://images.unsplash.com/photo-1486406146926-c627a92ad1ab?auto=format&fit=crop&w=1200&q=80","type":"image","title":"Tower Elevation","is_cover":true},{"url":"https://images.unsplash.com/photo-1497366216548-37526070297c?auto=format&fit=crop&w=1200&q=80","type":"image","title":"Open Office Floor","is_cover":false}]'::jsonb, true, false);

  -- SL1-004
  v_prop_addr_id := gen_random_uuid();
  v_prop_id := gen_random_uuid();
  INSERT INTO public.addresses (id, full_address, landmark, city, state, pincode, country, latitude, longitude, entity_type, entity_id, is_deleted)
  VALUES (v_prop_addr_id, 'Ground Floor, Corner Plaza, Linking Road, Khar West', 'Near Khar Telephone Exchange', 'Mumbai', 'Maharashtra', '400052', 'India', 19.0688, 72.8344, 'property', v_prop_id, false);

  INSERT INTO public.properties (id, broker_id, address_id, property_title, property_description, property_type, listing_type, price, area, area_unit, bedrooms, bathrooms, balconies, parking, floor_number, total_floors, furnishing_status, property_status, construction_status, facing, amenities, medias, is_active, is_deleted)
  VALUES (v_prop_id, v_b1_broker_id, v_prop_addr_id, 'High-Street Retail Showroom on Linking Road at Khar West, Mumbai', 'Prominent retail flagship showroom with 80-ft clear road frontage on Mumbai highest-footfall shopping corridor.', 'commercial'::public.property_type_enum, 'rent'::public.listing_type_enum, 480000, 2400, 'sqft'::public.area_unit_enum, 0, 2, 0, 2, 1, 4, 'semi_furnished'::public.furnishing_status_enum, 'available'::public.property_status_enum, 'ready_to_move'::public.construction_status_enum, 'west'::public.facing_direction_enum, '["Power Backup","24x7 Security","CCTV Surveillance","High Footfall Visibility"]'::jsonb, '[{"url":"https://images.unsplash.com/photo-1497215728101-856f4ea42174?auto=format&fit=crop&w=1200&q=80","type":"image","title":"Retail Showroom Frontage","is_cover":true}]'::jsonb, true, false);

  -- SL1-005
  v_prop_addr_id := gen_random_uuid();
  v_prop_id := gen_random_uuid();
  INSERT INTO public.addresses (id, full_address, landmark, city, state, pincode, country, latitude, longitude, entity_type, entity_id, is_deleted)
  VALUES (v_prop_addr_id, 'Flat 12B, Marine Mansion, Marine Drive', 'Opposite Queen Necklace Promenade', 'Mumbai', 'Maharashtra', '400020', 'India', 18.9438, 72.8232, 'property', v_prop_id, false);

  INSERT INTO public.properties (id, broker_id, address_id, property_title, property_description, property_type, listing_type, price, area, area_unit, bedrooms, bathrooms, balconies, parking, floor_number, total_floors, furnishing_status, property_status, construction_status, facing, amenities, medias, is_active, is_deleted)
  VALUES (v_prop_id, v_b1_broker_id, v_prop_addr_id, 'Waterfront 3 BHK Luxury Duplex at Marine Drive, South Mumbai', 'Iconic heritage seafront duplex with timeless Art Deco architecture, majestic sunset views, and high ceilings.', 'apartment'::public.property_type_enum, 'sale'::public.listing_type_enum, 140000000, 2600, 'sqft'::public.area_unit_enum, 3, 4, 2, 2, 12, 16, 'fully_furnished'::public.furnishing_status_enum, 'available'::public.property_status_enum, 'ready_to_move'::public.construction_status_enum, 'west'::public.facing_direction_enum, '["Power Backup","24x7 Security","Sea View Sundeck","Covered Car Parking"]'::jsonb, '[{"url":"https://images.unsplash.com/photo-1545324418-cc1a3fa10c00?auto=format&fit=crop&w=1200&q=80","type":"image","title":"Marine Drive Living Area","is_cover":true}]'::jsonb, true, false);


  -- =========================================================================
  -- 2. CREATE BROKER 2: Roy & Associates Prime Realty (Bengaluru)
  -- =========================================================================
  INSERT INTO public.addresses (id, full_address, landmark, city, state, pincode, country, latitude, longitude, entity_type, entity_id, is_deleted)
  VALUES (v_b2_addr_id, 'No. 402, 100 Feet Road, HAL 2nd Stage, Indiranagar', 'Near Sony Signal', 'Bengaluru', 'Karnataka', '560038', 'India', 12.9784, 77.6408, 'broker', v_b2_broker_id, false);

  INSERT INTO public.brokers (id, business_name, broker_code, plan, onboarding_status, address_id, is_active, is_deleted, auto_approve_video_requests, setup_details)
  VALUES (v_b2_broker_id, 'Roy & Associates Prime Realty', 'RA1', 'GROWTH PRO', 'completed', v_b2_addr_id, true, false, true, '{"account_created":true,"business_info_added":true,"facebook_connected":true,"instagram_connected":true,"properties_imported":true}'::jsonb);

  INSERT INTO auth.users (id, instance_id, aud, role, email, encrypted_password, email_confirmed_at, raw_app_meta_data, raw_user_meta_data, created_at, updated_at, phone, phone_confirmed_at, confirmation_token, email_change, email_change_token_new, recovery_token)
  VALUES (v_b2_user_id, '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated', 'ananya.roy@realtybazaar.in', v_encrypted_password, NOW(), '{"provider":"email","providers":["email"]}'::jsonb, '{"name":"Ananya Roy","role":"broker"}'::jsonb, NOW(), NOW(), '919845033442', NOW(), '', '', '', '');

  INSERT INTO public.users (id, name, email, phone, phone_country_code, phone_country_iso, role, is_active, is_deleted, broker_id, is_email_verified, cover_image, notes)
  VALUES (v_b2_user_id, 'Ananya Roy', 'ananya.roy@realtybazaar.in', '9845033442', '91', 'IN', 'broker'::public.user_role, true, false, v_b2_broker_id, true, '{"url":"https://images.unsplash.com/photo-1573496359142-b8d87734a5a2?auto=format&fit=crop&w=1200&q=80","name":"cover.jpg"}'::jsonb, 'Bengaluru prime residential and villa specialist across Indiranagar, Whitefield, and Sarjapur.');

  -- Properties for Broker 2
  -- RA1-001
  v_prop_addr_id := gen_random_uuid();
  v_prop_id := gen_random_uuid();
  INSERT INTO public.addresses (id, full_address, landmark, city, state, pincode, country, latitude, longitude, entity_type, entity_id, is_deleted)
  VALUES (v_prop_addr_id, 'Apartment 4A, Green Meadows, 12th Main, Indiranagar', 'Near Defence Colony Park', 'Bengaluru', 'Karnataka', '560038', 'India', 12.9719, 77.6412, 'property', v_prop_id, false);

  INSERT INTO public.properties (id, broker_id, address_id, property_title, property_description, property_type, listing_type, price, area, area_unit, bedrooms, bathrooms, balconies, parking, floor_number, total_floors, furnishing_status, property_status, construction_status, facing, amenities, medias, is_active, is_deleted)
  VALUES (v_prop_id, v_b2_broker_id, v_prop_addr_id, 'Scandinavian Minimalist 3 BHK Smart Home with Home Automation at Indiranagar, Bengaluru', 'Chic urban retreat featuring minimalist natural oak woodwork, voice-controlled smart ambient lighting, and serene balcony garden.', 'apartment'::public.property_type_enum, 'sale'::public.listing_type_enum, 31000000, 1820, 'sqft'::public.area_unit_enum, 3, 3, 2, 2, 4, 8, 'semi_furnished'::public.furnishing_status_enum, 'available'::public.property_status_enum, 'ready_to_move'::public.construction_status_enum, 'north_east'::public.facing_direction_enum, '["Smart Home Automation","Gymnasium","Solar Water Heater","Club House","Covered Car Parking","24x7 Security"]'::jsonb, '[{"url":"https://images.unsplash.com/photo-1600585154340-be6161a56a0c?auto=format&fit=crop&w=1200&q=80","type":"image","title":"Living Space","is_cover":true},{"url":"https://images.unsplash.com/photo-1512917774080-9991f1c4c750?auto=format&fit=crop&w=1200&q=80","type":"image","title":"Balcony Nook","is_cover":false}]'::jsonb, true, false);

  -- RA1-002
  v_prop_addr_id := gen_random_uuid();
  v_prop_id := gen_random_uuid();
  INSERT INTO public.addresses (id, full_address, landmark, city, state, pincode, country, latitude, longitude, entity_type, entity_id, is_deleted)
  VALUES (v_prop_addr_id, 'Villa 28, Palm Meadows Gated Enclave, Whitefield', 'Near Forum Shantiniketan Mall', 'Bengaluru', 'Karnataka', '560066', 'India', 12.9855, 77.7346, 'property', v_prop_id, false);

  INSERT INTO public.properties (id, broker_id, address_id, property_title, property_description, property_type, listing_type, price, area, area_unit, bedrooms, bathrooms, balconies, parking, floor_number, total_floors, furnishing_status, property_status, construction_status, facing, amenities, medias, is_active, is_deleted)
  VALUES (v_prop_id, v_b2_broker_id, v_prop_addr_id, 'Contemporary 4 BHK Gated Community Villa with Private Garden at Whitefield, Bengaluru', 'Luxury independent villa nestled in a lush 50-acre gated enclave. Comes with landscaped private lawn, modular bar, and double covered carport.', 'villa'::public.property_type_enum, 'sale'::public.listing_type_enum, 54000000, 3800, 'sqft'::public.area_unit_enum, 4, 5, 3, 2, 1, 2, 'fully_furnished'::public.furnishing_status_enum, 'available'::public.property_status_enum, 'ready_to_move'::public.construction_status_enum, 'east'::public.facing_direction_enum, '["Private Garden","Swimming Pool","Tennis Court","Club House","Jogging Track","24x7 Security","EV Charging Station"]'::jsonb, '[{"url":"https://images.unsplash.com/photo-1613977257363-707ba9348227?auto=format&fit=crop&w=1200&q=80","type":"image","title":"Villa Facade","is_cover":true},{"url":"https://images.unsplash.com/photo-1570129477492-45c003edd2be?auto=format&fit=crop&w=1200&q=80","type":"image","title":"Lawn Garden","is_cover":false}]'::jsonb, true, false);

  -- RA1-003
  v_prop_addr_id := gen_random_uuid();
  v_prop_id := gen_random_uuid();
  INSERT INTO public.addresses (id, full_address, landmark, city, state, pincode, country, latitude, longitude, entity_type, entity_id, is_deleted)
  VALUES (v_prop_addr_id, 'Flat 301, Nexus Residency, 5th Block, Koramangala', 'Near Jyoti Nivas College', 'Bengaluru', 'Karnataka', '560095', 'India', 12.9352, 77.6245, 'property', v_prop_id, false);

  INSERT INTO public.properties (id, broker_id, address_id, property_title, property_description, property_type, listing_type, price, area, area_unit, bedrooms, bathrooms, balconies, parking, floor_number, total_floors, furnishing_status, property_status, construction_status, facing, amenities, medias, is_active, is_deleted)
  VALUES (v_prop_id, v_b2_broker_id, v_prop_addr_id, 'Executive 2 BHK Urban Loft near Tech Hub at Koramangala, Bengaluru', 'Modern loft apartment ideal for tech professionals. Walking distance from premier cafes, co-working spaces, and nightlife.', 'apartment'::public.property_type_enum, 'rent'::public.listing_type_enum, 65000, 1150, 'sqft'::public.area_unit_enum, 2, 2, 1, 1, 3, 6, 'fully_furnished'::public.furnishing_status_enum, 'available'::public.property_status_enum, 'ready_to_move'::public.construction_status_enum, 'north'::public.facing_direction_enum, '["Gymnasium","Power Backup","24x7 Security","High Speed Elevators"]'::jsonb, '[{"url":"https://images.unsplash.com/photo-1493809842364-78817add7ffb?auto=format&fit=crop&w=1200&q=80","type":"image","title":"Living Lounge","is_cover":true}]'::jsonb, true, false);

  -- RA1-004
  v_prop_addr_id := gen_random_uuid();
  v_prop_id := gen_random_uuid();
  INSERT INTO public.addresses (id, full_address, landmark, city, state, pincode, country, latitude, longitude, entity_type, entity_id, is_deleted)
  VALUES (v_prop_addr_id, 'Sky Residence 32B, Lakeview Heights, Outer Ring Road, Bellandur', 'Behind EcoWorld Tech Park', 'Bengaluru', 'Karnataka', '560103', 'India', 12.9255, 77.6782, 'property', v_prop_id, false);

  INSERT INTO public.properties (id, broker_id, address_id, property_title, property_description, property_type, listing_type, price, area, area_unit, bedrooms, bathrooms, balconies, parking, floor_number, total_floors, furnishing_status, property_status, construction_status, facing, amenities, medias, is_active, is_deleted)
  VALUES (v_prop_id, v_b2_broker_id, v_prop_addr_id, '4 BHK Sky Villa on 32nd Floor with Lake Views at Bellandur, Bengaluru', 'High-rise residence with uninterrupted lake panorama, private foyer, wrap-around sundeck, and expansive bedroom suites.', 'apartment'::public.property_type_enum, 'sale'::public.listing_type_enum, 48000000, 3100, 'sqft'::public.area_unit_enum, 4, 4, 3, 2, 32, 36, 'semi_furnished'::public.furnishing_status_enum, 'available'::public.property_status_enum, 'under_construction'::public.construction_status_enum, 'east'::public.facing_direction_enum, '["Infinity Rooftop Pool","Club House","Squash Court","Badminton Court","Children Play Area"]'::jsonb, '[{"url":"https://images.unsplash.com/photo-1600607687939-ce8a6c25118c?auto=format&fit=crop&w=1200&q=80","type":"image","title":"Panoramic Deck","is_cover":true}]'::jsonb, true, false);

  -- RA1-005
  v_prop_addr_id := gen_random_uuid();
  v_prop_id := gen_random_uuid();
  INSERT INTO public.addresses (id, full_address, landmark, city, state, pincode, country, latitude, longitude, entity_type, entity_id, is_deleted)
  VALUES (v_prop_addr_id, 'Plot No. 112, Grandeur Greens Township, Sarjapur Road', 'Opposite Wipro SEZ Campus', 'Bengaluru', 'Karnataka', '560035', 'India', 12.8984, 77.7123, 'property', v_prop_id, false);

  INSERT INTO public.properties (id, broker_id, address_id, property_title, property_description, property_type, listing_type, price, area, area_unit, bedrooms, bathrooms, balconies, parking, floor_number, total_floors, furnishing_status, property_status, construction_status, facing, amenities, medias, is_active, is_deleted)
  VALUES (v_prop_id, v_b2_broker_id, v_prop_addr_id, '4,000 sqft Premium Gated Villa Plot with Clubhouse Membership at Sarjapur Road, Bengaluru', 'Ready-to-construct corner residential plot with tree-lined avenue roads, underground utilities, and guaranteed BDA compliance.', 'plot'::public.property_type_enum, 'sale'::public.listing_type_enum, 19500000, 4000, 'sqft'::public.area_unit_enum, 0, 0, 0, 0, 0, 0, 'unfurnished'::public.furnishing_status_enum, 'available'::public.property_status_enum, 'ready_to_move'::public.construction_status_enum, 'north_east'::public.facing_direction_enum, '["Club House","Gated Security","Tree-Lined Avenues","Underground Cabling"]'::jsonb, '[{"url":"https://images.unsplash.com/photo-1500382017468-9049fed747ef?auto=format&fit=crop&w=1200&q=80","type":"image","title":"Plot View","is_cover":true}]'::jsonb, true, false);


  -- =========================================================================
  -- 3. CREATE BROKER 3: Oberoi Commercial & Retail Advisory (Delhi NCR)
  -- =========================================================================
  INSERT INTO public.addresses (id, full_address, landmark, city, state, pincode, country, latitude, longitude, entity_type, entity_id, is_deleted)
  VALUES (v_b3_addr_id, '11th Floor, Two Horizon Centre, Golf Course Road, DLF Phase 5', 'Near One Horizon Center', 'Gurgaon', 'Haryana', '122002', 'India', 28.4595, 77.0266, 'broker', v_b3_broker_id, false);

  INSERT INTO public.brokers (id, business_name, broker_code, plan, onboarding_status, address_id, is_active, is_deleted, auto_approve_video_requests, setup_details)
  VALUES (v_b3_broker_id, 'Oberoi Commercial & Retail Advisory', 'OC1', 'HIGH-VOLUME ELITE', 'completed', v_b3_addr_id, true, false, true, '{"account_created":true,"business_info_added":true,"facebook_connected":true,"instagram_connected":true,"properties_imported":true}'::jsonb);

  INSERT INTO auth.users (id, instance_id, aud, role, email, encrypted_password, email_confirmed_at, raw_app_meta_data, raw_user_meta_data, created_at, updated_at, phone, phone_confirmed_at, confirmation_token, email_change, email_change_token_new, recovery_token)
  VALUES (v_b3_user_id, '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated', 'kabir.oberoi@realtybazaar.in', v_encrypted_password, NOW(), '{"provider":"email","providers":["email"]}'::jsonb, '{"name":"Kabir Oberoi","role":"broker"}'::jsonb, NOW(), NOW(), '919811055663', NOW(), '', '', '', '');

  INSERT INTO public.users (id, name, email, phone, phone_country_code, phone_country_iso, role, is_active, is_deleted, broker_id, is_email_verified, cover_image, notes)
  VALUES (v_b3_user_id, 'Kabir Oberoi', 'kabir.oberoi@realtybazaar.in', '9811055663', '91', 'IN', 'broker'::public.user_role, true, false, v_b3_broker_id, true, '{"url":"https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?auto=format&fit=crop&w=1200&q=80","name":"cover.jpg"}'::jsonb, 'Institutional commercial asset advisor and luxury estate broker across Gurgaon and South Delhi.');

  -- Properties for Broker 3
  -- OC1-001
  v_prop_addr_id := gen_random_uuid();
  v_prop_id := gen_random_uuid();
  INSERT INTO public.addresses (id, full_address, landmark, city, state, pincode, country, latitude, longitude, entity_type, entity_id, is_deleted)
  VALUES (v_prop_addr_id, '7th Floor, Cyber Park Avenue, Golf Course Extension Road', 'Near Sector 56 Metro Station', 'Gurgaon', 'Haryana', '122018', 'India', 28.4112, 77.0689, 'property', v_prop_id, false);

  INSERT INTO public.properties (id, broker_id, address_id, property_title, property_description, property_type, listing_type, price, area, area_unit, bedrooms, bathrooms, balconies, parking, floor_number, total_floors, furnishing_status, property_status, construction_status, facing, amenities, medias, is_active, is_deleted)
  VALUES (v_prop_id, v_b3_broker_id, v_prop_addr_id, 'Premium Grade-A Office Floor Plate with 100% Power Backup at Golf Course Ext Road, Gurgaon', 'LEED Platinum certified commercial floor plate offering top-tier mechanical ventilation, dedicated executive restrooms, and multi-tier security.', 'commercial'::public.property_type_enum, 'lease'::public.listing_type_enum, 520000, 6800, 'sqft'::public.area_unit_enum, 0, 6, 0, 6, 7, 18, 'unfurnished'::public.furnishing_status_enum, 'available'::public.property_status_enum, 'ready_to_move'::public.construction_status_enum, 'north_east'::public.facing_direction_enum, '["100% DG Power Backup","Central HVAC","High Speed Elevators","24x7 Security","Multi-Level Parking","CCTV Surveillance"]'::jsonb, '[{"url":"https://images.unsplash.com/photo-1486406146926-c627a92ad1ab?auto=format&fit=crop&w=1200&q=80","type":"image","title":"Corporate Glass Elevation","is_cover":true}]'::jsonb, true, false);

  -- OC1-002
  v_prop_addr_id := gen_random_uuid();
  v_prop_id := gen_random_uuid();
  INSERT INTO public.addresses (id, full_address, landmark, city, state, pincode, country, latitude, longitude, entity_type, entity_id, is_deleted)
  VALUES (v_prop_addr_id, 'Worldmark 3, Hospitality District, Aerocity', 'Minutes from Terminal 3 IGI Airport', 'New Delhi', 'Delhi', '110037', 'India', 28.5492, 77.1214, 'property', v_prop_id, false);

  INSERT INTO public.properties (id, broker_id, address_id, property_title, property_description, property_type, listing_type, price, area, area_unit, bedrooms, bathrooms, balconies, parking, floor_number, total_floors, furnishing_status, property_status, construction_status, facing, amenities, medias, is_active, is_deleted)
  VALUES (v_prop_id, v_b3_broker_id, v_prop_addr_id, 'High-Footfall Corner Retail Flagship Showroom at Aerocity, New Delhi', 'High-end retail anchor showroom situated inside Worldmark Aerocity with high domestic & global footfalls.', 'commercial'::public.property_type_enum, 'lease'::public.listing_type_enum, 850000, 4200, 'sqft'::public.area_unit_enum, 0, 3, 0, 4, 1, 6, 'unfurnished'::public.furnishing_status_enum, 'available'::public.property_status_enum, 'ready_to_move'::public.construction_status_enum, 'east'::public.facing_direction_enum, '["Valet Parking","Central Air Conditioning","24x7 Security","Airport Connectivity"]'::jsonb, '[{"url":"https://images.unsplash.com/photo-1497215728101-856f4ea42174?auto=format&fit=crop&w=1200&q=80","type":"image","title":"Aerocity Retail Hub","is_cover":true}]'::jsonb, true, false);

  -- OC1-003
  v_prop_addr_id := gen_random_uuid();
  v_prop_id := gen_random_uuid();
  INSERT INTO public.addresses (id, full_address, landmark, city, state, pincode, country, latitude, longitude, entity_type, entity_id, is_deleted)
  VALUES (v_prop_addr_id, '2nd Floor, S-Block, Greater Kailash II', 'Near M-Block Market', 'New Delhi', 'Delhi', '110048', 'India', 28.5323, 77.2415, 'property', v_prop_id, false);

  INSERT INTO public.properties (id, broker_id, address_id, property_title, property_description, property_type, listing_type, price, area, area_unit, bedrooms, bathrooms, balconies, parking, floor_number, total_floors, furnishing_status, property_status, construction_status, facing, amenities, medias, is_active, is_deleted)
  VALUES (v_prop_id, v_b3_broker_id, v_prop_addr_id, 'Modern 4 BHK Luxury Builder Floor with Private Lift at Greater Kailash II, South Delhi', 'Ultra-luxurious builder floor with private key-accessed elevator, Italian modular kitchen, servant quarters, and 2 stilt parkings.', 'apartment'::public.property_type_enum, 'sale'::public.listing_type_enum, 68000000, 3200, 'sqft'::public.area_unit_enum, 4, 5, 2, 2, 2, 4, 'fully_furnished'::public.furnishing_status_enum, 'available'::public.property_status_enum, 'ready_to_move'::public.construction_status_enum, 'north_east'::public.facing_direction_enum, '["Private Elevator","Power Backup","Stilt Parking","Gated Security"]'::jsonb, '[{"url":"https://images.unsplash.com/photo-1600585154340-be6161a56a0c?auto=format&fit=crop&w=1200&q=80","type":"image","title":"Interior Living Room","is_cover":true}]'::jsonb, true, false);

  -- OC1-004
  v_prop_addr_id := gen_random_uuid();
  v_prop_id := gen_random_uuid();
  INSERT INTO public.addresses (id, full_address, landmark, city, state, pincode, country, latitude, longitude, entity_type, entity_id, is_deleted)
  VALUES (v_prop_addr_id, 'Farm 14, Main Green Avenue, Chattarpur Farms', 'Near Tivoli Grand', 'New Delhi', 'Delhi', '110074', 'India', 28.5021, 77.1689, 'property', v_prop_id, false);

  INSERT INTO public.properties (id, broker_id, address_id, property_title, property_description, property_type, listing_type, price, area, area_unit, bedrooms, bathrooms, balconies, parking, floor_number, total_floors, furnishing_status, property_status, construction_status, facing, amenities, medias, is_active, is_deleted)
  VALUES (v_prop_id, v_b3_broker_id, v_prop_addr_id, '5 BHK Super-Luxury Farmhouse with Swimming Pool & Lawn at Chattarpur, New Delhi', 'Magnificent 2-acre private country estate with heated pool, landscaped pavilions, organic kitchen garden, and guardhouse.', 'villa'::public.property_type_enum, 'sale'::public.listing_type_enum, 220000000, 10500, 'sqft'::public.area_unit_enum, 5, 6, 4, 6, 1, 2, 'fully_furnished'::public.furnishing_status_enum, 'available'::public.property_status_enum, 'ready_to_move'::public.construction_status_enum, 'east'::public.facing_direction_enum, '["Private Swimming Pool","2-Acre Lawn","Staff Quarters","Solar Microgrid","Dolby Theatre"]'::jsonb, '[{"url":"https://images.unsplash.com/photo-1564013799919-ab600027ffc6?auto=format&fit=crop&w=1200&q=80","type":"image","title":"Estate Elevation","is_cover":true}]'::jsonb, true, false);

  -- OC1-005
  v_prop_addr_id := gen_random_uuid();
  v_prop_id := gen_random_uuid();
  INSERT INTO public.addresses (id, full_address, landmark, city, state, pincode, country, latitude, longitude, entity_type, entity_id, is_deleted)
  VALUES (v_prop_addr_id, 'Tower C, Apt 1502, The Grand Arch, Sector 58', 'Off Golf Course Extension Road', 'Gurgaon', 'Haryana', '122011', 'India', 28.4078, 77.0894, 'property', v_prop_id, false);

  INSERT INTO public.properties (id, broker_id, address_id, property_title, property_description, property_type, listing_type, price, area, area_unit, bedrooms, bathrooms, balconies, parking, floor_number, total_floors, furnishing_status, property_status, construction_status, facing, amenities, medias, is_active, is_deleted)
  VALUES (v_prop_id, v_b3_broker_id, v_prop_addr_id, 'Executive 3 BHK Apartment in Platinum Green Township at Sector 58, Gurgaon', 'Spacious residential apartment with smart temperature controls, double-glazed windows, and access to 30,000 sqft clubhouse.', 'apartment'::public.property_type_enum, 'sale'::public.listing_type_enum, 34500000, 2150, 'sqft'::public.area_unit_enum, 3, 3, 2, 2, 15, 28, 'semi_furnished'::public.furnishing_status_enum, 'available'::public.property_status_enum, 'ready_to_move'::public.construction_status_enum, 'north'::public.facing_direction_enum, '["Club House","Swimming Pool","Tennis Court","Badminton Court","Gymnasium"]'::jsonb, '[{"url":"https://images.unsplash.com/photo-1502005229762-ee1b2da97e06?auto=format&fit=crop&w=1200&q=80","type":"image","title":"Master Bedroom","is_cover":true}]'::jsonb, true, false);


  -- =========================================================================
  -- 4. CREATE BROKER 4: Rao Heritage & Luxury Living (Hyderabad)
  -- =========================================================================
  INSERT INTO public.addresses (id, full_address, landmark, city, state, pincode, country, latitude, longitude, entity_type, entity_id, is_deleted)
  VALUES (v_b4_addr_id, 'Plot 82, Road No. 36, Jubilee Hills', 'Near Peddamma Temple Metro', 'Hyderabad', 'Telangana', '500033', 'India', 17.4319, 78.4073, 'broker', v_b4_broker_id, false);

  INSERT INTO public.brokers (id, business_name, broker_code, plan, onboarding_status, address_id, is_active, is_deleted, auto_approve_video_requests, setup_details)
  VALUES (v_b4_broker_id, 'Rao Heritage & Luxury Living', 'RH1', 'AGENCY & TEAMS', 'completed', v_b4_addr_id, true, false, true, '{"account_created":true,"business_info_added":true,"facebook_connected":true,"instagram_connected":true,"properties_imported":true}'::jsonb);

  INSERT INTO auth.users (id, instance_id, aud, role, email, encrypted_password, email_confirmed_at, raw_app_meta_data, raw_user_meta_data, created_at, updated_at, phone, phone_confirmed_at, confirmation_token, email_change, email_change_token_new, recovery_token)
  VALUES (v_b4_user_id, '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated', 'siddharth.rao@realtybazaar.in', v_encrypted_password, NOW(), '{"provider":"email","providers":["email"]}'::jsonb, '{"name":"Siddharth Rao","role":"broker"}'::jsonb, NOW(), NOW(), '919849077884', NOW(), '', '', '', '');

  INSERT INTO public.users (id, name, email, phone, phone_country_code, phone_country_iso, role, is_active, is_deleted, broker_id, is_email_verified, cover_image, notes)
  VALUES (v_b4_user_id, 'Siddharth Rao', 'siddharth.rao@realtybazaar.in', '9849077884', '91', 'IN', 'broker'::public.user_role, true, false, v_b4_broker_id, true, '{"url":"https://images.unsplash.com/photo-1500648767791-00dcc994a43e?auto=format&fit=crop&w=1200&q=80","name":"cover.jpg"}'::jsonb, 'Premier Hyderabad broker specializing in Jubilee Hills villas, Kokapet high-rises, and Hitec City tech corridors.');

  -- Properties for Broker 4
  -- RH1-001
  v_prop_addr_id := gen_random_uuid();
  v_prop_id := gen_random_uuid();
  INSERT INTO public.addresses (id, full_address, landmark, city, state, pincode, country, latitude, longitude, entity_type, entity_id, is_deleted)
  VALUES (v_prop_addr_id, 'Villa 9, Road No. 10, Jubilee Hills', 'Opposite KBR National Park', 'Hyderabad', 'Telangana', '500033', 'India', 17.4285, 78.4152, 'property', v_prop_id, false);

  INSERT INTO public.properties (id, broker_id, address_id, property_title, property_description, property_type, listing_type, price, area, area_unit, bedrooms, bathrooms, balconies, parking, floor_number, total_floors, furnishing_status, property_status, construction_status, facing, amenities, medias, is_active, is_deleted)
  VALUES (v_prop_id, v_b4_broker_id, v_prop_addr_id, 'Royal 5 BHK Independent Palatial Villa with Dolby Atmos Theatre at Jubilee Hills, Hyderabad', 'Stately architectural residence with imported Italian fixtures, private elevator, swimming pool, and custom home theatre.', 'villa'::public.property_type_enum, 'sale'::public.listing_type_enum, 165000000, 7200, 'sqft'::public.area_unit_enum, 5, 6, 3, 4, 1, 3, 'fully_furnished'::public.furnishing_status_enum, 'available'::public.property_status_enum, 'ready_to_move'::public.construction_status_enum, 'east'::public.facing_direction_enum, '["Private Swimming Pool","Dolby Atmos Theatre","Private Elevator","Staff Quarters","Smart Home Automation"]'::jsonb, '[{"url":"https://images.unsplash.com/photo-1580587771525-78b9dba3b914?auto=format&fit=crop&w=1200&q=80","type":"image","title":"Palatial Villa Front","is_cover":true}]'::jsonb, true, false);

  -- RH1-002
  v_prop_addr_id := gen_random_uuid();
  v_prop_id := gen_random_uuid();
  INSERT INTO public.addresses (id, full_address, landmark, city, state, pincode, country, latitude, longitude, entity_type, entity_id, is_deleted)
  VALUES (v_prop_addr_id, 'Tower 4, Sky Villa 3801, Golden Mile, Kokapet', 'Adjacent to ORR Exit 1', 'Hyderabad', 'Telangana', '500075', 'India', 17.3912, 78.3341, 'property', v_prop_id, false);

  INSERT INTO public.properties (id, broker_id, address_id, property_title, property_description, property_type, listing_type, price, area, area_unit, bedrooms, bathrooms, balconies, parking, floor_number, total_floors, furnishing_status, property_status, construction_status, facing, amenities, medias, is_active, is_deleted)
  VALUES (v_prop_id, v_b4_broker_id, v_prop_addr_id, '4 BHK Panoramic Golf View Penthouse on 38th Floor at Kokapet, Hyderabad', 'Ultra-tall high-rise residence overlooking the scenic Kokapet Lake & rolling greens of the golf course.', 'penthouse'::public.property_type_enum, 'sale'::public.listing_type_enum, 62000000, 4600, 'sqft'::public.area_unit_enum, 4, 5, 3, 3, 38, 42, 'semi_furnished'::public.furnishing_status_enum, 'available'::public.property_status_enum, 'under_construction'::public.construction_status_enum, 'north_east'::public.facing_direction_enum, '["Infinity Rooftop Pool","Club House","Golf Putting Green","Gymnasium","24x7 Security"]'::jsonb, '[{"url":"https://images.unsplash.com/photo-1613490493576-7fde63acd811?auto=format&fit=crop&w=1200&q=80","type":"image","title":"Sky Penthouse Deck","is_cover":true}]'::jsonb, true, false);

  -- RH1-003
  v_prop_addr_id := gen_random_uuid();
  v_prop_id := gen_random_uuid();
  INSERT INTO public.addresses (id, full_address, landmark, city, state, pincode, country, latitude, longitude, entity_type, entity_id, is_deleted)
  VALUES (v_prop_addr_id, 'Level 4, Cyber Gateway, Madhapur, Hitec City', 'Opposite Cyber Towers', 'Hyderabad', 'Telangana', '500081', 'India', 17.4483, 78.3815, 'property', v_prop_id, false);

  INSERT INTO public.properties (id, broker_id, address_id, property_title, property_description, property_type, listing_type, price, area, area_unit, bedrooms, bathrooms, balconies, parking, floor_number, total_floors, furnishing_status, property_status, construction_status, facing, amenities, medias, is_active, is_deleted)
  VALUES (v_prop_id, v_b4_broker_id, v_prop_addr_id, 'Fully-Furnished Co-working & Startup Workspace Hub at Hitec City, Hyderabad', 'Plug-and-play modern corporate office space with 120 workstations, 4 meeting pods, cafeteria, and high-speed fiber internet.', 'commercial'::public.property_type_enum, 'lease'::public.listing_type_enum, 380000, 4500, 'sqft'::public.area_unit_enum, 0, 4, 0, 4, 4, 10, 'fully_furnished'::public.furnishing_status_enum, 'available'::public.property_status_enum, 'ready_to_move'::public.construction_status_enum, 'north'::public.facing_direction_enum, '["Central AC","100% Power Backup","Conference Rooms","High Speed Internet","24x7 Security"]'::jsonb, '[{"url":"https://images.unsplash.com/photo-1497366216548-37526070297c?auto=format&fit=crop&w=1200&q=80","type":"image","title":"Startup Workspace","is_cover":true}]'::jsonb, true, false);

  -- RH1-004
  v_prop_addr_id := gen_random_uuid();
  v_prop_id := gen_random_uuid();
  INSERT INTO public.addresses (id, full_address, landmark, city, state, pincode, country, latitude, longitude, entity_type, entity_id, is_deleted)
  VALUES (v_prop_addr_id, 'Apt 1104, Financial Heights, Nanakramguda, Gachibowli', 'Near US Consulate', 'Hyderabad', 'Telangana', '500032', 'India', 17.4156, 78.3491, 'property', v_prop_id, false);

  INSERT INTO public.properties (id, broker_id, address_id, property_title, property_description, property_type, listing_type, price, area, area_unit, bedrooms, bathrooms, balconies, parking, floor_number, total_floors, furnishing_status, property_status, construction_status, facing, amenities, medias, is_active, is_deleted)
  VALUES (v_prop_id, v_b4_broker_id, v_prop_addr_id, '3 BHK Premium Smart Residence with 3 Car Parkings at Gachibowli, Hyderabad', 'Luxury apartment situated right inside Hyderabad Financial District, with 3 dedicated basement parking slots.', 'apartment'::public.property_type_enum, 'sale'::public.listing_type_enum, 24000000, 2200, 'sqft'::public.area_unit_enum, 3, 3, 2, 3, 11, 24, 'semi_furnished'::public.furnishing_status_enum, 'available'::public.property_status_enum, 'ready_to_move'::public.construction_status_enum, 'east'::public.facing_direction_enum, '["Club House","Swimming Pool","Gymnasium","3 Covered Parkings","24x7 Security"]'::jsonb, '[{"url":"https://images.unsplash.com/photo-1560448204-e02f11c3d0e2?auto=format&fit=crop&w=1200&q=80","type":"image","title":"Living Space","is_cover":true}]'::jsonb, true, false);

  -- RH1-005
  v_prop_addr_id := gen_random_uuid();
  v_prop_id := gen_random_uuid();
  INSERT INTO public.addresses (id, full_address, landmark, city, state, pincode, country, latitude, longitude, entity_type, entity_id, is_deleted)
  VALUES (v_prop_addr_id, 'Plot No. 44, Neopolis Boulevard, Kokapet', 'Near Trump Tower Site', 'Hyderabad', 'Telangana', '500075', 'India', 17.4005, 78.3289, 'property', v_prop_id, false);

  INSERT INTO public.properties (id, broker_id, address_id, property_title, property_description, property_type, listing_type, price, area, area_unit, bedrooms, bathrooms, balconies, parking, floor_number, total_floors, furnishing_status, property_status, construction_status, facing, amenities, medias, is_active, is_deleted)
  VALUES (v_prop_id, v_b4_broker_id, v_prop_addr_id, '6,000 sqft West-Facing Luxury Villa Plot in Gated Township at Neopolis, Hyderabad', 'Premium corner plot in Hyderabad ultra-luxury mega layout with unlimited FSI potential and 100-ft approach roads.', 'plot'::public.property_type_enum, 'sale'::public.listing_type_enum, 51000000, 6000, 'sqft'::public.area_unit_enum, 0, 0, 0, 0, 0, 0, 'unfurnished'::public.furnishing_status_enum, 'available'::public.property_status_enum, 'ready_to_move'::public.construction_status_enum, 'west'::public.facing_direction_enum, '["Gated Community","Wide 100-ft Roads","Underground Utilities"]'::jsonb, '[{"url":"https://images.unsplash.com/photo-1500076656116-558758c991c1?auto=format&fit=crop&w=1200&q=80","type":"image","title":"Neopolis Plot Enclave","is_cover":true}]'::jsonb, true, false);


  -- =========================================================================
  -- 5. CREATE BROKER 5: Joshi Urban Spaces & Penthouses (Pune)
  -- =========================================================================
  INSERT INTO public.addresses (id, full_address, landmark, city, state, pincode, country, latitude, longitude, entity_type, entity_id, is_deleted)
  VALUES (v_b5_addr_id, '3rd Floor, Sky Vista, Airport Road, Viman Nagar', 'Near Symbiosis International School', 'Pune', 'Maharashtra', '411014', 'India', 18.5679, 73.9143, 'broker', v_b5_broker_id, false);

  INSERT INTO public.brokers (id, business_name, broker_code, plan, onboarding_status, address_id, is_active, is_deleted, auto_approve_video_requests, setup_details)
  VALUES (v_b5_broker_id, 'Joshi Urban Spaces & Penthouses', 'JU1', 'GROWTH PRO', 'completed', v_b5_addr_id, true, false, true, '{"account_created":true,"business_info_added":true,"facebook_connected":true,"instagram_connected":true,"properties_imported":true}'::jsonb);

  INSERT INTO auth.users (id, instance_id, aud, role, email, encrypted_password, email_confirmed_at, raw_app_meta_data, raw_user_meta_data, created_at, updated_at, phone, phone_confirmed_at, confirmation_token, email_change, email_change_token_new, recovery_token)
  VALUES (v_b5_user_id, '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated', 'meera.joshi@realtybazaar.in', v_encrypted_password, NOW(), '{"provider":"email","providers":["email"]}'::jsonb, '{"name":"Meera Joshi","role":"broker"}'::jsonb, NOW(), NOW(), '919822099005', NOW(), '', '', '', '');

  INSERT INTO public.users (id, name, email, phone, phone_country_code, phone_country_iso, role, is_active, is_deleted, broker_id, is_email_verified, cover_image, notes)
  VALUES (v_b5_user_id, 'Meera Joshi', 'meera.joshi@realtybazaar.in', '9822099005', '91', 'IN', 'broker'::public.user_role, true, false, v_b5_broker_id, true, '{"url":"https://images.unsplash.com/photo-1580489944761-15a19d654956?auto=format&fit=crop&w=1200&q=80","name":"cover.jpg"}'::jsonb, 'Specialist broker for Koregaon Park, Baner hill-view penthouses, and Viman Nagar boutique spaces.');

  -- Properties for Broker 5
  -- JU1-001
  v_prop_addr_id := gen_random_uuid();
  v_prop_id := gen_random_uuid();
  INSERT INTO public.addresses (id, full_address, landmark, city, state, pincode, country, latitude, longitude, entity_type, entity_id, is_deleted)
  VALUES (v_prop_addr_id, 'Flat 6A, Gulmohar Avenue, Lane 7, Koregaon Park', 'Near Osho Garden', 'Pune', 'Maharashtra', '411001', 'India', 18.5362, 73.8939, 'property', v_prop_id, false);

  INSERT INTO public.properties (id, broker_id, address_id, property_title, property_description, property_type, listing_type, price, area, area_unit, bedrooms, bathrooms, balconies, parking, floor_number, total_floors, furnishing_status, property_status, construction_status, facing, amenities, medias, is_active, is_deleted)
  VALUES (v_prop_id, v_b5_broker_id, v_prop_addr_id, 'Modernist 3 BHK Garden-Facing Residence in Leafy Boulevard at Koregaon Park, Pune', 'Serene urban home with floor-to-ceiling glass openings facing lush rain trees, teakwood flooring, and custom modular kitchen.', 'apartment'::public.property_type_enum, 'sale'::public.listing_type_enum, 28500000, 1850, 'sqft'::public.area_unit_enum, 3, 3, 2, 2, 6, 11, 'semi_furnished'::public.furnishing_status_enum, 'available'::public.property_status_enum, 'ready_to_move'::public.construction_status_enum, 'north_east'::public.facing_direction_enum, '["Gymnasium","Covered Car Parking","24x7 Security","Club House","Power Backup"]'::jsonb, '[{"url":"https://images.unsplash.com/photo-1600566753376-12c8ab7fb75b?auto=format&fit=crop&w=1200&q=80","type":"image","title":"Living Space","is_cover":true}]'::jsonb, true, false);

  -- JU1-002
  v_prop_addr_id := gen_random_uuid();
  v_prop_id := gen_random_uuid();
  INSERT INTO public.addresses (id, full_address, landmark, city, state, pincode, country, latitude, longitude, entity_type, entity_id, is_deleted)
  VALUES (v_prop_addr_id, 'Penthouse 18B, Baner Crest, Baner-Pashan Link Road', 'Overlooking Pashan Hills', 'Pune', 'Maharashtra', '411045', 'India', 18.5590, 73.7868, 'property', v_prop_id, false);

  INSERT INTO public.properties (id, broker_id, address_id, property_title, property_description, property_type, listing_type, price, area, area_unit, bedrooms, bathrooms, balconies, parking, floor_number, total_floors, furnishing_status, property_status, construction_status, facing, amenities, medias, is_active, is_deleted)
  VALUES (v_prop_id, v_b5_broker_id, v_prop_addr_id, '4 BHK Sky Mansion with 360-Degree Hill Views at Baner, Pune', 'Exclusive top-floor penthouse with unobstructed hill vistas, private sundeck, personal gym room, and motorized blinds.', 'penthouse'::public.property_type_enum, 'sale'::public.listing_type_enum, 44000000, 3600, 'sqft'::public.area_unit_enum, 4, 5, 3, 2, 18, 19, 'fully_furnished'::public.furnishing_status_enum, 'available'::public.property_status_enum, 'ready_to_move'::public.construction_status_enum, 'west'::public.facing_direction_enum, '["Infinity Rooftop Pool","Private Gym","Smart Home Automation","Club House","Power Backup"]'::jsonb, '[{"url":"https://images.unsplash.com/photo-1600585154340-be6161a56a0c?auto=format&fit=crop&w=1200&q=80","type":"image","title":"Sky Penthouse Deck","is_cover":true}]'::jsonb, true, false);

  -- JU1-003
  v_prop_addr_id := gen_random_uuid();
  v_prop_id := gen_random_uuid();
  INSERT INTO public.addresses (id, full_address, landmark, city, state, pincode, country, latitude, longitude, entity_type, entity_id, is_deleted)
  VALUES (v_prop_addr_id, 'Apt 203, Riverside Haven, Central Avenue, Kalyani Nagar', 'Behind Jogger Park', 'Pune', 'Maharashtra', '411006', 'India', 18.5477, 73.9034, 'property', v_prop_id, false);

  INSERT INTO public.properties (id, broker_id, address_id, property_title, property_description, property_type, listing_type, price, area, area_unit, bedrooms, bathrooms, balconies, parking, floor_number, total_floors, furnishing_status, property_status, construction_status, facing, amenities, medias, is_active, is_deleted)
  VALUES (v_prop_id, v_b5_broker_id, v_prop_addr_id, 'Boutique 2 BHK Designer Loft with Modular Island Kitchen at Kalyani Nagar, Pune', 'Stylishly furnished urban loft apartment with bespoke furniture, built-in espresso bar, and high-speed Wi-Fi readiness.', 'apartment'::public.property_type_enum, 'rent'::public.listing_type_enum, 55000, 1100, 'sqft'::public.area_unit_enum, 2, 2, 1, 1, 2, 7, 'fully_furnished'::public.furnishing_status_enum, 'available'::public.property_status_enum, 'ready_to_move'::public.construction_status_enum, 'east'::public.facing_direction_enum, '["Gymnasium","Power Backup","24x7 Security","Covered Car Parking"]'::jsonb, '[{"url":"https://images.unsplash.com/photo-1522708323590-d24dbb6b0267?auto=format&fit=crop&w=1200&q=80","type":"image","title":"Designer Loft Living","is_cover":true}]'::jsonb, true, false);

  -- JU1-004
  v_prop_addr_id := gen_random_uuid();
  v_prop_id := gen_random_uuid();
  INSERT INTO public.addresses (id, full_address, landmark, city, state, pincode, country, latitude, longitude, entity_type, entity_id, is_deleted)
  VALUES (v_prop_addr_id, 'Townhouse 12, Riverview Enclave, Kharadi Main Road', 'Near EON Free Zone IT Park', 'Pune', 'Maharashtra', '411014', 'India', 18.5516, 73.9348, 'property', v_prop_id, false);

  INSERT INTO public.properties (id, broker_id, address_id, property_title, property_description, property_type, listing_type, price, area, area_unit, bedrooms, bathrooms, balconies, parking, floor_number, total_floors, furnishing_status, property_status, construction_status, facing, amenities, medias, is_active, is_deleted)
  VALUES (v_prop_id, v_b5_broker_id, v_prop_addr_id, 'Brand New 3 BHK Gated Townhouse with Private Backyard at Kharadi, Pune', 'Spacious duplex row townhouse located 5 mins from EON IT Park, featuring a private landscaped patio and solar water heating.', 'row_house'::public.property_type_enum, 'sale'::public.listing_type_enum, 17500000, 2200, 'sqft'::public.area_unit_enum, 3, 3, 2, 2, 1, 2, 'semi_furnished'::public.furnishing_status_enum, 'available'::public.property_status_enum, 'ready_to_move'::public.construction_status_enum, 'east'::public.facing_direction_enum, '["Private Backyard","Solar Water Heater","Club House","Swimming Pool","24x7 Security"]'::jsonb, '[{"url":"https://images.unsplash.com/photo-1512917774080-9991f1c4c750?auto=format&fit=crop&w=1200&q=80","type":"image","title":"Townhouse Garden Patio","is_cover":true}]'::jsonb, true, false);

  -- JU1-005
  v_prop_addr_id := gen_random_uuid();
  v_prop_id := gen_random_uuid();
  INSERT INTO public.addresses (id, full_address, landmark, city, state, pincode, country, latitude, longitude, entity_type, entity_id, is_deleted)
  VALUES (v_prop_addr_id, '2nd Floor, Phoenix Marketcity Commercial Hub, Viman Nagar', 'Opposite Phoenix Mall', 'Pune', 'Maharashtra', '411014', 'India', 18.5601, 73.9168, 'property', v_prop_id, false);

  INSERT INTO public.properties (id, broker_id, address_id, property_title, property_description, property_type, listing_type, price, area, area_unit, bedrooms, bathrooms, balconies, parking, floor_number, total_floors, furnishing_status, property_status, construction_status, facing, amenities, medias, is_active, is_deleted)
  VALUES (v_prop_id, v_b5_broker_id, v_prop_addr_id, '3,500 sqft Commercial Boutique Office on High Street at Viman Nagar, Pune', 'High-end commercial office space in the bustling Viman Nagar commercial corridor, equipped with 3 executive cabins and pantry.', 'commercial'::public.property_type_enum, 'lease'::public.listing_type_enum, 220000, 3500, 'sqft'::public.area_unit_enum, 0, 3, 0, 3, 2, 6, 'unfurnished'::public.furnishing_status_enum, 'available'::public.property_status_enum, 'ready_to_move'::public.construction_status_enum, 'north'::public.facing_direction_enum, '["High Speed Elevators","Power Backup","24x7 Security","Covered Car Parking"]'::jsonb, '[{"url":"https://images.unsplash.com/photo-1497215728101-856f4ea42174?auto=format&fit=crop&w=1200&q=80","type":"image","title":"Viman Nagar Commercial Office","is_cover":true}]'::jsonb, true, false);

  RAISE NOTICE 'Successfully created 5 unique brokers and seeded 25 distinct properties on Production.';
END;
$$;
