// File: lib/modules/dashboard/widgets/setup_step_tile_widget.dart
// Purpose: Modular reusable tile widget displaying an onboarding setup step card with gradient icon background, white circular asset icon support, minor description, and status pill.

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../../app/app_colors.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../providers/dashboard/dashboard_provider.dart';

class SetupStepTileWidget extends StatelessWidget {
  final OnboardingStep step;
  final VoidCallback onTap;

  const SetupStepTileWidget({
    super.key,
    required this.step,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final titleText = context.tr('step_${step.id}');
    final descText = context.tr('step_${step.id}_desc');

    final primaryColor = step.gradientColors.first;
    final secondaryColor = step.gradientColors.length > 1
        ? step.gradientColors[1]
        : step.gradientColors.first;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14.0),
          child: Container(
            padding: const EdgeInsets.all(12.0),
            decoration: BoxDecoration(
              color: step.isCompleted
                  ? AppColors.setupTileSuccessBg
                  : primaryColor.withValues(alpha: 0.03),
              borderRadius: BorderRadius.circular(14.0),
              border: Border.all(
                color: step.isCompleted
                    ? AppColors.setupTileSuccessBorder
                    : primaryColor.withValues(alpha: 0.25),
                width: 1.0,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 6.0,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Icon Container (Vibrant Gradient background + white SVG icon)
                Container(
                  width: 44.0,
                  height: 44.0,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [primaryColor, secondaryColor],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12.0),
                    boxShadow: [
                      BoxShadow(
                        color: primaryColor.withValues(alpha: 0.25),
                        blurRadius: 6.0,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: SvgPicture.asset(
                    step.svgAssetPath,
                    width: 22.0,
                    height: 22.0,
                    colorFilter: const ColorFilter.mode(
                      Colors.white,
                      BlendMode.srcIn,
                    ),
                  ),
                ),
                const SizedBox(width: 12.0),

                // Title & Minor Description
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        titleText,
                        style: const TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3.0),
                      Text(
                        descText,
                        style: const TextStyle(
                          fontSize: 11.0,
                          fontWeight: FontWeight.w400,
                          color: AppColors.textSecondary,
                          height: 1.25,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8.0),

                // Status Badge / Check Icon
                if (step.isCompleted)
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 4.0),
                    child: Icon(
                      Icons.check_circle_rounded,
                      color: AppColors.statusSuccessText,
                      size: 24.0,
                    ),
                  )
                else
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8.0,
                      vertical: 4.0,
                    ),
                    decoration: BoxDecoration(
                      color: primaryColor.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(20.0),
                      border: Border.all(
                        color: primaryColor.withValues(alpha: 0.3),
                        width: 1.0,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          context.tr('start_setup'),
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.bold,
                            color: primaryColor,
                          ),
                        ),
                        const SizedBox(width: 2.0),
                        Icon(
                          Icons.chevron_right_rounded,
                          color: primaryColor,
                          size: 14.0,
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
