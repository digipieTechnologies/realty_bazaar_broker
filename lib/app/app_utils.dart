// File: lib/app/app_utils.dart
// Purpose: Centralized helper utility methods.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../util/common_ext.dart';
import '../widgets/dialogs/app_dialog.dart';
import '../widgets/toast/app_toast.dart';

class AppUtils {
  AppUtils._();

  // --- CONFIRMATION DIALOG ---

  /// Shows a themed confirmation dialog and returns [bool?]:
  /// - `true`  → user pressed confirm
  /// - `false` → user pressed cancel
  /// - `null`  → user dismissed via back button or barrier tap
  static Future<bool?> showConfirmationDialog(
    BuildContext context, {
    required String title,
    required String description,
    DialogType type = DialogType.info,
    required String confirmText,
    String? cancelText,
  }) {
    return AppDialog.showConfirmationDialog(
      context,
      title: title,
      description: description,
      type: type,
      confirmText: confirmText,
      cancelText: cancelText,
    );
  }

  // --- VALIDATORS ---

  static String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email is required';
    }
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value.trim())) {
      return 'Please enter a valid email address';
    }
    return null;
  }

  static String? validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Phone number is required';
    }
    // General global phone matcher: allows leading +, minimum 7 digits
    final phoneRegex = RegExp(r'^\+?[0-9]{7,15}$');
    if (!phoneRegex.hasMatch(value.replaceAll(RegExp(r'[\s\-()]'), ''))) {
      return 'Please enter a valid phone number';
    }
    return null;
  }

  static String? validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Full name is required';
    }
    final nameVal = value.trim();
    if (nameVal.length < 2) {
      return 'Name must be at least 2 characters long';
    }
    final nameRegex = RegExp(r"^[a-zA-Z0-9\s\.\-\']+$");
    if (!nameRegex.hasMatch(nameVal)) {
      return 'Name can only contain letters, numbers, and standard characters';
    }
    return null;
  }

  static String? validateRequired(String? value, {String? fieldName}) {
    if (value == null || value.trim().isEmpty) {
      return fieldName != null ? '$fieldName is required' : 'This field is required';
    }
    return null;
  }

  // --- FORMATTERS ---

  static String formatCurrency(double amount, {String symbol = '\$'}) {
    return '$symbol${amount.toStringAsFixed(2).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}';
  }

  static String formatDate(DateTime date, {String format = 'yyyy-MM-dd'}) {
    try {
      return DateFormat(format).format(date);
    } catch (_) {
      return DateFormat('yyyy-MM-dd').format(date);
    }
  }

  static String formatDateTime(dynamic dateOrIsoString, {String format = 'MMM d, yyyy at h:mm a'}) {
    if (dateOrIsoString == null) return '';
    DateTime? dt;
    if (dateOrIsoString is DateTime) {
      dt = dateOrIsoString;
    } else if (dateOrIsoString is String) {
      dt = DateTime.tryParse(dateOrIsoString);
    }
    if (dt == null) return '';
    try {
      return DateFormat(format).format(dt.toLocal());
    } catch (_) {
      return dt.toLocal().toString();
    }
  }

  /// Launches a URL using url_launcher with multi-mode fallback for macOS, iOS, Android, and Web.
  static Future<bool> launchAppUrl(String urlString) async {
    if (urlString.isEmpty) {
      AppToast.showError('Invalid Link', 'No URL link was provided.');
      return false;
    }

    final Uri url = Uri.parse(urlString.trim());

    try {
      final bool launched = await launchUrl(url, mode: LaunchMode.externalApplication);
      if (launched) return true;
    } catch (e) {
      debugPrint('LaunchMode.externalApplication failed ($urlString): $e');
    }

    try {
      final bool launched = await launchUrl(url, mode: LaunchMode.platformDefault);
      if (launched) return true;
    } catch (e) {
      debugPrint('LaunchMode.platformDefault failed ($urlString): $e');
    }

    try {
      final bool launched = await launchUrl(url);
      if (launched) return true;
    } catch (e) {
      debugPrint('Basic launchUrl failed ($urlString): $e');
    }

    AppToast.showError('Launch Failed', 'Could not open connection link in browser.');
    return false;
  }

  // --- SCREEN SIZE HELPERS ---

  static double getScreenWidth(BuildContext context) => context.width;
  static double getScreenHeight(BuildContext context) => context.height;

  static bool isMobile(BuildContext context) => context.isMobile;
  static bool isTablet(BuildContext context) => context.isTablet;
  static bool isDesktop(BuildContext context) => context.isDesktop;

  // --- DEBOUNCER ---

  static void Function(void Function() action) debounce({int milliseconds = 300}) {
    Timer? timer;
    return (void Function() action) {
      if (timer != null) {
        timer!.cancel();
      }
      timer = Timer(Duration(milliseconds: milliseconds), action);
    };
  }

  // --- UI INTERACTION OVERLAYS ---

  /// Centralized helper to dismiss/hide the soft keyboard before any API submission or form action.
  static void hideKeyboard([BuildContext? context]) {
    if (context != null) {
      final currentFocus = FocusScope.of(context);
      if (!currentFocus.hasPrimaryFocus && currentFocus.focusedChild != null) {
        currentFocus.unfocus();
      }
    }
    FocusManager.instance.primaryFocus?.unfocus();
  }

  static void dismissKeyboard(BuildContext context) {
    hideKeyboard(context);
  }

  static void showSnackBar(
    BuildContext context, {
    required String message,
    bool isError = false,
    String? actionLabel,
    VoidCallback? onActionPressed,
  }) {
    if (isError) {
      AppToast.showError('Notice', message);
    } else {
      AppToast.showSuccess('Success', message);
    }
  }
}
