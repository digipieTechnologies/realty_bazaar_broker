-- Migration: 20260831163000_seed_10_luxury_properties.sql
-- Description: Inserts 10 world-class real estate properties with realistic details, addresses, and high-definition Unsplash photography for broker `3e28978a-2a02-47fb-b1cd-28afde308aee`.

DO $$
DECLARE
  v_broker_id uuid := '3e28978a-2a02-47fb-b1cd-28afde308aee';
  v_addr_id_1 uuid := gen_random_uuid();
  v_addr_id_2 uuid := gen_random_uuid();
  v_addr_id_3 uuid := gen_random_uuid();
  v_addr_id_4 uuid := gen_random_uuid();
  v_addr_id_5 uuid := gen_random_uuid();
  v_addr_id_6 uuid := gen_random_uuid();
  v_addr_id_7 uuid := gen_random_uuid();
  v_addr_id_8 uuid := gen_random_uuid();
  v_addr_id_9 uuid := gen_random_uuid();
  v_addr_id_10 uuid := gen_random_uuid();
  v_prop_id_1 uuid := gen_random_uuid();
  v_prop_id_2 uuid := gen_random_uuid();
  v_prop_id_3 uuid := gen_random_uuid();
  v_prop_id_4 uuid := gen_random_uuid();
  v_prop_id_5 uuid := gen_random_uuid();
  v_prop_id_6 uuid := gen_random_uuid();
  v_prop_id_7 uuid := gen_random_uuid();
  v_prop_id_8 uuid := gen_random_uuid();
  v_prop_id_9 uuid := gen_random_uuid();
  v_prop_id_10 uuid := gen_random_uuid();
BEGIN

-- 0. Ensure Broker Record Exists
INSERT INTO public.brokers (id, business_name, onboarding_status, is_active)
VALUES (v_broker_id, 'The Realty Bazaar Prime Brokerage', 'completed', true)
ON CONFLICT (id) DO NOTHING;

-- 1. Insert 10 Real Estate Addresses
INSERT INTO public.addresses (id, full_address, city, state, country, pincode, entity_type, entity_id) VALUES
(v_addr_id_1, 'Altamount Road, Cumballa Hill, Mumbai, Maharashtra 400026', 'Mumbai', 'Maharashtra', 'India', '400026', 'property', v_prop_id_1),
(v_addr_id_2, 'Sector 54, Golf Course Road, Gurgaon, Haryana 122002', 'Gurgaon', 'Haryana', 'India', '122002', 'property', v_prop_id_2),
(v_addr_id_3, 'Candolim Beach Road, North Goa, Goa 403515', 'Goa', 'Goa', 'India', '403515', 'property', v_prop_id_3),
(v_addr_id_4, 'Lane 7, Koregaon Park, Pune, Maharashtra 411001', 'Pune', 'Maharashtra', 'India', '411001', 'property', v_prop_id_4),
(v_addr_id_5, 'Road No. 36, Jubilee Hills, Hyderabad, Telangana 500033', 'Hyderabad', 'Telangana', 'India', '500033', 'property', v_prop_id_5),
(v_addr_id_6, '100 Feet Road, Indiranagar, Bengaluru, Karnataka 560038', 'Bengaluru', 'Karnataka', 'India', '560038', 'property', v_prop_id_6),
(v_addr_id_7, 'Mindspace IT Park, HITEC City, Hyderabad, Telangana 500081', 'Hyderabad', 'Telangana', 'India', '500081', 'property', v_prop_id_7),
(v_addr_id_8, 'Veshvi Coastal Road, Alibaug, Raigad, Maharashtra 402201', 'Alibaug', 'Maharashtra', 'India', '402201', 'property', v_prop_id_8),
(v_addr_id_9, 'Jacob Road, Civil Lines, Jaipur, Rajasthan 302006', 'Jaipur', 'Rajasthan', 'India', '302006', 'property', v_prop_id_9),
(v_addr_id_10, 'Worli Sea Face, Worli, Mumbai, Maharashtra 400030', 'Mumbai', 'Maharashtra', 'India', '400030', 'property', v_prop_id_10);

