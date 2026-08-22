// File: lib/widgets/common/common_app_bar.dart
// Purpose: Centralized common app bar component for consistent static theme, icon style, and branding across the app.

import 'package:flutter/material.dart';
import '../../app/app_colors.dart';
import '../../app/app_text_styles.dart';
import '../buttons/app_back_button.dart';

class CommonAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String? title;
  final Widget? titleWidget;
  final String? subtitle;
  final Widget? leading;
  final bool showBackButton;
  final VoidCallback? onBackPressed;
  final IconData backIcon;
  final List<Widget>? actions;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final double elevation;
  final bool centerTitle;
  final PreferredSizeWidget? bottom;
  final Widget? logo;
  final double toolbarHeight;

  const CommonAppBar({
    super.key,
    this.title,
    this.titleWidget,
    this.subtitle,
    this.leading,
    this.showBackButton = true,
    this.onBackPressed,
    this.backIcon = Icons.chevron_left_rounded,
    this.actions,
    this.backgroundColor,
    this.foregroundColor,
    this.elevation = 0.0,
    this.centerTitle = false,
    this.bottom,
    this.logo,
    this.toolbarHeight = kToolbarHeight,
  });

  @override
  Size get preferredSize => Size.fromHeight(
        toolbarHeight + (bottom?.preferredSize.height ?? 0.0),
      );

  @override
  Widget build(BuildContext context) {
    final ModalRoute<dynamic>? parentRoute = ModalRoute.of(context);
    final bool canPop = parentRoute?.canPop ?? false;
    final bool effectiveShowBackButton =
        showBackButton && (canPop || onBackPressed != null);

    final effectiveFgColor = foregroundColor ?? AppColors.textPrimary;
    final effectiveBgColor = backgroundColor ?? AppColors.surface;

    Widget? leadingWidget = leading;
    if (leadingWidget == null && effectiveShowBackButton) {
      leadingWidget = AppBackButton(
        icon: backIcon,
        color: effectiveFgColor,
        onPressed: onBackPressed,
      );
    }

    Widget? effectiveTitleWidget = titleWidget;
    if (effectiveTitleWidget == null && (title != null || logo != null)) {
      effectiveTitleWidget = Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (logo != null) ...[
            logo!,
            const SizedBox(width: 10.0),
          ],
          if (title != null)
            Flexible(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: centerTitle
                    ? CrossAxisAlignment.center
                    : CrossAxisAlignment.start,
                children: [
                  Text(
                    title!,
                    style: AppTextStyles.heading3.copyWith(
                      fontWeight: FontWeight.bold,
                      color: effectiveFgColor,
                      fontSize: 18.0,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (subtitle != null && subtitle!.isNotEmpty) ...[
                    const SizedBox(height: 2.0),
                    Text(
                      subtitle!,
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textSecondary,
                        fontSize: 12.0,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
        ],
      );
    }

    List<Widget>? effectiveActions = actions;
    if (effectiveActions != null && effectiveActions.isNotEmpty) {
      effectiveActions = [
        ...effectiveActions,
        const SizedBox(width: 8.0),
      ];
    }

    return AppBar(
      backgroundColor: effectiveBgColor,
      foregroundColor: effectiveFgColor,
      elevation: elevation,
      centerTitle: centerTitle,
      automaticallyImplyLeading: false,
      leading: leadingWidget,
      title: effectiveTitleWidget,
      actions: effectiveActions,
      bottom: bottom,
      surfaceTintColor: Colors.transparent,
      titleSpacing:
          (leadingWidget != null) ? 0.0 : NavigationToolbar.kMiddleSpacing,
    );
  }
}
