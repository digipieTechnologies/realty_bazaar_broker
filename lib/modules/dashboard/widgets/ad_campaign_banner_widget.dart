// File: lib/modules/dashboard/widgets/ad_campaign_banner_widget.dart
// Purpose: Compact, colorful banner widget for navigating to Ad Campaign Settings screen from the Dashboard,
// using design system tokens (AppColors) and unified buttons (AppButton).

import 'package:flutter/material.dart';

import '../../../../app/app_colors.dart';
import '../../../../app/app_routes.dart';
import '../../../../app/app_text_styles.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../widgets/buttons/app_button.dart';

class AdCampaignBannerWidget extends StatelessWidget {
  const AdCampaignBannerWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: AppColors.primaryGradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16.0),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10.0),
            decoration: BoxDecoration(
              color: AppColors.surface.withValues(alpha: 0.18),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.campaign_rounded, color: AppColors.surface, size: 24.0),
          ),
          const SizedBox(width: 14.0),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  context.tr('ad_campaign_settings'),
                  style: AppTextStyles.heading3.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.surface,
                    fontSize: 15.0,
                  ),
                ),
                const SizedBox(height: 3.0),
                Text(
                  context.tr('ad_campaign_banner_desc'),
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.surface.withValues(alpha: 0.88),
                    fontSize: 12.0,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12.0),
          AppButton.solid(
            text: context.tr('manage'),
            height: 36.0,
            borderRadius: 10.0,
            color: AppColors.surface,
            textColor: AppColors.primary,
            padding: const EdgeInsets.symmetric(horizontal: 14.0),
            onPressed: () => AppRoutes.navigateToCampaignSettings(context),
          ),
        ],
      ),
    );
  }
}
