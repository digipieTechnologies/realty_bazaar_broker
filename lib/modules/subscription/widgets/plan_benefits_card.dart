// File: lib/modules/subscription/widgets/plan_benefits_card.dart
// Purpose: Shared benefits card widget used across subscription success and active plan detail screens.

import 'package:flutter/material.dart';

import '../../../app/app_colors.dart';
import '../../../app/app_text_styles.dart';

class PlanBenefitsCard extends StatelessWidget {
  final List<String> benefits;
  final String title;

  const PlanBenefitsCard({
    super.key,
    required this.benefits,
    this.title = 'Plan Benefits',
  });

  @override
  Widget build(BuildContext context) {
    final List<String> displayFeatures = benefits.isNotEmpty
        ? benefits
        : const [
            'Unlimited High-Intent Lead Access & Direct Contact',
            'Automated AI Social Media Posters & Ad Campaigns',
            'Full Campaign Strategy & 24/7 Priority Support',
            'Instant WhatsApp & Push Notification Alerts',
          ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(22.0),
        border: Border.all(color: AppColors.primary100, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary500.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6.0),
                decoration: BoxDecoration(
                  color: AppColors.primary50,
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: const Icon(Icons.auto_awesome_rounded, size: 16.0, color: AppColors.primary500),
              ),
              const SizedBox(width: 10.0),
              Text(
                title,
                style: AppTextStyles.body1.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                  fontSize: 14.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14.0),
          ...displayFeatures.map((feature) => _buildFeatureItem(feature)),
        ],
      ),
    );
  }

  Widget _buildFeatureItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10.0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 10.0),
        decoration: BoxDecoration(
          color: AppColors.primary50.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(12.0),
          border: Border.all(color: AppColors.primary100),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(4.0),
              decoration: const BoxDecoration(color: AppColors.successLight, shape: BoxShape.circle),
              child: const Icon(Icons.check_rounded, size: 13.0, color: AppColors.success),
            ),
            const SizedBox(width: 10.0),
            Expanded(
              child: Text(
                text,
                style: AppTextStyles.body2.copyWith(
                  color: AppColors.textPrimary,
                  fontSize: 13.0,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
