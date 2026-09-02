// File: lib/widgets/dialogs/estimated_results_info_dialog.dart
// Purpose: Standalone dialog providing detailed explanations for estimated ad campaign results (Views & WhatsApp leads).

// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';

import '../../app/app_colors.dart';
import '../../app/app_text_styles.dart';
import '../buttons/app_button.dart';
import 'app_base_dialog.dart';

class EstimatedResultsInfoDialog extends StatelessWidget {
  const EstimatedResultsInfoDialog({super.key});

  /// Static helper to display the dialog
  static Future<void> show(BuildContext context) {
    return AppBaseDialog.show(context: context, child: const EstimatedResultsInfoDialog());
  }

  @override
  Widget build(BuildContext context) {
    return AppBaseDialog(
      title: 'About Estimated Results',
      subtitle: 'Campaign projection benchmark details',
      headerIcon: Icons.insights_rounded,
      maxWidth: 480.0,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Banner note
          Container(
            padding: const EdgeInsets.all(14.0),
            decoration: BoxDecoration(
              color: AppColors.primary50,
              borderRadius: BorderRadius.circular(14.0),
              border: Border.all(color: AppColors.consultationBannerBorder),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.info_outline_rounded, size: 20.0, color: AppColors.primary),
                const SizedBox(width: 10.0),
                Expanded(
                  child: Text(
                    'Metric projections are benchmark estimates calculated using average Meta & Google ad performance data.',
                    style: AppTextStyles.body2.copyWith(
                      color: AppColors.consultationBannerText,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18.0),

          Text(
            'Key Factors Influencing Results:',
            style: AppTextStyles.body1.copyWith(
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
              fontSize: 14.0,
            ),
          ),
          const SizedBox(height: 12.0),

          _buildFactorBullet(
            iconData: Icons.location_on_outlined,
            iconColor: AppColors.primary,
            title: 'Property Location & Area Demand',
            description:
                'Inquiry rates vary by city and micro-market. Prime high-demand locations typically see faster lead responses.',
          ),
          const SizedBox(height: 12.0),

          _buildFactorBullet(
            iconData: Icons.currency_rupee_rounded,
            iconColor: AppColors.success,
            title: 'Property Price Point & Category',
            description:
                'Affordable and mid-range residential listings convert faster than ultra-luxury niche properties.',
          ),
          const SizedBox(height: 12.0),

          _buildFactorBullet(
            iconData: Icons.palette_outlined,
            iconColor: AppColors.tagIndigo,
            title: 'Ad Design & Creative Quality',
            description:
                'Eye-catching property graphics and HD video walkthroughs significantly boost buyer engagement.',
          ),
          const SizedBox(height: 12.0),

          _buildFactorBullet(
            iconData: Icons.trending_up_rounded,
            iconColor: AppColors.warning,
            title: 'Market Activity & Target Audience',
            description:
                'Seasonal demand, interest rate trends, and demographic targeting affect conversion speeds.',
          ),
        ],
      ),
      footer: SizedBox(
        width: double.infinity,
        child: AppButton.solid(
          text: 'Got It',
          onPressed: () => Navigator.of(context).pop(),
          height: 48.0,
          borderRadius: 12.0,
        ),
      ),
    );
  }

  Widget _buildFactorBullet({
    required IconData iconData,
    required Color iconColor,
    required String title,
    required String description,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(7.0),
          decoration: BoxDecoration(color: iconColor.withValues(alpha: 0.1), shape: BoxShape.circle),
          child: Icon(iconData, size: 16.0, color: iconColor),
        ),
        const SizedBox(width: 12.0),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTextStyles.body2.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                  fontSize: 13.0,
                ),
              ),
              const SizedBox(height: 2.0),
              Text(
                description,
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.textSecondary,
                  fontSize: 11.5,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
