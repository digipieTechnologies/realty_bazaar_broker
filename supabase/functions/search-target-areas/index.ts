// File: supabase/functions/search-target-areas/index.ts
// Purpose: Edge function to search target locations (localities, areas, cities, states) in India via Google Maps API.
// Strips specific building/society/flat names and formats clean area/city location entries.

import { serve } from "https://deno.land/std@0.224.0/http/server.ts";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

interface TargetAreaResult {
  full_area: string;
  area: string;
  city: string;
  state: string;
  county: string;
  pincode: string;
  latitude: number;
  longitude: number;
}

// Plus Code pattern detector (e.g., 6WXF+JHF, 8J6V+2X)
const PLUS_CODE_REGEX = /[A-Z0-9]{4,8}\+[A-Z0-9]{2,4}/i;

// Comprehensive list of society/building/apartment keywords in English/Gujarati transliteration
const BUILDING_SOCIETY_KEYWORDS = [
  "society", "socity", "soc", "shoc", "soc.",
  "bunglows", "bungalow", "bungalows", "bnglow",
  "chsl", "chs", "apt", "apts", "appartment", "apartment", "apartments",
  "residency", "realty", "rowhouse", "row house", "villas", "villa",
  "homes", "nivas", "niwas", "heights", "arcade", "square",
  "palace", "chambers", "flats", "flat", "plaza", "estate",
  "township", "nest", "haven", "bliss", "paradise", "valley",
  "greens", "residence", "coop", "co-op", "building", "house",
  "plots", "plot", "complex", "shopping", "hub", "infra",
  "enclave", "shoppes", "sanctuary", "cottage", "manor", "court",
  "terrace", "gardens", "resort", "commercial"
];

function containsBuildingKeyword(str: string): boolean {
  const lower = str.toLowerCase();
  return BUILDING_SOCIETY_KEYWORDS.some((kw) => lower.includes(kw));
}

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const { query } = await req.json();
    const rawQuery = (query ?? "").toString().trim();

    // If query is empty, return empty list
    if (!rawQuery) {
      return new Response(
        JSON.stringify({ data: [] }),
        {
          headers: { "Content-Type": "application/json", ...corsHeaders },
          status: 200,
        }
      );
    }

    const GOOGLE_MAPS_API_KEY = Deno.env.get("GOOGLE_MAPS_API_KEY");

    if (GOOGLE_MAPS_API_KEY) {
      try {
        // Search Places Autocomplete using rawQuery prefix, biased to Gujarat, India
        const autocompleteUrl = `https://maps.googleapis.com/maps/api/place/autocomplete/json?input=${encodeURIComponent(
          rawQuery
        )}&location=22.2587,71.1924&radius=300000&components=country:in&key=${GOOGLE_MAPS_API_KEY}`;

        const autoRes = await fetch(autocompleteUrl);
        if (autoRes.ok) {
          const autoData = await autoRes.json();
          const predictions = autoData.predictions ?? [];

          const results: TargetAreaResult[] = [];
          const seenKeys = new Set<string>();

          for (const pred of predictions) {
            const desc = pred.description ?? "";

            // 1. Filter out Plus Codes (e.g. 6WXF+JHF)
            if (PLUS_CODE_REGEX.test(desc)) continue;

            const placeId = pred.place_id;
            const detailsUrl = `https://maps.googleapis.com/maps/api/place/details/json?place_id=${placeId}&fields=address_components,geometry,formatted_address&key=${GOOGLE_MAPS_API_KEY}`;
            const detailsRes = await fetch(detailsUrl);
            if (detailsRes.ok) {
              const detailsData = await detailsRes.json();
              const result = detailsData.result;
              if (result) {
                const formattedAddress = result.formatted_address ?? desc;

                // Skip if formatted address contains a Plus Code
                if (PLUS_CODE_REGEX.test(formattedAddress)) continue;

                const components = result.address_components ?? [];
                let area = "";
                let city = "";
                let state = "";
                let county = "";
                let pincode = "";

                for (const comp of components) {
                  const types: string[] = comp.types ?? [];
                  if (
                    types.includes("sublocality") ||
                    types.includes("sublocality_level_1") ||
                    types.includes("neighborhood")
                  ) {
                    area = comp.long_name;
                  } else if (types.includes("locality")) {
                    city = comp.long_name;
                  } else if (types.includes("administrative_area_level_1")) {
                    state = comp.long_name;
                  } else if (types.includes("administrative_area_level_2")) {
                    county = comp.long_name;
                  } else if (types.includes("postal_code")) {
                    pincode = comp.long_name;
                  }
                }

                // If area component contains a society/building keyword, clear it
                if (area && containsBuildingKeyword(area)) {
                  area = "";
                }

                const areaName = area || city || rawQuery;
                const cityName = city || "Gujarat";

                // Construct clean area full_area string without society/building names
                const cleanParts: string[] = [];
                if (areaName) cleanParts.push(areaName);
                if (cityName && cityName !== areaName) cleanParts.push(cityName);
                if (state && state !== cityName) cleanParts.push(state);
                if (pincode) cleanParts.push(pincode);
                cleanParts.push("India");

                const cleanFullArea = cleanParts.join(", ");

                // Final check: if cleanFullArea contains building keywords, skip
                if (containsBuildingKeyword(cleanFullArea)) continue;

                // Deduplicate by clean area + city key
                const dedupKey = `${areaName.toLowerCase().trim()}_${cityName.toLowerCase().trim()}`;
                if (seenKeys.has(dedupKey)) continue;
                seenKeys.add(dedupKey);

                results.push({
                  full_area: cleanFullArea,
                  area: areaName,
                  city: cityName,
                  state: state || "Gujarat",
                  county: county || cityName,
                  pincode: pincode || "380001",
                  latitude: result.geometry?.location?.lat ?? 22.2587,
                  longitude: result.geometry?.location?.lng ?? 71.1924,
                });
              }
            }

            if (results.length >= 10) break;
          }

          if (results.length > 0) {
            return new Response(
              JSON.stringify({ data: results }),
              {
                headers: { "Content-Type": "application/json", ...corsHeaders },
                status: 200,
              }
            );
          }
        }
      } catch (err) {
        console.warn("[search-target-areas] Google Places API call failed:", err);
      }
    }

    // If location is not found or API failed, return empty list (no dynamic fallback)
    return new Response(
      JSON.stringify({ data: [] }),
      {
        headers: { "Content-Type": "application/json", ...corsHeaders },
        status: 200,
      }
    );
  } catch (error) {
    return new Response(JSON.stringify({ error: (error as Error).message }), {
      headers: { "Content-Type": "application/json", ...corsHeaders },
      status: 500,
    });
  }
});
