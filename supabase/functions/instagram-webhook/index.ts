import { serve } from "https://deno.land/std@0.224.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

serve(async (req) => {
  const url = new URL(req.url);

  // 1. Meta Webhook Verification (GET Request)
  if (req.method === "GET") {
    const mode = url.searchParams.get("hub.mode");
    const token = url.searchParams.get("hub.verify_token");
    const challenge = url.searchParams.get("hub.challenge");

    // Read the secret verification token dynamically from environment variables
    const verifyToken = Deno.env.get("META_VERIFY_TOKEN");

    if (!verifyToken) {
      console.error("META_VERIFY_TOKEN environment variable is not set on Supabase secrets.");
      return new Response("Server configuration error", { status: 500 });
    }

    if (mode === "subscribe" && token === verifyToken) {
      console.log("Instagram Webhook verified successfully!");
      return new Response(challenge, { status: 200 });
    }

    console.warn("Webhook verification failed: Token mismatch.");
    return new Response("Verification failed", { status: 403 });
  }

  // 2. Incoming Event Handler (POST Request)
  if (req.method === "POST") {
    try {
      const payload = await req.json();
      console.log("Received Webhook Payload:", JSON.stringify(payload));

      const supabase = createClient(
        Deno.env.get("SUPABASE_URL") ?? "",
        Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? ""
      );

      const entry = payload.entry?.[0];
      if (!entry) {
        return new Response("NO_ENTRY", { status: 200 });
      }

      const instagramAccountId = entry.id; // Instagram Business Account ID or Facebook Page ID

      // Fetch the access token for this Instagram account from social_accounts table.
      const { data: accounts, error: accErr } = await supabase
        .from("social_accounts")
        .select("id, broker_id, access_token, page_access_token, instagram_username, is_connected")
        .eq("platform", "instagram")
        .eq("is_connected", true)
        .or(`page_id.eq.${instagramAccountId},instagram_account_id.eq.${instagramAccountId}`)
        .order("updated_at", { ascending: false })
        .limit(1);

      if (accErr || !accounts || accounts.length === 0) {
        console.error(`No connected token found for Instagram account identifier: ${instagramAccountId}`, accErr);
        return new Response("TOKEN_NOT_FOUND", { status: 200 });
      }

      const account = accounts[0];

      const isDirectLogin = !account.page_access_token;
      const token = account.page_access_token || account.access_token;

      // Handle incoming comments on posts (Comment Webhook)
      if (entry.changes?.[0]?.value) {
        const change = entry.changes[0].value;
        const commentId = change.id || change.comment_id;
        
        // Prevent responding to self-comments
        if (
          change.from?.id === instagramAccountId || 
          change.from?.username === account.instagram_username
        ) {
          console.log(`Ignored self-comment from username: ${change.from?.username}`);
        } else if (commentId) {
          const commentText = change.text;
          const mediaId = change.media?.id; // Meta Post ID

          if (!mediaId) {
            console.warn("Ignored comment: missing media/post ID.");
          } else {
            // Check if this post is present in our social_posts table.
            // Note: Meta mediaId may be formatted as "PAGEID_POSTID" or pure post ID.
            const pureMediaId = mediaId.includes("_") ? mediaId.split("_").pop()! : mediaId;

            const { data: posts, error: postErr } = await supabase
              .from("social_posts")
              .select("id, post_id")
              .or(`post_id.eq.${mediaId},post_id.eq.${pureMediaId},post_id.ilike.%${pureMediaId}`)
              .limit(1);

            if (postErr) {
              console.error(`Error querying social_posts for mediaId ${mediaId}:`, postErr);
            }

            const postExists = posts && posts.length > 0 ? posts[0] : null;

            if (postExists) {
              const targetMediaId = postExists.post_id || pureMediaId;
              const portalUrl = (Deno.env.get("WEB_PORTAL_APP_URL") || "").replace(/\/$/, "");

              console.log(`User commenting "${commentText}" on post ${mediaId} (matched ${targetMediaId} in social_posts). Triggering auto-DM.`);
              // Send auto-DM with specific listing form link matching the post ID using the comment_id
              await sendInstagramDM(
                supabase,
                account.id,
                token,
                { comment_id: commentId },
                `Hi! Thank you for commenting on our post. Here is the link to view the property details and connect directly with a broker: ${portalUrl}/form/${targetMediaId}`,
                isDirectLogin
              );
            } else {
              console.log(`Ignored comment: post ${mediaId} (pure: ${pureMediaId}) was not uploaded via our platform (not found in social_posts).`);
            }
          }
        }
      }

      return new Response("EVENT_RECEIVED", { status: 200 });
    } catch (err) {
      console.error("Failed processing incoming webhook event:", err);
      return new Response(JSON.stringify({ error: err.message }), { status: 500 });
    }
  }

  return new Response("Method not allowed", { status: 405 });
});

// Helper function to send DMs via Meta Send API
async function sendInstagramDM(
  supabase: any,
  accountId: string,
  accessToken: string,
  recipient: { id?: string; comment_id?: string },
  messageText: string,
  isDirectLogin: boolean
) {
  const recipientId = recipient.id || recipient.comment_id || "unknown";
  const apiDomain = isDirectLogin ? "https://graph.instagram.com" : "https://graph.facebook.com";
  try {
    const res = await fetch(`${apiDomain}/v23.0/me/messages?access_token=${accessToken}`, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        recipient,
        message: { text: messageText },
      }),
    });

    if (!res.ok) {
      const errBody = await res.text();
      console.error(`Failed to send Instagram DM to user ${recipientId}. Meta API response:`, errBody);

      try {
        const parsed = JSON.parse(errBody);
        if (parsed?.error?.code === 190 || parsed?.error?.error_subcode === 460) {
          console.warn(`[OAuthException 190/460] Instagram access token has been invalidated by Meta for account ID ${accountId}. Updating social_accounts table to is_connected = false...`);
          await supabase
            .from("social_accounts")
            .update({ is_connected: false, is_active: false })
            .eq("id", accountId);
        }
      } catch (_) {
        // Ignore JSON parse error
      }
    } else {
      console.log(`Instagram DM successfully sent to user ${recipientId}`);
    }
  } catch (err) {
    console.error("Network error sending Instagram DM:", err);
  }
}
