// File: lib/widgets/buttons/app_back_button.dart
// Purpose: Modular reusable App Back Button widget with consistent size, icon, mouse cursor, tooltip, and pop action across the app.

import 'package:flutter/material.dart';

import '../../app/app_colors.dart';

class AppBackButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final Color? color;
  final double size;
  final IconData icon;

  const AppBackButton({
    super.key,
    this.onPressed,
    this.color,
    this.size = 28.0,
    this.icon = Icons.chevron_left_rounded,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? AppColors.textPrimary;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: IconButton(
        icon: Icon(icon, color: effectiveColor, size: size),
        tooltip: MaterialLocalizations.of(context).backButtonTooltip,
        onPressed: () {
          if (onPressed != null) {
            onPressed!();
          } else {
            Navigator.of(context).maybePop();
          }
        },
      ),
    );
  }
}
