// File: supabase/functions/send-fcm-notification/index.ts
// Purpose: Supabase Edge Function to dispatch push notifications via OneSignal REST API.

import { serve } from "https://deno.land/std@0.224.0/http/server.ts";

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
    const payload = await req.json();

    // 1. Extract notification record (supports Database Webhook insert format or direct POST payload)
    const record = payload.record ?? payload;

    if (!record || !record.title || !record.notification_type) {
      return new Response(
        JSON.stringify({ error: "Invalid notification record payload" }),
        { headers: { "Content-Type": "application/json", ...corsHeaders }, status: 400 }
      );
    }

    const { receiver_id, receiver_ids, video_request_id, notification_type, title, description, data } = record;

    // 2. Read OneSignal API credentials from Environment Secrets
    const oneSignalApiKey = Deno.env.get("ONESIGNAL_REST_API_KEY");
    const oneSignalAppId = Deno.env.get("ONESIGNAL_APP_ID") || "efebf0cf-7143-4e0b-95c3-b4cd8f4319e0";

    if (!oneSignalApiKey) {
      return new Response(
        JSON.stringify({ error: "ONESIGNAL_REST_API_KEY secret is missing in Supabase Secrets." }),
        { headers: { "Content-Type": "application/json", ...corsHeaders }, status: 500 }
      );
    }

    // 3. Build OneSignal Push Notification Payload
    const oneSignalPayload: any = {
      app_id: oneSignalAppId,
      headings: { en: title },
      contents: { en: description || "" },
      data: {
        notification_type: String(notification_type),
        type: String(notification_type),
        title: String(title),
        description: String(description || ""),
        video_request_id: video_request_id || (data ? data.video_request_id : null),
        ...(data || {}),
      },
    };

    // 4. Resolve Target User IDs Array from receiver_ids or receiver_id
    let targetUserIds: string[] = [];
    if (Array.isArray(receiver_ids) && receiver_ids.length > 0) {
      targetUserIds = receiver_ids.filter(Boolean);
    } else if (receiver_id) {
      targetUserIds = [receiver_id];
    }

    if (targetUserIds.length > 0) {
      oneSignalPayload.include_aliases = {
        external_id: targetUserIds,
      };
      oneSignalPayload.target_channel = "push";
    } else {
      oneSignalPayload.included_segments = ["All"];
    }

    // 5. Dispatch Push Notification via OneSignal REST API
    const osRes = await fetch("https://onesignal.com/api/v1/notifications", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        Authorization: `Basic ${oneSignalApiKey}`,
      },
      body: JSON.stringify(oneSignalPayload),
    });

    const osResultText = await osRes.text();

    if (!osRes.ok) {
      console.error("OneSignal API Error:", osResultText);
      return new Response(
        JSON.stringify({ error: `OneSignal API error: ${osResultText}` }),
        { headers: { "Content-Type": "application/json", ...corsHeaders }, status: 500 }
      );
    }

    return new Response(
      JSON.stringify({
        success: true,
        message: "Notification dispatched successfully via OneSignal.",
        response: JSON.parse(osResultText),
      }),
      { headers: { "Content-Type": "application/json", ...corsHeaders }, status: 200 }
    );
  } catch (err) {
    return new Response(
      JSON.stringify({ error: (err as Error).message }),
      { headers: { "Content-Type": "application/json", ...corsHeaders }, status: 500 }
    );
  }
});
