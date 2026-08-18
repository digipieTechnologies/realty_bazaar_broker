// File: lib/modules/dashboard/widgets/leads/lead_action_button.dart
// Purpose: Common, reusable action button widget for lead dashboard.

import 'package:flutter/material.dart';
import '../../../../app/app_colors.dart';
import '../../../../app/app_text_styles.dart';

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
      return OutlinedButton.icon(
        style: OutlinedButton.styleFrom(
          minimumSize: Size(0, height),
          side: const BorderSide(color: AppColors.border),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10.0),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
        ),
        onPressed: onPressed,
        icon: icon != null
            ? Icon(icon, size: 18.0, color: AppColors.textPrimary)
            : const SizedBox.shrink(),
        label: Text(
          label,
          style: AppTextStyles.button.copyWith(
            color: AppColors.textPrimary,
            fontSize: 13.0,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }

    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        minimumSize: Size(0, height),
        backgroundColor: backgroundColor,
        foregroundColor: foregroundColor,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10.0),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 18.0),
      ),
      onPressed: onPressed,
      icon: icon != null
          ? Icon(icon, size: 18.0, color: foregroundColor)
          : const SizedBox.shrink(),
      label: Text(
        label,
        style: AppTextStyles.button.copyWith(
          color: foregroundColor,
          fontSize: 13.0,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
