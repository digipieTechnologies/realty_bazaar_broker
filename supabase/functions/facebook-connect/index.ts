import { serve } from "https://deno.land/std@0.224.0/http/server.ts";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", {
      headers: corsHeaders,
    });
  }

  try {
    const appId = Deno.env.get("META_APP_ID");
    let redirectUri = Deno.env.get("FACEBOOK_REDIRECT_URI");

    if (!appId || !redirectUri) {
      throw new Error("Missing Facebook/Meta server environment variables.");
    }

    if (redirectUri.includes("meta-callback")) {
      redirectUri = redirectUri.replace("meta-callback", "facebook-callback");
    }

    const scopes = [
      "pages_show_list",
      "pages_read_engagement",
      "pages_read_user_content",
      "pages_manage_posts",
      "pages_manage_metadata",
      "pages_manage_ads",
      "ads_management",
      "ads_read",
      "business_management",
      "pages_messaging",
      "read_insights",
    ];

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

    // Set state parameter to broker_id to associate returning OAuth redirects
    const state = brokerId;

    const authUrl =
      `https://www.facebook.com/v23.0/dialog/oauth` +
      `?client_id=${encodeURIComponent(appId)}` +
      `&redirect_uri=${encodeURIComponent(redirectUri)}` +
      `&scope=${encodeURIComponent(scopes.join(","))}` +
      `&response_type=code` +
      `&state=${state}`;

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
