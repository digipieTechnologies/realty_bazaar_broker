import { serve } from "https://deno.land/std@0.224.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

interface MediaItem {
  media_url: string;
  thumbnail_url?: string | null;
  type: string;
}

// Meta Graph API POST helper
async function graphPost(apiBase: string, endpoint: string, payload: Record<string, any>, accessToken: string) {
  const url = `${apiBase}/${endpoint}?access_token=${accessToken}`;
  const response = await fetch(url, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
    },
    body: JSON.stringify(payload),
  });

  if (!response.ok) {
    const errorData = await response.json().catch(() => ({}));
    const err = errorData.error || {};
    const errMsg = err.message || response.statusText;
    const errUserMsg = err.error_user_msg ? ` (${err.error_user_msg})` : "";
    const subcode = err.error_subcode ? ` [subcode: ${err.error_subcode}]` : "";
    throw new Error(`Meta Graph API POST error on ${endpoint}: ${errMsg}${errUserMsg}${subcode}`);
  }
  return await response.json();
}

// Meta Graph API GET helper
async function graphGet(apiBase: string, endpoint: string, fields: string, accessToken: string) {
  const url = `${apiBase}/${endpoint}?fields=${fields}&access_token=${accessToken}`;
  const response = await fetch(url);

  if (!response.ok) {
    const errorData = await response.json().catch(() => ({}));
    const err = errorData.error || {};
    const errMsg = err.message || response.statusText;
    const errUserMsg = err.error_user_msg ? ` (${err.error_user_msg})` : "";
    const subcode = err.error_subcode ? ` [subcode: ${err.error_subcode}]` : "";
    throw new Error(`Meta Graph API GET error on ${endpoint}: ${errMsg}${errUserMsg}${subcode}`);
  }
  return await response.json();
}

