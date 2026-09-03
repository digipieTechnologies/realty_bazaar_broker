// File: lib/modules/dashboard/widgets/leads/lead_action_button.dart
// Purpose: Common, reusable action button widget for lead dashboard using unified AppButton.

import 'package:flutter/material.dart';

import '../../../../app/app_colors.dart';
import '../../../../app/app_text_styles.dart';
import '../../../../widgets/buttons/app_button.dart';

class LeadActionButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback onPressed;
  final Color backgroundColor;
  final Color foregroundColor;
  final bool isSecondary;
  final double height;

  const LeadActionButton({
    super.key,
    required this.label,
    this.icon,
    required this.onPressed,
    this.backgroundColor = AppColors.primary,
    this.foregroundColor = Colors.white,
    this.isSecondary = false,
    this.height = 42.0,
  });

  @override
  Widget build(BuildContext context) {
    if (isSecondary) {
      return AppButton.outline(
        text: label,
        iconData: icon,
        onPressed: onPressed,
        height: height,
        borderRadius: 10.0,
        borderColor: AppColors.border,
        textColor: AppColors.textPrimary,
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        textStyle: AppTextStyles.button.copyWith(
          color: AppColors.textPrimary,
          fontSize: 13.0,
          fontWeight: FontWeight.w600,
        ),
      );
    }

    return AppButton.solid(
      text: label,
      iconData: icon,
      onPressed: onPressed,
      height: height,
      borderRadius: 10.0,
      color: backgroundColor,
      textColor: foregroundColor,
      padding: const EdgeInsets.symmetric(horizontal: 18.0),
      textStyle: AppTextStyles.button.copyWith(
        color: foregroundColor,
        fontSize: 13.0,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}
