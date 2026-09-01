// File: lib/widgets/badges/app_platform_badge.dart
// Purpose: Reusable platform source pill badge component for Facebook Lead Ads and Instagram Lead Forms across all screens and tiles.

import 'package:flutter/material.dart';

import '../../app/app_colors.dart';
import '../../app/app_text_styles.dart';
import '../../models/social_enums.dart';
import '../icons/app_icons.dart';

class AppPlatformBadge extends StatelessWidget {
  final SocialPlatform? platform;
  final bool isHeaderStyle;
  final double iconSize;
  final EdgeInsetsGeometry? padding;
  final TextStyle? textStyle;

  const AppPlatformBadge({
    super.key,
    required this.platform,
    this.isHeaderStyle = false,
    this.iconSize = 14.0,
    this.padding,
    this.textStyle,
  });

  @override
  Widget build(BuildContext context) {
    if (platform == null) {
      return Text(
        '--',
        style: AppTextStyles.caption.copyWith(
          color: AppColors.textMuted,
          fontWeight: FontWeight.w600,
        ),
      );
    }

    final isFacebook = platform == SocialPlatform.facebook;
    final isInstagram = platform == SocialPlatform.instagram;

    final Color brandColor = isFacebook
        ? AppColors.facebook
        : (isInstagram ? AppColors.instagram : AppColors.textSecondary);

    final String labelText = isFacebook ? 'Facebook' : (isInstagram ? 'Instagram' : 'Other');

    final Widget brandIcon = isFacebook
        ? FacebookIconWidget(size: iconSize)
        : (isInstagram ? InstagramIconWidget(size: iconSize) : const Icon(Icons.public, size: 14.0));

    final EdgeInsetsGeometry effectivePadding = padding ??
        const EdgeInsets.symmetric(horizontal: 10.0, vertical: 4.0);

    if (isHeaderStyle) {
      return Container(
        padding: effectivePadding,
        decoration: BoxDecoration(
          color: AppColors.white.withValues(alpha: 0.92),
          borderRadius: BorderRadius.circular(20.0),
          boxShadow: [
            BoxShadow(
              color: AppColors.shadow.withValues(alpha: 0.1),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            brandIcon,
            const SizedBox(width: 6.0),
            Text(
              labelText,
              style: textStyle ??
                  TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: effectivePadding,
      decoration: BoxDecoration(
        color: brandColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20.0),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          brandIcon,
          const SizedBox(width: 6.0),
          Text(
            labelText,
            style: textStyle ??
                TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.bold,
                  color: brandColor,
                ),
          ),
        ],
      ),
    );
  }
}
