// File: lib/core/extensions/context_extensions.dart
// Purpose: Extension methods on BuildContext for cleaner UI code.

import 'package:flutter/material.dart';
import '../../app/app_constants.dart';

extension ContextExtensions on BuildContext {
  // Theme shorthand access
  ThemeData get theme => Theme.of(this);
  TextTheme get textTheme => theme.textTheme;
  ColorScheme get colorScheme => theme.colorScheme;

  // Media Query shorthand dimensions
  double get screenWidth => MediaQuery.of(this).size.width;
  double get screenHeight => MediaQuery.of(this).size.height;

  // Orientation helper
  bool get isLandscape =>
      MediaQuery.of(this).orientation == Orientation.landscape;

  // Responsive Breakpoint shorthand access
  bool get isMobile => screenWidth < AppConstants.breakpointMobile;
  bool get isTablet =>
      screenWidth >= AppConstants.breakpointMobile &&
      screenWidth < AppConstants.breakpointTablet;
  bool get isDesktop => screenWidth >= AppConstants.breakpointTablet;

  // Safe Area padding shorthand
  EdgeInsets get viewPadding => MediaQuery.of(this).viewPadding;
  EdgeInsets get viewInsets => MediaQuery.of(this).viewInsets;

  // Navigation shortcuts via context
  void pop<T>([T? result]) => Navigator.of(this).pop(result);
}
