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
    const { property, isEdit } = await req.json();

    if (!property) {
      return new Response(JSON.stringify({ error: "Missing property payload" }), {
        headers: { "Content-Type": "application/json", ...corsHeaders },
        status: 400,
      });
    }

    const supabase = createClient(
      Deno.env.get("SUPABASE_URL") ?? "",
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? ""
    );

    let finalProperty = null;

    if (isEdit) {
      const propertyId = property.id;
      if (!propertyId) {
        return new Response(JSON.stringify({ error: "Missing property ID for update" }), {
          headers: { "Content-Type": "application/json", ...corsHeaders },
          status: 400,
        });
      }

      // Update nested address if provided
      if (property.address) {
        const { id: addrId, created_at, updated_at, ...addressPayload } = property.address;
        const addressIdToUpdate = property.address_id || addrId;
        if (addressIdToUpdate) {
          addressPayload.entity_id = propertyId;
          addressPayload.entity_type = "property";

          const { error: addressErr } = await supabase
            .from("addresses")
            .update(addressPayload)
            .eq("id", addressIdToUpdate);

          if (addressErr) {
            return new Response(JSON.stringify({ error: `Failed to update address: ${addressErr.message}` }), {
              headers: { "Content-Type": "application/json", ...corsHeaders },
              status: 400,
            });
          }
        }
      }

      // Update property record
      const { address, id, created_at, updated_at, ...propertyPayload } = property;
      const { data: updatedProp, error: propertyErr } = await supabase
        .from("properties")
        .update(propertyPayload)
        .eq("id", propertyId)
        .select()
        .single();

      if (propertyErr) {
        return new Response(JSON.stringify({ error: `Failed to update property: ${propertyErr.message}` }), {
          headers: { "Content-Type": "application/json", ...corsHeaders },
          status: 400,
        });
      }

      finalProperty = updatedProp;
    } else {
      // Create new property
      // 1. Insert property record first with address_id = null to obtain its UUID
      const { address, id, created_at, updated_at, ...propertyPayload } = property;
      propertyPayload.address_id = null;

      const { data: newProp, error: propertyErr } = await supabase
        .from("properties")
        .insert(propertyPayload)
        .select("id")
        .single();

      if (propertyErr) {
        return new Response(JSON.stringify({ error: `Failed to insert property: ${propertyErr.message}` }), {
          headers: { "Content-Type": "application/json", ...corsHeaders },
          status: 400,
        });
      }

      const propertyId = newProp.id;
      let addressId = null;

      // 2. Insert address record referencing the new propertyId (satisfying NOT NULL constraint)
      if (address) {
        const { id: addrId, created_at, updated_at, ...addressPayload } = address;
        addressPayload.entity_id = propertyId;
        addressPayload.entity_type = "property";

        const { data: newAddr, error: addressErr } = await supabase
          .from("addresses")
          .insert(addressPayload)
          .select("id")
          .single();

        if (addressErr) {
          // Roll back property insertion on failure
          await supabase.from("properties").delete().eq("id", propertyId);
          return new Response(JSON.stringify({ error: `Failed to insert address: ${addressErr.message}` }), {
            headers: { "Content-Type": "application/json", ...corsHeaders },
            status: 400,
          });
        }
        addressId = newAddr.id;

        // 3. Link address_id in properties back to the newly created address
        const { error: linkErr } = await supabase
          .from("properties")
          .update({ address_id: addressId })
          .eq("id", propertyId);

        if (linkErr) {
          // Roll back both insertions on failure
          await supabase.from("addresses").delete().eq("id", addressId);
          await supabase.from("properties").delete().eq("id", propertyId);
          return new Response(JSON.stringify({ error: `Failed to link address to property: ${linkErr.message}` }), {
            headers: { "Content-Type": "application/json", ...corsHeaders },
            status: 400,
          });
        }
      }

      finalProperty = { ...newProp, address_id: addressId };
    }

    return new Response(JSON.stringify({ success: true, property: finalProperty }), {
      headers: { "Content-Type": "application/json", ...corsHeaders },
      status: 200,
    });

  } catch (err) {
    return new Response(JSON.stringify({ error: err.message }), {
      headers: { "Content-Type": "application/json", ...corsHeaders },
      status: 500,
    });
  }
});
