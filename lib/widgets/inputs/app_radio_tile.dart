// File: lib/widgets/inputs/app_radio_tile.dart
// Purpose: Reusable common radio tile component featuring selection state, custom colors (primary when selected, light black/secondary when unselected), and tap callback.

import 'package:flutter/material.dart';

import '../../app/app_colors.dart';
import '../../app/app_text_styles.dart';

class AppRadioTile extends StatelessWidget {
  final bool isSelected;
  final String label;
  final VoidCallback onTap;
  final TextStyle? labelStyle;
  final EdgeInsetsGeometry padding;

  const AppRadioTile({
    super.key,
    required this.isSelected,
    required this.label,
    required this.onTap,
    this.labelStyle,
    this.padding = const EdgeInsets.symmetric(horizontal: 4.0, vertical: 6.0),
  });

  @override
  Widget build(BuildContext context) {
    // Custom radio circle styling
    final Color borderAndDotColor =
        isSelected ? AppColors.primary : AppColors.textSecondary.withValues(alpha: 0.6);
    final Color labelColor =
        isSelected ? AppColors.textPrimary : AppColors.textSecondary;
    final FontWeight labelFontWeight =
        isSelected ? FontWeight.bold : FontWeight.w500;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8.0),
      child: Padding(
        padding: padding,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Custom Radio Circle Button
            Container(
              width: 20.0,
              height: 20.0,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: borderAndDotColor,
                  width: 2.0,
                ),
              ),
              child: isSelected
                  ? Center(
                      child: Container(
                        width: 10.0,
                        height: 10.0,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.primary,
                        ),
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 8.0),
            Text(
              label,
              style: labelStyle ??
                  AppTextStyles.body2.copyWith(
                    fontSize: 14.0,
                    fontWeight: labelFontWeight,
                    color: labelColor,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
