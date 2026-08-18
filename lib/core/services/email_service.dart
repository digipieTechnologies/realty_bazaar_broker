// File: lib/core/services/email_service.dart
// Purpose: Centralized service to send emails by invoking the Supabase Edge Function 'send-email' via Resend.

import 'package:flutter/foundation.dart';
import '../supabase/supabase_config.dart';

class EmailService {
  EmailService._();

  /// Sends a generic email via Supabase Edge Function 'send-email' (using Resend).
  ///
  /// Parameters:
  /// - [to]: Target email address or a list of emails.
  /// - [subject]: Email subject line.
  /// - [html]: Optional HTML body string.
  /// - [text]: Optional plain text body fallback.
  /// - [from]: Optional custom sender.
  ///
  /// Returns `true` if email was sent successfully, `false` otherwise.
  static Future<bool> sendEmail({
    required dynamic to,
    required String subject,
    String? html,
    String? text,
    String? from,
  }) async {
    try {
      final Map<String, dynamic> bodyData = {
        'to': to,
        'subject': subject,
      };
      if (html != null) bodyData['html'] = html;
      if (text != null) bodyData['text'] = text;
      if (from != null) bodyData['from'] = from;

      final response = await SupabaseConfig.client.functions.invoke(
        'send-email',
        body: bodyData,
      );

      if (response.status == 200) {
        debugPrint('[EmailService] Email sent successfully to: $to');
        return true;
      } else {
        debugPrint('[EmailService] Failed to send email. Status: ${response.status}, Error: ${response.data}');
        return false;
      }
    } catch (e) {
      debugPrint('[EmailService] Exception invoking send-email edge function: $e');
      return false;
    }
  }
}
