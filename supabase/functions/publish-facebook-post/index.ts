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
async function graphPost(
  apiBase: string,
  endpoint: string,
  payload: Record<string, any>,
  accessToken: string
) {
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
      throw new Error(
        "Missing required parameter: medias list containing at least 1 item"
      );
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
      throw new Error(
        `Failed to retrieve social account: ${accountError.message}`
      );
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
    // Separate media into photos and videos
    // Meta Graph API attached_media ONLY accepts Photo IDs. Video IDs cannot be passed to attached_media on /feed.
    const photos = medias.filter(
      (m) =>
        m.type?.toLowerCase() === "image" ||
        m.type?.toLowerCase() === "photo" ||
        m.type?.toLowerCase() !== "video"
    );
    const videos = medias.filter((m) => m.type?.toLowerCase() === "video");
    console.log(
      `Processing Facebook post for Page ${pageId}: ${photos.length} photo(s), ${videos.length} video(s)`
    );
    // --- CASE 1: SINGLE MEDIA ITEM ---
    if (medias.length === 1) {
      const media = medias[0];
      const isVideo = media.type?.toLowerCase() === "video";
      if (isVideo) {
        // Upload single video to Facebook Page
        console.log(`Publishing single video to FB Page ${pageId}`);
        const videoRes = await graphPost(
          apiBase,
          `${pageId}/videos`,
          {
            file_url: media.media_url,
            description: caption,
            published: true,
          },
          pageToken
        );
        publishedPostId = videoRes.id;
      } else {
        // Upload single photo to Facebook Page
        console.log(`Publishing single photo to FB Page ${pageId}`);
        const photoRes = await graphPost(
          apiBase,
          `${pageId}/photos`,
          {
            url: media.media_url,
            message: caption,
            published: true,
          },
          pageToken
        );
        publishedPostId = photoRes.post_id || photoRes.id;
      }
    }
    // --- CASE 2: MULTIPLE PHOTOS ONLY (ALBUM POST) ---
    else if (videos.length === 0 && photos.length > 1) {
      console.log(`Publishing multi-photo album with ${photos.length} photos to FB Page ${pageId}`);
      const attachedMedia: Record<string, any>[] = [];
      for (let i = 0; i < photos.length; i++) {
        const photoRes = await graphPost(
          apiBase,
          `${pageId}/photos`,
          {
            url: photos[i].media_url,
            published: false,
          },
          pageToken
        );
        attachedMedia.push({ media_fbid: photoRes.id });
      }
      // Publish feed post attaching all uploaded photo IDs
      const feedRes = await graphPost(
        apiBase,
        `${pageId}/feed`,
        {
          message: caption,
          attached_media: attachedMedia,
        },
        pageToken
      );
      publishedPostId = feedRes.id;
    }
    // --- CASE 3: MULTIPLE VIDEOS ONLY ---
    else if (photos.length === 0 && videos.length > 1) {
      console.log(`Publishing ${videos.length} videos to FB Page ${pageId}`);
      for (let i = 0; i < videos.length; i++) {
        const videoRes = await graphPost(
          apiBase,
          `${pageId}/videos`,
          {
            file_url: videos[i].media_url,
            description: caption,
            published: true,
          },
          pageToken
        );
        if (i === 0) {
          publishedPostId = videoRes.id; // Primary post reference
        }
      }
    }
    // --- CASE 4: DYNAMIC MIXED MEDIA (PHOTOS + VIDEOS TOGETHER) ---
    else {
      console.log(
        `Publishing mixed media post (${photos.length} photos + ${videos.length} videos) to FB Page ${pageId}`
      );
      // Step A: Handle photos first
      if (photos.length === 1) {
        // Publish single photo with main caption
        const photoRes = await graphPost(
          apiBase,
          `${pageId}/photos`,
          {
            url: photos[0].media_url,
            message: caption,
            published: true,
          },
          pageToken
        );
        publishedPostId = photoRes.post_id || photoRes.id;
      } else if (photos.length > 1) {
        // Upload photos unpublished first, then post feed album
        const attachedMedia: Record<string, any>[] = [];
        for (let i = 0; i < photos.length; i++) {
          const photoRes = await graphPost(
            apiBase,
            `${pageId}/photos`,
            {
              url: photos[i].media_url,
              published: false,
            },
            pageToken
          );
          attachedMedia.push({ media_fbid: photoRes.id });
        }
        const feedRes = await graphPost(
          apiBase,
          `${pageId}/feed`,
          {
            message: caption,
            attached_media: attachedMedia,
          },
          pageToken
        );
        publishedPostId = feedRes.id;
      }
      // Step B: Handle videos separately to avoid Meta API attached_media error
      for (let i = 0; i < videos.length; i++) {
        const videoRes = await graphPost(
          apiBase,
          `${pageId}/videos`,
          {
            file_url: videos[i].media_url,
            description: caption,
            published: true,
          },
          pageToken
        );
        // If there were no photos, set publishedPostId to the first video ID
        if (!publishedPostId && i === 0) {
          publishedPostId = videoRes.id;
        }
      }
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
      const isVideoOnly = photos.length === 0 && videos.length > 0;
      const permalinkUrl = isVideoOnly
        ? `https://www.facebook.com/${pageId}/videos/${publishedPostId}/`
        : `https://www.facebook.com/${publishedPostId}/`;
      const cleanPropertyId =
        typeof propertyId === "string" &&
        propertyId.trim().length > 0 &&
        propertyId.trim() !== "null"
          ? propertyId.trim()
          : null;
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
        console.warn(
          `Upsert with onConflict failed (${dbError.message}). Retrying direct insert...`
        );
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
        console.log(
          `Published FB post synced to local DB successfully! (ID: ${syncedPost?.id})`
        );
      }
    } catch (syncErr) {
      console.error(`FB Post publishing succeeded but database syncing failed:`, syncErr);
    }
    return new Response(
      JSON.stringify({
        success: true,
        message: "Post successfully published to Facebook Page.",
        mediaId: publishedPostId,
        permalink:
          syncedPost?.permalink || `https://www.facebook.com/${publishedPostId}/`,
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