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
    const supabaseUrl = Deno.env.get("SUPABASE_URL");
    const supabaseServiceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");

    if (!supabaseUrl || !supabaseServiceRoleKey) {
      throw new Error("Missing server configuration environment variables (SUPABASE_URL / SUPABASE_SERVICE_ROLE_KEY).");
    }

    let brokerId = "";
    let platform = "";

    try {
      const body = await req.json();
      brokerId = body?.broker_id || "";
      platform = body?.platform || "";
    } catch (_err) {
      throw new Error("Invalid JSON request body. Expected broker_id and platform.");
    }

    if (!brokerId) {
      throw new Error("Missing required parameter: broker_id");
    }

    if (!platform || (platform !== "facebook" && platform !== "instagram")) {
      throw new Error("Missing or invalid platform parameter. Expected 'facebook' or 'instagram'.");
    }

    console.log(`[Disconnect] Processing request for broker: ${brokerId}, platform: ${platform}`);

    const supabase = createClient(supabaseUrl, supabaseServiceRoleKey);

    // 1. Fetch social account details from Database
    const { data: account, error: accountError } = await supabase
      .from("social_accounts")
      .select("*")
      .eq("broker_id", brokerId)
      .eq("platform", platform)
      .maybeSingle();

    if (accountError) {
      throw new Error(`Failed to query social_accounts: ${accountError.message}`);
    }

    if (!account) {
      console.log(`[Disconnect] No active ${platform} connection found in DB for broker ${brokerId}. Cleaning up any lingering records.`);
    }

    const apiBase = "https://graph.facebook.com/v23.0";
    const userToken = account?.access_token || "";
    const pageToken = account?.page_access_token || userToken;
    const pageId = account?.page_id || "";
    const fbUserId = account?.facebook_user_id || account?.user_id || "";

    // 2. Unsubscribe Webhooks on Meta side if Page ID & Page Access Token exist
    if (pageId && pageToken) {
      try {
        console.log(`[Disconnect] Unsubscribing webhooks for Meta Page ID: ${pageId}`);
        const unsubscribeUrl = `${apiBase}/${pageId}/subscribed_apps?access_token=${pageToken}`;
        const unsubRes = await fetch(unsubscribeUrl, { method: "DELETE" });
        const unsubData = await unsubRes.json().catch(() => ({}));
        
        if (unsubRes.ok && unsubData.success) {
          console.log(`[Disconnect] Webhooks successfully unsubscribed for Page ${pageId}`);
        } else {
          console.warn(`[Disconnect] Webhook unsubscription returned:`, unsubData);
        }
      } catch (unsubErr) {
        console.error(`[Disconnect] Error unsubscribing webhooks for Page ${pageId}:`, unsubErr);
      }
    }

    // 3. Revoke Meta App Permissions (User Access Token)
    const tokenToRevoke = userToken || pageToken;
    if (tokenToRevoke) {
      try {
        const targetId = fbUserId || "me";
        console.log(`[Disconnect] Revoking Meta permissions for target: ${targetId}`);
        const revokeUrl = `${apiBase}/${targetId}/permissions?access_token=${tokenToRevoke}`;
        const revokeRes = await fetch(revokeUrl, { method: "DELETE" });
        const revokeData = await revokeRes.json().catch(() => ({}));

        if (revokeRes.ok && revokeData.success) {
          console.log(`[Disconnect] Meta permissions successfully revoked for ${targetId}`);
        } else {
          console.warn(`[Disconnect] Meta permission revocation returned:`, revokeData);
        }
      } catch (revokeErr) {
        console.error(`[Disconnect] Error revoking Meta permissions:`, revokeErr);
      }
    }

    // 4. Disconnect: Clear access tokens and update connection record in `social_accounts` table
    if (account?.id) {
      console.log(`[Disconnect] Updating ${platform} account ID ${account.id} in social_accounts table: clearing tokens and setting is_connected = false for broker: ${brokerId}`);
      const { error: updateError } = await supabase
        .from("social_accounts")
        .update({
          access_token: null,
          page_access_token: null,
          is_connected: false,
          is_active: false,
          updated_at: new Date().toISOString(),
        })
        .eq("id", account.id);

      if (updateError) {
        throw new Error(`Failed to update social connection record in database: ${updateError.message}`);
      }
    } else {
      console.log(`[Disconnect] Updating ${platform} account by broker_id for broker: ${brokerId}`);
      const { error: updateError } = await supabase
        .from("social_accounts")
        .update({
          access_token: null,
          page_access_token: null,
          is_connected: false,
          is_active: false,
          updated_at: new Date().toISOString(),
        })
        .eq("broker_id", brokerId)
        .filter("platform", "eq", platform);

      if (updateError) {
        throw new Error(`Failed to update social connection record in database: ${updateError.message}`);
      }
    }

    console.log(`[Disconnect] ${platform} connection successfully marked as disconnected (is_connected = false) for broker ${brokerId}`);

    return new Response(
      JSON.stringify({
        success: true,
        message: `Successfully disconnected ${platform}, unsubscribed webhooks, and revoked Meta permissions.`,
        platform: platform,
        broker_id: brokerId,
      }),
      {
        status: 200,
        headers: {
          ...corsHeaders,
          "Content-Type": "application/json",
        },
      }
    );

  } catch (e) {
    const errorMsg = e instanceof Error ? e.message : "An unexpected server error occurred.";
    console.error(`[Disconnect] Server Error: ${errorMsg}`);

    return new Response(
      JSON.stringify({
        success: false,
        message: errorMsg,
      }),
      {
        status: 400,
        headers: {
          ...corsHeaders,
          "Content-Type": "application/json",
        },
      }
    );
  }
});
