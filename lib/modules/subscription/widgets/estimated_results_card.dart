// File: lib/modules/subscription/widgets/estimated_results_card.dart
// Purpose: Metric card displaying dynamic estimated campaign results (Views & WhatsApp leads) with interactive info dialog.

// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../app/app_colors.dart';
import '../../../app/app_text_styles.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../widgets/dialogs/estimated_results_info_dialog.dart';

class EstimatedResultsCard extends StatelessWidget {
  final double planAmount;
  final int days;

  const EstimatedResultsCard({super.key, required this.planAmount, required this.days});

  @override
  Widget build(BuildContext context) {
    // 80% of plan fee goes directly to ad budget
    final double adSpend = planAmount * 0.8;

    // Estimate leads based on ₹150 avg cost per buyer lead
    final int estLeadsMin = (adSpend / 160).round();
    final int estLeadsMax = (adSpend / 140).round();

    // Estimate views based on ₹0.15 avg cost per view
    final int estViewsK = ((adSpend / 0.16) / 1000).round();

    final NumberFormat numFmt = NumberFormat('#,##,###', 'en_IN');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18.0),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20.0),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.8)),
        boxShadow: [
          BoxShadow(color: AppColors.shadow.withValues(alpha: 0.04), blurRadius: 12.0, offset: const Offset(0, 3)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                context.tr('estimated_results'),
                style: AppTextStyles.body1.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                  fontSize: 15.0,
                ),
              ),
              const SizedBox(width: 4.0),
              InkWell(
                onTap: () => EstimatedResultsInfoDialog.show(context),
                borderRadius: BorderRadius.circular(16.0),
                child: const Padding(
                  padding: EdgeInsets.all(4.0),
                  child: Icon(Icons.info_outline_rounded, size: 17.0, color: AppColors.primary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14.0),
          Row(
            children: [
              // Metric 1: Views
              Expanded(
                child: _buildMetricPill(
                  iconData: Icons.remove_red_eye_rounded,
                  iconColor: AppColors.primary,
                  bgColor: AppColors.primary.withValues(alpha: 0.04),
                  borderColor: AppColors.primary.withValues(alpha: 0.15),
                  valueText: '${numFmt.format(estViewsK)}K+',
                  label: context.tr('views_uppercase'),
                ),
              ),
              const SizedBox(width: 12.0),
              // Metric 2: Leads
              Expanded(
                child: _buildMetricPill(
                  iconData: Icons.group_add_rounded,
                  iconColor: AppColors.success,
                  bgColor: AppColors.success.withValues(alpha: 0.04),
                  borderColor: AppColors.success.withValues(alpha: 0.15),
                  valueText: '$estLeadsMin–$estLeadsMax',
                  label: context.tr('leads_uppercase'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12.0),
          Text(
            context
                .tr('estimated_results_desc')
                .replaceAll('{min}', estLeadsMin.toString())
                .replaceAll('{max}', estLeadsMax.toString())
                .replaceAll('{days}', days.toString()),
            style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary, fontSize: 12.0, height: 1.35),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricPill({
    required IconData iconData,
    required Color iconColor,
    required Color bgColor,
    required Color borderColor,
    required String valueText,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(14.0),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8.0),
            decoration: BoxDecoration(color: iconColor.withValues(alpha: 0.12), shape: BoxShape.circle),
            child: Icon(iconData, size: 18.0, color: iconColor),
          ),
          const SizedBox(width: 10.0),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  valueText,
                  style: AppTextStyles.body1.copyWith(
                    fontWeight: FontWeight.w900,
                    color: AppColors.textPrimary,
                    fontSize: 16.0,
                  ),
                ),
                Text(
                  label,
                  style: AppTextStyles.caption.copyWith(
                    color: iconColor, // Use the icon color for the label to make it more colorful
                    fontWeight: FontWeight.w800,
                    fontSize: 10.0,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
