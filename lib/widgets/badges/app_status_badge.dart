// File: lib/widgets/badges/app_status_badge.dart
// Purpose: Universal live status badge pill widget featuring a customizable status dot indicator, high-contrast text, and responsive border styling.

import 'package:flutter/material.dart';
import '../../app/app_colors.dart';
import '../../app/app_text_styles.dart';

class AppStatusBadge extends StatelessWidget {
  final String text;
  final bool isConnected;
  final bool showDot;
  final Color? dotColor;
  final Color? textColor;
  final Color? backgroundColor;
  final Color? borderColor;
  final double fontSize;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;

  const AppStatusBadge({
    super.key,
    required this.text,
    this.isConnected = false,
    this.showDot = true,
    this.dotColor,
    this.textColor,
    this.backgroundColor,
    this.borderColor,
    this.fontSize = 9.5,
    this.padding,
    this.onTap,
  });

  /// Factory constructor for connected / disconnected social state
  factory AppStatusBadge.socialStatus({
    Key? key,
    required String text,
    required bool isConnected,
    VoidCallback? onTap,
  }) {
    return AppStatusBadge(
      key: key,
      text: text,
      isConnected: isConnected,
      showDot: isConnected,
      dotColor: isConnected ? AppColors.success : null,
      textColor: isConnected ? AppColors.statusSuccessText : AppColors.textSecondary,
      borderColor: isConnected
          ? AppColors.success.withValues(alpha: 0.3)
          : AppColors.border,
      backgroundColor: Colors.white,
      onTap: onTap,
    );
  }

  @override
  Widget build(BuildContext context) {
    final effectiveTextColor = textColor ??
        (isConnected ? AppColors.statusSuccessText : AppColors.textSecondary);

    final effectiveDotColor = dotColor ??
        (isConnected ? AppColors.success : AppColors.textMuted);

    final effectiveBorderColor = borderColor ??
        (isConnected
            ? AppColors.success.withValues(alpha: 0.3)
            : AppColors.border);

    final effectiveBgColor = backgroundColor ?? Colors.white;

    Widget badgeContent = Container(
      padding: padding ?? const EdgeInsets.symmetric(horizontal: 9.0, vertical: 4.5),
      decoration: BoxDecoration(
        color: effectiveBgColor,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(
          color: effectiveBorderColor,
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 4.0,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showDot) ...[
            Container(
              width: 6.0,
              height: 6.0,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: effectiveDotColor,
              ),
            ),
            const SizedBox(width: 4.0),
          ],
          Text(
            text.toUpperCase(),
            style: AppTextStyles.caption.copyWith(
              fontSize: fontSize,
              fontWeight: FontWeight.w800,
              color: effectiveTextColor,
              letterSpacing: 0.4,
            ),
          ),
        ],
      ),
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12.0),
        child: badgeContent,
      );
    }

    return badgeContent;
  }
}
