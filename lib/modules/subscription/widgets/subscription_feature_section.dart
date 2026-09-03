// File: lib/modules/subscription/widgets/subscription_feature_section.dart
// Purpose: Horizontal scrollable feature section for SubscriptionPackageDetailScreen.

import 'package:flutter/material.dart';

import '../../../app/app_colors.dart';
import '../../../app/app_text_styles.dart';
import '../../../core/localization/app_localizations.dart';
import 'subscription_feature_card.dart';

class SubscriptionFeatureItemData {
  final String title;
  final String description;
  final String assetPath;

  const SubscriptionFeatureItemData({required this.title, required this.description, required this.assetPath});
}

class SubscriptionFeatureSection extends StatelessWidget {
  final List<SubscriptionFeatureItemData> features;

  const SubscriptionFeatureSection({super.key, required this.features});

  static List<SubscriptionFeatureItemData> getDefaultFeatures(BuildContext context) {
    return [
      SubscriptionFeatureItemData(
        title: context.tr('feature_ad_design_title'),
        description: context.tr('feature_ad_design_desc'),
        assetPath: 'assets/images/subscription_features/ad_design.png',
      ),
      SubscriptionFeatureItemData(
        title: context.tr('feature_copywriting_title'),
        description: context.tr('feature_copywriting_desc'),
        assetPath: 'assets/images/subscription_features/content_creation.png',
      ),
      SubscriptionFeatureItemData(
        title: context.tr('feature_whatsapp_title'),
        description: context.tr('feature_whatsapp_desc'),
        assetPath: 'assets/images/subscription_features/whatsapp_leads.png',
      ),
      SubscriptionFeatureItemData(
        title: context.tr('feature_targeting_title'),
        description: context.tr('feature_targeting_desc'),
        assetPath: 'assets/images/subscription_features/audience_targeting.png',
      ),
      SubscriptionFeatureItemData(
        title: context.tr('feature_ai_opt_title'),
        description: context.tr('feature_ai_opt_desc'),
        assetPath: 'assets/images/subscription_features/campaign_optimization.png',
      ),
      SubscriptionFeatureItemData(
        title: context.tr('feature_analytics_title'),
        description: context.tr('feature_analytics_desc'),
        assetPath: 'assets/images/subscription_features/analytics.png',
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final list = features.isNotEmpty ? features : getDefaultFeatures(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4.0),
          child: Text(
            context.tr('package_includes'),
            style: AppTextStyles.heading3.copyWith(
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
              fontSize: 18.0,
            ),
          ),
        ),
        const SizedBox(height: 14.0),
        SizedBox(
          height: 135.0,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: list.length,
            separatorBuilder: (_, _) => const SizedBox(width: 14.0),
            itemBuilder: (context, index) {
              final item = list[index];
              return SubscriptionFeatureCard(
                title: item.title,
                description: item.description,
                assetIconPath: item.assetPath,
              );
            },
          ),
        ),
      ],
    );
  }
}
