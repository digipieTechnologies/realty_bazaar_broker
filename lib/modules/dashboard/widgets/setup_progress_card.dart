import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../app/app_colors.dart';
import '../../../../app/app_text_styles.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../providers/dashboard/dashboard_provider.dart';
import '../../../../providers/social/social_provider.dart';
import '../../../../widgets/common/app_card_container.dart';

class SetupProgressCard extends StatelessWidget {
  final bool showHeader;
  final VoidCallback? onClose;

  const SetupProgressCard({
    super.key,
    this.showHeader = false,
    this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final dashboardProvider = context.watch<DashboardProvider>();
    final socialProvider = context.watch<SocialProvider>();

    final steps = dashboardProvider.getOnboardingSteps(
      socialProvider.isFacebookConnected,
      socialProvider.isInstagramConnected,
    );
    final percentage = dashboardProvider.getCompletionPercentage(
      socialProvider.isFacebookConnected,
      socialProvider.isInstagramConnected,
    );
    final percentageText = '${(percentage * 100).toInt()}%';

    // Split steps for two columns
    final leftColSteps = [
      steps[0], // Account Created
      steps[2], // Connect Facebook
      steps[4], // Import Properties
      steps[6], // Configure Notifications
    ];
    final rightColSteps = [
      steps[1], // Business Info Added
      steps[3], // Connect Instagram
      steps[5], // Invite Team
    ];

    return AppCardContainer(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showHeader) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(20.0, 14.0, 12.0, 14.0),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      context.tr('finish_setup'),
                      style: AppTextStyles.heading3.copyWith(
                        fontSize: 16.0,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.close_rounded,
                      color: AppColors.textSecondary,
                      size: 22.0,
                    ),
                    onPressed: onClose ?? () => Navigator.of(context).pop(),
                    tooltip: 'Close',
                  ),
                ],
              ),
            ),
            const Divider(height: 1.0, color: AppColors.border),
          ],
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!showHeader) ...[
                  Text(
                    context.tr('finish_setup'),
                    style: const TextStyle(
                      fontSize: 16.0,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 24.0),
                ],
                
                // Progress and Steps Row (Responsive: Column on Mobile/Narrow width, Row on Desktop)
                LayoutBuilder(
                  builder: (context, constraints) {
                    final isNarrow = constraints.maxWidth < 480.0;
                    
                    final progressCircle = Center(
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          SizedBox(
                            width: 100.0,
                            height: 100.0,
                            child: CircularProgressIndicator(
                              value: percentage,
                              strokeWidth: 8.0,
                              backgroundColor: AppColors.border,
                              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                            ),
                          ),
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                percentageText,
                                style: AppTextStyles.heading2.copyWith(
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              Text(
                                context.tr('complete_caps'),
                                style: AppTextStyles.caption.copyWith(
                                  fontSize: 9.0,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textMuted,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );

                    final isMobileNarrow = constraints.maxWidth < 450.0;

                    Widget checklistGrid;
                    if (isMobileNarrow) {
                      checklistGrid = Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: steps.map((step) => _buildChecklistRow(context, step)).toList(),
                      );
                    } else {
                      checklistGrid = Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Column 1
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: leftColSteps.map((step) => _buildChecklistRow(context, step)).toList(),
                            ),
                          ),
                          const SizedBox(width: 16.0),
                          // Column 2
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: rightColSteps.map((step) => _buildChecklistRow(context, step)).toList(),
                            ),
                          ),
                        ],
                      );
                    }

                    if (isNarrow) {
                      return Column(
                        children: [
                          progressCircle,
                          const SizedBox(height: 24.0),
                          checklistGrid,
                        ],
                      );
                    }

                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        progressCircle,
                        const SizedBox(width: 32.0),
                        Expanded(child: checklistGrid),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 8.0),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChecklistRow(BuildContext context, OnboardingStep step) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        children: [
          Icon(
            step.isCompleted ? Icons.check_circle_rounded : Icons.circle_outlined,
            color: step.isCompleted ? AppColors.primary : AppColors.textMuted,
            size: 20.0,
          ),
          const SizedBox(width: 8.0),
          Expanded(
            child: Text(
              context.tr('step_${step.id}'),
              style: TextStyle(
                fontSize: 13.0,
                fontWeight: step.isCompleted ? FontWeight.w600 : FontWeight.w400,
                color: step.isCompleted ? AppColors.textPrimary : AppColors.textSecondary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
