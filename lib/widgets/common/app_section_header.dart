// File: lib/widgets/common/app_section_header.dart
// Purpose: Reusable section category header widget with icon container badge, uppercase title, optional trailing action, and customizable padding.

import 'package:flutter/material.dart';
import '../../app/app_colors.dart';
import '../../app/app_text_styles.dart';

class AppSectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget? trailing;
  final EdgeInsetsGeometry padding;
  final Color? iconColor;
  final Color? iconBgColor;

  const AppSectionHeader({
    super.key,
    required this.title,
    required this.icon,
    this.trailing,
    this.padding = const EdgeInsets.only(bottom: 12.0),
    this.iconColor,
    this.iconBgColor,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveIconColor = iconColor ?? AppColors.primary;
    final effectiveIconBgColor = iconBgColor ?? AppColors.primary.withValues(alpha: 0.1);

    return Padding(
      padding: padding,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6.0),
            decoration: BoxDecoration(
              color: effectiveIconBgColor,
              borderRadius: BorderRadius.circular(8.0),
            ),
            child: Icon(
              icon,
              size: 16.0,
              color: effectiveIconColor,
            ),
          ),
          const SizedBox(width: 10.0),
          Expanded(
            child: Text(
              title.toUpperCase(),
              style: AppTextStyles.caption.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: 12.0,
                letterSpacing: 1.0,
                color: AppColors.textSecondary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: 12.0),
            trailing!,
          ],
        ],
      ),
    );
  }
}
