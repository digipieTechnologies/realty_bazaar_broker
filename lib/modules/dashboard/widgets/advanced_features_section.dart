import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../app/app_colors.dart';
import '../../../../app/app_text_styles.dart';
import '../../../../providers/dashboard/dashboard_provider.dart';
import '../../../../core/localization/app_localizations.dart';

class AdvancedFeaturesSection extends StatelessWidget {
  const AdvancedFeaturesSection({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DashboardProvider>();
    final features = provider.advancedFeatures;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.tr('unlock_adv_growth'),
          style: const TextStyle(
            fontSize: 16.0,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 4.0),
        Text(
          context.tr('connecting_enables_ecosystem'),
          style: AppTextStyles.body2.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 16.0),

        // Horizontal scrollable ListView of 6 cards
        SizedBox(
          height: 110.0,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: features.length,
            separatorBuilder: (context, index) => const SizedBox(width: 12.0),
            itemBuilder: (context, index) {
              final feature = features[index];
              return Container(
                width: 180.0,
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12.0),
                  border: Border.all(color: AppColors.border, width: 1.0),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Icon(
                      feature.icon,
                      color: AppColors.primary,
                      size: 24.0,
                    ),
                    const SizedBox(height: 8.0),
                    Text(
                      context.tr('adv_feature_${feature.title.toLowerCase().replaceAll(' ', '_').replaceAll('-', '_')}'),
                      style: const TextStyle(
                        fontSize: 12.0,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
