// File: lib/widgets/common/app_empty_state_widget.dart
// Purpose: Reusable, modern, and professional empty state view for lists, tables, and screens when data is null or empty.

import 'package:flutter/material.dart';
import '../../app/app_colors.dart';
import '../../app/app_text_styles.dart';

class AppEmptyStateWidget extends StatelessWidget {
  final IconData? icon;
  final Widget? iconWidget;
  final String title;
  final String? description;
  final Widget? action;
  final double iconSize;
  final Color? iconColor;
  final Color? iconBackgroundColor;
  final EdgeInsetsGeometry padding;

  const AppEmptyStateWidget({
    super.key,
    this.icon,
    this.iconWidget,
    required this.title,
    this.description,
    this.action,
    this.iconSize = 32.0,
    this.iconColor,
    this.iconBackgroundColor,
    this.padding = const EdgeInsets.symmetric(vertical: 36.0, horizontal: 20.0),
  });

  @override
  Widget build(BuildContext context) {
    final themeIconColor = iconColor ?? AppColors.primary;
    final themeBgColor = iconBackgroundColor ?? themeIconColor.withValues(alpha: 0.08);

    return Padding(
      padding: padding,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Styled Icon Badge
            if (iconWidget != null || icon != null) ...[
              Container(
                padding: const EdgeInsets.all(14.0),
                decoration: BoxDecoration(
                  color: themeBgColor,
                  shape: BoxShape.circle,
                ),
                child: iconWidget ??
                    Icon(
                      icon,
                      size: iconSize,
                      color: themeIconColor,
                    ),
              ),
              const SizedBox(height: 14.0),
            ],

            // Title
            Text(
              title,
              style: AppTextStyles.heading3.copyWith(
                fontSize: 15.0,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),

            // Description
            if (description != null && description!.isNotEmpty) ...[
              const SizedBox(height: 5.0),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 320.0),
                child: Text(
                  description!,
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textMuted,
                    fontSize: 12.0,
                    height: 1.35,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],

            // Optional Action Button
            if (action != null) ...[
              const SizedBox(height: 18.0),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}
