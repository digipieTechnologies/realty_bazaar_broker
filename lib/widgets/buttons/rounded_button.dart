// File: lib/widgets/buttons/rounded_button.dart
// Purpose: Backward-compatible wrapper delegating to central AppButton design system.

import 'package:flutter/material.dart';
import 'app_button.dart';

typedef ButtonVariant = AppButtonVariant;

class RoundedButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final Widget? icon;
  final bool isLoading;
  final bool isDisabled;
  final double? width;
  final double height;
  final double borderRadius;
  final Color? color;
  final List<Color>? gradientColors;
  final Color? borderColor;
  final TextStyle? textStyle;
  final EdgeInsets? padding;
  final double iconSpacing;

  const RoundedButton({
    super.key,
    required this.text,
    this.onPressed,
    this.variant = AppButtonVariant.solid,
    this.icon,
    this.isLoading = false,
    this.isDisabled = false,
    this.width,
    this.height = 48.0,
    this.borderRadius = 8.0,
    this.color,
    this.gradientColors,
    this.borderColor,
    this.textStyle,
    this.padding,
    this.iconSpacing = 8.0,
  });

  @override
  Widget build(BuildContext context) {
    return AppButton(
      text: text,
      onPressed: onPressed,
      variant: variant,
      icon: icon,
      isLoading: isLoading,
      isDisabled: isDisabled,
      width: width,
      height: height,
      borderRadius: borderRadius,
      color: color,
      gradientColors: gradientColors,
      borderColor: borderColor,
      textStyle: textStyle,
      padding: padding,
      iconSpacing: iconSpacing,
    );
  }
}
