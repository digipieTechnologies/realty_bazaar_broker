// File: lib/widgets/buttons/app_circular_chevron.dart
// Purpose: Reusable circular chevron icon toggle button widget for expanding/collapsing cards, dropdowns, and sections.

import 'package:flutter/material.dart';
import '../../app/app_colors.dart';

class AppCircularChevron extends StatelessWidget {
  final bool isExpanded;
  final IconData collapsedIcon;
  final IconData expandedIcon;
  final Color? iconColor;
  final Color? backgroundColor;
  final double iconSize;
  final double padding;
  final VoidCallback? onTap;

  const AppCircularChevron({
    super.key,
    this.isExpanded = false,
    this.collapsedIcon = Icons.keyboard_arrow_down_rounded,
    this.expandedIcon = Icons.keyboard_arrow_up_rounded,
    this.iconColor,
    this.backgroundColor,
    this.iconSize = 20.0,
    this.padding = 4.0,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveIconColor = iconColor ?? AppColors.textSecondary;
    final effectiveBgColor = backgroundColor ?? Colors.white.withValues(alpha: 0.8);

    Widget chevronWidget = Container(
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        color: effectiveBgColor,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 4.0,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: AnimatedRotation(
        turns: isExpanded ? 0.5 : 0.0,
        duration: const Duration(milliseconds: 200),
        child: Icon(
          collapsedIcon,
          color: effectiveIconColor,
          size: iconSize,
        ),
      ),
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: chevronWidget,
      );
    }

    return chevronWidget;
  }
}
