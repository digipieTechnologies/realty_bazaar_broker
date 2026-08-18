// File: lib/widgets/buttons/app_button.dart
// Purpose: Main unified button widget across the entire application with theme support, loading states, variants, and responsive styling.

import 'package:flutter/material.dart';
import '../../app/app_colors.dart';
import '../../app/app_text_styles.dart';
import '../containers/container_corner.dart';
import '../loaders/app_loader.dart';

enum AppButtonVariant { solid, gradient, outline, secondary, text, danger }

class AppButton extends StatelessWidget {
  final String? text;
  final Widget? child;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final Widget? icon;
  final IconData? iconData;
  final bool isLoading;
  final bool isDisabled;
  final double? width;
  final double height;
  final double borderRadius;
  final Color? color;
  final Color? textColor;
  final List<Color>? gradientColors;
  final Color? borderColor;
  final TextStyle? textStyle;
  final EdgeInsets? padding;
  final double iconSpacing;
  final String? tooltip;
  final double elevation;

  const AppButton({
    super.key,
    this.text,
    this.child,
    this.onPressed,
    this.variant = AppButtonVariant.solid,
    this.icon,
    this.iconData,
    this.isLoading = false,
    this.isDisabled = false,
    this.width,
    this.height = 48.0,
    this.borderRadius = 10.0,
    this.color,
    this.textColor,
    this.gradientColors,
    this.borderColor,
    this.textStyle,
    this.padding,
    this.iconSpacing = 8.0,
    this.tooltip,
    this.elevation = 0.0,
  });

  // Handy named constructors for clean code usage
  factory AppButton.solid({
    Key? key,
    String? text,
    VoidCallback? onPressed,
    Widget? icon,
    IconData? iconData,
    bool isLoading = false,
    bool isDisabled = false,
    double? width,
    double height = 48.0,
    double borderRadius = 10.0,
    Color? color,
    Color? textColor,
    TextStyle? textStyle,
    EdgeInsets? padding,
  }) {
    return AppButton(
      key: key,
      text: text,
      onPressed: onPressed,
      variant: AppButtonVariant.solid,
      icon: icon,
      iconData: iconData,
      isLoading: isLoading,
      isDisabled: isDisabled,
      width: width,
      height: height,
      borderRadius: borderRadius,
      color: color,
      textColor: textColor,
      textStyle: textStyle,
      padding: padding,
    );
  }

  factory AppButton.outline({
    Key? key,
    String? text,
    VoidCallback? onPressed,
    Widget? icon,
    IconData? iconData,
    bool isLoading = false,
    bool isDisabled = false,
    double? width,
    double height = 48.0,
    double borderRadius = 10.0,
    Color? borderColor,
    Color? textColor,
    TextStyle? textStyle,
    EdgeInsets? padding,
  }) {
    return AppButton(
      key: key,
      text: text,
      onPressed: onPressed,
      variant: AppButtonVariant.outline,
      icon: icon,
      iconData: iconData,
      isLoading: isLoading,
      isDisabled: isDisabled,
      width: width,
      height: height,
      borderRadius: borderRadius,
      borderColor: borderColor,
      textColor: textColor,
      textStyle: textStyle,
      padding: padding,
    );
  }

