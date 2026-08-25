// File: supabase/functions/send-email/index.ts
// Purpose: Supabase Edge Function to send emails via Resend REST API with anti-spam deliverability compliance.

import { serve } from "https://deno.land/std@0.224.0/http/server.ts";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

interface SendEmailRequest {
  to: string | string[];
  subject: string;
  html?: string;
  text?: string;
  from?: string;
  reply_to?: string;
}

serve(async (req) => {
  // Handle CORS preflight requests
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    // 1. Read Resend API Key & Secrets from Environment Variables
    const resendApiKey = Deno.env.get("RESEND_API_KEY");
    if (!resendApiKey) {
      return new Response(
        JSON.stringify({
          error: "RESEND_API_KEY is missing in Supabase Edge Function secrets.",
        }),
        {
          headers: { "Content-Type": "application/json", ...corsHeaders },
          status: 500,
        }
      );
    }

    // 2. Parse request payload
    const body: SendEmailRequest = await req.json();
    const { to, subject, html, text, from, reply_to } = body;

    // Validate required fields
    if (!to || !subject || (!html && !text)) {
      return new Response(
        JSON.stringify({
          error: "Missing required fields. 'to', 'subject', and either 'html' or 'text' are required.",
        }),
        {
          headers: { "Content-Type": "application/json", ...corsHeaders },
          status: 400,
        }
      );
    }

    // 3. Format recipient email array
    const recipients = Array.isArray(to) ? to : [to];

    // 4. Sender & Reply-To email (Prioritizes payload `from`, then `RESEND_FROM_EMAIL` secret)
    const secretFrom = Deno.env.get("RESEND_FROM_EMAIL");
    const defaultFrom = secretFrom || "The Realty Bazaar <no-reply@therealtybazaar.com>";
    const sender = from || defaultFrom;

    const secretReplyTo = Deno.env.get("RESEND_REPLY_TO");
    const replyTo = reply_to || secretReplyTo;

    // 5. Auto-generate plain text body from HTML if text is missing (crucial for Gmail Anti-Spam compliance)
    let plainText = text;
    if (!plainText && html) {
      plainText = html
        .replace(/<style[^>]*>[\s\S]*?<\/style>/gi, "")
        .replace(/<[^>]+>/g, " ")
        .replace(/\s+/g, " ")
        .trim();
    }

    // 6. Construct Resend payload with anti-spam compliance fields
    const resendPayload: Record<string, unknown> = {
      from: sender,
      to: recipients,
      subject: subject,
    };

    if (html) resendPayload.html = html;
    if (plainText) resendPayload.text = plainText;
    if (replyTo) resendPayload.reply_to = replyTo;

    // 7. Send email via Resend REST API
    const resendResponse = await fetch("https://api.resend.com/emails", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        Authorization: `Bearer ${resendApiKey}`,
      },
      body: JSON.stringify(resendPayload),
    });

    const resendResult = await resendResponse.json();

    if (!resendResponse.ok) {
      console.error("Resend API Error:", resendResult);
      return new Response(
        JSON.stringify({
          error: "Failed to send email via Resend API",
          details: resendResult,
        }),
        {
          headers: { "Content-Type": "application/json", ...corsHeaders },
          status: resendResponse.status,
        }
      );
    }

    // 8. Return success response
    return new Response(
      JSON.stringify({
        success: true,
        message: "Email sent successfully",
        data: resendResult,
      }),
      {
        headers: { "Content-Type": "application/json", ...corsHeaders },
        status: 200,
      }
    );
  } catch (err) {
    console.error("Unhandled Edge Function Error:", err);
    return new Response(
      JSON.stringify({ error: (err as Error).message }),
      {
        headers: { "Content-Type": "application/json", ...corsHeaders },
        status: 500,
      }
    );
  }
});
