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
      throw new Error("Missing server configuration environment variables.");
    }

    let brokerId = "";
    let page = 1;
    let limit = 10;
    let afterCursor = "";

    try {
      const body = await req.json();
      brokerId = body?.broker_id || "";
      page = Number(body?.page) || 1;
      limit = Number(body?.limit) || 10;
      afterCursor = body?.after_cursor || "";
    } catch (_err) {
      throw new Error("Invalid request body. Expected JSON payload.");
    }

    if (!brokerId) {
      throw new Error("Missing required parameter: broker_id");
    }

    if (page < 1) page = 1;
    if (limit < 1) limit = 10;

    console.log(`[Fetch Instagram Posts] Broker: ${brokerId}, Page: ${page}, Limit: ${limit}`);

    const supabase = createClient(supabaseUrl, supabaseServiceRoleKey);

    // 1. Fetch Instagram social account record for this broker
    const { data: accounts, error: dbError } = await supabase
      .from("social_accounts")
      .select("*")
      .eq("broker_id", brokerId)
      .eq("platform", "instagram");

    if (dbError) {
      throw new Error(`Failed to query database: ${dbError.message}`);
    }

    const igAccount = (accounts || []).find(
      (a) => (a.is_connected !== false) && (a.is_active !== false) && (a.instagram_account_id || a.page_id || a.access_token)
    );

    if (!igAccount) {
      console.log(`[Fetch Instagram Posts] No active Instagram connection found for broker: ${brokerId}`);
      return new Response(
        JSON.stringify({
          success: true,
          is_connected: false,
          posts: [],
          page: 1,
          total_items: 0,
          total_pages: 0,
          has_more: false,
        }),
        {
          status: 200,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    const igAccountId = igAccount.instagram_account_id || igAccount.page_id;
    const pageToken = igAccount.page_access_token;
    const userToken = igAccount.access_token;

    // Determine candidate endpoints and tokens to support both Meta FB-linked and Direct IG tokens
    const candidateRequests: Array<{ url: string; token: string }> = [];

    // Option A: Facebook Graph API with Page Access Token & Account ID
    if (pageToken && pageToken.trim() !== "" && pageToken !== "null" && igAccountId) {
      let url = `https://graph.facebook.com/v23.0/${igAccountId}/media?fields=id,caption,media_type,media_url,thumbnail_url,permalink,timestamp,like_count,comments_count&limit=${limit}&access_token=${encodeURIComponent(pageToken)}`;
      if (afterCursor) url += `&after=${encodeURIComponent(afterCursor)}`;
      candidateRequests.push({ url, token: pageToken });
    }

    // Option B: Facebook Graph API with User Access Token & Account ID
    if (userToken && userToken.trim() !== "" && userToken !== "null" && igAccountId) {
      let url = `https://graph.facebook.com/v23.0/${igAccountId}/media?fields=id,caption,media_type,media_url,thumbnail_url,permalink,timestamp,like_count,comments_count&limit=${limit}&access_token=${encodeURIComponent(userToken)}`;
      if (afterCursor) url += `&after=${encodeURIComponent(afterCursor)}`;
      candidateRequests.push({ url, token: userToken });
    }

    // Option C: Direct Instagram Graph API (/me/media) with User Access Token
    if (userToken && userToken.trim() !== "" && userToken !== "null") {
      let url = `https://graph.instagram.com/me/media?fields=id,caption,media_type,media_url,thumbnail_url,permalink,timestamp,like_count,comments_count&limit=${limit}&access_token=${encodeURIComponent(userToken)}`;
      if (afterCursor) url += `&after=${encodeURIComponent(afterCursor)}`;
      candidateRequests.push({ url, token: userToken });
    }

    if (candidateRequests.length === 0) {
      console.log(`[Fetch Instagram Posts] No valid tokens available for Instagram account of broker ${brokerId}`);
      return new Response(
        JSON.stringify({
          success: true,
          is_connected: false,
          posts: [],
          page: 1,
          total_items: 0,
          total_pages: 0,
          has_more: false,
        }),
        {
          status: 200,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    let metaRes: Response | null = null;
    let metaData: any = null;

    // Try candidate endpoints sequentially until one succeeds
    for (const reqObj of candidateRequests) {
      try {
        console.log(`[Fetch Instagram Posts] Attempting endpoint: ${reqObj.url.substring(0, 75)}...`);
        const res = await fetch(reqObj.url);
        if (res.ok) {
          metaRes = res;
          metaData = await res.json();
          break;
        } else {
          const errBody = await res.json().catch(() => ({}));
          console.warn(`[Fetch Instagram Posts] Candidate endpoint failed (HTTP ${res.status}):`, errBody);
        }
      } catch (err) {
        console.warn(`[Fetch Instagram Posts] Fetch error:`, err);
      }
    }

    if (!metaRes || !metaData || !metaData.data) {
      console.log(`[Fetch Instagram Posts] All Instagram API endpoints failed or token invalid for broker ${brokerId}. Updating DB to is_connected = false.`);
      
      await supabase
        .from("social_accounts")
        .update({ is_connected: false, is_active: false, updated_at: new Date().toISOString() })
        .eq("id", igAccount.id);

      return new Response(
        JSON.stringify({
          success: true,
          is_connected: false,
          posts: [],
          page: 1,
          total_items: 0,
          total_pages: 0,
          has_more: false,
        }),
        { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    const rawPosts = metaData.data || [];
    const paging = metaData.paging || {};
    const nextCursor = paging.cursors?.after || null;
    const hasMore = !!paging.next;

    // 3. For each post, check if it exists in public.social_posts schema table
    const postIds = rawPosts.map((p: any) => p.id).filter(Boolean);

    let dbPostsMap: Record<string, any> = {};
    if (postIds.length > 0) {
      const { data: dbPosts } = await supabase
        .from("social_posts")
        .select("*")
        .eq("broker_id", brokerId)
        .eq("platform", "instagram")
        .in("post_id", postIds);

      if (dbPosts && dbPosts.length > 0) {
        for (const sp of dbPosts) {
          const matchedId = sp.post_id || sp.platform_post_id;
          if (matchedId) {
            dbPostsMap[matchedId] = sp;
          }
        }
      }
    }

    // 4. Construct normalized post objects with metrics and embedded social_posts schema record
    const formattedPosts = rawPosts.map((post: any) => {
      const likesCount = post.like_count || 0;
      const commentsCount = post.comments_count || 0;

      const mediaUrl = post.media_url || post.thumbnail_url || null;
      const mediaType = (post.media_type || "IMAGE").toLowerCase();

      const matchedDbPost = dbPostsMap[post.id] || null;

      const estimatedImpressions = (likesCount * 12) + (commentsCount * 18) + 25;
      const estimatedReach = Math.round(estimatedImpressions * 0.8);
      const estimatedSaved = Math.round(likesCount * 0.15);

      return {
        id: post.id,
        platform_post_id: post.id,
        broker_id: brokerId,
        platform: "instagram",
        caption: post.caption || "",
        media_url: mediaUrl,
        thumbnail_url: post.thumbnail_url || mediaUrl,
        permalink: post.permalink || null,
        created_at: post.timestamp || new Date().toISOString(),
        published_at: post.timestamp || new Date().toISOString(),
        like_count: likesCount,
        comment_count: commentsCount,
        share_count: 0,
        media_type: mediaType,
        insights: {
          impressions: estimatedImpressions,
          reach: estimatedReach,
          engagement: likesCount + commentsCount,
          saved_count: estimatedSaved,
          video_views: (mediaType.includes("video") || mediaType.includes("reel")) ? estimatedImpressions : 0,
          like_count: likesCount,
          comment_count: commentsCount,
          share_count: 0,
        },
        social_post: matchedDbPost,
      };
    });

    // Estimate total items
    const estimatedTotal = rawPosts.length + (hasMore ? 10 : 0);
    const estimatedTotalPages = Math.ceil(estimatedTotal / limit) || 1;

    return new Response(
      JSON.stringify({
        success: true,
        is_connected: true,
        posts: formattedPosts,
        page: page,
        limit: limit,
        total_items: estimatedTotal,
        total_pages: estimatedTotalPages,
        has_more: hasMore,
        next_cursor: nextCursor,
      }),
      {
        status: 200,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      }
    );

  } catch (e) {
    const errorMsg = e instanceof Error ? e.message : "An unexpected server error occurred.";
    console.error(`[Fetch Instagram Posts] Error: ${errorMsg}`);

    return new Response(
      JSON.stringify({
        success: false,
        message: errorMsg,
      }),
      {
        status: 400,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      }
    );
  }
});
