import { serve } from "https://deno.land/std@0.224.0/http/server.ts";

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
    const clientId = Deno.env.get("INSTAGRAM_CLIENT_ID") || Deno.env.get("META_APP_ID");

    if (!clientId) {
      throw new Error("Missing INSTAGRAM_CLIENT_ID or META_APP_ID environment variable on Supabase.");
    }

    const rawRedirectUri = Deno.env.get("INSTAGRAM_REDIRECT_URI") || Deno.env.get("META_REDIRECT_URI") || Deno.env.get("FACEBOOK_REDIRECT_URI");
    if (!rawRedirectUri) {
      throw new Error("Missing INSTAGRAM_REDIRECT_URI, META_REDIRECT_URI, or FACEBOOK_REDIRECT_URI environment variable on Supabase.");
    }
    const redirectUri = rawRedirectUri
      .replace("meta-callback", "instagram-callback")
      .replace("facebook-callback", "instagram-callback");

    let brokerId = "";
    try {
      const body = await req.json();
      brokerId = body?.broker_id || "";
    } catch (_err) {
      throw new Error("Invalid request body. Expected JSON with broker_id.");
    }

    if (!brokerId) {
      throw new Error("Missing broker_id parameter.");
    }

    // Permissions/scopes for Direct Instagram Login to manage messages and comments
    const scopes = [
      "instagram_business_basic",
      "instagram_business_manage_messages",
      "instagram_business_manage_comments",
      "instagram_business_content_publish",
    ];

    const authUrl =
      `https://www.instagram.com/oauth/authorize` +
      `?client_id=${encodeURIComponent(clientId)}` +
      `&redirect_uri=${encodeURIComponent(redirectUri)}` +
      `&scope=${encodeURIComponent(scopes.join(","))}` +
      `&response_type=code` +
      `&state=${brokerId}`;

    return new Response(
      JSON.stringify({
        success: true,
        url: authUrl,
      }),
      {
        headers: {
          ...corsHeaders,
          "Content-Type": "application/json",
        },
      },
    );
  } catch (e) {
    return new Response(
      JSON.stringify({
        success: false,
        message: e instanceof Error ? e.message : "Unknown error",
      }),
      {
        status: 400,
        headers: {
          ...corsHeaders,
          "Content-Type": "application/json",
        },
      },
    );
  }
});