-- 2. Insert 10 Ultra-High-Quality Properties
-- Property 1: The Imperial Sky Villa (Mumbai)
INSERT INTO public.properties (
  id, broker_id, address_id, property_title, property_description,
  property_type, listing_type, price, area, area_unit,
  bedrooms, bathrooms, balconies, parking, floor_number, total_floors,
  furnishing_status, property_status, construction_status, facing,
  amenities, medias, is_active
) VALUES (
  v_prop_id_1, v_broker_id, v_addr_id_1,
  'The Imperial Sky Villa',
  'Ultra-luxurious sea-facing duplex villa featuring double-height ceiling lounge, private pool, floor-to-ceiling glass walls, imported Italian marble, and panoramic views of the Arabian Sea.',
  'villa'::property_type_enum, 'sale'::listing_type_enum, 45000000.00, 5200.00, 'sqft'::area_unit_enum,
  5, 6, 3, 3, 34, 40,
  'fully_furnished'::furnishing_status_enum, 'available'::property_status_enum, 'ready_to_move'::construction_status_enum, 'north_east'::facing_direction_enum,
  '["Private Infinity Pool", "Sea View Deck", "Private Elevator", "Italian Marble Flooring", "24/7 Concierge", "Automated Smart Home", "Private Gym & Spa"]'::jsonb,
  '[
    {"type": "image", "url": "https://images.unsplash.com/photo-1613977257363-707ba9348227?auto=format&fit=crop&w=1200&q=80", "thumbnail": "https://images.unsplash.com/photo-1613977257363-707ba9348227?auto=format&fit=crop&w=400&q=80"},
    {"type": "image", "url": "https://images.unsplash.com/photo-1600585154340-be6161a56a0c?auto=format&fit=crop&w=1200&q=80", "thumbnail": "https://images.unsplash.com/photo-1600585154340-be6161a56a0c?auto=format&fit=crop&w=400&q=80"},
    {"type": "image", "url": "https://images.unsplash.com/photo-1600566753376-12c8ab7fb75b?auto=format&fit=crop&w=1200&q=80", "thumbnail": "https://images.unsplash.com/photo-1600566753376-12c8ab7fb75b?auto=format&fit=crop&w=400&q=80"}
  ]'::jsonb,
  true
),

-- Property 2: Elysium Luxury Penthouse (Gurgaon)
(
  v_prop_id_2, v_broker_id, v_addr_id_2,
  'Elysium Luxury Golf Course Penthouse',
  'Exquisite penthouse apartment on Golf Course Road with private sky deck, home automation, Poggenpohl fitted kitchen, and unobstructed views of the Aravalli hills and golf green.',
  'apartment'::property_type_enum, 'sale'::listing_type_enum, 28500000.00, 3850.00, 'sqft'::area_unit_enum,
  4, 4, 2, 2, 18, 20,
  'fully_furnished'::furnishing_status_enum, 'available'::property_status_enum, 'ready_to_move'::construction_status_enum, 'east'::facing_direction_enum,
  '["Golf Course View", "Rooftop Sky Deck", "German Modular Kitchen", "Home Automation", "Temperature Controlled Pool", "EV Charging Point"]'::jsonb,
  '[
    {"type": "image", "url": "https://images.unsplash.com/photo-1545324418-cc1a3fa10c00?auto=format&fit=crop&w=1200&q=80", "thumbnail": "https://images.unsplash.com/photo-1545324418-cc1a3fa10c00?auto=format&fit=crop&w=400&q=80"},
    {"type": "image", "url": "https://images.unsplash.com/photo-1616594039964-ae9021a400a0?auto=format&fit=crop&w=1200&q=80", "thumbnail": "https://images.unsplash.com/photo-1616594039964-ae9021a400a0?auto=format&fit=crop&w=400&q=80"},
    {"type": "image", "url": "https://images.unsplash.com/photo-1512917774080-9991f1c4c750?auto=format&fit=crop&w=1200&q=80", "thumbnail": "https://images.unsplash.com/photo-1512917774080-9991f1c4c750?auto=format&fit=crop&w=400&q=80"}
  ]'::jsonb,
  true
),

