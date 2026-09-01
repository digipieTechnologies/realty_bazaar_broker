// File: lib/widgets/buttons/app_floating_action_button.dart
// Purpose: Reusable Floating Action Button (FAB) following the application design system.

import 'package:flutter/material.dart';

import '../../app/app_colors.dart';
import '../../app/app_text_styles.dart';

class AppFloatingActionButton extends StatelessWidget {
  final VoidCallback onPressed;
  final String? label;
  final IconData icon;
  final Color backgroundColor;
  final Color foregroundColor;
  final double elevation;
  final bool isExtended;
  final String? tooltip;

  const AppFloatingActionButton({
    super.key,
    required this.onPressed,
    this.label,
    this.icon = Icons.add_rounded,
    this.backgroundColor = AppColors.primary,
    this.foregroundColor = Colors.white,
    this.elevation = 4.0,
    this.isExtended = true,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    if (label != null && label!.isNotEmpty && isExtended) {
      return FloatingActionButton.extended(
        onPressed: onPressed,
        label: Text(
          label!,
          style: AppTextStyles.button.copyWith(
            color: foregroundColor,
            fontWeight: FontWeight.bold,
            fontSize: 13.5,
            letterSpacing: 0.3,
          ),
        ),
        icon: Icon(icon, color: foregroundColor, size: 20.0),
        backgroundColor: backgroundColor,
        elevation: elevation,
        tooltip: tooltip ?? label,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30.0)),
      );
    }

    return FloatingActionButton(
      onPressed: onPressed,
      backgroundColor: backgroundColor,
      elevation: elevation,
      tooltip: tooltip ?? label,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
      child: Icon(icon, color: foregroundColor, size: 22.0),
    );
  }
}
