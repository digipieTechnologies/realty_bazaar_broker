// File: supabase/functions/generate-post-content/index.ts
// Purpose: Single-call edge function that returns all social post content:
//   topHeader, instagramHandle (or facebook page name), location (area/locality only),
//   bottomContact (broker name + phone), and a short viral caption.

import { serve } from "https://deno.land/std@0.224.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const { propertyId, brokerId, instagramUsername, facebookPageName } =
      await req.json()li;

    if (!propertyId) {
      return new Response(
        JSON.stringify({ error: "Missing propertyId in request payload" }),
        {
          headers: { "Content-Type": "application/json", ...corsHeaders },
          status: 400,
        }
      );
    }

    const supabase = createClient(
      Deno.env.get("SUPABASE_URL") ?? "",
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? ""
    );

    // ── 1. Fetch property + address ──────────────────────────────────────────
    const { data: property, error: propertyErr } = await supabase
      .from("properties")
      .select("*, address:addresses(*)")
      .eq("id", propertyId)
      .maybeSingle();

    if (propertyErr || !property) {
      return new Response(
        JSON.stringify({
          error: propertyErr?.message ?? `Property not found: ${propertyId}`,
        }),
        {
          headers: { "Content-Type": "application/json", ...corsHeaders },
          status: propertyErr ? 500 : 404,
        }
      );
    }

    // ── 2. Fetch broker contact details ──────────────────────────────────────
    let brokerPhone = "";
    let brokerName = "";

    const resolvedBrokerId = brokerId ?? property.broker_id;
    if (resolvedBrokerId) {
      // Try by broker_id column first, then fallback to id column
      const { data: brokerByBrokerId } = await supabase
        .from("users")
        .select("name, phone")
        .eq("broker_id", resolvedBrokerId)
        .maybeSingle();

      if (brokerByBrokerId) {
        brokerPhone = brokerByBrokerId.phone ?? "";
        brokerName = brokerByBrokerId.name ?? "";
      } else {
        const { data: brokerById } = await supabase
          .from("users")
          .select("name, phone")
          .eq("id", resolvedBrokerId)
          .maybeSingle();

        if (brokerById) {
          brokerPhone = brokerById.phone ?? "";
          brokerName = brokerById.name ?? "";
        }
      }
    }

    // ── 3. Build structured property info ────────────────────────────────────
    const addr = property.address ?? {};
    const locality =
      addr.locality ?? addr.area ?? addr.landmark ?? addr.city ?? "";
    const city = addr.city ?? "";
    const locationText = (locality || city).toUpperCase() || "PRIME LOCATION";

    const bhkStr = property.bedrooms > 0 ? `${property.bedrooms} BHK ` : "";
    const pType = (property.property_type ?? "PROPERTY").toUpperCase();
    const lType = (property.listing_type ?? "SALE").toUpperCase();
    const areaStr =
      property.area > 0
        ? `${Math.round(property.area)} ${(property.area_unit ?? "SQFT").toUpperCase()}`
        : "";
    const furnish = (property.furnishing_status ?? "").toUpperCase();

    const isRent = (property.listing_type ?? "").toLowerCase() === "rent";
    const price = Number(property.price ?? 0);
    const priceFormatted =
      price >= 10000000
        ? `${(price / 10000000).toFixed(2)} Cr`
        : price >= 100000
        ? `${(price / 100000).toFixed(2)} Lakh`
        : price > 0
        ? price.toLocaleString("en-IN")
        : "";

    // ── 4. Build deterministic (non-AI) values ───────────────────────────────
    const topHeaderParts = [
      `${bhkStr}${pType} FOR ${lType} IN ${(city || locality).toUpperCase()}`,
    ];
    if (areaStr) topHeaderParts.push(areaStr);
    if (furnish && furnish !== "UNFURNISHED") topHeaderParts.push(furnish);
    const topHeader = topHeaderParts.join(" / ");

    const socialHandle =
      instagramUsername
        ? `IG - @${instagramUsername.toUpperCase()}`
        : facebookPageName
        ? `FB - ${facebookPageName.toUpperCase()}`
        : "BROKERHIVE";

    const bottomContact = brokerName && brokerPhone
      ? `${brokerName.toUpperCase()} - ${brokerPhone}`
      : brokerPhone
      ? `CALL / WHATSAPP: ${brokerPhone}`
      : "CONTACT BROKER FOR SITE VISIT";

    // ── 5. Try Gemini for caption (rich, full property details) ──────────────
    const GEMINI_API_KEY = Deno.env.get("GEMINI_API_KEY");
    let caption = "";

    if (GEMINI_API_KEY) {
      // Pick best available flash model
      let modelName = "gemini-2.5-flash";
      try {
        const listRes = await fetch(
          `https://generativelanguage.googleapis.com/v1beta/models?key=${GEMINI_API_KEY}`
        );
        if (listRes.ok) {
          const listData = await listRes.json();
          const flashModels = (listData.models ?? [])
            .filter((m: any) => {
              const n = (m.name ?? "").toLowerCase();
              return (
                n.includes("flash") &&
                !n.includes("omni") &&
                !n.includes("preview") &&
                m.supportedGenerationMethods?.includes("generateContent")
              );
            })
            .map((m: any) => m.name.replace("models/", ""))
            .sort((a: string, b: string) => b.localeCompare(a));
          if (flashModels.length > 0) modelName = flashModels[0];
        }
      } catch (_) {
        // use default
      }

      // Build full property detail block for the prompt
      const bathrooms = property.bathrooms > 0 ? `${property.bathrooms} Bath` : "";
      const balconies = property.balconies > 0 ? `${property.balconies} Balcon${property.balconies > 1 ? "ies" : "y"}` : "";
      const parking = property.parking > 0 ? `${property.parking} Parking` : "";
      const floor = property.floor_number != null ? `Floor ${property.floor_number}${property.total_floors ? `/${property.total_floors}` : ""}` : "";
      const constructionStatus = property.construction_status ?? "";
      const facing = property.facing ?? "";
      const amenities: string[] = Array.isArray(property.amenities) ? property.amenities.slice(0, 6) : [];
      const fullAddress = addr.full_address ?? "";

      const propertySpecs = [
        bhkStr ? `${bhkStr}` : "",
        pType,
        lType,
        areaStr,
        bathrooms,
        balconies,
        parking,
        furnish,
        floor,
        constructionStatus,
        facing,
      ].filter(Boolean).join(" | ");

      const brokerLine = brokerName && brokerPhone
        ? `${brokerName} — 📞 ${brokerPhone}`
        : brokerPhone
        ? `📞 ${brokerPhone}`
        : "📞 DM for site visit";

      const prompt = `You are a top Indian real estate social media copywriter. Write a premium, viral Instagram/Facebook post caption for this property listing.

PROPERTY DETAILS:
Title: ${property.property_title}
Type: ${propertySpecs}
Price: ₹${priceFormatted}${isRent ? " / month" : ""}
Location: ${locality || city}${fullAddress ? " — " + fullAddress : ""}
Amenities: ${amenities.length > 0 ? amenities.join(", ") : "N/A"}
Broker: ${brokerLine}

FORMAT — write EXACTLY in this structure (use these emoji lines):
🏠 [Catchy headline — property title or a creative hook]

💰 Price: ₹${priceFormatted}${isRent ? "/month" : ""}
🛏 ${bhkStr ? bhkStr.trim() : pType} | ${areaStr || "Spacious"}${bathrooms ? " | " + bathrooms : ""}${balconies ? " | " + balconies : ""}${parking ? " | " + parking : ""}
🪑 ${furnish || "Available for viewing"}${constructionStatus ? " | " + constructionStatus : ""}${floor ? " | " + floor : ""}
📍 ${locality || city}${city && locality && locality !== city ? ", " + city : ""}${fullAddress ? "\n📌 " + fullAddress : ""}
${amenities.length > 0 ? "✅ " + amenities.slice(0, 5).join(" | ") : ""}

${brokerLine}
💬 WhatsApp / Call for site visit & full details!

[5-7 targeted hashtags: city, locality, property type, listing type, viral Indian real estate tags]

RULES:
- Use real emojis throughout (🏠 💰 🛏 🪑 📍 ✅ 📞 💬 🔑 🌟).
- Keep it engaging and professional — no generic filler text.
- Broker phone number MUST appear.
- Return ONLY the caption text. No markdown, no quotes, no extra explanation.`;

      try {
        const geminiRes = await fetch(
          `https://generativelanguage.googleapis.com/v1beta/models/${modelName}:generateContent?key=${GEMINI_API_KEY}`,
          {
            method: "POST",
            headers: { "Content-Type": "application/json" },
            body: JSON.stringify({
              contents: [{ parts: [{ text: prompt }] }],
            }),
          }
        );

        if (geminiRes.ok) {
          const geminiData = await geminiRes.json();
          caption =
            geminiData.candidates?.[0]?.content?.parts?.[0]?.text?.trim() ??
            "";
        }
      } catch (e) {
        console.warn("[generate-post-content] Gemini call failed:", e);
      }
    }

    // ── 6. Fallback caption if Gemini failed ─────────────────────────────────
    if (!caption) {
      const bathrooms = property.bathrooms > 0 ? ` | ${property.bathrooms} Bath` : "";
      const areaLine = areaStr ? ` | ${areaStr}` : "";
      const brokerLine = brokerPhone
        ? `📞 Call / WhatsApp: ${brokerPhone}`
        : "📞 DM for site visit!";
      const furnishLine = furnish && furnish !== "UNFURNISHED" ? ` | ${furnish}` : "";
      const amenities: string[] = Array.isArray(property.amenities) ? property.amenities.slice(0, 4) : [];

      caption = `🏠 ${property.property_title}

💰 ₹${priceFormatted}${isRent ? "/month" : ""}
🛏 ${bhkStr ? bhkStr.trim() : pType}${areaLine}${bathrooms}${furnishLine}
📍 ${locality || city}
${amenities.length > 0 ? "✅ " + amenities.join(" | ") + "\n" : ""}
${brokerName ? brokerName + " — " : ""}${brokerLine}
💬 WhatsApp / Call for site visit!

#RealEstate #${(city || "India").replace(/\s+/g, "")}Property #${pType.replace(/\s+/g, "")}For${lType} #DreamHome #IndianRealEstate`;
    }


    // ── 7. Return all fields ─────────────────────────────────────────────────
    return new Response(
      JSON.stringify({
        topHeader,
        instagramHandle: socialHandle,
        location: locationText,
        bottomContact,
        caption,
        brokerPhone,
        brokerName,
      }),
      {
        headers: { "Content-Type": "application/json", ...corsHeaders },
        status: 200,
      }
    );
  } catch (error) {
    return new Response(JSON.stringify({ error: error.message }), {
      headers: { "Content-Type": "application/json", ...corsHeaders },
      status: 500,
    });
  }
});