-- Property 3: Serene Palms Sea Villa (Goa)
(
  v_prop_id_3, v_broker_id, v_addr_id_3,
  'Serene Palms Beachfront Villa',
  'Exclusive 4-BHK private Portuguese-modern villa situated steps from Candolim Beach. Comes with a private lap pool, lush tropical garden, teakwood interiors, and outdoor BBQ lounge.',
  'villa'::property_type_enum, 'sale'::listing_type_enum, 35000000.00, 4500.00, 'sqft'::area_unit_enum,
  4, 5, 3, 2, 1, 2,
  'fully_furnished'::furnishing_status_enum, 'available'::property_status_enum, 'ready_to_move'::construction_status_enum, 'west'::facing_direction_enum,
  '["Private Infinity Pool", "Direct Beach Access", "Tropical Landscaped Garden", "Gazebo Deck", "Solar Power Grid", "Staff Quarters"]'::jsonb,
  '[
    {"type": "image", "url": "https://images.unsplash.com/photo-1580587771525-78b9dba3b914?auto=format&fit=crop&w=1200&q=80", "thumbnail": "https://images.unsplash.com/photo-1580587771525-78b9dba3b914?auto=format&fit=crop&w=400&q=80"},
    {"type": "image", "url": "https://images.unsplash.com/photo-1600596542815-ffad4c1539a9?auto=format&fit=crop&w=1200&q=80", "thumbnail": "https://images.unsplash.com/photo-1600596542815-ffad4c1539a9?auto=format&fit=crop&w=400&q=80"}
  ]'::jsonb,
  true
),

-- Property 4: The Crest Horizon Duplex (Pune)
(
  v_prop_id_4, v_broker_id, v_addr_id_4,
  'The Crest Horizon Luxury Duplex',
  'Premium 3-BHK fully-furnished penthouse duplex in Koregaon Park with private terrace garden, designer lighting, smart security system, and floor-to-ceiling glass balcony.',
  'apartment'::property_type_enum, 'rent'::listing_type_enum, 150000.00, 2800.00, 'sqft'::area_unit_enum,
  3, 3, 2, 2, 12, 15,
  'fully_furnished'::furnishing_status_enum, 'available'::property_status_enum, 'ready_to_move'::construction_status_enum, 'north'::facing_direction_enum,
  '["Private Terrace Garden", "Smart Keyless Lock", "Clubhouse Access", "Olympic Gym", "Covered Basement Parking", "Power Backup"]'::jsonb,
  '[
    {"type": "image", "url": "https://images.unsplash.com/photo-1600585154340-be6161a56a0c?auto=format&fit=crop&w=1200&q=80", "thumbnail": "https://images.unsplash.com/photo-1600585154340-be6161a56a0c?auto=format&fit=crop&w=400&q=80"},
    {"type": "image", "url": "https://images.unsplash.com/photo-1616594039964-ae9021a400a0?auto=format&fit=crop&w=1200&q=80", "thumbnail": "https://images.unsplash.com/photo-1616594039964-ae9021a400a0?auto=format&fit=crop&w=400&q=80"}
  ]'::jsonb,
  true
),

-- Property 5: Jubilee Signature Estate (Hyderabad)
(
  v_prop_id_5, v_broker_id, v_addr_id_5,
  'Jubilee Signature Mansion',
  'Palatial 6-BHK independent estate in prime Jubilee Hills. Boasts a 4-car garage, private elevator, home cinema hall, Olympic lap pool, and landscaped courtyard.',
  'villa'::property_type_enum, 'sale'::listing_type_enum, 62000000.00, 7000.00, 'sqft'::area_unit_enum,
  6, 7, 4, 4, 1, 3,
  'semi_furnished'::furnishing_status_enum, 'available'::property_status_enum, 'ready_to_move'::construction_status_enum, 'east'::facing_direction_enum,
  '["Private Swimming Pool", "Home Cinema Theater", "Private Elevator", "Landscaped Courtyard", "Guard Quarters", "CCTV 360 Grid"]'::jsonb,
  '[
    {"type": "image", "url": "https://images.unsplash.com/photo-1600596542815-ffad4c1539a9?auto=format&fit=crop&w=1200&q=80", "thumbnail": "https://images.unsplash.com/photo-1600596542815-ffad4c1539a9?auto=format&fit=crop&w=400&q=80"},
    {"type": "image", "url": "https://images.unsplash.com/photo-1613977257363-707ba9348227?auto=format&fit=crop&w=1200&q=80", "thumbnail": "https://images.unsplash.com/photo-1613977257363-707ba9348227?auto=format&fit=crop&w=400&q=80"}
  ]'::jsonb,
  true
),

