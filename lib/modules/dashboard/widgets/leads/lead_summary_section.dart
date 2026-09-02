// File: lib/modules/dashboard/widgets/leads/lead_summary_section.dart
// Purpose: Responsive container section for top lead summary metrics.

import 'package:flutter/material.dart';
import 'package:the_realty_bazaar/core/localization/app_localizations.dart';

import '../../../../app/app_colors.dart';
import '../../../../util/common_ext.dart';
import 'lead_summary_card.dart';

class LeadSummarySection extends StatelessWidget {
  final int totalLeads;
  final int qualifiedLeads;
  final int nurturingLeads;
  final double conversionRate;

  const LeadSummarySection({
    super.key,
    required this.totalLeads,
    required this.qualifiedLeads,
    required this.nurturingLeads,
    required this.conversionRate,
  });

  @override
  Widget build(BuildContext context) {
    final isMobile = context.isMobile;
    final isDesktop = context.isDesktop;

    if (isMobile) {
      // Mobile compact 2x2 grid view with mainAxisExtent to ensure fixed height
      return GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: 4,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 10.0,
          mainAxisSpacing: 10.0,
          mainAxisExtent: 76.0,
        ),
        itemBuilder: (context, index) {
          switch (index) {
            case 0:
              return LeadSummaryCard(
                title: context.tr('total_leads'),
                value: '$totalLeads',
                icon: Icons.trending_up_rounded,
                iconColor: AppColors.success,
                isCompact: true,
              );
            case 1:
              return LeadSummaryCard(
                title: context.tr('qualified'),
                value: '$qualifiedLeads',
                icon: Icons.check_circle_outline_rounded,
                iconColor: AppColors.primary,
                isCompact: true,
              );
            case 2:
              return LeadSummaryCard(
                title: context.tr('nurturing'),
                value: '$nurturingLeads',
                icon: Icons.access_time_rounded,
                iconColor: AppColors.warning,
                isCompact: true,
              );
            default:
              return LeadSummaryCard(
                title: context.tr('conversion'),
                value: '${(conversionRate * 100).toStringAsFixed(1)}%',
                icon: Icons.pie_chart_outline_rounded,
                iconColor: AppColors.primary,
                isCompact: true,
              );
          }
        },
      );
    }

    // Desktop / Tablet 4-column layout with fixed mainAxisExtent (130px) for comfortable vertical height
    final crossAxisCount = isDesktop ? 4 : 2;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 4,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 16.0,
        mainAxisSpacing: 16.0,
        mainAxisExtent: 130.0,
      ),
      itemBuilder: (context, index) {
        switch (index) {
          case 0:
            return LeadSummaryCard(
              title: context.tr('total_leads'),
              value: '$totalLeads',
              subtitle: context.tr('plus_twelve_percent_month'),
              icon: Icons.trending_up_rounded,
              iconColor: AppColors.success,
            );
          case 1:
            return LeadSummaryCard(
              title: context.tr('qualified'),
              value: '$qualifiedLeads',
              subtitle: context.tr('high_priority'),
              icon: Icons.check_circle_outline_rounded,
              iconColor: AppColors.primary,
            );
          case 2:
            return LeadSummaryCard(
              title: context.tr('nurturing'),
              value: '$nurturingLeads',
              subtitle: context.tr('in_pipeline'),
              icon: Icons.access_time_rounded,
              iconColor: AppColors.warning,
            );
          default:
            return LeadSummaryCard(
              title: context.tr('conversion_rate'),
              value: '${(conversionRate * 100).toStringAsFixed(1)}%',
              progress: conversionRate,
            );
        }
      },
    );
  }
}
