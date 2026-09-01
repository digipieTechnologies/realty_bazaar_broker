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
  final double width;

  const SubscriptionFeatureCard({
    super.key,
    required this.title,
    required this.description,
    required this.assetIconPath,
    this.width = 285.0,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 12.0),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18.0),
        border: Border.all(
          color: AppColors.border.withValues(alpha: 0.85),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow.withValues(alpha: 0.05),
            blurRadius: 12.0,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header Row: Compact 38x38 Logo + Title
          Row(
            children: [
              Container(
                width: 38.0,
                height: 38.0,
                padding: const EdgeInsets.all(4.0),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primary.withValues(alpha: 0.08),
                      AppColors.primary.withValues(alpha: 0.03),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(10.0),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    width: 1.0,
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(7.0),
                  child: Image.asset(
                    assetIconPath,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return const Icon(
                        Icons.auto_awesome_rounded,
                        color: AppColors.primary,
                        size: 20.0,
                      );
                    },
                  ),
                ),
              ),

              const SizedBox(width: 10.0),

              // Title on the right side of Logo
              Expanded(
                child: Text(
                  title,
                  style: AppTextStyles.body1.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                    fontSize: 14.5,
                    letterSpacing: -0.2,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),

          const SizedBox(height: 8.0),

          // Compact Feature Description
          Text(
            description,
            style: AppTextStyles.body2.copyWith(
              color: AppColors.textSecondary,
              fontSize: 12.0,
              height: 1.32,
            ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
