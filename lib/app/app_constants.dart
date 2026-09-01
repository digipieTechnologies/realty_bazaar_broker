// File: lib/app/app_constants.dart
// Purpose: Global constant variables for dimensions, settings, and storage.

import 'package:flutter/widgets.dart';

class AppConstants {

  AppConstants._();

  // Support Contact Phone Numbers
  static const String supportPhoneNumber = '+919033582481';
  static const String supportPhoneDisplay = '+91 90335 82481';

  // Layout Dimensions (Paddings, Margins, Spacings)
  static const double paddingXS = 4.0;
  static const double paddingS = 8.0;
  static const double paddingM = 16.0;
  static const double paddingL = 24.0;
  static const double paddingXL = 32.0;

  // Screen Edge Padding (Uniform across all dashboard tabs)
  static const double tabContentPadding = 24.0;
  static const EdgeInsets tabScreenPadding = EdgeInsets.all(24.0);

  static EdgeInsets getTabPadding(BuildContext context, {double bottomExtra = 0.0}) {
    final isMobile = MediaQuery.of(context).size.width < breakpointMobile;
    final hPadding = isMobile ? 12.0 : 24.0;
    final vPadding = isMobile ? 12.0 : 24.0;
    return EdgeInsets.fromLTRB(hPadding, vPadding, hPadding, vPadding + bottomExtra);
  }


  static const double borderRadiusS = 4.0;
  static const double borderRadiusM = 8.0;
  static const double borderRadiusL = 12.0;
  static const double borderRadiusXL = 24.0;

  // Animation Speeds
  static const int durationFastMs = 150;
  static const int durationNormalMs = 300;
  static const int durationSlowMs = 500;

  // Network Settings
  static const int connectionTimeoutMs = 15000;
  static const int receiveTimeoutMs = 15000;

  // Storage Keys
  static const String keyUserToken = 'user_token';
  static const String keyUserPreferences = 'user_prefs';
  static const String keyIsFirstRun = 'is_first_run';

  // Responsive Breakpoints
  static const double breakpointMobile = 600.0;
  static const double breakpointTablet = 960.0;
}
