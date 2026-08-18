// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import '../../app/app_colors.dart';
import '../../app/app_assets.dart';

class AppLogo extends StatelessWidget {
  final double size;
  final double? iconSize;
  final BorderRadius? borderRadius;
  final Color? backgroundColor;
  final Color? iconColor;

  const AppLogo({
    super.key,
    this.size = 40.0,
    this.iconSize,
    this.borderRadius,
    this.backgroundColor,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveIconSize = iconSize ?? (size * 0.55);
    final effectiveBorderRadius =
        borderRadius ?? BorderRadius.circular(size * 0.28);
    final effectiveBgColor =
        backgroundColor ?? AppColors.primary.withOpacity(0.08);
    final effectiveIconColor = iconColor ?? AppColors.primary;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: effectiveBgColor,
        borderRadius: effectiveBorderRadius,
      ),
      alignment: Alignment.center,
      child: Image.asset(
        AppAssets.logo,
        color: effectiveIconColor,
        width: effectiveIconSize,
        height: effectiveIconSize,
        fit: BoxFit.contain,
      ),
    );
  }
}