-- Property 6: Zenith Skyline High-Rise (Bengaluru)
(
  v_prop_id_6, v_broker_id, v_addr_id_6,
  'Zenith Skyline Executive Residence',
  'State-of-the-art 3-BHK luxury apartment in Indiranagar. Highlights include a sky lounge deck, infinity edge rooftop pool, automated curtains, and acoustic soundproof windows.',
  'apartment'::property_type_enum, 'sale'::listing_type_enum, 19800000.00, 2450.00, 'sqft'::area_unit_enum,
  3, 3, 2, 2, 14, 22,
  'fully_furnished'::furnishing_status_enum, 'available'::property_status_enum, 'under_construction'::construction_status_enum, 'north_east'::facing_direction_enum,
  '["Rooftop Infinity Pool", "Sky Lounge & Cafe", "Squash Court", "Co-Working Pods", "Full Power Backup", "24/7 Security"]'::jsonb,
  '[
    {"type": "image", "url": "https://images.unsplash.com/photo-1545324418-cc1a3fa10c00?auto=format&fit=crop&w=1200&q=80", "thumbnail": "https://images.unsplash.com/photo-1545324418-cc1a3fa10c00?auto=format&fit=crop&w=400&q=80"},
    {"type": "image", "url": "https://images.unsplash.com/photo-1600566753376-12c8ab7fb75b?auto=format&fit=crop&w=1200&q=80", "thumbnail": "https://images.unsplash.com/photo-1600566753376-12c8ab7fb75b?auto=format&fit=crop&w=400&q=80"}
  ]'::jsonb,
  true
),

-- Property 7: Promenade Tech Park Office (Hyderabad)
(
  v_prop_id_7, v_broker_id, v_addr_id_7,
  'Promenade Tech Park Corporate Office',
  'Grade-A commercial office space in HITEC City. Fully plug-and-play with 60 workstations, 3 executive cabins, 2 conference rooms, server room, and cafeteria.',
  'commercial'::property_type_enum, 'rent'::listing_type_enum, 280000.00, 4200.00, 'sqft'::area_unit_enum,
  0, 2, 0, 5, 8, 12,
  'fully_furnished'::furnishing_status_enum, 'available'::property_status_enum, 'ready_to_move'::construction_status_enum, 'north'::facing_direction_enum,
  '["60 Plug-and-Play Desks", "Centralized VRV AC", "High-Speed Fiber", "Server Room", "Cafeteria", "24/7 Access & Security"]'::jsonb,
  '[
    {"type": "image", "url": "https://images.unsplash.com/photo-1497366216548-37526070297c?auto=format&fit=crop&w=1200&q=80", "thumbnail": "https://images.unsplash.com/photo-1497366216548-37526070297c?auto=format&fit=crop&w=400&q=80"},
    {"type": "image", "url": "https://images.unsplash.com/photo-1497215728101-856f4ea42174?auto=format&fit=crop&w=1200&q=80", "thumbnail": "https://images.unsplash.com/photo-1497215728101-856f4ea42174?auto=format&fit=crop&w=400&q=80"}
  ]'::jsonb,
  true
),

