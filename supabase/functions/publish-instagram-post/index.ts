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

// Meta Graph API POST helper with dual-host retry (supports both graph.instagram.com and graph.facebook.com)
async function graphPost(apiBase: string, endpoint: string, payload: Record<string, any>, accessToken: string) {
  const cleanToken = accessToken.trim();
  
  const executePost = async (base: string) => {
    const url = `${base}/${endpoint}?access_token=${encodeURIComponent(cleanToken)}`;
    return await fetch(url, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "Authorization": `Bearer ${cleanToken}`,
      },
      body: JSON.stringify({
        ...payload,
        access_token: cleanToken,
      }),
    });
  };

  let response = await executePost(apiBase);
  if (!response.ok) {
    const errorData = await response.json().catch(() => ({}));
    const err = errorData.error || {};
    const errMsg = err.message || response.statusText;

    // If token parsing/invalid token error, try alternative host (graph.instagram.com <-> graph.facebook.com)
    if (errMsg.includes("Cannot parse access token") || errMsg.includes("Invalid OAuth access token") || errMsg.includes("OAuthException")) {
      const altBase = apiBase.includes("facebook.com")
        ? "https://graph.instagram.com/v23.0"
        : "https://graph.facebook.com/v23.0";
      
      console.log(`[publish-instagram-post] Retrying graphPost on alternate host: ${altBase}`);
      const altResponse = await executePost(altBase);
      if (altResponse.ok) {
        return await altResponse.json();
      }
    }

    const errUserMsg = err.error_user_msg ? ` (${err.error_user_msg})` : "";
    const subcode = err.error_subcode ? ` [subcode: ${err.error_subcode}]` : "";
    const code = err.code ? ` [code: ${err.code}]` : "";
    throw new Error(`Meta Graph API POST error on ${endpoint}: ${errMsg}${errUserMsg}${code}${subcode}`);
  }
  return await response.json();
}

// Meta Graph API GET helper with dual-host retry
async function graphGet(apiBase: string, endpoint: string, fields: string, accessToken: string) {
  const cleanToken = accessToken.trim();
  
  const executeGet = async (base: string) => {
    const url = `${base}/${endpoint}?fields=${encodeURIComponent(fields)}&access_token=${encodeURIComponent(cleanToken)}`;
    return await fetch(url, {
      headers: {
        "Authorization": `Bearer ${cleanToken}`,
      },
    });
  };

  let response = await executeGet(apiBase);
  if (!response.ok) {
    const errorData = await response.json().catch(() => ({}));
    const err = errorData.error || {};
    const errMsg = err.message || response.statusText;

    if (errMsg.includes("Cannot parse access token") || errMsg.includes("Invalid OAuth access token") || errMsg.includes("OAuthException")) {
      const altBase = apiBase.includes("facebook.com")
        ? "https://graph.instagram.com/v23.0"
        : "https://graph.facebook.com/v23.0";
      
      console.log(`[publish-instagram-post] Retrying graphGet on alternate host: ${altBase}`);
      const altResponse = await executeGet(altBase);
      if (altResponse.ok) {
        return await altResponse.json();
      }
    }

    const errUserMsg = err.error_user_msg ? ` (${err.error_user_msg})` : "";
    const subcode = err.error_subcode ? ` [subcode: ${err.error_subcode}]` : "";
    const code = err.code ? ` [code: ${err.code}]` : "";
    throw new Error(`Meta Graph API GET error on ${endpoint}: ${errMsg}${errUserMsg}${code}${subcode}`);
  }
  return await response.json();
}

