import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../widgets/toast/app_toast.dart';

class AppUtils {
  AppUtils._();

  /// Launches a URL using url_launcher with multi-mode fallback for macOS, iOS, Android, and Web.
  static Future<bool> launchAppUrl(String urlString) async {
    if (urlString.isEmpty) {
      AppToast.showError('Invalid Link', 'No URL link was provided.');
      return false;
    }

    final Uri url = Uri.parse(urlString.trim());

    // 1. Attempt external application launch
    try {
      final bool launched = await launchUrl(
        url,
        mode: LaunchMode.externalApplication,
      );
      if (launched) return true;
    } catch (e) {
      debugPrint('LaunchMode.externalApplication failed ($urlString): $e');
    }

    // 2. Fallback to platform default launch
    try {
      final bool launched = await launchUrl(
        url,
        mode: LaunchMode.platformDefault,
      );
      if (launched) return true;
    } catch (e) {
      debugPrint('LaunchMode.platformDefault failed ($urlString): $e');
    }

    // 3. Fallback to basic launchUrl
    try {
      final bool launched = await launchUrl(url);
      if (launched) return true;
    } catch (e) {
      debugPrint('Basic launchUrl failed ($urlString): $e');
    }

    AppToast.showError(
      'Launch Failed',
      'Could not open connection link in browser.',
    );
    return false;
  }
}