-- Property 8: Greenfield Eco Plot (Alibaug)
(
  v_prop_id_8, v_broker_id, v_addr_id_8,
  'Greenfield Eco Sanctuary Plot',
  'Prime clear-title NA agricultural & villa development plot in Alibaug. Surrounded by coconut groves, fruit orchards, and scenic hill views.',
  'plot'::property_type_enum, 'sale'::listing_type_enum, 12500000.00, 10800.00, 'sqft'::area_unit_enum,
  0, 0, 0, 0, 0, 0,
  'unfurnished'::furnishing_status_enum, 'available'::property_status_enum, 'ready_to_move'::construction_status_enum, 'east'::facing_direction_enum,
  '["Gated Community Plot", "Electricity & Water Connection", "Internal Concrete Road", "Fenced Border", "Security Gate"]'::jsonb,
  '[
    {"type": "image", "url": "https://images.unsplash.com/photo-1500382017468-9049fed747ef?auto=format&fit=crop&w=1200&q=80", "thumbnail": "https://images.unsplash.com/photo-1500382017468-9049fed747ef?auto=format&fit=crop&w=400&q=80"}
  ]'::jsonb,
  true
),

-- Property 9: Regency Heritage Villa (Jaipur)
(
  v_prop_id_9, v_broker_id, v_addr_id_9,
  'The Regency Heritage Villa',
  'Grand 5-BHK luxury heritage-style villa in Civil Lines. Highlights include hand-carved stone archways, internal fountain courtyard, swimming pool, and royal suite balconies.',
  'villa'::property_type_enum, 'sale'::listing_type_enum, 38000000.00, 5000.00, 'sqft'::area_unit_enum,
  5, 5, 3, 3, 1, 2,
  'fully_furnished'::furnishing_status_enum, 'available'::property_status_enum, 'ready_to_move'::construction_status_enum, 'east'::facing_direction_enum,
  '["Heritage Courtyard Pool", "Traditional Handcrafted Stone", "Manicured Private Garden", "Staff Quarters", "Solar Water Heating"]'::jsonb,
  '[
    {"type": "image", "url": "https://images.unsplash.com/photo-1580587771525-78b9dba3b914?auto=format&fit=crop&w=1200&q=80", "thumbnail": "https://images.unsplash.com/photo-1580587771525-78b9dba3b914?auto=format&fit=crop&w=400&q=80"},
    {"type": "image", "url": "https://images.unsplash.com/photo-1600596542815-ffad4c1539a9?auto=format&fit=crop&w=1200&q=80", "thumbnail": "https://images.unsplash.com/photo-1600596542815-ffad4c1539a9?auto=format&fit=crop&w=400&q=80"}
  ]'::jsonb,
  true
),

-- Property 10: Grand Bay Sea-Facing Residence (Mumbai)
(
  v_prop_id_10, v_broker_id, v_addr_id_10,
  'The Grand Bay Ocean Suite',
  'Spectacular 3-BHK high-floor apartment overlooking Worli Sea Face. Fully designed by international architects with motorized blinds, Italian marble, and private ocean terrace.',
  'apartment'::property_type_enum, 'rent'::listing_type_enum, 320000.00, 3100.00, 'sqft'::area_unit_enum,
  3, 4, 2, 2, 22, 30,
  'fully_furnished'::furnishing_status_enum, 'available'::property_status_enum, 'ready_to_move'::construction_status_enum, 'west'::facing_direction_enum,
  '["Unobstructed Ocean View", "Valet Parking", "Clubhouse & Jacuzzi", "Biometric Access", "Centralized Climate Control"]'::jsonb,
  '[
    {"type": "image", "url": "https://images.unsplash.com/photo-1512917774080-9991f1c4c750?auto=format&fit=crop&w=1200&q=80", "thumbnail": "https://images.unsplash.com/photo-1512917774080-9991f1c4c750?auto=format&fit=crop&w=400&q=80"},
    {"type": "image", "url": "https://images.unsplash.com/photo-1545324418-cc1a3fa10c00?auto=format&fit=crop&w=1200&q=80", "thumbnail": "https://images.unsplash.com/photo-1545324418-cc1a3fa10c00?auto=format&fit=crop&w=400&q=80"}
  ]'::jsonb,
  true
);

END $$;
