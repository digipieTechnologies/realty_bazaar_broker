// File: lib/widgets/common/wizard_footer_widget.dart
// Purpose: Compact wizard footer with AppButton action buttons and centered step dots indicator.

import 'package:flutter/material.dart';

import '../../app/app_colors.dart';
import '../buttons/app_button.dart';

class WizardFooterWidget extends StatelessWidget {
  final int currentStep;
  final int totalSteps;
  final VoidCallback? onBackPressed;
  final VoidCallback? onNextPressed;
  final bool isSaving;
  final String? backLabel;
  final String? nextLabel;
  final bool showStepDots;

  const WizardFooterWidget({
    super.key,
    required this.currentStep,
    required this.totalSteps,
    this.onBackPressed,
    this.onNextPressed,
    this.isSaving = false,
    this.backLabel,
    this.nextLabel,
    this.showStepDots = true,
  });

  @override
  Widget build(BuildContext context) {
    final isLastStep = currentStep == totalSteps - 1;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 2.0, horizontal: 4.0),
      color: Colors.transparent,
      child: Row(
        children: [
          // 1. BACK BUTTON (Icon-only chevron_left)
          if (currentStep > 0)
            AppButton.outline(
              iconData: Icons.chevron_left_rounded,
              width: 38.0,
              height: 38.0,
              borderRadius: 10.0,
              padding: EdgeInsets.zero,
              borderColor: AppColors.border,
              textColor: AppColors.textPrimary,
              onPressed: onBackPressed,
            )
          else
            const SizedBox(width: 38.0, height: 38.0),

          const Spacer(),

          // 2. STEP DOTS (ALWAYS IN THE CENTER BETWEEN BOTH BUTTONS)
          if (showStepDots)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(totalSteps, (index) {
                final isActive = index == currentStep;
                final isCompleted = index < currentStep;

                return AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  margin: const EdgeInsets.symmetric(horizontal: 4.0),
                  width: isActive ? 20.0 : 7.0,
                  height: 7.0,
                  decoration: BoxDecoration(
                    color: isActive
                        ? AppColors.primary
                        : (isCompleted ? AppColors.primary.withValues(alpha: 0.4) : AppColors.border),
                    borderRadius: BorderRadius.circular(3.5),
                  ),
                );
              }),
            ),

          const Spacer(),

          // 3. NEXT / SAVE BUTTON (Icon-only chevron_right or check_rounded)
          AppButton.solid(
            isLoading: isSaving,
            iconData: isLastStep ? Icons.check_rounded : Icons.chevron_right_rounded,
            width: 38.0,
            height: 38.0,
            borderRadius: 10.0,
            padding: EdgeInsets.zero,
            color: AppColors.primary,
            onPressed: isSaving ? null : onNextPressed,
          ),
        ],
      ),
    );
  }
}
