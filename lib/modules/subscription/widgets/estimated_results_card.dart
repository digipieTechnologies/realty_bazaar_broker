// File: lib/modules/subscription/widgets/estimated_results_card.dart
// Purpose: Metric card displaying dynamic estimated campaign results (Views & WhatsApp leads).

// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../app/app_colors.dart';
import '../../../app/app_text_styles.dart';

class EstimatedResultsCard extends StatelessWidget {
  final double planAmount;
  final int days;

  const EstimatedResultsCard({
    super.key,
    required this.planAmount,
    required this.days,
  });

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
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(20.0),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Estimated Results',
                style: AppTextStyles.body1.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                  fontSize: 15.0,
                ),
              ),
              const SizedBox(width: 6.0),
              const Icon(
                Icons.info_outline_rounded,
                size: 16.0,
                color: AppColors.textMuted,
              ),
            ],
          ),
          const SizedBox(height: 14.0),
          Row(
            children: [
              // Metric 1: Views
              Expanded(
                child: _buildMetricPill(
                  iconData: Icons.remove_red_eye_outlined,
                  iconColor: const Color(0xFF3B82F6),
                  valueText: '${numFmt.format(estViewsK)}K+',
                  label: 'VIEWS',
                ),
              ),
              const SizedBox(width: 12.0),
              // Metric 2: WhatsApp Leads
              Expanded(
                child: _buildMetricPill(
                  iconData: Icons.trending_up_rounded,
                  iconColor: const Color(0xFF10B981),
                  valueText: '$estLeadsMin–$estLeadsMax',
                  label: 'WHATSAPP LEADS',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12.0),
          Text(
            'Receive estimated $estLeadsMin to $estLeadsMax qualified buyer leads directly on WhatsApp within $days days.',
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textSecondary,
              fontSize: 12.0,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricPill({
    required IconData iconData,
    required Color iconColor,
    required String valueText,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14.0),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8.0),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
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
                    color: AppColors.textMuted,
                    fontWeight: FontWeight.w700,
                    fontSize: 10.0,
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
