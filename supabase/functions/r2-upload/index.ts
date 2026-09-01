import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.39.0";
import { S3Client, PutObjectCommand, DeleteObjectCommand } from "https://esm.sh/@aws-sdk/client-s3@3.450.0";
import { getSignedUrl } from "https://esm.sh/@aws-sdk/s3-request-presigner@3.450.0";

const R2_ACCOUNT_ID = Deno.env.get("R2_ACCOUNT_ID") || "";
const R2_ACCESS_KEY_ID = Deno.env.get("R2_ACCESS_KEY_ID") || "";
const R2_SECRET_ACCESS_KEY = Deno.env.get("R2_SECRET_ACCESS_KEY") || "";
const R2_BUCKET_NAME = Deno.env.get("R2_BUCKET_NAME") || "brokers";
const R2_PUBLIC_DOMAIN = Deno.env.get("R2_PUBLIC_DOMAIN") || "";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL") || "";
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") || "";

const s3Client = new S3Client({
  region: "auto",
  endpoint: `https://${R2_ACCOUNT_ID}.r2.cloudflarestorage.com`,
  credentials: {
    accessKeyId: R2_ACCESS_KEY_ID,
    secretAccessKey: R2_SECRET_ACCESS_KEY,
  },
});

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const url = new URL(req.url);
    const action = url.searchParams.get("action");
    const body = await req.json();

    if (action === "presign") {
      const { entityType, entityId, fileName, mimeType, fileSize, skipDbInsert, oldR2Key } = body;

      const ext = fileName.includes(".") ? fileName.split(".").pop() : "jpg";
      const timestamp = Date.now();
      const r2Key = `${entityType}/${entityId}/${timestamp}_${fileName}`;

      const command = new PutObjectCommand({
        Bucket: R2_BUCKET_NAME,
        Key: r2Key,
        ContentType: mimeType,
      });

      const presignedUrl = await getSignedUrl(s3Client, command, { expiresIn: 3600 });
      const publicUrl = `${R2_PUBLIC_DOMAIN.replace(/\/$/, "")}/${r2Key}`;

      let attachmentId = null;

      if (!skipDbInsert) {
        const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY);
        const { data, error } = await supabase
          .from("attachments")
          .insert({
            entity_type: entityType,
            entity_id: String(entityId),
            url: publicUrl,
            r2_key: r2Key,
            file_name: fileName,
            file_type: mimeType,
            file_size: fileSize,
          })
          .select("id")
          .single();

        if (!error && data) {
          attachmentId = data.id;
        }
      }

      if (oldR2Key) {
        try {
          await s3Client.send(new DeleteObjectCommand({ Bucket: R2_BUCKET_NAME, Key: oldR2Key }));
        } catch (_) {
          // ignore cleanup errors
        }
      }

      return new Response(
        JSON.stringify({
          presignedUrl,
          publicUrl,
          r2Key,
          attachmentId,
        }),
        { headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    if (action === "delete") {
      const { r2Key, attachmentId } = body;

      if (r2Key) {
        await s3Client.send(new DeleteObjectCommand({ Bucket: R2_BUCKET_NAME, Key: r2Key }));
      }

      if (attachmentId) {
        const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY);
        await supabase.from("attachments").delete().eq("id", attachmentId);
      }

      return new Response(JSON.stringify({ success: true }), {
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    return new Response(JSON.stringify({ error: "Invalid action" }), {
      status: 400,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  } catch (error) {
    return new Response(JSON.stringify({ error: error.message }), {
      status: 500,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }
});
