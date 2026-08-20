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
  final bool useWhiteLogo;

  const AppLogo({
    super.key,
    this.size = 40.0,
    this.iconSize,
    this.borderRadius,
    this.backgroundColor,
    this.iconColor,
    this.useWhiteLogo = false,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveIconSize = iconSize ?? (size * 0.75);
    final effectiveBorderRadius =
        borderRadius ?? BorderRadius.circular(size * 0.28);
    final effectiveBgColor =
        backgroundColor ?? AppColors.primary.withOpacity(0.08);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: effectiveBgColor,
        borderRadius: effectiveBorderRadius,
      ),
      alignment: Alignment.center,
      child: Image.asset(
        useWhiteLogo ? AppAssets.logoWhite : AppAssets.logoTransparent,
        color: iconColor,
        width: effectiveIconSize,
        height: effectiveIconSize,
        fit: BoxFit.contain,
      ),
    );
  }
}
