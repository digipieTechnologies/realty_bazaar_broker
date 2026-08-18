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
      console.log("Facebook Webhook verified successfully!");
      return new Response(challenge, { status: 200 });
    }

    console.warn("Webhook verification failed: Token mismatch.");
    return new Response("Verification failed", { status: 403 });
  }

  // 2. Incoming Event Handler (POST Request)
  if (req.method === "POST") {
    try {
      const payload = await req.json();
      console.log("Received Facebook Webhook Payload:", JSON.stringify(payload));

      const supabase = createClient(
        Deno.env.get("SUPABASE_URL") ?? "",
        Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? ""
      );

      const entry = payload.entry?.[0];
      if (!entry) {
        return new Response("NO_ENTRY", { status: 200 });
      }

      const pageId = entry.id; // Facebook Page ID

      // Fetch the page access token for this Facebook Page from social_accounts table.
      const { data: accounts, error: accErr } = await supabase
        .from("social_accounts")
        .select("id, broker_id, page_access_token, page_name, is_connected")
        .eq("platform", "facebook")
        .eq("page_id", pageId)
        .eq("is_connected", true)
        .order("updated_at", { ascending: false })
        .limit(1);

      if (accErr || !accounts || accounts.length === 0) {
        console.error(`No connected token found for Facebook Page identifier: ${pageId}`, accErr);
        return new Response("TOKEN_NOT_FOUND", { status: 200 });
      }

      const account = accounts[0];

      const token = account.page_access_token;
      if (!token) {
        console.error(`Page access token is null for Page: ${pageId}`);
        return new Response("TOKEN_IS_NULL", { status: 200 });
      }

      // Handle feed changes (Comments on Posts)
      const change = entry.changes?.[0]?.value;
      if (change && change.item === "comment" && change.verb === "add") {
        const commentId = change.comment_id || change.id;
        const postId = change.post_id;
        const commentText = change.message;
        const senderId = change.from?.id;

        // Prevent self-responding
        if (senderId === pageId) {
          console.log(`Ignored self-comment from Page: ${account.page_name}`);
        } else if (commentId && postId) {
          // Check if this post exists in our social_posts table.
          // Note: Meta sends postId formatted as "PAGEID_POSTID" (e.g. 1204957666034331_122114087607381597)
          // or as pure post ID (122114087607381597). We check both variations in social_posts.
          const purePostId = postId.includes("_") ? postId.split("_").pop()! : postId;

          const { data: posts, error: postErr } = await supabase
            .from("social_posts")
            .select("id, post_id")
            .or(`post_id.eq.${postId},post_id.eq.${purePostId},post_id.ilike.%${purePostId}`)
            .limit(1);

          if (postErr) {
            console.error(`Error querying social_posts for postId ${postId}:`, postErr);
          }

          const postExists = posts && posts.length > 0 ? posts[0] : null;

          if (postExists) {
            const targetPostId = postExists.post_id || purePostId;
            const portalUrl = (Deno.env.get("WEB_PORTAL_APP_URL") || "").replace(/\/$/, "");

            console.log(`User commenting "${commentText}" on Facebook post ${postId} (matched ${targetPostId} in social_posts). Triggering auto-DM.`);

            // Send auto-DM with link matching the post ID using the comment_id
            await sendFacebookMessengerDM(
              supabase,
              account.id,
              token,
              { comment_id: commentId },
              `Hi! Thank you for commenting on our post. Here is the link to view the property details and connect directly with a broker: ${portalUrl}/form/${targetPostId}`
            );
          } else {
            console.log(`Ignored comment: post ${postId} (pure: ${purePostId}) was not uploaded via our platform (not found in social_posts).`);
          }
        }
      }

      return new Response("EVENT_RECEIVED", { status: 200 });
    } catch (err) {
      console.error("Failed processing incoming Facebook webhook event:", err);
      return new Response(JSON.stringify({ error: err.message }), { status: 500 });
    }
  }

  return new Response("Method not allowed", { status: 405 });
});

// Helper function to send private Messenger DMs via Meta Send API
async function sendFacebookMessengerDM(
  supabase: any,
  accountId: string,
  accessToken: string,
  recipient: { comment_id: string },
  messageText: string
) {
  try {
    const res = await fetch(`https://graph.facebook.com/v23.0/me/messages?access_token=${accessToken}`, {
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
      console.error(`Failed to send Messenger DM. Meta API response:`, errBody);

      try {
        const parsed = JSON.parse(errBody);
        if (parsed?.error?.code === 190 || parsed?.error?.error_subcode === 460) {
          console.warn(`[OAuthException 190/460] Facebook access token has been invalidated by Meta for account ID ${accountId}. Updating social_accounts table to is_connected = false...`);
          await supabase
            .from("social_accounts")
            .update({ is_connected: false, is_active: false })
            .eq("id", accountId);
        }
      } catch (_) {
        // Ignore JSON parse error
      }
    } else {
      console.log(`Messenger DM successfully sent to commenter: ${recipient.comment_id}`);
    }
  } catch (err) {
    console.error("Network error sending Messenger DM:", err);
  }
}
