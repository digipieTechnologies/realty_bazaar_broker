// File: lib/modules/subscription/widgets/platforms_covered_widget.dart
// Purpose: Badge container displaying active ad distribution platforms (Facebook & Instagram).

// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';

import '../../../app/app_colors.dart';
import '../../../app/app_text_styles.dart';

class PlatformsCoveredWidget extends StatelessWidget {
  const PlatformsCoveredWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18.0),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20.0),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.8)),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow.withValues(alpha: 0.04),
            blurRadius: 12.0,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Platforms Covered',
            style: AppTextStyles.body1.copyWith(
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
              fontSize: 15.0,
            ),
          ),
          const SizedBox(height: 12.0),
          Wrap(
            spacing: 10.0,
            runSpacing: 10.0,
            children: [
              _buildChannelPill(
                assetPath: 'assets/icons/facebook.png',
                fallbackIcon: Icons.facebook_rounded,
                label: 'Facebook Page',
                brandColor: AppColors.facebook,
                bgColor: AppColors.facebook.withValues(alpha: 0.08),
                borderColor: AppColors.facebook.withValues(alpha: 0.3),
              ),
              _buildChannelPill(
                assetPath: 'assets/icons/instagram.png',
                fallbackIcon: Icons.camera_alt_rounded,
                label: 'Instagram Business',
                brandColor: AppColors.instagram,
                bgColor: AppColors.instagram.withValues(alpha: 0.08),
                borderColor: AppColors.instagram.withValues(alpha: 0.3),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChannelPill({
    required String assetPath,
    required IconData fallbackIcon,
    required String label,
    required Color brandColor,
    required Color bgColor,
    required Color borderColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 6.0),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(
            assetPath,
            width: 14.0,
            height: 14.0,
            errorBuilder: (context, error, stackTrace) => Icon(fallbackIcon, size: 14.0, color: brandColor),
          ),
          const SizedBox(width: 6.0),
          Text(
            label,
            style: AppTextStyles.body2.copyWith(
              color: brandColor,
              fontSize: 12.0,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
