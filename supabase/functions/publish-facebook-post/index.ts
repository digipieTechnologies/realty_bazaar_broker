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
  thumbnail_url?: string;
}

// Meta Graph API POST helper
async function graphPost(apiBase: string, endpoint: string, payload: Record<string, any>, accessToken: string) {
  const params = new URLSearchParams();
  for (const [key, value] of Object.entries(payload)) {
    if (key === "attached_media" && Array.isArray(value)) {
      // Meta Graph API requires attached_media[0]={"media_fbid":"..."}, attached_media[1]=...
      value.forEach((item, index) => {
        params.append(`attached_media[${index}]`, JSON.stringify(item));
      });
    } else if (typeof value === "object" && value !== null) {
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

    const videos = medias.filter((m) => m.type?.toLowerCase() === "video");
    const photos = medias.filter((m) => m.type?.toLowerCase() !== "video");

    console.log(`Publishing to FB Page ${pageId}: ${photos.length} photos, ${videos.length} videos`);

    let primaryPostId = "";
    let primaryPermalink = "";
    const createdPosts: { postId: string; isVideo: boolean; medias: MediaItem[] }[] = [];

    // 1. Publish Video if present (Facebook requires standalone video posts)
    if (videos.length > 0) {
      const video = videos[0];
      console.log(`Publishing video post to FB Page ${pageId}...`);
      const videoRes = await graphPost(apiBase, `${pageId}/videos`, {
        file_url: video.media_url,
        description: caption,
        published: true,
      }, pageToken);

      const videoPostId = videoRes.id;
      createdPosts.push({
        postId: videoPostId,
        isVideo: true,
        medias: [video],
      });
      primaryPostId = videoPostId;
      primaryPermalink = `https://www.facebook.com/${pageId}/videos/${videoPostId}/`;
    }

    // 2. Publish Photo(s) if present
    if (photos.length === 1) {
      console.log(`Publishing single photo post to FB Page ${pageId}...`);
      const photoRes = await graphPost(apiBase, `${pageId}/photos`, {
        url: photos[0].media_url,
        message: caption,
        published: true,
      }, pageToken);

      const photoPostId = photoRes.post_id || photoRes.id;
      createdPosts.push({
        postId: photoPostId,
        isVideo: false,
        medias: [photos[0]],
      });
      if (!primaryPostId) {
        primaryPostId = photoPostId;
        primaryPermalink = `https://www.facebook.com/${photoPostId}/`;
      }
    } else if (photos.length > 1) {
      console.log(`Publishing multi-photo album post (${photos.length} photos) to FB Page ${pageId}...`);
      const attachedMedia: Record<string, any>[] = [];

      for (let i = 0; i < photos.length; i++) {
        const photo = photos[i];
        const photoRes = await graphPost(apiBase, `${pageId}/photos`, {
          url: photo.media_url,
          published: false,
          temporary: true,
        }, pageToken);
        attachedMedia.push({ media_fbid: photoRes.id });
      }

      // Publish feed post attaching all uploaded photos into 1 single post
      const feedRes = await graphPost(apiBase, `${pageId}/feed`, {
        message: caption,
        attached_media: attachedMedia,
      }, pageToken);

      const albumPostId = feedRes.id;
      createdPosts.push({
        postId: albumPostId,
        isVideo: false,
        medias: photos,
      });
      if (!primaryPostId) {
        primaryPostId = albumPostId;
        primaryPermalink = `https://www.facebook.com/${albumPostId}/`;
      }
    }

    console.log(`Facebook post(s) created successfully! Primary ID: ${primaryPostId}`);

    // --- SYNC PUBLISHED POSTS TO DATABASE ---
    let syncedPost = null;
    const cleanPropertyId = (typeof propertyId === "string" && propertyId.trim().length > 0 && propertyId.trim() !== "null") ? propertyId.trim() : null;

    for (const postInfo of createdPosts) {
      try {
        console.log(`Syncing published FB post to database: ${postInfo.postId}`);
        
        const mediaUrlsList = postInfo.medias.map((media) => ({
          type: media.type?.toLowerCase() === "video" ? "video" : "image",
          url: media.media_url,
          thumbnail: media.thumbnail_url || media.media_url,
        }));

        const permalinkUrl = postInfo.isVideo 
          ? `https://www.facebook.com/${pageId}/videos/${postInfo.postId}/` 
          : `https://www.facebook.com/${postInfo.postId}/`;

        const socialPostRecord = {
          broker_id: brokerId,
          property_id: cleanPropertyId,
          platform: "facebook",
          page_id: pageId,
          post_id: postInfo.postId,
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
          console.error(`Database sync failed for FB post ${postInfo.postId}: ${dbError.message}`);
        } else {
          syncedPost = dbData;
          console.log(`Published FB post synced to local DB successfully! (ID: ${syncedPost?.id})`);
        }
      } catch (syncErr) {
        console.error(`FB Post database syncing failed for ${postInfo.postId}:`, syncErr);
      }
    }

    return new Response(
      JSON.stringify({
        success: true,
        message: "Post successfully published to Facebook Page.",
        mediaId: primaryPostId,
        permalink: primaryPermalink || `https://www.facebook.com/${primaryPostId}/`,
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
