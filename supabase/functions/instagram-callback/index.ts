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

  const webAppUrl = (Deno.env.get("WEB_PORTAL_APP_URL") || "").replace(/\/$/, "");
  const url = new URL(req.url);
  const code = url.searchParams.get("code");
  const error = url.searchParams.get("error");
  const errorDescription = url.searchParams.get("error_description");
  const brokerId = url.searchParams.get("state"); // broker_id passed as state

  // If the user cancelled or Instagram returned an error
  if (error) {
    const redirectUrl = `${webAppUrl}/social-connection-result?platform=instagram&connected=false&error=${encodeURIComponent(errorDescription || error)}`;
    return new Response(null, {
      status: 302,
      headers: {
        Location: redirectUrl,
        ...corsHeaders,
      },
    });
  }

  if (!code) {
    const redirectUrl = `${webAppUrl}/social-connection-result?platform=instagram&connected=false&error=${encodeURIComponent("Missing authorization code")}`;
    return new Response(null, {
      status: 302,
      headers: {
        Location: redirectUrl,
        ...corsHeaders,
      },
    });
  }

  if (!brokerId) {
    const redirectUrl = `${webAppUrl}/social-connection-result?platform=instagram&connected=false&error=${encodeURIComponent("Missing state broker_id parameter")}`;
    return new Response(null, {
      status: 302,
      headers: {
        Location: redirectUrl,
        ...corsHeaders,
      },
    });
  }

  try {
    const clientId = Deno.env.get("INSTAGRAM_CLIENT_ID") || Deno.env.get("META_APP_ID");
    const clientSecret = Deno.env.get("INSTAGRAM_CLIENT_SECRET") || Deno.env.get("META_APP_SECRET");
    const supabaseUrl = Deno.env.get("SUPABASE_URL");
    const supabaseServiceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");

    if (!clientId || !clientSecret || !supabaseUrl || !supabaseServiceRoleKey) {
      throw new Error("Missing server configuration environment variables.");
    }

    const rawRedirectUri = Deno.env.get("INSTAGRAM_REDIRECT_URI") || Deno.env.get("META_REDIRECT_URI") || Deno.env.get("FACEBOOK_REDIRECT_URI");
    if (!rawRedirectUri) {
      throw new Error("Missing INSTAGRAM_REDIRECT_URI, META_REDIRECT_URI, or FACEBOOK_REDIRECT_URI environment variable on Supabase.");
    }
    const redirectUri = rawRedirectUri
      .replace("meta-callback", "instagram-callback")
      .replace("facebook-callback", "instagram-callback");

    // 1. Exchange authorization code for a short-lived Instagram user access token
    const tokenExchangeUrl = "https://api.instagram.com/oauth/access_token";
    const tokenParams = new URLSearchParams();
    tokenParams.append("client_id", clientId);
    tokenParams.append("client_secret", clientSecret);
    tokenParams.append("grant_type", "authorization_code");
    tokenParams.append("redirect_uri", redirectUri);
    tokenParams.append("code", code);

    const tokenRes = await fetch(tokenExchangeUrl, {
      method: "POST",
      body: tokenParams,
    });

    if (!tokenRes.ok) {
      const errData = await tokenRes.json().catch(() => ({}));
      throw new Error(`Short-lived token exchange failed: ${errData.error_message || tokenRes.statusText}`);
    }
    const tokenData = await tokenRes.json();
    const shortLivedToken = tokenData.access_token;
    const instagramUserId = tokenData.user_id;

    // 2. Exchange short-lived token for a long-lived Access Token (lasts 60 days)
    const longLivedTokenUrl = `https://graph.instagram.com/access_token` +
      `?grant_type=ig_exchange_token` +
      `&client_secret=${clientSecret}` +
      `&access_token=${shortLivedToken}`;

    const longLivedRes = await fetch(longLivedTokenUrl);
    if (!longLivedRes.ok) {
      const errData = await longLivedRes.json().catch(() => ({}));
      throw new Error(`Long-lived token exchange failed: ${errData.error?.message || longLivedRes.statusText}`);
    }
    const longLivedData = await longLivedRes.json();
    const userAccessToken = longLivedData.access_token;
    const expiresIn = longLivedData.expires_in || 5184000; // default 60 days
    const expiresAt = new Date(Date.now() + expiresIn * 1000).toISOString();

    // 3. Fetch Instagram user profile to retrieve the username and professional account ID (user_id)
    const meRes = await fetch(`https://graph.instagram.com/me?fields=id,username,user_id&access_token=${userAccessToken}`);
    if (!meRes.ok) {
      const errData = await meRes.json().catch(() => ({}));
      throw new Error(`Profile fetch failed: ${errData.error?.message || meRes.statusText}`);
    }
    const meData = await meRes.json();
    const instagramUsername = meData.username;
    const resolvedAccountId = (meData.user_id || meData.id).toString();

    // Initialize Supabase Client
    const supabase = createClient(supabaseUrl, supabaseServiceRoleKey);

    // 4. Check if connection row exists for this broker & platform, update if exists, insert if new
    const igPayload = {
      broker_id: brokerId,
      platform: "instagram",
      instagram_account_id: resolvedAccountId,
      instagram_username: instagramUsername,
      access_token: userAccessToken,
      expires_at: expiresAt,
      is_connected: true,
      is_active: true,
      updated_at: new Date().toISOString(),
    };

    const { data: existingIgRecord } = await supabase
      .from("social_accounts")
      .select("id")
      .eq("broker_id", brokerId)
      .or(`platform.eq.instagram,instagram_account_id.eq.${resolvedAccountId}`)
      .maybeSingle();

    if (existingIgRecord?.id) {
      console.log(`[IG Callback] Existing Instagram account found (ID: ${existingIgRecord.id}). Updating row...`);
      const { error: updateIgError } = await supabase
        .from("social_accounts")
        .update({
          ...igPayload,
          platform: "instagram",
        })
        .eq("id", existingIgRecord.id);

      if (updateIgError) {
        throw new Error(`Failed to update Instagram account: ${updateIgError.message}`);
      }
    } else {
      console.log(`[IG Callback] No existing Instagram account found for broker ${brokerId}. Inserting new row...`);
      const { error: insertIgError } = await supabase
        .from("social_accounts")
        .insert({
          ...igPayload,
          platform: "instagram",
        });

      if (insertIgError) {
        throw new Error(`Failed to insert Instagram account: ${insertIgError.message}`);
      }
    }

    // 4b. Check and update broker setup_details JSONB (instagram_connected)
    try {
      const { data: brokerRecord } = await supabase
        .from("brokers")
        .select("setup_details")
        .eq("id", brokerId)
        .maybeSingle();

      const currentSetupDetails = brokerRecord?.setup_details || {};
      if (!currentSetupDetails.instagram_connected) {
        const updatedSetupDetails = {
          ...currentSetupDetails,
          account_created: currentSetupDetails.account_created ?? true,
          business_info_added: currentSetupDetails.business_info_added ?? false,
          facebook_connected: currentSetupDetails.facebook_connected ?? false,
          instagram_connected: true,
          properties_imported: currentSetupDetails.properties_imported ?? false,
          team_invited: currentSetupDetails.team_invited ?? false,
        };

        const { error: updateSetupError } = await supabase
          .from("brokers")
          .update({ setup_details: updatedSetupDetails })
          .eq("id", brokerId);

        if (updateSetupError) {
          console.warn(`[IG Callback] Warning updating broker setup_details:`, updateSetupError.message);
        } else {
          console.log(`[IG Callback] Successfully set setup_details.instagram_connected = true for broker ${brokerId}`);
        }
      }
    } catch (setupErr) {
      console.warn(`[IG Callback] Error handling setup_details check:`, setupErr);
    }

    // 5. Success! Redirect user to the web success page
    const redirectUrl = `${webAppUrl}/social-connection-result?platform=instagram&connected=true`;

    return new Response(null, {
      status: 302,
      headers: {
        ...corsHeaders,
        Location: redirectUrl,
      },
    });

  } catch (e) {
    const errorMsg = e instanceof Error ? e.message : "Unknown error";
    console.error(`Instagram callback error: ${errorMsg}`);

    const redirectUrl = `${webAppUrl}/social-connection-result?platform=instagram&connected=false&error=${encodeURIComponent(errorMsg)}`;

    return new Response(null, {
      status: 302,
      headers: {
        ...corsHeaders,
        Location: redirectUrl,
      },
    });
  }
});
