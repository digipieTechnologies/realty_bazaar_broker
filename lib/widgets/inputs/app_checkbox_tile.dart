// File: lib/widgets/inputs/app_checkbox_tile.dart
// Purpose: Reusable common checkbox tile component featuring tap target, active color customization, and custom typography.

import 'package:flutter/material.dart';

import '../../app/app_colors.dart';
import '../../app/app_text_styles.dart';

class AppCheckboxTile extends StatelessWidget {
  final bool value;
  final ValueChanged<bool?> onChanged;
  final String label;
  final TextStyle? labelStyle;
  final Color activeColor;
  final double borderRadius;
  final EdgeInsetsGeometry padding;

  const AppCheckboxTile({
    super.key,
    required this.value,
    required this.onChanged,
    required this.label,
    this.labelStyle,
    this.activeColor = AppColors.primary,
    this.borderRadius = 4.0,
    this.padding = const EdgeInsets.symmetric(vertical: 4.0),
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => onChanged(!value),
      borderRadius: BorderRadius.circular(8.0),
      child: Padding(
        padding: padding,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 24.0,
              height: 24.0,
              child: Checkbox(
                value: value,
                onChanged: onChanged,
                activeColor: activeColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(borderRadius),
                ),
              ),
            ),
            const SizedBox(width: 8.0),
            Text(
              label,
              style: labelStyle ??
                  AppTextStyles.body2.copyWith(
                    fontSize: 14.0,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
