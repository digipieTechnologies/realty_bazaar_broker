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
    const supabaseUrl = Deno.env.get("SUPABASE_URL");
    const supabaseServiceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");

    if (!supabaseUrl || !supabaseServiceRoleKey) {
      throw new Error(
        "Missing server configuration environment variables (SUPABASE_URL / SUPABASE_SERVICE_ROLE_KEY)."
      );
    }

    const supabaseAdmin = createClient(supabaseUrl, supabaseServiceRoleKey);

    let body: any = {};
    try {
      body = await req.json();
    } catch (_e) {
      body = {};
    }

    const action = body?.action || "request"; // 'request' | 'process'
    const clientIp =
      req.headers.get("x-forwarded-for") ||
      req.headers.get("cf-connecting-ip") ||
      "";

    // Helper to normalize phone strings (extract digits & optional country code)
    const parsePhoneNumber = (raw: string) => {
      // Remove all non-digits except leading '+'
      const cleaned = raw.trim().replace(/[^\d+]/g, "");
      let countryCode = "91"; // Default to India
      let phone = cleaned.replace(/\D/g, "");

      if (cleaned.startsWith("+")) {
        const withoutPlus = cleaned.substring(1);
        // Standard codes: +91 (India, 12 digits total), +1 (US/Canada, 11 digits total), etc.
        if (withoutPlus.startsWith("91") && withoutPlus.length > 10) {
          countryCode = "91";
          phone = withoutPlus.substring(2);
        } else if (withoutPlus.startsWith("1") && withoutPlus.length > 10) {
          countryCode = "1";
          phone = withoutPlus.substring(1);
        } else if (withoutPlus.length > 10) {
          // General fallback: last 10 digits as phone, leading digits as country code
          phone = withoutPlus.slice(-10);
          countryCode = withoutPlus.slice(0, -10);
        }
      } else if (phone.length > 10) {
        // e.g. 919988998899
        if (phone.startsWith("91")) {
          countryCode = "91";
          phone = phone.substring(2);
        } else {
          phone = phone.slice(-10);
          countryCode = phone.slice(0, -10) || "91";
        }
      }

      return { phone, phoneCountryCode: countryCode };
    };

    // =========================================================================
    // ACTION: REQUEST (Called by in-app user or public web form)
    // =========================================================================
    if (action === "request") {
      const authHeader = req.headers.get("Authorization");
      const reason = body?.reason || "User requested account deletion";
      let userId: string | null = null;
      let userEmail: string | null = body?.email ? body.email.trim().toLowerCase() : null;
      let userPhone: string | null = null;
      let userCountryCode: string | null = null;
      let brokerId: string | null = null;

      if (body?.phone) {
        const parsed = parsePhoneNumber(body.phone);
        userPhone = parsed.phone;
        userCountryCode = parsed.phoneCountryCode;
      }

      // 1. Check if authenticated
      if (authHeader && authHeader.startsWith("Bearer ")) {
        const token = authHeader.replace("Bearer ", "").trim();
        if (token) {
          const {
            data: { user },
            error: authError,
          } = await supabaseAdmin.auth.getUser(token);

          if (!authError && user?.id) {
            userId = user.id;
            userEmail = userEmail || user.email?.toLowerCase() || null;

            // Fetch user profile
            const { data: userProfile } = await supabaseAdmin
              .from("users")
              .select("id, email, phone, phone_country_code, broker_id")
              .eq("id", userId)
              .maybeSingle();

            if (userProfile) {
              brokerId = userProfile.broker_id;
              userEmail = userEmail || userProfile.email?.toLowerCase() || null;
              userPhone = userPhone || userProfile.phone || null;
              userCountryCode = userCountryCode || userProfile.phone_country_code || "91";
            }
          } else if (authError) {
            console.warn(`[DeleteAccount] Auth token verification warning: ${authError.message}`);
          }
        }
      }

      // If unauthenticated guest request, attempt to resolve user profile by email or phone
      if (!userId && (userEmail || userPhone)) {
        let query = supabaseAdmin
          .from("users")
          .select("id, email, phone, phone_country_code, broker_id");

        if (userEmail) {
          query = query.ilike("email", userEmail.trim());
        } else if (userPhone) {
          // Match by phone number and country code if present, or search phone suffix
          if (userCountryCode) {
            query = query.eq("phone", userPhone).eq("phone_country_code", userCountryCode);
          } else {
            query = query.eq("phone", userPhone);
          }
        }

        const { data: matchedUsers, error: queryErr } = await query;
        if (queryErr) {
          console.error(`[DeleteAccount] User lookup error: ${queryErr.message}`);
        }

        // Fallback: If not matched by exact country code, try matching just phone number
        if ((!matchedUsers || matchedUsers.length === 0) && userPhone) {
          const { data: fallbackUsers } = await supabaseAdmin
            .from("users")
            .select("id, email, phone, phone_country_code, broker_id")
            .eq("phone", userPhone);

          if (fallbackUsers && fallbackUsers.length > 0) {
            userId = fallbackUsers[0].id;
            brokerId = fallbackUsers[0].broker_id;
            userEmail = userEmail || fallbackUsers[0].email;
            userPhone = fallbackUsers[0].phone;
            userCountryCode = fallbackUsers[0].phone_country_code || "91";
          }
        } else if (matchedUsers && matchedUsers.length > 0) {
          userId = matchedUsers[0].id;
          brokerId = matchedUsers[0].broker_id;
          userEmail = userEmail || matchedUsers[0].email;
          userPhone = matchedUsers[0].phone;
          userCountryCode = matchedUsers[0].phone_country_code || "91";
        }
      }

      // If user cannot be found for given email or phone
      if (!userId) {
        return new Response(
          JSON.stringify({
            error:
              "No active account found matching the provided email or phone number. Please verify your details.",
          }),
          {
            status: 404,
            headers: { ...corsHeaders, "Content-Type": "application/json" },
          }
        );
      }

      console.log(
        `[DeleteAccount] Resolved user for request: userId=${userId}, brokerId=${brokerId}, email=${userEmail}, phone=${userPhone}`
      );

      // 2. Duplicate Request Check in account_deletion_requests (status = 'pending')
      let duplicateQuery = supabaseAdmin
        .from("account_deletion_requests")
        .select("id, user_id, status, requested_at, updated_at")
        .eq("status", "pending");

      if (userId) {
        duplicateQuery = duplicateQuery.eq("user_id", userId);
      } else if (userEmail) {
        duplicateQuery = duplicateQuery.ilike("email", userEmail);
      } else if (userPhone) {
        duplicateQuery = duplicateQuery.eq("phone", userPhone);
      }

      const { data: existingRequests, error: checkError } =
        await duplicateQuery.maybeSingle();

      if (checkError && checkError.code !== "PGRST116") {
        console.error(`[DeleteAccount] Error checking duplicate: ${checkError.message}`);
      }

      if (existingRequests) {
        // Update updated_at and reason
        await supabaseAdmin
          .from("account_deletion_requests")
          .update({
            updated_at: new Date().toISOString(),
            reason: reason,
            requested_ip: clientIp || undefined,
          })
          .eq("id", existingRequests.id);

        return new Response(
          JSON.stringify({
            success: false,
            already_exists: true,
            message:
              "A deletion request for this account has already been submitted and is currently pending review by our compliance team.",
          }),
          {
            status: 409,
            headers: { ...corsHeaders, "Content-Type": "application/json" },
          }
        );
      }

      // 3. Create new record in account_deletion_requests with non-null userId
      const formattedPhone = userPhone
        ? `${userCountryCode ? `+${userCountryCode} ` : ""}${userPhone}`
        : null;

      const { data: newRequest, error: insertError } = await supabaseAdmin
        .from("account_deletion_requests")
        .insert({
          user_id: userId,
          broker_id: brokerId,
          email: userEmail,
          phone: formattedPhone,
          status: "pending",
          deletion_type: "soft",
          reason: reason,
          requested_ip: clientIp,
          requested_at: new Date().toISOString(),
          updated_at: new Date().toISOString(),
        })
        .select()
        .single();

      if (insertError) {
        console.error(`[DeleteAccount] Insert error: ${insertError.message}`);
      }

      // 4. Immediately soft-delete all data across schema so user data is instantly isolated & inaccessible
      if (userId || brokerId) {
        console.log(
          `[DeleteAccount] Triggering immediate soft-delete isolation for user: ${userId}, broker: ${brokerId}`
        );
        const { error: rpcError } = await supabaseAdmin.rpc(
          "execute_user_deletion",
          {
            p_user_id: userId,
            p_broker_id: brokerId,
            p_mode: "soft",
            p_reason: reason,
          }
        );

        if (rpcError) {
          console.error(`[DeleteAccount] RPC isolation error: ${rpcError.message}`);
        }
      }

      return new Response(
        JSON.stringify({
          success: true,
          request_id: newRequest?.id,
          message:
            "Your account deletion request has been submitted. Your account and personal data have been deactivated and isolated.",
        }),
        {
          status: 200,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    // =========================================================================
    // ACTION: PROCESS (Called by Super Admin to approve / reject / hard-purge)
    // =========================================================================
    if (action === "process") {
      const authHeader = req.headers.get("Authorization");
      if (!authHeader) {
        return new Response(
          JSON.stringify({ error: "Unauthorized. Super Admin token required." }),
          {
            status: 401,
            headers: { ...corsHeaders, "Content-Type": "application/json" },
          }
        );
      }

      const token = authHeader.replace("Bearer ", "");
      const {
        data: { user: adminUser },
        error: adminAuthError,
      } = await supabaseAdmin.auth.getUser(token);

      if (adminAuthError || !adminUser) {
        return new Response(
          JSON.stringify({ error: "Invalid admin authentication token." }),
          {
            status: 401,
            headers: { ...corsHeaders, "Content-Type": "application/json" },
          }
        );
      }

      const requestId = body?.request_id;
      let targetUserId = body?.user_id;
      let targetBrokerId = body?.broker_id;
      const deletionType = body?.deletion_type === "hard" ? "hard" : "soft";
      const status = body?.status || "approved"; // 'approved' | 'rejected'

      if (requestId && (!targetUserId || !targetBrokerId)) {
        const { data: reqData } = await supabaseAdmin
          .from("account_deletion_requests")
          .select("user_id, broker_id")
          .eq("id", requestId)
          .maybeSingle();

        if (reqData) {
          targetUserId = targetUserId || reqData.user_id;
          targetBrokerId = targetBrokerId || reqData.broker_id;
        }
      }

      if (!requestId && !targetUserId) {
        return new Response(
          JSON.stringify({ error: "Missing request_id or user_id parameter." }),
          {
            status: 400,
            headers: { ...corsHeaders, "Content-Type": "application/json" },
          }
        );
      }

      console.log(
        `[DeleteAccount Admin Process] Admin ${adminUser.id} executing ${deletionType} deletion for request: ${requestId}, target user: ${targetUserId}`
      );

      // Execute dynamic schema deletion
      let rpcResult: any = null;
      if (status === "approved" && (targetUserId || targetBrokerId)) {
        const { data: rpcData, error: rpcError } = await supabaseAdmin.rpc(
          "execute_user_deletion",
          {
            p_user_id: targetUserId,
            p_broker_id: targetBrokerId,
            p_mode: deletionType,
          }
        );

        if (rpcError) {
          throw new Error(`Database deletion error: ${rpcError.message}`);
        }
        rpcResult = rpcData;

        // Permanently delete user from Supabase Auth ONLY if hard delete is chosen by Super Admin
        if (deletionType === "hard" && targetUserId) {
          console.log(`[DeleteAccount Admin Process] Hard deleting auth user: ${targetUserId}`);
          await supabaseAdmin.auth.admin.deleteUser(targetUserId);
        }
      }

      // Update request record
      if (requestId) {
        await supabaseAdmin
          .from("account_deletion_requests")
          .update({
            status: status,
            deletion_type: deletionType,
            processed_at: new Date().toISOString(),
            processed_by_admin_id: adminUser.id,
          })
          .eq("id", requestId);
      }

      return new Response(
        JSON.stringify({
          success: true,
          status: status,
          deletion_type: deletionType,
          details: rpcResult,
          message: `Account deletion request ${status} successfully.`,
        }),
        {
          status: 200,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    return new Response(
      JSON.stringify({ error: `Unknown action: '${action}'. Expected 'request' or 'process'.` }),
      {
        status: 400,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      }
    );
  } catch (err: any) {
    console.error("[DeleteAccount] Server error:", err);
    return new Response(
      JSON.stringify({
        error: err.message || "Internal server error during account deletion.",
      }),
      {
        status: 500,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      }
    );
  }
});
