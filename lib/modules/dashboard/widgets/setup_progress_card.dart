// File: lib/modules/dashboard/widgets/setup_progress_card.dart
// Purpose: Modern colorful tile-based onboarding setup dialog card widget with rich descriptions and smart UI navigation.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../providers/auth/auth_provider.dart';
import '../../../../providers/dashboard/dashboard_provider.dart';
import '../../../../providers/social/social_provider.dart';
import '../../../../widgets/common/app_card_container.dart';
import 'setup_step_tile_widget.dart';

class SetupProgressCard extends StatelessWidget {
  final bool showHeader;
  final bool showCardBorder;
  final VoidCallback? onClose;

  const SetupProgressCard({super.key, this.showHeader = false, this.showCardBorder = false, this.onClose});

  void _handleStepTap(BuildContext context, OnboardingStep step) {
    if ((step.id == 'connect_facebook' || step.id == 'connect_instagram') && !step.isCompleted) {
      final socialProvider = context.read<SocialProvider>();
      final authProvider = context.read<AuthProvider>();
      final brokerId = authProvider.userProfile?.brokerId?.id;

      if (brokerId != null) {
        if (step.id == 'connect_facebook') {
          socialProvider.connectFacebook(brokerId);
        } else if (step.id == 'connect_instagram') {
          socialProvider.connectInstagramDirectly(brokerId);
        }
      }
      // Do not close the dialog, wait for the real-time update to mark it completed
      return;
    }

    if (step.routePath.isEmpty) return;

    if (onClose != null) {
      onClose!();
    } else {
      final nav = Navigator.of(context, rootNavigator: true);
      if (nav.canPop()) {
        nav.pop();
      }
    }
    context.go(step.routePath);
  }

  @override
  Widget build(BuildContext context) {
    final dashboardProvider = context.watch<DashboardProvider>();
    final authProvider = context.watch<AuthProvider>();
    final setupDetails = authProvider.userProfile?.brokerId?.setupDetails;

    final steps = dashboardProvider.getOnboardingSteps(setupDetails: setupDetails);

    final Widget content = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: EdgeInsets.all(showHeader ? 20.0 : 0.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Step Tiles Layout (Grid / Responsive list using SetupStepTileWidget)
              LayoutBuilder(
                builder: (context, constraints) {
                  final bool useTwoColumns = constraints.maxWidth >= 500.0;

                  if (!useTwoColumns) {
                    return Column(
                      children: steps
                          .map(
                            (step) =>
                                SetupStepTileWidget(step: step, onTap: () => _handleStepTap(context, step)),
                          )
                          .toList(),
                    );
                  }

                  // Two-column layout
                  final leftSteps = <OnboardingStep>[];
                  final rightSteps = <OnboardingStep>[];
                  for (int i = 0; i < steps.length; i++) {
                    if (i % 2 == 0) {
                      leftSteps.add(steps[i]);
                    } else {
                      rightSteps.add(steps[i]);
                    }
                  }

                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          children: leftSteps
                              .map(
                                (step) => SetupStepTileWidget(
                                  step: step,
                                  onTap: () => _handleStepTap(context, step),
                                ),
                              )
                              .toList(),
                        ),
                      ),
                      const SizedBox(width: 14.0),
                      Expanded(
                        child: Column(
                          children: rightSteps
                              .map(
                                (step) => SetupStepTileWidget(
                                  step: step,
                                  onTap: () => _handleStepTap(context, step),
                                ),
                              )
                              .toList(),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );

    if (showCardBorder) {
      return AppCardContainer(padding: EdgeInsets.zero, child: content);
    }

    return content;
  }
}
