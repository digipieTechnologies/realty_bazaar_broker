// File: lib/util/common_ext.dart
// Purpose: Extension methods on standard objects, strings, context, and widgets for Auth.

import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

extension StringX on String? {
  /// Checks if string is null, empty or consists only of whitespaces.
  bool get isEmptyORNull => this == null || this!.trim().isEmpty;

  /// Verifies email format using RegExp.
  bool get isEmail {
    if (isEmptyORNull) return false;
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    return emailRegex.hasMatch(this!.trim());
  }

  /// Verifies password meets complexity rules:
  /// - Minimum 8 characters
  /// - At least one uppercase letter
  /// - At least one lowercase letter
  /// - At least one digit
  /// - At least one special character
  bool get isStrongPassword {
    if (isEmptyORNull) return false;
    final val = this!.trim();
    if (val.length < 8) return false;
    final hasUpper = val.contains(RegExp(r'[A-Z]'));
    final hasLower = val.contains(RegExp(r'[a-z]'));
    final hasDigit = val.contains(RegExp(r'[0-9]'));
    final hasSpecial = val.contains(RegExp(r'[!@#\$%^&*(),.?":{}|<>]'));
    return hasUpper && hasLower && hasDigit && hasSpecial;
  }

  /// Removes all whitespace characters from a string.
  String removeSpaces() {
    if (this == null) return '';
    return this!.replaceAll(RegExp(r'\s+'), '');
  }
}

extension ContextX on BuildContext {
  /// Shorthand screen width.
  double get width => MediaQuery.sizeOf(this).width;

  /// Shorthand screen height.
  double get height => MediaQuery.sizeOf(this).height;

  /// Safe area bottom padding (useful for keyboard-aware layouts).
  double get bottomPadding => MediaQuery.viewPaddingOf(this).bottom;

  /// Responsive Breakpoint checkers
  bool get isMobileUI => width < 600;
  bool get isTabletUI => width >= 600 && width < 950;
  bool get isDesktopUI => width >= 950;

  /// Safely pops the current route if possible.
  void popIfCan() {
    if (Navigator.of(this).canPop()) {
      Navigator.of(this).pop();
    }
  }
}

extension WidgetX on Widget {
  Widget disable({
    bool isDisable = true,
    bool changeOpacity = true,
    double opacity = 0.5,
  }) {
    if (!isDisable) return this;
    return AbsorbPointer(
      absorbing: true,
      child: Opacity(opacity: changeOpacity ? opacity : 1.0, child: this),
    );
  }
}

extension ObjectX on Object {
  /// Translates backend/network exceptions into user-friendly error messages,
  /// completely filtering raw stack traces and SQL details.
  String getUserExceptionMessage() {
    final str = toString().toLowerCase();

    // Intercept connection/network failures from any exception wrapper (AuthException, ClientException, etc.)
    if (str.contains('socketexception') ||
        str.contains('connection failed') ||
        str.contains('clientexception') ||
        str.contains('network') ||
        str.contains('operation not permitted') ||
        str.contains('failed host lookup') ||
        str.contains('errno =')) {
      return 'Connection failed. Please check your internet connection and try again.';
    }

    if (this is AuthException) {
      final error = this as AuthException;
      final msg = error.message;
      if (msg.contains('Invalid login credentials') ||
          msg.contains('invalid_credentials')) {
        return 'Invalid login credentials. Please check your email and password.';
      }
      if (msg.contains('User already registered') ||
          msg.contains('already exists') ||
          msg.contains('email_exists')) {
        return 'An account with this email address already exists.';
      }
      if (msg.contains('Email not confirmed') ||
          msg.contains('confirmation_required')) {
        return 'Please verify your email address before signing in.';
      }
      if (msg.contains('Password should be')) {
        return 'Password must be at least 8 characters and meet complexity rules.';
      }
      return msg;
    } else if (this is PostgrestException) {
      final error = this as PostgrestException;
      final msg = error.message;
      if (msg.contains('duplicate key') ||
          msg.contains('violates unique constraint')) {
        return 'An account with these details is already registered.';
      }
      return 'Database synchronization error. Please try again.';
    } else if (this is SocketException) {
      return 'No internet connection. Please verify your network and try again.';
    } else if (this is TimeoutException) {
      return 'Request timed out. Please check your connection and try again.';
    }

    if (str.contains('invalid login credentials') ||
        str.contains('invalid_credentials')) {
      return 'Invalid login credentials. Please check your email and password.';
    }
    if (str.contains('already exists') || str.contains('email_exists')) {
      return 'An account with this email address already exists.';
    }
    return 'An unexpected error occurred. Please try again later.';
  }
}
