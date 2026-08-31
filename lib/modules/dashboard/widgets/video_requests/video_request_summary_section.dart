// File: lib/modules/dashboard/widgets/video_requests/video_request_summary_section.dart
// Purpose: Responsive container section for top video request summary metrics.

// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';

import '../../../../app/app_colors.dart';
import '../../../../app/app_text_styles.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../util/common_ext.dart';
import '../../../../widgets/common/app_card_container.dart';
import '../leads/lead_summary_card.dart';

class VideoRequestSummarySection extends StatelessWidget {
  final int totalRequests;
  final int pendingRequests;
  final int inProgressRequests;
  final int completedRequests;
  final bool isExpanded;
  final VoidCallback onToggle;

  const VideoRequestSummarySection({
    super.key,
    required this.totalRequests,
    required this.pendingRequests,
    required this.inProgressRequests,
    required this.completedRequests,
    required this.isExpanded,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final isMobile = context.isMobileUI;
    final isDesktop = context.isDesktop;

    return AppCardContainer(
      borderRadius: 12.0,
      onTap: onToggle,
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                context.tr('summary'),
                style: AppTextStyles.heading3.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                  fontSize: 16.0,
                ),
              ),
              Icon(
                isExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                color: AppColors.textSecondary,
                size: 24.0,
              ),
            ],
          ),

          // Expanded Grid Content
          if (isExpanded) ...[
            const SizedBox(height: 16.0),
            if (isMobile)
              GridView.builder(
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
                        title: context.tr('total_requests'),
                        value: '$totalRequests',
                        icon: Icons.trending_up_rounded,
                        iconColor: AppColors.success,
                        isCompact: true,
                      );
                    case 1:
                      return LeadSummaryCard(
                        title: context.tr('pending'),
                        value: '$pendingRequests',
                        icon: Icons.hourglass_empty_rounded,
                        iconColor: AppColors.warning,
                        isCompact: true,
                      );
                    case 2:
                      return LeadSummaryCard(
                        title: context.tr('in_progress'),
                        value: '$inProgressRequests',
                        icon: Icons.run_circle_outlined,
                        iconColor: AppColors.info,
                        isCompact: true,
                      );
                    default:
                      return LeadSummaryCard(
                        title: context.tr('completed'),
                        value: '$completedRequests',
                        icon: Icons.check_circle_outline,
                        iconColor: AppColors.success,
                        isCompact: true,
                      );
                  }
                },
              )
            else
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: 4,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: isDesktop ? 4 : 2,
                  crossAxisSpacing: 16.0,
                  mainAxisSpacing: 16.0,
                  mainAxisExtent: 130.0,
                ),
                itemBuilder: (context, index) {
                  switch (index) {
                    case 0:
                      return LeadSummaryCard(
                        title: context.tr('total_requests'),
                        value: '$totalRequests',
                        subtitle: 'Submitted shoots',
                        icon: Icons.trending_up_rounded,
                        iconColor: AppColors.success,
                      );
                    case 1:
                      return LeadSummaryCard(
                        title: context.tr('pending'),
                        value: '$pendingRequests',
                        subtitle: 'Awaiting review',
                        icon: Icons.hourglass_empty_rounded,
                        iconColor: AppColors.warning,
                      );
                    case 2:
                      return LeadSummaryCard(
                        title: context.tr('in_progress'),
                        value: '$inProgressRequests',
                        subtitle: 'Field team filming',
                        icon: Icons.run_circle_outlined,
                        iconColor: AppColors.info,
                      );
                    default:
                      return LeadSummaryCard(
                        title: context.tr('completed'),
                        value: '$completedRequests',
                        subtitle: 'Uploaded to listings',
                        icon: Icons.check_circle_outline,
                        iconColor: AppColors.success,
                      );
                  }
                },
              ),
          ],
        ],
      ),
    );
  }
}
