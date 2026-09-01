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
    let brokerId = "";
    let targetPlatform = null; // optional 'facebook' or 'instagram'

    try {
      const body = await req.json();
      brokerId = body?.broker_id || "";
      targetPlatform = body?.platform || null;
    } catch (_err) {
      throw new Error("Invalid request body. Expected JSON with broker_id.");
    }

    if (!brokerId) {
      throw new Error("Missing broker_id parameter.");
    }

    const supabaseUrl = Deno.env.get("SUPABASE_URL");
    const supabaseServiceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");

    if (!supabaseUrl || !supabaseServiceRoleKey) {
      throw new Error("Missing server configuration environment variables.");
    }

    const supabase = createClient(supabaseUrl, supabaseServiceRoleKey);

    // Retrieve active social accounts for this broker
    let query = supabase
      .from("social_accounts")
      .select("*")
      .eq("broker_id", brokerId)
      .eq("is_active", true);

    if (targetPlatform) {
      query = query.eq("platform", targetPlatform);
    }

    const { data: accounts, error: accountsError } = await query;

    if (accountsError) {
      throw new Error(`Failed to retrieve social accounts: ${accountsError.message}`);
    }

    if (!accounts || accounts.length === 0) {
      return new Response(
        JSON.stringify({
          success: true,
          message: "No active social accounts connected.",
          syncedCount: 0,
        }),
        {
          headers: { ...corsHeaders, "Content-Type": "application/json" },
          status: 200,
        }
      );
    }

    let syncedPostsCount = 0;
    const syncLogs = [];

    for (const account of accounts) {
      const { platform, page_id, page_access_token, access_token, instagram_account_id } = account;

      if (platform === "facebook") {
        console.log(`Syncing Facebook Page posts for page: ${page_id}`);
        // Fetch feed, videos, and reels (for exact reels views)
        const feedFields = "id,message,created_time,full_picture,permalink_url,attachments{media,type,subattachments},comments.summary(true),likes.summary(true)";
        const videoFields = "id,description,created_time,picture,permalink_url,comments.summary(true),likes.summary(true)";
        
        const feedUrl = `https://graph.facebook.com/v23.0/${page_id}/feed?fields=${feedFields}&limit=100&access_token=${page_access_token}`;
        const videosUrl = `https://graph.facebook.com/v23.0/${page_id}/videos?fields=${videoFields}&limit=100&access_token=${page_access_token}`;
        const videoReelsUrl = `https://graph.facebook.com/v23.0/${page_id}/video_reels?fields=${videoFields}&limit=100&access_token=${page_access_token}`;

        const [feedRes, videosRes, videoReelsRes] = await Promise.all([
          fetch(feedUrl),
          fetch(videosUrl),
          fetch(videoReelsUrl),
        ]);

        let feedData = { data: [] };
        let videosData = { data: [] };
        let videoReelsData = { data: [] };

        if (feedRes.ok) {
          feedData = await feedRes.json();
        } else {
          const err = await feedRes.json().catch(() => ({}));
          console.error(`Facebook feed fetch failed for page ${page_id}:`, err);
          syncLogs.push(`Facebook feed error: ${err.error?.message || feedRes.statusText}`);
        }

        if (videosRes.ok) {
          videosData = await videosRes.json();
        } else {
          const err = await videosRes.json().catch(() => ({}));
          console.error(`Facebook videos fetch failed for page ${page_id}:`, err);
          syncLogs.push(`Facebook videos error: ${err.error?.message || videosRes.statusText}`);
        }

        if (videoReelsRes.ok) {
          videoReelsData = await videoReelsRes.json();
        } else {
          const err = await videoReelsRes.json().catch(() => ({}));
          console.error(`Facebook reels fetch failed for page ${page_id}:`, err);
          syncLogs.push(`Facebook reels error: ${err.error?.message || videoReelsRes.statusText}`);
        }

        // Retrieve video views (total_video_views) via Graph API Batch Requests for Facebook video and reel nodes
        const allFacebookVideoIds = [
          ...(videoReelsData.data || []).map((r: any) => r.id),
          ...(videosData.data || []).map((v: any) => v.id),
        ].filter(Boolean);

        const facebookViewsMap = new Map();

        if (allFacebookVideoIds.length > 0) {
          // Meta batch request limit is 50
          const batch = allFacebookVideoIds.slice(0, 50).map((videoId: string) => ({
            method: "GET",
            relative_url: `${videoId}/video_insights?metric=total_video_views`,
          }));

          try {
            const batchRes = await fetch(`https://graph.facebook.com/v23.0/`, {
              method: "POST",
              headers: {
                "Content-Type": "application/json",
              },
              body: JSON.stringify({
                access_token: page_access_token,
                batch: JSON.stringify(batch),
              }),
            });

            if (batchRes.ok) {
              const batchResults = await batchRes.json();
              for (let i = 0; i < batchResults.length; i++) {
                const itemResult = batchResults[i];
                const videoId = allFacebookVideoIds[i];

                if (itemResult.code === 200) {
                  const insightsData = JSON.parse(itemResult.body);
                  if (insightsData.data && insightsData.data.length > 0) {
                    const viewsMetric = insightsData.data.find((m: any) => m.name === "total_video_views");
                    if (viewsMetric && viewsMetric.values && viewsMetric.values.length > 0) {
                      facebookViewsMap.set(videoId, viewsMetric.values[0].value || 0);
                    }
                  }
                } else {
                  let errMsg = `Code ${itemResult.code}`;
                  try {
                    const errBody = JSON.parse(itemResult.body);
                    if (errBody.error?.message) {
                      errMsg = errBody.error.message;
                    }
                  } catch (_e) {}
                  console.warn(`Failed to fetch insights for FB video ${videoId}: ${errMsg}`);
                  syncLogs.push(`Facebook insights error for video ${videoId}: ${errMsg}`);
                }
              }
            }
          } catch (batchErr) {
            console.error("Facebook batch insights fetch failed:", batchErr);
          }
        }

        const processedPosts = new Map();

        // 1. Process Page Reels (gives us Reels views!)
        if (videoReelsData.data) {
          for (const reel of videoReelsData.data) {
            const postId = reel.id;
            const caption = reel.description || null;
            const views = facebookViewsMap.get(postId) || 0;
            const comments = reel.comments?.summary?.total_count || 0;
            const likes = reel.likes?.summary?.total_count || 0;
            const mediaUrl = reel.picture || null;

            processedPosts.set(postId, {
              broker_id: brokerId,
              platform: "facebook",
              page_id: page_id,
              post_id: postId,
              caption: caption,
              media_urls: mediaUrl ? [{ type: "video", url: mediaUrl, thumbnail: mediaUrl }] : [],
              permalink: reel.permalink_url || null,
              views_count: views,
              comment_count: comments,
              likes_count: likes,
              published_at: reel.created_time || null,
            });
          }
        }

        // 2. Process Page Videos (gives us video views!)
        if (videosData.data) {
          for (const video of videosData.data) {
            const postId = video.id;
            const caption = video.description || null;
            const views = facebookViewsMap.get(postId) || 0;
            const comments = video.comments?.summary?.total_count || 0;
            const likes = video.likes?.summary?.total_count || 0;
            const mediaUrl = video.picture || null;

            processedPosts.set(postId, {
              broker_id: brokerId,
              platform: "facebook",
              page_id: page_id,
              post_id: postId,
              caption: caption,
              media_urls: mediaUrl ? [{ type: "video", url: mediaUrl, thumbnail: mediaUrl }] : [],
              permalink: video.permalink_url || null,
              views_count: views,
              comment_count: comments,
              likes_count: likes,
              published_at: video.created_time || null,
            });
          }
        }

        // 3. Process General Page Feed (posts, photos, status updates)
        if (feedData.data) {
          for (const post of feedData.data) {
            const postId = post.id;
            
            // If already processed as a video or reel (which has accurate views count), keep that but merge text description if missing
            if (processedPosts.has(postId)) {
              const existing = processedPosts.get(postId);
              if (!existing.caption && post.message) {
                existing.caption = post.message;
              }
              continue;
            }

            const caption = post.message || null;
            const comments = post.comments?.summary?.total_count || 0;
            const likes = post.likes?.summary?.total_count || 0;
            const permalink = post.permalink_url || null;
            const publishedAt = post.created_time || null;

            // Extract media assets
            const mediaUrls = [];
            if (post.attachments?.data) {
              for (const att of post.attachments.data) {
                if (att.media?.image?.src) {
                  mediaUrls.push({
                    type: att.type || "image",
                    url: att.media.image.src,
                  });
                }
                if (att.subattachments?.data) {
                  for (const sub of att.subattachments.data) {
                    if (sub.media?.image?.src) {
                      mediaUrls.push({
                        type: sub.type || "image",
                        url: sub.media.image.src,
                      });
                    }
                  }
                }
              }
            } else if (post.full_picture) {
              mediaUrls.push({
                type: "image",
                url: post.full_picture,
              });
            }

            processedPosts.set(postId, {
              broker_id: brokerId,
              platform: "facebook",
              page_id: page_id,
              post_id: postId,
              caption: caption,
              media_urls: mediaUrls,
              permalink: permalink,
              views_count: 0,
              comment_count: comments,
              likes_count: likes,
              published_at: publishedAt,
            });
          }
        }

        const facebookPostsArray = Array.from(processedPosts.values());
        if (facebookPostsArray.length > 0) {
          const { error: upsertError } = await supabase
            .from("social_posts")
            .upsert(facebookPostsArray, { onConflict: "broker_id,platform,post_id" });

          if (upsertError) {
            console.error(`Error upserting Facebook posts: ${upsertError.message}`);
            syncLogs.push(`Failed to upsert Facebook posts: ${upsertError.message}`);
          } else {
            syncedPostsCount += facebookPostsArray.length;
            syncLogs.push(`Synced ${facebookPostsArray.length} Facebook posts.`);
          }
        } else {
          syncLogs.push(`No new Facebook posts found.`);
        }
      }

      if (platform === "instagram" && instagram_account_id) {
        console.log(`Syncing Instagram Media for account: ${instagram_account_id}`);
        const igToken = page_access_token || access_token;

        const igMediaUrl = `https://graph.facebook.com/v23.0/${instagram_account_id}/media?fields=id,caption,media_type,media_url,thumbnail_url,permalink,timestamp,comments_count,like_count&access_token=${igToken}`;
        const igRes = await fetch(igMediaUrl);

        if (!igRes.ok) {
          const igErr = await igRes.json();
          console.error(`Failed to fetch Instagram media:`, igErr);
          syncLogs.push(`Failed to fetch Instagram media: ${igErr.error?.message || "Unknown error"}`);
          continue;
        }

        const igData = await igRes.json();
        if (!igData.data || igData.data.length === 0) {
          syncLogs.push(`No Instagram media found.`);
          continue;
        }

        const igPosts = igData.data;
        const igProcessedPosts = [];

        // Retrieve video views (plays) via Graph API Batch Requests for video nodes
        const videoPosts = igPosts.filter((p: any) => p.media_type === "VIDEO");
        const videoViewsMap = new Map();

        if (videoPosts.length > 0) {
          const batch = videoPosts.slice(0, 50).map((video: any) => ({
            method: "GET",
            relative_url: `${video.id}/insights?metric=plays`,
          }));

          try {
            const batchRes = await fetch(`https://graph.facebook.com/v23.0/`, {
              method: "POST",
              headers: {
                "Content-Type": "application/json",
              },
              body: JSON.stringify({
                access_token: igToken,
                batch: JSON.stringify(batch),
              }),
            });

            if (batchRes.ok) {
              const batchResults = await batchRes.json();
              for (let i = 0; i < batchResults.length; i++) {
                const itemResult = batchResults[i];
                const videoId = videoPosts[i].id;

                if (itemResult.code === 200) {
                  const insightsData = JSON.parse(itemResult.body);
                  if (insightsData.data && insightsData.data.length > 0) {
                    const playsMetric = insightsData.data.find((m: any) => m.name === "plays");
                    if (playsMetric && playsMetric.values && playsMetric.values.length > 0) {
                      videoViewsMap.set(videoId, playsMetric.values[0].value || 0);
                    }
                  }
                } else {
                  console.warn(`Failed to fetch insights for IG video ${videoId}: code ${itemResult.code}`);
                }
              }
            }
          } catch (batchErr) {
            console.error("Instagram batch insights fetch failed:", batchErr);
          }
        }

        // Process each media item
        for (const post of igPosts) {
          const postId = post.id;
          const caption = post.caption || null;
          const comments = post.comments_count || 0;
          const likes = post.like_count || 0;
          const permalink = post.permalink || null;
          const publishedAt = post.timestamp || null;
          const mediaType = post.media_type;

          let views = 0;
          if (mediaType === "VIDEO") {
            views = videoViewsMap.get(postId) || 0;
          }

          const mediaUrls = [];
          if (mediaType === "CAROUSEL_ALBUM") {
            // Fetch child items for carousel albums
            try {
              const childrenRes = await fetch(
                `https://graph.facebook.com/v23.0/${postId}/children?fields=id,media_type,media_url,thumbnail_url&access_token=${igToken}`
              );
              if (childrenRes.ok) {
                const childrenData = await childrenRes.json();
                if (childrenData.data) {
                  for (const child of childrenData.data) {
                    mediaUrls.push({
                      type: child.media_type?.toLowerCase() || "image",
                      url: child.media_url,
                      thumbnail: child.thumbnail_url || child.media_url,
                    });
                  }
                }
              }
            } catch (childErr) {
              console.warn(`Failed to fetch carousel children for IG post ${postId}:`, childErr);
            }
          }

          if (mediaUrls.length === 0) {
            mediaUrls.push({
              type: mediaType?.toLowerCase() || "image",
              url: post.media_url || null,
              thumbnail: post.thumbnail_url || post.media_url || null,
            });
          }

          igProcessedPosts.push({
            broker_id: brokerId,
            platform: "instagram",
            page_id: instagram_account_id,
            post_id: postId,
            caption: caption,
            media_urls: mediaUrls,
            permalink: permalink,
            views_count: views,
            comment_count: comments,
            likes_count: likes,
            published_at: publishedAt,
          });
        }

        if (igProcessedPosts.length > 0) {
          const { error: upsertError } = await supabase
            .from("social_posts")
            .upsert(igProcessedPosts, { onConflict: "broker_id,platform,post_id" });

          if (upsertError) {
            console.error(`Error upserting Instagram posts: ${upsertError.message}`);
            syncLogs.push(`Failed to upsert Instagram posts: ${upsertError.message}`);
          } else {
            syncedPostsCount += igProcessedPosts.length;
            syncLogs.push(`Synced ${igProcessedPosts.length} Instagram posts.`);
          }
        }
      }
    }

    return new Response(
      JSON.stringify({
        success: true,
        message: "Sync completed successfully.",
        syncedCount: syncedPostsCount,
        logs: syncLogs,
      }),
      {
        headers: { ...corsHeaders, "Content-Type": "application/json" },
        status: 200,
      }
    );
  } catch (e) {
    const errorMsg = e instanceof Error ? e.message : "Unknown error";
    console.error(`Error in sync-social-posts edge function: ${errorMsg}`);
    return new Response(
      JSON.stringify({
        success: false,
        message: errorMsg,
      }),
      {
        headers: { ...corsHeaders, "Content-Type": "application/json" },
        status: 400,
      }
    );
  }
});
