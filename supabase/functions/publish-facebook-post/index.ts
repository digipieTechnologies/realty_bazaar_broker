import { serve } from "https://deno.land/std@0.224.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

interface MediaItem {
  media_url: string;
  type: string;
}

// Meta Graph API POST helper
async function graphPost(apiBase: string, endpoint: string, payload: Record<string, any>, accessToken: string) {
  const params = new URLSearchParams();
  for (const [key, value] of Object.entries(payload)) {
    if (typeof value === "object") {
      params.append(key, JSON.stringify(value));
    } else {
      params.append(key, String(value));
    }
  }

  const url = `${apiBase}/${endpoint}?access_token=${accessToken}`;
  const response = await fetch(url, {
    method: "POST",
    headers: {
      "Content-Type": "application/x-www-form-urlencoded",
    },
    body: params.toString(),
  });

  if (!response.ok) {
    const errorData = await response.json().catch(() => ({}));
    const err = errorData.error || {};
    const errMsg = err.message || response.statusText;
    throw new Error(`Meta Graph API POST error on ${endpoint}: ${errMsg}`);
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
    throw new Error(`Meta Graph API GET error on ${endpoint}: ${errMsg}`);
  }
  return await response.json();
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
      caption = body?.caption || "";
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

    // Retrieve active Facebook connection details for this broker
    const { data: account, error: accountError } = await supabase
      .from("social_accounts")
      .select("*")
      .eq("broker_id", brokerId)
      .eq("platform", "facebook")
      .eq("is_active", true)
      .maybeSingle();

    if (accountError) {
      throw new Error(`Failed to retrieve social account: ${accountError.message}`);
    }

    if (!account || !account.page_id) {
      throw new Error("No active Facebook Page connection found for this broker.");
    }

    const pageId = account.page_id;
    const pageToken = account.page_access_token || account.access_token;

    if (!pageToken) {
      throw new Error("Missing page access token for connected Facebook Page.");
    }

    const apiBase = "https://graph.facebook.com/v23.0";
    let publishedPostId = "";

    // Flow for Single Media Post
    if (medias.length === 1) {
      const media = medias[0];
      const isVideo = media.type?.toLowerCase() === "video";
      console.log(`Publishing single media post to FB Page ${pageId} (isVideo: ${isVideo})`);

      if (isVideo) {
        // Upload video to Facebook page
        const videoRes = await graphPost(apiBase, `${pageId}/videos`, {
          file_url: media.media_url,
          description: caption,
          published: true,
        }, pageToken);
        publishedPostId = videoRes.id;
      } else {
        // Upload photo to Facebook page
        const photoRes = await graphPost(apiBase, `${pageId}/photos`, {
          url: media.media_url,
          message: caption,
          published: true,
        }, pageToken);
        // Photos endpoint returns id and post_id. Use post_id as the main reference for comments
        publishedPostId = photoRes.post_id || photoRes.id;
      }

    } else {
      // Flow for Multi-Photo Post (Album)
      console.log(`Publishing multi-photo post with ${medias.length} items to FB Page ${pageId}`);
      const attachedMedia: Record<string, any>[] = [];

      for (let i = 0; i < medias.length; i++) {
        const media = medias[i];
        const isVideo = media.type?.toLowerCase() === "video";

        if (isVideo) {
          // Upload video unpublished first
          const videoRes = await graphPost(apiBase, `${pageId}/videos`, {
            file_url: media.media_url,
            published: false,
          }, pageToken);
          attachedMedia.push({ media_fbid: videoRes.id });
        } else {
          // Upload photo unpublished first
          const photoRes = await graphPost(apiBase, `${pageId}/photos`, {
            url: media.media_url,
            published: false,
          }, pageToken);
          attachedMedia.push({ media_fbid: photoRes.id });
        }
      }

      // Publish feed post attaching all uploaded media items
      const feedRes = await graphPost(apiBase, `${pageId}/feed`, {
        message: caption,
        attached_media: attachedMedia,
      }, pageToken);
      publishedPostId = feedRes.id;
    }

    console.log(`Facebook post successfully published! Live ID: ${publishedPostId}`);

    // --- SYNC PUBLISHED POST TO DATABASE ---
    let syncedPost = null;
    try {
      console.log(`Syncing published FB post to database: ${publishedPostId}`);
      
      const mediaUrlsList = medias.map((media) => ({
        type: media.type?.toLowerCase() === "video" ? "video" : "image",
        url: media.media_url,
        thumbnail: media.media_url,
      }));

      const isVideo = medias.length === 1 && medias[0].type?.toLowerCase() === "video";
      const permalinkUrl = isVideo 
        ? `https://www.facebook.com/${pageId}/videos/${publishedPostId}/` 
        : `https://www.facebook.com/${publishedPostId}/`;

      const cleanPropertyId = (typeof propertyId === "string" && propertyId.trim().length > 0 && propertyId.trim() !== "null") ? propertyId.trim() : null;

      const socialPostRecord = {
        broker_id: brokerId,
        property_id: cleanPropertyId,
        platform: "facebook",
        page_id: pageId,
        post_id: publishedPostId,
        caption: caption || null,
        media_urls: mediaUrlsList,
        permalink: permalinkUrl,
        views_count: 0,
        comment_count: 0,
        likes_count: 0,
        published_at: new Date().toISOString(),
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
        console.error(`Database sync failed for FB post: ${dbError.message}`);
      } else {
        syncedPost = dbData;
        console.log(`Published FB post synced to local DB successfully! (ID: ${syncedPost?.id})`);
      }

    } catch (syncErr) {
      console.error(`FB Post publishing succeeded but database syncing failed:`, syncErr);
    }

    return new Response(
      JSON.stringify({
        success: true,
        message: "Post successfully published to Facebook Page.",
        mediaId: publishedPostId,
        permalink: syncedPost?.permalink || `https://www.facebook.com/${publishedPostId}/`,
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
    console.error(`Error publishing Facebook post: ${errorMsg}`);
    
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