// Poll status of an Instagram media container (required for both image & video processing)
async function pollContainerStatus(apiBase: string, containerId: string, accessToken: string): Promise<void> {
  const maxRetries = 30; // 30 retries * 3s = 90s max wait
  for (let i = 0; i < maxRetries; i++) {
    // Small delay before checking to allow Meta backend to process asynchronous download
    await new Promise((resolve) => setTimeout(resolve, 2500));

    const data = await graphGet(apiBase, containerId, "status_code,status", accessToken);
    const statusCode = data.status_code; // e.g. FINISHED, IN_PROGRESS, ERROR, PUBLISHED

    console.log(`Container ${containerId} status (attempt ${i + 1}): ${statusCode}`);

    if (statusCode === "FINISHED" || statusCode === "PUBLISHED") {
      return;
    } else if (statusCode === "ERROR" || statusCode === "EXPIRED") {
      throw new Error(`Container creation failed with status ${statusCode}: ${data.status || "Unknown error"}`);
    }
  }
  throw new Error(`Polling timed out for container ${containerId}`);
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

    // Parse and validate request body
    let brokerId = "";
    let propertyId: string | null = null;
    let caption = "";
    let medias: MediaItem[] = [];

    try {
      const body = await req.json();
      brokerId = body?.broker_id || "";
      propertyId = body?.property_id || body?.propertyId || null;
      caption = body?.caption || body?.Caption || "";
      medias = body?.medias || [];
    } catch (_err) {
      throw new Error("Invalid request body. Expected JSON payload.");
    }

    if (!brokerId) {
      throw new Error("Missing required parameter: broker_id");
    }

    if (!Array.isArray(medias) || medias.length === 0) {
      throw new Error("Missing required parameter: medias list containing at least 1 item");
    }

    // Initialize Supabase Client with Service Role Key
    const supabase = createClient(supabaseUrl, supabaseServiceRoleKey, {
      auth: { persistSession: false, autoRefreshToken: false },
    });

    // Retrieve active Instagram connection details for this broker
    const { data: account, error: accountError } = await supabase
      .from("social_accounts")
      .select("*")
      .eq("broker_id", brokerId)
      .eq("platform", "instagram")
      .eq("is_active", true)
      .maybeSingle();

    if (accountError) {
      throw new Error(`Failed to retrieve social account: ${accountError.message}`);
    }

    if (!account || !account.instagram_account_id) {
      throw new Error("No active Instagram Business Account connection found for this broker.");
    }

    const igAccountId = account.instagram_account_id;
    
    // Strict selection to avoid empty/null strings
    let igToken = "";
    if (account.page_access_token && account.page_access_token.trim() !== "" && account.page_access_token !== "null") {
      igToken = account.page_access_token;
    } else if (account.access_token && account.access_token.trim() !== "" && account.access_token !== "null") {
      igToken = account.access_token;
    }

    if (!igToken) {
      throw new Error("Missing or invalid access token for connected Instagram account.");
    }

    // Dynamic routing to support Direct Instagram login and Meta (Facebook Page linked) login
    const isDirectLogin = !account.page_access_token;
    const apiBase = isDirectLogin ? "https://graph.instagram.com" : "https://graph.facebook.com/v23.0";

    console.log(`Resolved token length: ${igToken.length}, starts with: ${igToken.substring(0, 8)}... (isDirectLogin: ${isDirectLogin})`);

    let publishedMediaId = "";

    // Flow for Single Media Post
    if (medias.length === 1) {
      const media = medias[0];
      const isVideo = media.type?.toLowerCase() === "video";
      console.log(`Publishing single media post (isVideo: ${isVideo}) for broker ${brokerId}`);

      const containerParams: Record<string, any> = {
        caption: caption,
      };

      if (isVideo) {
        containerParams.media_type = "REELS";
        containerParams.video_url = media.media_url;
        containerParams.share_to_feed = true;
        if (media.thumbnail_url) {
          containerParams.cover_url = media.thumbnail_url;
        }
      } else {
        containerParams.image_url = media.media_url;
      }

      // 1. Create Media Container
      const containerRes = await graphPost(apiBase, `${igAccountId}/media`, containerParams, igToken);
      const creationId = containerRes.id;

      // 2. Poll status until container is FINISHED (required by Meta Graph API to prevent subcode 2207027)
      console.log(`Media container created: ${creationId}. Polling status...`);
      await pollContainerStatus(apiBase, creationId, igToken);

      // 3. Publish the container
      console.log(`Publishing media container: ${creationId}`);
      const publishRes = await graphPost(apiBase, `${igAccountId}/media_publish`, { creation_id: creationId }, igToken);
      publishedMediaId = publishRes.id;

    } else {
      // Flow for Carousel (Multi-Media) Post
      console.log(`Publishing carousel post with ${medias.length} items for broker ${brokerId}`);
      const itemContainerIds: string[] = [];

      // 1. Create containers for all carousel items
      for (let i = 0; i < medias.length; i++) {
        const media = medias[i];
        const isVideo = media.type?.toLowerCase() === "video";

        const itemParams: Record<string, any> = {
          is_carousel_item: true,
        };

        if (isVideo) {
          itemParams.media_type = "VIDEO";
          itemParams.video_url = media.media_url;
          if (media.thumbnail_url) {
            itemParams.cover_url = media.thumbnail_url;
          }
        } else {
          itemParams.image_url = media.media_url;
        }

        console.log(`Creating carousel item container ${i + 1}/${medias.length} (isVideo: ${isVideo})`);
        const itemRes = await graphPost(apiBase, `${igAccountId}/media`, itemParams, igToken);
        itemContainerIds.push(itemRes.id);
      }

      // 2. Poll status for all carousel item containers until FINISHED
      console.log(`Polling status for ${itemContainerIds.length} carousel item containers...`);
      for (const itemContainerId of itemContainerIds) {
        await pollContainerStatus(apiBase, itemContainerId, igToken);
      }

      // 3. Create the Carousel (Album) Container
      console.log(`Creating Carousel parent container with children: ${itemContainerIds}`);
      const carouselRes = await graphPost(apiBase, `${igAccountId}/media`, {
        media_type: "CAROUSEL",
        children: itemContainerIds,
        caption: caption,
      }, igToken);
      const carouselCreationId = carouselRes.id;

      // 4. Poll status for the Carousel parent container until FINISHED
      console.log(`Polling status for Carousel parent container: ${carouselCreationId}...`);
      await pollContainerStatus(apiBase, carouselCreationId, igToken);

      // 5. Publish the Carousel container
      console.log(`Publishing Carousel container: ${carouselCreationId}`);
      const publishRes = await graphPost(apiBase, `${igAccountId}/media_publish`, { creation_id: carouselCreationId }, igToken);
      publishedMediaId = publishRes.id;
    }

    console.log(`Instagram post successfully published! Live ID: ${publishedMediaId}`);

    // --- SYNC PUBLISHED POST TO DATABASE ---
    let syncedPost = null;
    try {
      console.log(`Retrieving details of published post: ${publishedMediaId}`);
      // Fetch details of the live post from Instagram
      const postDetails = await graphGet(
        apiBase,
        publishedMediaId,
        "id,caption,media_type,media_url,thumbnail_url,permalink,timestamp,comments_count,like_count",
        igToken
      );

      const mediaUrlsList = [];
      const isCarousel = postDetails.media_type === "CAROUSEL_ALBUM";

      if (isCarousel) {
        try {
          const childrenData = await graphGet(apiBase, `${publishedMediaId}/children`, "id,media_type,media_url,thumbnail_url", igToken);
          if (childrenData.data) {
            for (const child of childrenData.data) {
              mediaUrlsList.push({
                type: child.media_type?.toLowerCase() || "image",
                url: child.media_url,
                thumbnail: child.thumbnail_url || child.media_url || null,
              });
            }
          }
        } catch (childErr) {
          console.warn(`Could not sync children for published carousel post:`, childErr);
        }
      }

      if (mediaUrlsList.length === 0) {
        mediaUrlsList.push({
          type: postDetails.media_type?.toLowerCase() === "video" ? "video" : "image",
          url: postDetails.media_url || null,
          thumbnail: postDetails.thumbnail_url || postDetails.media_url || null,
        });
      }

      const cleanPropertyId = (typeof propertyId === "string" && propertyId.trim().length > 0 && propertyId.trim() !== "null") ? propertyId.trim() : null;

      const socialPostRecord = {
        broker_id: brokerId,
        property_id: cleanPropertyId,
        platform: "instagram",
        page_id: igAccountId,
        post_id: publishedMediaId,
        caption: postDetails.caption || null,
        media_urls: mediaUrlsList,
        permalink: postDetails.permalink || null,
        views_count: 0, // initially 0
        comment_count: postDetails.comments_count || 0,
        likes_count: postDetails.like_count || 0,
        published_at: postDetails.timestamp || new Date().toISOString(),
      };

      let { data: dbData, error: dbError } = await supabase
        .from("social_posts")
        .upsert(socialPostRecord, { onConflict: "broker_id,platform,post_id" })
        .select()
        .maybeSingle();

      if (dbError) {
        console.warn(`Upsert with onConflict failed (${dbError.message}). Retrying direct insert...`);
        const insertRes = await supabase
          .from("social_posts")
          .insert(socialPostRecord)
          .select()
          .maybeSingle();
        dbData = insertRes.data;
        dbError = insertRes.error;
      }

      if (dbError) {
        console.error(`Database sync failed for IG post: ${dbError.message}`);
      } else {
        syncedPost = dbData;
        console.log(`Published IG post synced to local DB successfully! (ID: ${syncedPost?.id})`);
      }

    } catch (syncErr) {
      console.error(`Post publishing succeeded but database syncing failed:`, syncErr);
    }

    return new Response(
      JSON.stringify({
        success: true,
        message: "Post successfully published to Instagram.",
        mediaId: publishedMediaId,
        permalink: syncedPost?.permalink || `https://www.instagram.com/p/${publishedMediaId}/`,
        post: syncedPost,
      }),
      {
        headers: {
          ...corsHeaders,
          "Content-Type": "application/json",
        },
        status: 200,
      }
    );

  } catch (e) {
    const errorMsg = e instanceof Error ? e.message : "Unknown error";
    console.error(`Error publishing Instagram post: ${errorMsg}`);
    
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
