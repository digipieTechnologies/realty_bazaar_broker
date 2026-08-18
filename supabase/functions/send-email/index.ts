// File: supabase/functions/send-email/index.ts
// Purpose: Supabase Edge Function to send emails via Resend REST API, supporting secure server-side OTP retrieval.

import { serve } from "https://deno.land/std@0.224.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

interface SendEmailRequest {
  to: string | string[];
  subject?: string;
  html?: string;
  text?: string;
  from?: string;
  otp_type?: string;
}

serve(async (req) => {
  // Handle CORS preflight requests
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    // 1. Read Resend API Key from Environment Secrets
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
    const { to, from, otp_type } = body;
    let html = body.html;
    let subject = body.subject || "Your BrokerHive Verification Code";

    // Format recipient email array
    const recipients = Array.isArray(to) ? to : [to];
    if (!to || recipients.length === 0) {
      return new Response(
        JSON.stringify({ error: "Missing required 'to' recipient email." }),
        {
          headers: { "Content-Type": "application/json", ...corsHeaders },
          status: 400,
        }
      );
    }

    // 3. If otp_type is provided, retrieve active OTP securely server-side using Service Role Key
    if (otp_type && !html) {
      const supabaseUrl = Deno.env.get("SUPABASE_URL") || "";
      const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") || "";

      if (supabaseUrl && serviceRoleKey) {
        const adminClient = createClient(supabaseUrl, serviceRoleKey);
        const { data: otps, error: otpErr } = await adminClient
          .from("user_otps")
          .select("otp")
          .eq("email", recipients[0].toLowerCase().trim())
          .eq("otp_type", otp_type)
          .gte("expiry_at", new Date().toISOString())
          .order("created_at", { ascending: false })
          .limit(1);

        if (otpErr) {
          console.error("Error querying OTP from DB:", otpErr);
        }

        if (otps && otps.length > 0) {
          const otpCode = otps[0].otp;
          html = `<h2>Your Verification Code is: <b>${otpCode}</b></h2><p>This code will expire in 2 minutes.</p>`;
        } else {
          return new Response(
            JSON.stringify({ error: "No active verification code found for this email." }),
            {
              headers: { "Content-Type": "application/json", ...corsHeaders },
              status: 404,
            }
          );
        }
      }
    }

    // Validate required fields for Resend API
    if (!html && !body.text) {
      return new Response(
        JSON.stringify({ error: "Missing email content body." }),
        {
          headers: { "Content-Type": "application/json", ...corsHeaders },
          status: 400,
        }
      );
    }

    // 4. Default sender email (Using verified domain: therealtybazaar.com)
    const defaultFrom = Deno.env.get("RESEND_FROM_EMAIL") || "The Realty Bazaar <no-reply@therealtybazaar.com>";
    const sender = from || defaultFrom;

    // 5. Construct Resend payload (Include both HTML and plain text for spam filter compliance)
    const resendPayload: Record<string, unknown> = {
      from: sender,
      to: recipients,
      subject: subject,
    };

    if (html) resendPayload.html = html;
    if (body.text) {
      resendPayload.text = body.text;
    } else if (html) {
      resendPayload.text = html.replace(/<[^>]*>?/gm, " ").replace(/\s+/g, " ").trim();
    }

    // 6. Send email via Resend REST API
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

    // 7. Return success response
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
