// File: lib/modules/dashboard/widgets/compact_setup_progress_widget.dart
// Purpose: Stateful compact AppBar widget displaying live-updating circular completion percentage and title, opening full SetupProgressCard on tap in a dialog.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../app/app_colors.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../providers/auth/auth_provider.dart';
import '../../../../providers/dashboard/dashboard_provider.dart';
import '../../../../widgets/dialogs/app_base_dialog.dart';
import '../../../../widgets/shimmer/app_shimmer_container.dart';
import 'setup_progress_card.dart';
import 'setup_progress_circular_indicator_widget.dart';

class CompactSetupProgressWidget extends StatefulWidget {
  const CompactSetupProgressWidget({super.key});

  @override
  State<CompactSetupProgressWidget> createState() =>
      _CompactSetupProgressWidgetState();
}

class _CompactSetupProgressWidgetState
    extends State<CompactSetupProgressWidget> {
  void _showProgressDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        final dashboardProvider = dialogContext.watch<DashboardProvider>();
        final authProvider = dialogContext.watch<AuthProvider>();
        final setupDetails = authProvider.userProfile?.brokerId?.setupDetails;

        final steps = dashboardProvider.getOnboardingSteps(
          setupDetails: setupDetails,
        );
        final percentage = dashboardProvider.getCompletionPercentage(
          setupDetails: setupDetails,
        );
        final completedCount = steps.where((s) => s.isCompleted).length;
        final totalCount = steps.length;

        return AppBaseDialog(
          maxWidth: 680.0,
          headerIconWidget: SetupProgressCircularIndicatorWidget(
            percentage: percentage,
            size: 42.0,
            textStyle: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w900,
              color: AppColors.primary,
              letterSpacing: -0.4,
            ),
          ),
          title: dialogContext.tr('finish_setup'),
          subtitle:
              '$completedCount / $totalCount ${dialogContext.tr('completed_status')}',
          content: const SetupProgressCard(),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final dashboardProvider = context.watch<DashboardProvider>();
    final authProvider = context.watch<AuthProvider>();

    // Show shimmer placeholder until user/broker profile finishes loading
    if (authProvider.isLoading || authProvider.userProfile == null) {
      return const AppShimmerContainer(
        width: 120.0,
        height: 34.0,
        borderRadius: 17.0,
      );
    }

    final setupDetails = authProvider.userProfile?.brokerId?.setupDetails;

    final percentage = dashboardProvider.getCompletionPercentage(
      setupDetails: setupDetails,
    );

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => _showProgressDialog(context),
        child: Container(
          height: 34.0,
          padding: const EdgeInsets.fromLTRB(4.0, 4.0, 10.0, 4.0),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(17.0),
            border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.25),
              width: 1.0,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Reusable Circular Loader Widget
              SetupProgressCircularIndicatorWidget(
                percentage: percentage,
                size: 26.0,
                textStyle: const TextStyle(
                  fontSize: 9.0,
                  fontWeight: FontWeight.w900,
                  color: AppColors.primary,
                  letterSpacing: -0.4,
                ),
              ),
              const SizedBox(width: 6.0),
              Text(
                'Finish Setup',
                style: const TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
