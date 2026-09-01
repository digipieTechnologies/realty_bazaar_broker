-- Migration: Fix generate_user_otp RPC function with correct API keys and sender email
-- File: supabase/migrations/20260901202000_fix_generate_user_otp.sql

CREATE OR REPLACE FUNCTION public.generate_user_otp(
  p_email TEXT,
  p_otp_type TEXT
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_otp TEXT;
  v_expiry TIMESTAMPTZ;
  v_clean_email TEXT;
  v_clean_otp_type TEXT;
  v_request_id BIGINT;
  v_subject TEXT;
  v_description TEXT;
BEGIN
  v_clean_email := LOWER(TRIM(p_email));
  v_clean_otp_type := LOWER(TRIM(p_otp_type));

  IF v_clean_email IS NULL OR v_clean_email = '' THEN
    RAISE EXCEPTION 'Email address is required to generate OTP.';
  END IF;

  IF v_clean_otp_type IS NULL OR v_clean_otp_type = '' THEN
    RAISE EXCEPTION 'OTP type is required to generate OTP.';
  END IF;

  -- Dynamic subject & description based on otp_type (The Realty Bazaar branding)
  IF v_clean_otp_type = 'forgot_password' THEN
    v_subject := 'Reset Your Password - The Realty Bazaar';
    v_description := 'We received a request to reset your password. Please use the verification code below to proceed with updating your password.';
  ELSIF v_clean_otp_type = 'change_password' THEN
    v_subject := 'Change Password Code - The Realty Bazaar';
    v_description := 'We received a request to change your password. Please use the verification code below to proceed with updating your password.';
  ELSE
    v_subject := 'Your The Realty Bazaar Verification Code';
    v_description := 'We received a request to verify your email address. Please use the verification code below to complete the process.';
  END IF;

  -- Generate 6 digit OTP & set 30-second expiry
  v_otp := lpad(floor(random() * 900000 + 100000)::text, 6, '0');
  v_expiry := NOW() + INTERVAL '30 seconds';

  -- Delete any existing unverified OTP for this email and otp_type
  DELETE FROM public.user_otps
  WHERE LOWER(email) = v_clean_email
    AND (otp_type::text = v_clean_otp_type OR otp_type = v_clean_otp_type::otp_type_enum);

  -- Insert new OTP into public.user_otps table
  INSERT INTO public.user_otps (
    email,
    otp,
    otp_type,
    expiry_at,
    created_at
  )
  VALUES (
    v_clean_email,
    v_otp,
    v_clean_otp_type::otp_type_enum,
    v_expiry,
    NOW()
  );

  -- Fire send-email Edge Function via pg_net with verified domain sender
  SELECT net.http_post(
    url := 'https://btjzesvlexcvpqwisyet.supabase.co/functions/v1/send-email',
    headers := jsonb_build_object(
      'Content-Type', 'application/json',
      'apikey', 'sb_publishable_68yV-TwP5tS8TMG2yw50Nw_nllSeQXW',
      'Authorization', 'Bearer sb_publishable_68yV-TwP5tS8TMG2yw50Nw_nllSeQXW'
    ),
    body := jsonb_build_object(
      'to', v_clean_email,
      'from', 'The Realty Bazaar <no-reply@therealtybazaar.com>',
      'subject', v_subject,
      'text', 'Your The Realty Bazaar verification code is: ' || v_otp || '. This code will expire in 30 seconds.',
      'html',
        '<!DOCTYPE html>'
        || '<html lang="en"><head><meta charset="UTF-8"><meta name="viewport" content="width=device-width,initial-scale=1.0">'
        || '<style>'
        || 'body{margin:0;padding:0;font-family:-apple-system,BlinkMacSystemFont,''Segoe UI'',Roboto,''Helvetica Neue'',Arial,sans-serif;background-color:#f0f2f5;}'
        || '.wrapper{width:100%;background-color:#f0f2f5;padding:40px 0;}'
        || '.container{max-width:520px;margin:0 auto;background:#ffffff;border-radius:16px;overflow:hidden;box-shadow:0 4px 24px rgba(0,0,0,0.08);}'
        || '.header{background:linear-gradient(135deg,#1a73e8 0%,#0d47a1 100%);padding:36px 32px;text-align:center;}'
        || '.header h1{color:#ffffff;font-size:26px;font-weight:700;margin:0;letter-spacing:-0.5px;}'
        || '.header p{color:rgba(255,255,255,0.85);font-size:14px;margin:8px 0 0;font-weight:400;}'
        || '.body-content{padding:36px 32px;}'
        || '.greeting{font-size:16px;color:#1a1a2e;margin:0 0 16px;font-weight:500;}'
        || '.message{font-size:14px;color:#555770;line-height:1.6;margin:0 0 28px;}'
        || '.otp-box{background:linear-gradient(135deg,#e8f0fe 0%,#d2e3fc 100%);border:2px solid #1a73e8;border-radius:12px;padding:24px;text-align:center;margin:0 0 28px;}'
        || '.otp-label{font-size:12px;color:#555770;text-transform:uppercase;letter-spacing:2px;font-weight:600;margin:0 0 12px;}'
        || '.otp-code{font-size:36px;font-weight:800;color:#1a73e8;letter-spacing:8px;margin:0;font-family:''SF Mono'',''Fira Code'',''Courier New'',monospace;}'
        || '.expiry-badge{display:inline-block;background:#fff3e0;color:#e65100;font-size:12px;font-weight:600;padding:6px 14px;border-radius:20px;margin:16px 0 0;}'
        || '.divider{height:1px;background:#e8eaed;margin:0 0 24px;}'
        || '.security-note{font-size:13px;color:#888;line-height:1.5;margin:0 0 8px;}'
        || '.security-note strong{color:#555;}'
        || '.footer{background:#f8f9fa;padding:24px 32px;text-align:center;border-top:1px solid #e8eaed;}'
        || '.footer p{font-size:12px;color:#999;margin:0 0 4px;}'
        || '.footer a{color:#1a73e8;text-decoration:none;}'
        || '</style></head><body>'
        || '<div class="wrapper"><div class="container">'
        || '<div class="header">'
        || '<h1>The Realty Bazaar</h1>'
        || '<p>Real Estate Brokerage Platform</p>'
        || '</div>'
        || '<div class="body-content">'
        || '<p class="greeting">Hello,</p>'
        || '<p class="message">' || v_description || '</p>'
        || '<div class="otp-box">'
        || '<p class="otp-label">Verification Code</p>'
        || '<p class="otp-code">' || v_otp || '</p>'
        || '<span class="expiry-badge">⏱ Expires in 30 seconds</span>'
        || '</div>'
        || '<div class="divider"></div>'
        || '<p class="security-note"><strong>🔒 Security Notice:</strong> If you did not request this code, please ignore this email. Never share this code with anyone.</p>'
        || '<p class="security-note">This is an automated message from The Realty Bazaar — your trusted real estate brokerage management platform for managing leads, properties, and client relationships.</p>'
        || '</div>'
        || '<div class="footer">'
        || '<p>&copy; ' || EXTRACT(YEAR FROM NOW())::text || ' The Realty Bazaar. All rights reserved.</p>'
        || '<p>Powered by <a href="#">The Realty Bazaar Platform</a></p>'
        || '</div>'
        || '</div></div>'
        || '</body></html>'
    )
  ) INTO v_request_id;

  -- Return status metadata only, never expose raw OTP
  RETURN jsonb_build_object(
    'success', true,
    'message', 'OTP generated and email dispatch requested.',
    'email', v_clean_email,
    'otp_type', v_clean_otp_type,
    'request_id', v_request_id,
    'expiry_at', v_expiry
  );
END;
$$;

-- Grant execute permissions
GRANT EXECUTE ON FUNCTION public.generate_user_otp(TEXT, TEXT) TO anon, authenticated, service_role;
