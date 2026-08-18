// File: lib/modules/dashboard/widgets/compact_setup_progress_widget.dart
// Purpose: Stateful compact AppBar widget displaying live-updating circular completion percentage and title, opening full SetupProgressCard on tap in a dialog.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../app/app_colors.dart';
import '../../../../providers/dashboard/dashboard_provider.dart';
import '../../../../providers/social/social_provider.dart';
import '../../../../widgets/common/app_card_container.dart';
import 'setup_progress_card.dart';

class CompactSetupProgressWidget extends StatefulWidget {
  const CompactSetupProgressWidget({super.key});

  @override
  State<CompactSetupProgressWidget> createState() => _CompactSetupProgressWidgetState();
}

class _CompactSetupProgressWidgetState extends State<CompactSetupProgressWidget> {
  void _showProgressDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        insetPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
          child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 580.0),
          child: AppCardContainer(
            child: SingleChildScrollView(
              child: SetupProgressCard(
                showHeader: true,
                onClose: () => Navigator.of(dialogContext).pop(),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dashboardProvider = context.watch<DashboardProvider>();
    final socialProvider = context.watch<SocialProvider>();

    final percentage = dashboardProvider.getCompletionPercentage(
      socialProvider.isFacebookConnected,
      socialProvider.isInstagramConnected,
    );
    final int percentInt = (percentage * 100).toInt();

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
              // Mini Circular Loader with Percentage Digit
              SizedBox(
                width: 28.0,
                height: 28.0,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CircularProgressIndicator(
                      value: percentage,
                      strokeWidth: 2.5,
                      backgroundColor: AppColors.border,
                      valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(3.0),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          '$percentInt%',
                          style: const TextStyle(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w900,
                            color: AppColors.primary,
                            letterSpacing: -0.4,
                          ),
                        ),
                      ),
                    ),
                  ],
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
