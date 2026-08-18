import { serve } from "https://deno.land/std@0.224.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

// Validate token with Meta Graph API
async function validateMetaToken(token: string, platform: string): Promise<boolean> {
  try {
    if (!token) return false;

    const url = platform === "instagram"
      ? `https://graph.instagram.com/me?fields=id,username&access_token=${encodeURIComponent(token)}`
      : `https://graph.facebook.com/v23.0/me?access_token=${encodeURIComponent(token)}`;

    const res = await fetch(url);
    if (!res.ok) {
      const errData = await res.json().catch(() => ({}));
      console.warn(`[Token Check] ${platform} token validation failed (HTTP ${res.status}):`, errData);
      return false;
    }
    return true;
  } catch (err) {
    console.error(`[Token Check] Network error validating ${platform} token:`, err);
    return false;
  }
}

// Fetch live profile picture URL for Instagram and Facebook Pages
async function fetchProfilePicture(account: any, token: string): Promise<string | null> {
  try {
    if (!token) return null;
    const platform = account.platform;

    if (platform === "instagram") {
      const igId = account.instagram_account_id;
      if (igId) {
        const url = `https://graph.facebook.com/v23.0/${igId}?fields=profile_picture_url&access_token=${encodeURIComponent(token)}`;
        const res = await fetch(url);
        if (res.ok) {
          const data = await res.json();
          if (data.profile_picture_url) {
            console.log(`[Profile Pic] Successfully fetched Instagram DP: ${data.profile_picture_url}`);
            return data.profile_picture_url;
          }
        }
      }
      const igMeUrl = `https://graph.instagram.com/me?fields=profile_picture_url,username&access_token=${encodeURIComponent(token)}`;
      const igMeRes = await fetch(igMeUrl);
      if (igMeRes.ok) {
        const igMeData = await igMeRes.json();
        if (igMeData.profile_picture_url) {
          console.log(`[Profile Pic] Successfully fetched Instagram DP from me endpoint: ${igMeData.profile_picture_url}`);
          return igMeData.profile_picture_url;
        }
      }
    } else if (platform === "facebook") {
      const pageId = account.page_id;
      if (pageId) {
        const pageUrl = `https://graph.facebook.com/v23.0/${pageId}?fields=picture{url}&access_token=${encodeURIComponent(token)}`;
        const res = await fetch(pageUrl);
        if (res.ok) {
          const data = await res.json();
          if (data.picture?.data?.url) {
            return data.picture.data.url;
          }
        }
        return `https://graph.facebook.com/v23.0/${pageId}/picture?type=large`;
      }
    }
  } catch (err) {
    console.warn(`[Profile Pic] Failed to fetch profile picture for ${account.platform}:`, err);
  }
  return null;
}

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const supabaseUrl = Deno.env.get("SUPABASE_URL");
    const supabaseServiceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");

    if (!supabaseUrl || !supabaseServiceRoleKey) {
      throw new Error("Missing server configuration environment variables.");
    }

    let brokerId = "";
    try {
      const body = await req.json();
      brokerId = body?.broker_id || "";
    } catch (_err) {
      throw new Error("Invalid request body. Expected JSON payload with broker_id.");
    }

    if (!brokerId) {
      throw new Error("Missing required parameter: broker_id");
    }

    console.log(`[Fetch Social Connections] Fetching & validating accounts for broker: ${brokerId}`);

    const supabase = createClient(supabaseUrl, supabaseServiceRoleKey);

    // 1. Fetch all social account records for this broker from DB
    const { data: accounts, error: dbError } = await supabase
      .from("social_accounts")
      .select("*")
      .eq("broker_id", brokerId);

    if (dbError) {
      throw new Error(`Failed to fetch social accounts from database: ${dbError.message}`);
    }

    const processedAccounts = [];

    // 2. Iterate and validate tokens live against Meta Graph API
    for (const account of (accounts || [])) {
      const platform = account.platform;
      const isConnectedInDb = account.is_connected !== false && account.is_active !== false;
      const token = account.page_access_token || account.access_token;

      let isValidToken = isConnectedInDb;

      // Only perform live Meta Graph API check if marked as connected in DB
      if (isConnectedInDb && token) {
        isValidToken = await validateMetaToken(token, platform);

        // If Meta rejects the token (revoked, expired, password changed), update DB automatically
        if (!isValidToken) {
          console.log(`[Fetch Social Connections] ${platform} token invalid for broker ${brokerId}. Updating DB to is_connected = false.`);
          
          await supabase
            .from("social_accounts")
            .update({
              is_connected: false,
              is_active: false,
              updated_at: new Date().toISOString(),
            })
            .eq("id", account.id);

          account.is_connected = false;
          account.is_active = false;
        } else {
          // If valid, fetch live profile picture URL
          const picUrl = await fetchProfilePicture(account, token);
          if (picUrl) {
            account.profile_picture_url = picUrl;
            // Update profile_picture_url in DB
            await supabase
              .from("social_accounts")
              .update({
                profile_picture_url: picUrl,
                updated_at: new Date().toISOString(),
              })
              .eq("id", account.id);
          }
        }
      }

      processedAccounts.push(account);
    }

    // Separate into convenient platform objects
    const facebookAccount = processedAccounts.find((a) => a.platform === "facebook") || null;
    const instagramAccount = processedAccounts.find((a) => a.platform === "instagram") || null;

    console.log(`[Fetch Social Connections] Successfully processed ${processedAccounts.length} accounts for broker ${brokerId}`);

    return new Response(
      JSON.stringify({
        success: true,
        accounts: processedAccounts,
        facebook: facebookAccount,
        instagram: instagramAccount,
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
    console.error(`[Fetch Social Connections] Error: ${errorMsg}`);

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
