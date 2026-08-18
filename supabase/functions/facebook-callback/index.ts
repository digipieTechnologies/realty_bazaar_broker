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

  // If the user cancelled or Facebook returned an error
  if (error) {
    const redirectUrl = `${webAppUrl}/social-connection-result?platform=facebook&connected=false&error=${encodeURIComponent(errorDescription || error)}`;
    return new Response(null, {
      status: 302,
      headers: {
        Location: redirectUrl,
        ...corsHeaders,
      },
    });
  }

  if (!code) {
    const redirectUrl = `${webAppUrl}/social-connection-result?platform=facebook&connected=false&error=${encodeURIComponent("Missing authorization code")}`;
    return new Response(null, {
      status: 302,
      headers: {
        Location: redirectUrl,
        ...corsHeaders,
      },
    });
  }

  if (!brokerId) {
    const redirectUrl = `${webAppUrl}/social-connection-result?platform=facebook&connected=false&error=${encodeURIComponent("Missing state broker_id parameter")}`;
    return new Response(null, {
      status: 302,
      headers: {
        Location: redirectUrl,
        ...corsHeaders,
      },
    });
  }

  try {
    const appId = Deno.env.get("FACEBOOK_APP_ID") || Deno.env.get("META_APP_ID");
    const appSecret = Deno.env.get("FACEBOOK_APP_SECRET") || Deno.env.get("META_APP_SECRET");
    let redirectUri = Deno.env.get("FACEBOOK_REDIRECT_URI") || Deno.env.get("META_REDIRECT_URI");
    const supabaseUrl = Deno.env.get("SUPABASE_URL");
    const supabaseServiceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");

    if (!appId || !appSecret || !redirectUri || !supabaseUrl || !supabaseServiceRoleKey) {
      throw new Error("Missing server configuration environment variables.");
    }

    if (redirectUri.includes("meta-callback")) {
      redirectUri = redirectUri.replace("meta-callback", "facebook-callback");
    }

    // 1. Exchange code for a short-lived User Access Token
    const tokenExchangeUrl = `https://graph.facebook.com/v23.0/oauth/access_token` +
      `?client_id=${appId}` +
      `&redirect_uri=${encodeURIComponent(redirectUri)}` +
      `&client_secret=${appSecret}` +
      `&code=${code}`;

    const tokenRes = await fetch(tokenExchangeUrl);
    if (!tokenRes.ok) {
      const errData = await tokenRes.json();
      throw new Error(`Token exchange failed: ${errData.error?.message || tokenRes.statusText}`);
    }
    const tokenData = await tokenRes.json();
    const shortLivedToken = tokenData.access_token;

    // 2. Exchange short-lived token for a long-lived User Access Token
    const longLivedTokenUrl = `https://graph.facebook.com/v23.0/oauth/access_token` +
      `?grant_type=fb_exchange_token` +
      `&client_id=${appId}` +
      `&client_secret=${appSecret}` +
      `&fb_exchange_token=${shortLivedToken}`;

    const longLivedRes = await fetch(longLivedTokenUrl);
    if (!longLivedRes.ok) {
      const errData = await longLivedRes.json();
      throw new Error(`Long-lived token exchange failed: ${errData.error?.message || longLivedRes.statusText}`);
    }
    const longLivedData = await longLivedRes.json();
    const userAccessToken = longLivedData.access_token;
    const expiresIn = longLivedData.expires_in || 5184000; // default 60 days
    const expiresAt = new Date(Date.now() + expiresIn * 1000).toISOString();

    // 3. Get Facebook User ID
    const meRes = await fetch(`https://graph.facebook.com/v23.0/me?access_token=${userAccessToken}`);
    if (!meRes.ok) {
      throw new Error("Failed to fetch Facebook user profile info.");
    }
    const meData = await meRes.json();
    const facebookUserId = meData.id;

    // 4. Fetch Facebook Pages associated with this account
    const pagesRes = await fetch(`https://graph.facebook.com/v23.0/me/accounts?access_token=${userAccessToken}`);
    if (!pagesRes.ok) {
      const errBody = await pagesRes.text();
      console.error("Pages API error response:", errBody);
      throw new Error("Failed to retrieve Facebook Pages associated with this account.");
    }
    const pagesData = await pagesRes.json();

    // Debugging: Log granted permissions & pages data
    try {
      const permRes = await fetch(`https://graph.facebook.com/v23.0/me/permissions?access_token=${userAccessToken}`);
      if (permRes.ok) {
        const permData = await permRes.json();
        console.log("DEBUG: Granted Permissions for Token:", JSON.stringify(permData));
      }
    } catch (permErr) {
      console.warn("DEBUG: Failed to fetch permissions info:", permErr);
    }
    console.log("DEBUG: Facebook Pages API returned:", JSON.stringify(pagesData));

    if (!pagesData.data || pagesData.data.length === 0) {
      throw new Error("No Facebook Pages found associated with this account.");
    }

    // Pick the first associated Facebook Page
    const targetPage = pagesData.data[0];
    const pageId = targetPage.id;
    const pageName = targetPage.name;
    const pageAccessToken = targetPage.access_token;

    // 4a. Subscribe the app to the Facebook Page's feed webhook events
    try {
      const subscribeUrl = `https://graph.facebook.com/v23.0/${pageId}/subscribed_apps?subscribed_fields=feed&access_token=${pageAccessToken}`;
      const subRes = await fetch(subscribeUrl, { method: "POST" });
      if (subRes.ok) {
        const subData = await subRes.json();
        console.log(`Successfully subscribed app to Page feed events:`, JSON.stringify(subData));
      } else {
        const subErr = await subRes.json();
        console.error(`Failed to subscribe app to Page feed events:`, JSON.stringify(subErr));
      }
    } catch (subErr) {
      console.error("Error subscribing app to Page feed events:", subErr);
    }

    // 4b. Automatically link Facebook Page to Agency Meta Business Portfolio (if META_BUSINESS_ID secret is configured)
    const businessId = Deno.env.get("META_BUSINESS_ID");
    if (businessId) {
      try {
        console.log(`[FB Callback] Requesting partner page link for Page ${pageId} to Business Portfolio ${businessId}...`);
        const linkUrl = `https://graph.facebook.com/v23.0/${businessId}/client_pages` +
          `?page_id=${encodeURIComponent(pageId)}` +
          `&permitted_tasks=${encodeURIComponent(JSON.stringify(["ADVERTISE", "ANALYZE", "MANAGE"]))}` +
          `&access_token=${encodeURIComponent(userAccessToken)}`;

        const linkRes = await fetch(linkUrl, { method: "POST" });
        const linkData = await linkRes.json().catch(() => ({}));
        if (linkRes.ok && (linkData.success || linkData.id)) {
          console.log(`[FB Callback] Successfully linked Page ${pageId} to Business Portfolio ${businessId}!`);
        } else {
          console.warn(`[FB Callback] Business portfolio page link result:`, linkData);
        }
      } catch (linkErr) {
        console.error("[FB Callback] Error linking Page to Business Portfolio:", linkErr);
      }
    }

    // 4c. Fetch Broker's Meta Ad Accounts & Link to Business Portfolio
    let primaryAdAccountId: string | null = null;
    try {
      const adAccRes = await fetch(
        `https://graph.facebook.com/v23.0/me/adaccounts?fields=id,account_id,name,account_status&access_token=${userAccessToken}`
      );
      if (adAccRes.ok) {
        const adAccData = await adAccRes.json();
        if (adAccData.data && adAccData.data.length > 0) {
          primaryAdAccountId = adAccData.data[0].id; // Format: "act_XXXXXXXX"
          console.log(`[FB Callback] Found ${adAccData.data.length} Ad Accounts. Primary: ${primaryAdAccountId}`);

          if (businessId) {
            for (const adAccount of adAccData.data) {
              try {
                console.log(`[FB Callback] Requesting client ad account link for ${adAccount.id} to Business Portfolio ${businessId}...`);
                const adLinkUrl = `https://graph.facebook.com/v23.0/${businessId}/client_ad_accounts` +
                  `?adaccount_id=${encodeURIComponent(adAccount.id)}` +
                  `&permitted_tasks=${encodeURIComponent(JSON.stringify(["ADVERTISE", "ANALYZE"]))}` +
                  `&access_token=${encodeURIComponent(userAccessToken)}`;

                const adLinkRes = await fetch(adLinkUrl, { method: "POST" });
                const adLinkData = await adLinkRes.json().catch(() => ({}));
                if (adLinkRes.ok && (adLinkData.success || adLinkData.id)) {
                  console.log(`[FB Callback] Successfully linked Ad Account ${adAccount.id} to Business Portfolio ${businessId}!`);
                } else {
                  console.warn(`[FB Callback] Ad Account link result for ${adAccount.id}:`, adLinkData);
                }
              } catch (adLinkErr) {
                console.error(`[FB Callback] Error linking Ad Account ${adAccount.id}:`, adLinkErr);
              }
            }
          }
        }
      } else {
        const adAccErr = await adAccRes.json().catch(() => ({}));
        console.warn(`[FB Callback] Ad Accounts API response error:`, adAccErr);
      }
    } catch (adErr) {
      console.warn("[FB Callback] Failed to fetch or link Ad Accounts:", adErr);
    }

    // Initialize Supabase Client
    const supabase = createClient(supabaseUrl, supabaseServiceRoleKey);

    // 5. Check if Facebook connection row exists for this broker & platform, update if exists, insert if new
    const fbPayload: Record<string, any> = {
      broker_id: brokerId,
      platform: "facebook",
      facebook_user_id: facebookUserId,
      page_id: pageId,
      page_name: pageName,
      page_access_token: pageAccessToken,
      access_token: userAccessToken,
      expires_at: expiresAt,
      is_connected: true,
      is_active: true,
      updated_at: new Date().toISOString(),
    };

    if (primaryAdAccountId) {
      fbPayload.ad_account_id = primaryAdAccountId;
    }

    const { data: existingFbRecord } = await supabase
      .from("social_accounts")
      .select("id")
      .eq("broker_id", brokerId)
      .or(`platform.eq.facebook,page_id.eq.${pageId}`)
      .maybeSingle();

    if (existingFbRecord?.id) {
      console.log(`[FB Callback] Existing Facebook account found (ID: ${existingFbRecord.id}). Updating row...`);
      const { error: updateFbError } = await supabase
        .from("social_accounts")
        .update({
          ...fbPayload,
          platform: "facebook",
        })
        .eq("id", existingFbRecord.id);

      if (updateFbError) {
        throw new Error(`Failed to update Facebook account: ${updateFbError.message}`);
      }
    } else {
      console.log(`[FB Callback] No existing Facebook account found for broker ${brokerId}. Inserting new row...`);
      const { error: insertFbError } = await supabase
        .from("social_accounts")
        .insert({
          ...fbPayload,
          platform: "facebook",
        });

      if (insertFbError) {
        throw new Error(`Failed to insert Facebook account: ${insertFbError.message}`);
      }
    }

    // 6. Success! Redirect user to the web success page
    const redirectUrl = `${webAppUrl}/social-connection-result?platform=facebook&connected=true`;
    
    return new Response(null, {
      status: 302,
      headers: {
        Location: redirectUrl,
        ...corsHeaders
      },
    });

  } catch (e) {
    const errorMsg = e instanceof Error ? e.message : "Unknown error";
    console.error(`Facebook callback error: ${errorMsg}`);
    
    const redirectUrl = `${webAppUrl}/social-connection-result?platform=facebook&connected=false&error=${encodeURIComponent(errorMsg)}`;
    
    return new Response(null, {
      status: 302,
      headers: {
        Location: redirectUrl,
        ...corsHeaders
      },
    });
  }
});
