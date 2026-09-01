// File: lib/modules/dashboard/widgets/leads/lead_summary_section.dart
// Purpose: Responsive container section for top lead summary metrics.

import 'package:flutter/material.dart';

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
    final isMobile = context.isMobileUI;
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
                title: 'Total Leads',
                value: '$totalLeads',
                icon: Icons.trending_up_rounded,
                iconColor: AppColors.success,
                isCompact: true,
              );
            case 1:
              return LeadSummaryCard(
                title: 'Qualified',
                value: '$qualifiedLeads',
                icon: Icons.check_circle_outline_rounded,
                iconColor: AppColors.primary,
                isCompact: true,
              );
            case 2:
              return LeadSummaryCard(
                title: 'Nurturing',
                value: '$nurturingLeads',
                icon: Icons.access_time_rounded,
                iconColor: AppColors.warning,
                isCompact: true,
              );
            default:
              return LeadSummaryCard(
                title: 'Conversion',
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
            return const LeadSummaryCard(
              title: 'Total Leads',
              value: '1,284',
              subtitle: '+12% this month',
              icon: Icons.trending_up_rounded,
              iconColor: AppColors.success,
            );
          case 1:
            return const LeadSummaryCard(
              title: 'Qualified',
              value: '412',
              subtitle: 'High priority',
              icon: Icons.check_circle_outline_rounded,
              iconColor: AppColors.primary,
            );
          case 2:
            return const LeadSummaryCard(
              title: 'Nurturing',
              value: '756',
              subtitle: 'In pipeline',
              icon: Icons.access_time_rounded,
              iconColor: AppColors.warning,
            );
          default:
            return LeadSummaryCard(
              title: 'Conversion Rate',
              value: '${(conversionRate * 100).toStringAsFixed(1)}%',
              progress: conversionRate,
            );
        }
      },
    );
  }
}
