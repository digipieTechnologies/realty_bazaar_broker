// File: lib/modules/subscription/widgets/subscription_feature_section.dart
// Purpose: Horizontal scrollable feature section for SubscriptionPackageDetailScreen.

import 'package:flutter/material.dart';
import '../../../app/app_colors.dart';
import '../../../app/app_text_styles.dart';
import 'subscription_feature_card.dart';

class SubscriptionFeatureItemData {
  final String title;
  final String description;
  final String assetPath;

  const SubscriptionFeatureItemData({
    required this.title,
    required this.description,
    required this.assetPath,
  });
}

class SubscriptionFeatureSection extends StatelessWidget {
  final List<SubscriptionFeatureItemData> features;

  const SubscriptionFeatureSection({
    super.key,
    required this.features,
  });

  static List<SubscriptionFeatureItemData> getDefaultFeatures() {
    return const [
      SubscriptionFeatureItemData(
        title: 'Ad Designing',
        description: 'Our professional designers create high-converting ad graphics customized for your property listing.',
        assetPath: 'assets/images/subscription_features/ad_design.png',
      ),
      SubscriptionFeatureItemData(
        title: 'Content & Copywriting',
        description: 'Engaging real estate post captions and ad copies optimized for maximum buyer inquiries.',
        assetPath: 'assets/images/subscription_features/content_creation.png',
      ),
      SubscriptionFeatureItemData(
        title: 'WhatsApp Lead Delivery',
        description: 'Receive instant notifications and buyer contact details directly inside your WhatsApp inbox.',
        assetPath: 'assets/images/subscription_features/whatsapp_leads.png',
      ),
      SubscriptionFeatureItemData(
        title: 'Precision Targeting',
        description: 'Target active homebuyers and high-net-worth investors in your specific city and micro-market.',
        assetPath: 'assets/images/subscription_features/audience_targeting.png',
      ),
      SubscriptionFeatureItemData(
        title: 'AI Optimization',
        description: 'Real-time campaign budget reallocation to maximize leads while lowering cost-per-lead.',
        assetPath: 'assets/images/subscription_features/campaign_optimization.png',
      ),
      SubscriptionFeatureItemData(
        title: 'Live Analytics',
        description: 'Track ad views, click-through rates, and total leads captured on your growth dashboard.',
        assetPath: 'assets/images/subscription_features/analytics.png',
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final list = features.isNotEmpty ? features : getDefaultFeatures();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4.0),
          child: Text(
            'Package Includes',
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
