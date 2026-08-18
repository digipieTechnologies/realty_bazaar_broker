import 'package:flutter/material.dart';
import '../../app/app_colors.dart';
import '../../app/app_text_styles.dart';

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
    final computedNextText = nextLabel ?? (isLastStep ? 'Save & Publish' : 'Next Step');

    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 420;

        return Container(
          padding: EdgeInsets.symmetric(
            horizontal: isCompact ? 12.0 : 20.0,
            vertical: isCompact ? 12.0 : 16.0,
          ),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16.0),
            border: Border.all(color: AppColors.border, width: 1.0),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.05),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Show step dots above the button row ONLY on compact
              if (isCompact && showStepDots) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(totalSteps, (index) {
                    final isActive = index == currentStep;
                    final isCompleted = index < currentStep;

                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      margin: const EdgeInsets.symmetric(horizontal: 4.0),
                      width: isActive ? 24.0 : 8.0,
                      height: 6.0,
                      decoration: BoxDecoration(
                        color: isActive
                            ? AppColors.primary
                            : (isCompleted
                                ? AppColors.primary.withValues(alpha: 0.4)
                                : AppColors.border),
                        borderRadius: BorderRadius.circular(3.0),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 10.0),
              ],
              Row(
                children: [
                  // 1. BACK BUTTON (empty on step 0)
                  if (currentStep > 0)
                    MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: onBackPressed,
                          borderRadius: BorderRadius.circular(12.0),
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: isCompact ? 12.0 : 20.0,
                              vertical: isCompact ? 10.0 : 12.0,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.background,
                              borderRadius: BorderRadius.circular(12.0),
                              border: Border.all(color: AppColors.border, width: 1.0),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.arrow_back_rounded,
                                  size: 16.0,
                                  color: AppColors.textPrimary,
                                ),
                                const SizedBox(width: 6.0),
                                Text(
                                  backLabel ?? 'Back',
                                  style: AppTextStyles.body2.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textPrimary,
                                    fontSize: isCompact ? 12.5 : 14.0,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    )
                  else
                    const SizedBox.shrink(),

                  const Spacer(),

                  // 2. STEP DOTS (center, non-compact only)
                  if (!isCompact && showStepDots)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: List.generate(totalSteps, (index) {
                        final isActive = index == currentStep;
                        final isCompleted = index < currentStep;

                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          margin: const EdgeInsets.symmetric(horizontal: 4.0),
                          width: isActive ? 24.0 : 8.0,
                          height: 8.0,
                          decoration: BoxDecoration(
                            color: isActive
                                ? AppColors.primary
                                : (isCompleted
                                    ? AppColors.primary.withValues(alpha: 0.4)
                                    : AppColors.border),
                            borderRadius: BorderRadius.circular(4.0),
                          ),
                        );
                      }),
                    ),

                  const Spacer(),

                  // 3. NEXT / SAVE BUTTON
                  MouseRegion(
                    cursor: isSaving ? SystemMouseCursors.basic : SystemMouseCursors.click,
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: isSaving ? null : onNextPressed,
                        borderRadius: BorderRadius.circular(12.0),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: EdgeInsets.symmetric(
                            horizontal: isCompact ? 14.0 : 24.0,
                            vertical: isCompact ? 10.0 : 12.0,
                          ),
                          decoration: BoxDecoration(
                            gradient: isSaving
                                ? null
                                : const LinearGradient(
                                    colors: [AppColors.primary, Color(0xFF5B62F4)],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                            color: isSaving ? AppColors.border : AppColors.primary,
                            borderRadius: BorderRadius.circular(12.0),
                            boxShadow: isSaving
                                ? []
                                : [
                                    BoxShadow(
                                      color: AppColors.primary.withValues(alpha: 0.35),
                                      blurRadius: 12,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (isSaving)
                                const SizedBox(
                                  width: 18.0,
                                  height: 18.0,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.2,
                                    color: Colors.white,
                                  ),
                                )
                              else ...[
                                Text(
                                  computedNextText,
                                  style: AppTextStyles.body2.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    fontSize: isCompact ? 12.5 : 14.0,
                                  ),
                                ),
                                const SizedBox(width: 6.0),
                                Icon(
                                  isLastStep ? Icons.check_circle_rounded : Icons.arrow_forward_rounded,
                                  size: 16.0,
                                  color: Colors.white,
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
