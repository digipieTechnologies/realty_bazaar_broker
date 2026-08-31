// File: lib/modules/subscription/widgets/subscription_feature_card.dart
// Purpose: Reusable compact feature card with asset image illustration, title, and description.

// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import '../../../app/app_colors.dart';
import '../../../app/app_text_styles.dart';

class SubscriptionFeatureCard extends StatelessWidget {
  final String title;
  final String description;
  final String assetIconPath;

  const SubscriptionFeatureCard({
    super.key,
    required this.title,
    required this.description,
    required this.assetIconPath,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 210.0,
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20.0),
        border: Border.all(
          color: AppColors.border.withValues(alpha: 0.8),
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.05),
            blurRadius: 14.0,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Illustration Asset Icon
          Container(
            width: 52.0,
            height: 52.0,
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(14.0),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14.0),
              child: Image.asset(
                assetIconPath,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return const Icon(
                    Icons.auto_awesome_rounded,
                    color: AppColors.primary,
                    size: 26.0,
                  );
                },
              ),
            ),
          ),

          const SizedBox(height: 14.0),

          // Feature Title
          Text(
            title,
            style: AppTextStyles.body1.copyWith(
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
              fontSize: 15.0,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),

          const SizedBox(height: 6.0),

          // Feature Description
          Expanded(
            child: Text(
              description,
              style: AppTextStyles.body2.copyWith(
                color: AppColors.textSecondary,
                fontSize: 12.5,
                height: 1.35,
              ),
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