  factory AppButton.gradient({
    Key? key,
    String? text,
    VoidCallback? onPressed,
    Widget? icon,
    IconData? iconData,
    bool isLoading = false,
    bool isDisabled = false,
    double? width,
    double height = 48.0,
    double borderRadius = 10.0,
    List<Color>? gradientColors,
    TextStyle? textStyle,
    EdgeInsets? padding,
  }) {
    return AppButton(
      key: key,
      text: text,
      onPressed: onPressed,
      variant: AppButtonVariant.gradient,
      icon: icon,
      iconData: iconData,
      isLoading: isLoading,
      isDisabled: isDisabled,
      width: width,
      height: height,
      borderRadius: borderRadius,
      gradientColors: gradientColors,
      textStyle: textStyle,
      padding: padding,
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool effectivelyDisabled = isDisabled || isLoading || onPressed == null;

    // Resolve colors & styles based on theme and variant
    Color resolvedBgColor = Colors.transparent;
    List<Color> resolvedGradient = [Colors.transparent, Colors.transparent];
    Color resolvedBorderColor = Colors.transparent;

    TextStyle defaultBaseStyle = textStyle ?? AppTextStyles.button;
    Color resolvedTextColor = textColor ?? defaultBaseStyle.color ?? AppColors.surface;

    if (effectivelyDisabled) {
      resolvedBgColor = AppColors.border;
      resolvedTextColor = AppColors.textSecondary;
    } else {
      switch (variant) {
        case AppButtonVariant.solid:
          resolvedBgColor = color ?? AppColors.primary;
          resolvedTextColor = textColor ?? AppColors.surface;
          break;

        case AppButtonVariant.gradient:
          resolvedGradient = gradientColors ?? AppColors.primaryGradient;
          resolvedTextColor = textColor ?? AppColors.surface;
          break;

        case AppButtonVariant.outline:
          resolvedBgColor = color ?? Colors.transparent;
          resolvedBorderColor = borderColor ?? AppColors.border;
          if (textColor != null) {
            resolvedTextColor = textColor!;
          } else if (textStyle?.color != null &&
              textStyle!.color != AppColors.surface &&
              textStyle!.color != Colors.white) {
            resolvedTextColor = textStyle!.color!;
          } else {
            resolvedTextColor = AppColors.primary;
          }
          break;

        case AppButtonVariant.secondary:
          resolvedBgColor = color ?? AppColors.primary.withValues(alpha: 0.1);
          resolvedTextColor = textColor ?? AppColors.primary;
          break;

        case AppButtonVariant.text:
          resolvedBgColor = Colors.transparent;
          resolvedTextColor = textColor ?? AppColors.primary;
          break;

        case AppButtonVariant.danger:
          resolvedBgColor = color ?? const Color(0xFFEF4444);
          resolvedTextColor = textColor ?? AppColors.surface;
          break;
      }
    }

    final TextStyle resolvedStyle = defaultBaseStyle.copyWith(
      color: resolvedTextColor,
      fontWeight: defaultBaseStyle.fontWeight ?? FontWeight.bold,
    );

    // Build icon widget
    Widget? effectiveIcon = icon;
    if (effectiveIcon == null && iconData != null) {
      effectiveIcon = Icon(
        iconData,
        size: (resolvedStyle.fontSize ?? 14.0) + 4.0,
        color: resolvedTextColor,
      );
    }

    // Build internal content
    Widget bodyContent;
    if (child != null) {
      bodyContent = child!;
    } else {
      bodyContent = Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (isLoading) ...[
            AppLoader(
              size: (resolvedStyle.fontSize ?? 14.0) + 4.0,
              color: resolvedTextColor,
            ),
            SizedBox(width: iconSpacing),
          ] else if (effectiveIcon != null) ...[
            effectiveIcon,
            if (text != null && text!.isNotEmpty) SizedBox(width: iconSpacing),
          ],
          if (text != null && text!.isNotEmpty)
            Flexible(
              child: Text(
                text!,
                style: resolvedStyle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
        ],
      );
    }

    Widget buttonWidget = ContainerCorner(
      width: width,
      height: height,
      color: variant == AppButtonVariant.gradient && !effectivelyDisabled ? null : resolvedBgColor,
      colors: variant == AppButtonVariant.gradient && !effectivelyDisabled ? resolvedGradient : [Colors.transparent, Colors.transparent],
      borderColor: resolvedBorderColor,
      borderWidth: resolvedBorderColor != Colors.transparent ? 1.5 : 0.0,
      borderRadius: borderRadius,
      padding: padding ?? const EdgeInsets.symmetric(horizontal: 10.0),
      alignment: Alignment.center,
      onTap: effectivelyDisabled ? null : onPressed,
      tooltip: tooltip,
      child: bodyContent,
    );

    return buttonWidget;
  }
}
