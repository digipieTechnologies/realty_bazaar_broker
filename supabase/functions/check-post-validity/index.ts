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
    const { platform, post_id } = await req.json();

    if (!platform || !post_id) {
      return new Response(JSON.stringify({ error: "Missing platform or post_id" }), {
        headers: { "Content-Type": "application/json", ...corsHeaders },
        status: 400,
      });
    }

    const supabase = createClient(
      Deno.env.get("SUPABASE_URL") ?? "",
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? ""
    );

    // 1. Check if post already exists in the database
    const { data: existingPost } = await supabase
      .from("social_posts")
      .select("*")
      .eq("post_id", post_id)
      .eq("platform", platform)
      .maybeSingle();

    if (existingPost) {
      return new Response(
        JSON.stringify({
          is_valid: true,
          post: existingPost,
        }),
        {
          headers: { "Content-Type": "application/json", ...corsHeaders },
          status: 200,
        }
      );
    }

    // 2. Fetch all social accounts matching this platform to get an access token
    const { data: accounts, error: accountsErr } = await supabase
      .from("social_accounts")
      .select("*")
      .eq("platform", platform);

    if (accountsErr || !accounts || accounts.length === 0) {
      return new Response(
        JSON.stringify({
          is_valid: false,
          error: `No social accounts found linked for platform ${platform}`,
        }),
        {
          headers: { "Content-Type": "application/json", ...corsHeaders },
          status: 200, // Return 200 with is_valid: false
        }
      );
    }

    // 3. Attempt to fetch post details using the access tokens
    let fetchedPostData = null;
    let pageId = "";
    let brokerId = "";

    for (const account of accounts) {
      const token = account.access_token;
      
      try {
        if (platform === "facebook") {
          // Fetch Facebook post
          const res = await fetch(
            `https://graph.facebook.com/v23.0/${post_id}?fields=id,message,permalink_url,attachments{media,target,type,url,subattachments{data{media,type,url}}},comments.summary(true),likes.summary(true),created_time&access_token=${token}`
          );
          
          if (res.ok) {
            const data = await res.json();
            
            // Extract media URLs
            const mediaUrls = [];
            if (data.attachments?.data) {
              for (const att of data.attachments.data) {
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
            }
            
            // Fetch video insights if video type
            let viewsCount = 0;
            const hasVideo = data.attachments?.data?.some((a: any) => a.type?.includes("video") || a.type?.includes("reel")) || false;
            
            if (hasVideo) {
              const insightsRes = await fetch(
                `https://graph.facebook.com/v23.0/${post_id}/video_insights?metric=total_video_views&access_token=${token}`
              );
              if (insightsRes.ok) {
                const insights = await insightsRes.json();
                const viewsMetric = insights.data?.find((m: any) => m.name === "total_video_views");
                if (viewsMetric?.values?.length > 0) {
                  viewsCount = viewsMetric.values[0].value || 0;
                }
              }
            }

            pageId = account.page_id || "";
            brokerId = account.broker_id || "";
            fetchedPostData = {
              broker_id: brokerId,
              platform: "facebook",
              page_id: pageId,
              post_id: post_id,
              caption: data.message || null,
              media_urls: mediaUrls,
              permalink: data.permalink_url || null,
              views_count: viewsCount,
              comment_count: data.comments?.summary?.total_count || 0,
              likes_count: data.likes?.summary?.total_count || 0,
              published_at: data.created_time || null,
            };
            break; // Succeeded! Stop iterating tokens.
          }
        } else if (platform === "instagram") {
          // Fetch Instagram post
          const res = await fetch(
            `https://graph.facebook.com/v23.0/${post_id}?fields=id,caption,media_type,media_url,thumbnail_url,permalink,comments_count,like_count,timestamp&access_token=${token}`
          );

          if (res.ok) {
            const data = await res.json();
            const mediaType = data.media_type;
            const mediaUrls = [];

            if (mediaType === "CAROUSEL_ALBUM") {
              // Fetch carousel slides
              const childrenRes = await fetch(
                `https://graph.facebook.com/v23.0/${post_id}/children?fields=id,media_type,media_url,thumbnail_url&access_token=${token}`
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
            }

            if (mediaUrls.length === 0) {
              mediaUrls.push({
                type: mediaType?.toLowerCase() || "image",
                url: data.media_url || null,
                thumbnail: data.thumbnail_url || data.media_url || null,
              });
            }

            // Fetch video views (plays) if video type
            let viewsCount = 0;
            if (mediaType === "VIDEO") {
              const insightsRes = await fetch(
                `https://graph.facebook.com/v23.0/${post_id}/insights?metric=plays&access_token=${token}`
              );
              if (insightsRes.ok) {
                const insights = await insightsRes.json();
                const playsMetric = insights.data?.find((m: any) => m.name === "plays");
                if (playsMetric?.values?.length > 0) {
                  viewsCount = playsMetric.values[0].value || 0;
                }
              }
            }

            pageId = account.page_id || "";
            brokerId = account.broker_id || "";
            fetchedPostData = {
              broker_id: brokerId,
              platform: "instagram",
              page_id: pageId,
              post_id: post_id,
              caption: data.caption || null,
              media_urls: mediaUrls,
              permalink: data.permalink || null,
              views_count: viewsCount,
              comment_count: data.comments_count || 0,
              likes_count: data.like_count || 0,
              published_at: data.timestamp || null,
            };
            break; // Succeeded! Stop iterating tokens.
          }
        }
      } catch (err) {
        console.warn(`Failed token query for account ${account.id}:`, err);
      }
    }

    if (!fetchedPostData) {
      return new Response(
        JSON.stringify({
          is_valid: false,
          error: `Could not retrieve post ${post_id} from Meta Graph API using any of the available tokens.`,
        }),
        {
          headers: { "Content-Type": "application/json", ...corsHeaders },
          status: 200,
        }
      );
    }

    // 4. Save the fetched post details to local social_posts table
    const { data: savedPost, error: saveErr } = await supabase
      .from("social_posts")
      .insert(fetchedPostData)
      .select()
      .single();

    if (saveErr) {
      console.error("Failed to save fetched post:", saveErr);
      // Fallback: return it directly anyway even if saving failed
      return new Response(
        JSON.stringify({
          is_valid: true,
          post: fetchedPostData,
        }),
        {
          headers: { "Content-Type": "application/json", ...corsHeaders },
          status: 200,
        }
      );
    }

    return new Response(
      JSON.stringify({
        is_valid: true,
        post: savedPost,
      }),
      {
        headers: { "Content-Type": "application/json", ...corsHeaders },
        status: 200,
      }
    );

  } catch (err) {
    return new Response(JSON.stringify({ error: err.message }), {
      headers: { "Content-Type": "application/json", ...corsHeaders },
      status: 500,
    });
  }
});