// Poll status of an Instagram media container (required for both image & video processing)
async function pollContainerStatus(apiBase: string, containerId: string, accessToken: string): Promise<void> {
  const maxRetries = 30;
  for (let i = 0; i < maxRetries; i++) {
    await new Promise((resolve) => setTimeout(resolve, 2500));

    const data = await graphGet(apiBase, containerId, "status_code,status", accessToken);
    const statusCode = data.status_code;

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

    let brokerId = "";
    let propertyId: string | null = null;
    let caption = "";
    let medias: MediaItem[] = [];
    let userTags: Array<{ username: string; x: number; y: number }> = [];

    try {
      const body = await req.json();
      brokerId = body?.broker_id || "";
      propertyId = body?.property_id || body?.propertyId || null;
      caption = body?.caption || body?.Caption || "";
      medias = body?.medias || [];

      const rawUserTags = body?.user_tags || body?.userTags || [];
      if (Array.isArray(rawUserTags)) {
        userTags = rawUserTags
          .map((tag: any) => {
            if (typeof tag === "string") {
              const clean = tag.replace(/^@/, "").trim();
              return clean ? { username: clean, x: 0.5, y: 0.5 } : null;
            }
            if (tag && typeof tag === "object" && tag.username) {
              const clean = String(tag.username).replace(/^@/, "").trim();
              const x = typeof tag.x === "number" && !isNaN(tag.x) ? Math.max(0, Math.min(1, tag.x)) : 0.5;
              const y = typeof tag.y === "number" && !isNaN(tag.y) ? Math.max(0, Math.min(1, tag.y)) : 0.5;
              return clean ? { username: clean, x, y } : null;
            }
            return null;
          })
          .filter(Boolean) as Array<{ username: string; x: number; y: number }>;
      }
    } catch (_err) {
      throw new Error("Invalid request body. Expected JSON payload.");
    }

    if (!brokerId) {
      throw new Error("Missing required parameter: broker_id");
    }

    if (!medias || medias.length === 0) {
      throw new Error("At least one media item (image or video) is required.");
    }

    console.log(`[Publish Instagram Post] Starting for broker: ${brokerId} with ${medias.length} media item(s) and ${userTags.length} user tag(s)`);

    const supabase = createClient(supabaseUrl, supabaseServiceRoleKey);

    const { data: socialAccount, error: accountError } = await supabase
      .from("social_accounts")
      .select("*")
      .eq("broker_id", brokerId)
      .eq("platform", "instagram")
      .eq("is_active", true)
      .single();

    if (accountError || !socialAccount) {
      throw new Error(
        "No active Instagram account connected for this broker. Please connect Instagram first in Social Connections."
      );
    }

    const {
      instagram_account_id,
      page_access_token,
      access_token,
    } = socialAccount;

    const effectiveToken = page_access_token || access_token;
    if (!instagram_account_id || !effectiveToken) {
      throw new Error("Instagram account configuration is incomplete (missing Page/User access token).");
    }

    const isDirectIgToken =
      effectiveToken.startsWith("IG") ||
      effectiveToken.startsWith("IGAA") ||
      effectiveToken.startsWith("IGQ") ||
      (!page_access_token && Boolean(access_token));

    const apiBase = isDirectIgToken
      ? "https://graph.instagram.com/v23.0"
      : "https://graph.facebook.com/v23.0";
    let publishedMediaId: string = "";

    const isVideo = (item: MediaItem) => {
      const type = (item.type || "").toLowerCase();
      const url = (item.media_url || "").toLowerCase();
      return (
        type.includes("video") ||
        url.includes(".mp4") ||
        url.includes(".mov") ||
        url.includes(".m4v")
      );
    };

    if (medias.length === 1) {
      const media = medias[0];
      const isSingleVideo = isVideo(media);

      if (isSingleVideo) {
        console.log(`Creating single Instagram Reel/Video container for URL: ${media.media_url}`);
        const payload: Record<string, any> = {
          media_type: "REELS",
          video_url: media.media_url,
          caption: caption,
          share_to_feed: true,
        };
        if (media.thumbnail_url) {
          payload.cover_url = media.thumbnail_url;
        }

        const container = await graphPost(apiBase, `${instagram_account_id}/media`, payload, effectiveToken);
        await pollContainerStatus(apiBase, container.id, effectiveToken);

        const publishResult = await graphPost(
          apiBase,
          `${instagram_account_id}/media_publish`,
          { creation_id: container.id },
          effectiveToken
        );
        publishedMediaId = publishResult.id;
      } else {
        console.log(`Creating single Instagram Image container for URL: ${media.media_url}`);
        const payload: Record<string, any> = {
          image_url: media.media_url,
          caption: caption,
        };
        if (userTags.length > 0) {
          payload.user_tags = userTags;
        }

        let container;
        try {
          container = await graphPost(apiBase, `${instagram_account_id}/media`, payload, effectiveToken);
        } catch (postErr) {
          if (payload.user_tags) {
            console.warn(`[publish-instagram-post] Image container creation with user_tags failed (${postErr.message}). Retrying without user_tags...`);
            delete payload.user_tags;
            container = await graphPost(apiBase, `${instagram_account_id}/media`, payload, effectiveToken);
          } else {
            throw postErr;
          }
        }
        await pollContainerStatus(apiBase, container.id, effectiveToken);

        const publishResult = await graphPost(
          apiBase,
          `${instagram_account_id}/media_publish`,
          { creation_id: container.id },
          effectiveToken
        );
        publishedMediaId = publishResult.id;
      }
    } else {
      console.log(`Creating carousel with ${medias.length} items for Instagram...`);
      const itemContainerIds: string[] = [];

      for (let idx = 0; idx < medias.length; idx++) {
        const item = medias[idx];
        const itemIsVideo = isVideo(item);

        let itemPayload: Record<string, any> = {
          is_carousel_item: true,
        };

        if (itemIsVideo) {
          itemPayload.media_type = "VIDEO";
          itemPayload.video_url = item.media_url;
        } else {
          itemPayload.image_url = item.media_url;
          if (userTags.length > 0) {
            itemPayload.user_tags = userTags;
          }
        }

        let itemContainer;
        try {
          itemContainer = await graphPost(
            apiBase,
            `${instagram_account_id}/media`,
            itemPayload,
            effectiveToken
          );
        } catch (itemErr) {
          if (itemPayload.user_tags) {
            console.warn(`[publish-instagram-post] Carousel item creation with user_tags failed (${itemErr.message}). Retrying without user_tags...`);
            delete itemPayload.user_tags;
            itemContainer = await graphPost(
              apiBase,
              `${instagram_account_id}/media`,
              itemPayload,
              effectiveToken
            );
          } else {
            throw itemErr;
          }
        }
        itemContainerIds.push(itemContainer.id);
      }

      for (const containerId of itemContainerIds) {
        await pollContainerStatus(apiBase, containerId, effectiveToken);
      }

      const carouselPayload: Record<string, any> = {
        media_type: "CAROUSEL",
        children: itemContainerIds.join(","),
        caption: caption,
      };

      const carouselContainer = await graphPost(
        apiBase,
        `${instagram_account_id}/media`,
        carouselPayload,
        effectiveToken
      );

      await pollContainerStatus(apiBase, carouselContainer.id, effectiveToken);

      const publishResult = await graphPost(
        apiBase,
        `${instagram_account_id}/media_publish`,
        { creation_id: carouselContainer.id },
        effectiveToken
      );
      publishedMediaId = publishResult.id;
    }

    let fetchedPermalink: string | null = null;
    try {
      const postDetails = await graphGet(
        apiBase,
        publishedMediaId,
        "id,permalink,timestamp,media_type,thumbnail_url,media_url",
        effectiveToken
      );
      fetchedPermalink = postDetails?.permalink || null;
    } catch (err) {
      console.warn("Could not retrieve post permalink immediately:", err);
    }

    let syncedPost = null;
    try {
      const postRecord = {
        broker_id: brokerId,
        property_id: propertyId,
        platform: "instagram",
        page_id: instagram_account_id,
        post_id: publishedMediaId,
        caption: caption,
        media_urls: medias.map((m) => ({
          type: isVideo(m) ? "video" : "image",
          url: m.media_url,
          thumbnail: m.thumbnail_url || m.media_url,
        })),
        permalink: fetchedPermalink || `https://www.instagram.com/p/${publishedMediaId}/`,
        views_count: 0,
        comment_count: 0,
        likes_count: 0,
        published_at: new Date().toISOString(),
      };

      const { data: dbData, error: dbError } = await supabase
        .from("social_posts")
        .upsert(postRecord, {
          onConflict: "broker_id,platform,post_id",
        })
        .select("*")
        .single();

      if (dbError) {
        console.error(`Database sync failed for IG post: ${dbError.message}`);
      } else {
        syncedPost = dbData;
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
    const rawErrorMsg = e instanceof Error ? e.message : "Unknown error";
    console.error(`Error publishing Instagram post: ${rawErrorMsg}`);

    const lower = rawErrorMsg.toLowerCase();
    let userFriendlyMsg = "Unable to publish to Instagram. Please verify your connection and try again.";

    if (
      lower.includes("invalid oauth") ||
      lower.includes("cannot parse access token") ||
      lower.includes("code: 190") ||
      lower.includes("session has expired") ||
      lower.includes("error validating access token") ||
      lower.includes("token has expired")
    ) {
      userFriendlyMsg =
        "Your Instagram session has expired. Please go to Profile > Social Connections and reconnect your Instagram account.";

      // Attempt to set is_active: false on the social_account record
      try {
        const supabaseUrl = Deno.env.get("SUPABASE_URL");
        const supabaseServiceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
        if (supabaseUrl && supabaseServiceRoleKey && brokerId) {
          const supabase = createClient(supabaseUrl, supabaseServiceRoleKey);
          await supabase
            .from("social_accounts")
            .update({ is_active: false, updated_at: new Date().toISOString() })
            .eq("broker_id", brokerId)
            .eq("platform", "instagram");
        }
      } catch (deactErr) {
        console.error("Failed to deactivate expired social account:", deactErr);
      }
    } else if (lower.includes("permission") || lower.includes("not authorized") || lower.includes("missing permissions")) {
      userFriendlyMsg =
        "Publishing permission missing. Please reconnect your Instagram account and grant all publishing permissions.";
    } else if (lower.includes("aspect_ratio") || lower.includes("aspect ratio") || lower.includes("invalid aspect")) {
      userFriendlyMsg =
        "Photo or video aspect ratio is not supported by Instagram. Please select standard landscape (1.91:1), square (1:1), or vertical (4:5) media.";
    } else if (lower.includes("rate limit") || lower.includes("user request limit reached")) {
      userFriendlyMsg =
        "Instagram post limit reached. Please wait a few minutes before sharing another post.";
    } else if (lower.includes("video length") || lower.includes("video duration") || lower.includes("invalid video")) {
      userFriendlyMsg =
        "The selected video format or duration is not supported. Please ensure your video is under 15 minutes.";
    } else if (lower.includes("no active instagram account")) {
      userFriendlyMsg =
        "No active Instagram account connected. Please connect your account in Social Connections first.";
    } else if (lower.includes("at least one media item") || lower.includes("missing required parameter")) {
      userFriendlyMsg = "Please select at least one photo or video before publishing.";
    } else if (!rawErrorMsg.includes("Meta Graph API") && !rawErrorMsg.includes("Exception")) {
      userFriendlyMsg = rawErrorMsg;
    }

    return new Response(
      JSON.stringify({
        success: false,
        message: userFriendlyMsg,
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
