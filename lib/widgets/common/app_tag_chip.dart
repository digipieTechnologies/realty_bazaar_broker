// File: lib/widgets/common/app_tag_chip.dart
// Purpose: Reusable, modern, colorful tag chip widget with rounded borders, soft gradients, and optional action/remove icons.

import 'package:flutter/material.dart';

import '../../app/app_colors.dart';
import '../../app/app_text_styles.dart';

class AppTagChip extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;
  final IconData? icon;
  final IconData? trailingIcon;
  final bool isSelected;
  final Color? backgroundColor;
  final Color? textColor;
  final Color? borderColor;
  final EdgeInsetsGeometry? margin;

  const AppTagChip({
    super.key,
    required this.label,
    this.onTap,
    this.onDelete,
    this.icon,
    this.trailingIcon,
    this.isSelected = false,
    this.backgroundColor,
    this.textColor,
    this.borderColor,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveBg = backgroundColor ?? (isSelected ? AppColors.primary : AppColors.primary.withValues(alpha: 0.08));
    final effectiveTextColor = textColor ?? (isSelected ? Colors.white : AppColors.primary);
    final effectiveBorder = borderColor ?? (isSelected ? AppColors.primary : AppColors.primary.withValues(alpha: 0.18));

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      margin: margin ?? EdgeInsets.zero,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap ?? onDelete,
          borderRadius: BorderRadius.circular(20.0),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 4.5),
            decoration: BoxDecoration(
              color: effectiveBg,
              borderRadius: BorderRadius.circular(20.0),
              border: Border.all(color: effectiveBorder, width: 1.0),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.25),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[Icon(icon, size: 14.0, color: effectiveTextColor), const SizedBox(width: 6.0)],
                Flexible(
                  child: Text(
                    label,
                    style: AppTextStyles.caption.copyWith(
                      fontWeight: FontWeight.w600,
                      fontSize: 13.0,
                      color: effectiveTextColor,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (onDelete != null) ...[
                  const SizedBox(width: 6.0),
                  GestureDetector(
                    onTap: onDelete,
                    child: Container(
                      padding: const EdgeInsets.all(2.0),
                      decoration: BoxDecoration(
                        color: effectiveTextColor.withValues(alpha: 0.18),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.close_rounded, size: 12.0, color: effectiveTextColor),
                    ),
                  ),
                ],
                if (trailingIcon != null) ...[
                  const SizedBox(width: 6.0),
                  Icon(trailingIcon, size: 12.0, color: effectiveTextColor),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
