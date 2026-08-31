// File: lib/widgets/dialogs/app_base_dialog.dart
// Purpose: Premium common dialog template enforcing consistent theme, fixed header with icon & close button, edge-to-edge dividers, scrollable body, and optional fixed footer across the app.

import 'package:flutter/material.dart';

import '../../app/app_colors.dart';
import '../../app/app_text_styles.dart';

class AppBaseDialog extends StatelessWidget {
  final String? title;
  final Widget? titleWidget;
  final String? subtitle;
  final IconData? headerIcon;
  final Widget? headerIconWidget;
  final List<Widget>? headerActions;
  final bool showCloseButton;
  final VoidCallback? onClose;
  final bool isCloseDisabled;
  final Widget content;
  final Widget? footer;
  final double maxWidth;
  final double maxHeightFactor;
  final EdgeInsetsGeometry? headerPadding;
  final EdgeInsetsGeometry? contentPadding;
  final EdgeInsetsGeometry? footerPadding;
  final EdgeInsetsGeometry? padding; // Legacy fallback for contentPadding
  final bool showDivider;
  final bool showFooterDivider;
  final bool isScrollable;

  const AppBaseDialog({
    super.key,
    this.title,
    this.titleWidget,
    this.subtitle,
    this.headerIcon,
    this.headerIconWidget,
    this.headerActions,
    this.showCloseButton = true,
    this.onClose,
    this.isCloseDisabled = false,
    required this.content,
    this.footer,
    this.maxWidth = 580.0,
    this.maxHeightFactor = 0.88,
    this.headerPadding,
    this.contentPadding,
    this.footerPadding,
    this.padding,
    this.showDivider = true,
    this.showFooterDivider = true,
    this.isScrollable = true,
  });

  static Future<T?> show<T>({
    required BuildContext context,
    required Widget child,
    bool barrierDismissible = true,
  }) {
    return showDialog<T>(
      context: context,
      barrierDismissible: barrierDismissible,
      builder: (context) => child,
    );
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final isDesktop = mediaQuery.size.width >= 768;
    final dialogWidth = isDesktop ? maxWidth : mediaQuery.size.width * 0.94;
    final dialogMaxHeight = mediaQuery.size.height * (isDesktop ? maxHeightFactor : 0.92);

    final resolvedHeaderPadding =
        headerPadding ??
        (isDesktop
            ? const EdgeInsets.fromLTRB(20.0, 18.0, 16.0, 14.0)
            : const EdgeInsets.fromLTRB(14.0, 12.0, 10.0, 10.0));

    final resolvedContentPadding =
        contentPadding ?? padding ?? (isDesktop ? const EdgeInsets.all(20.0) : const EdgeInsets.all(12.0));

    final resolvedFooterPadding =
        footerPadding ??
        (isDesktop
            ? const EdgeInsets.all(16.0)
            : const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10.0));

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: isDesktop
          ? const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0)
          : const EdgeInsets.symmetric(horizontal: 10.0, vertical: 16.0),
      child: Container(
        width: dialogWidth,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(isDesktop ? 20.0 : 16.0),
          border: Border.all(color: AppColors.border, width: 1.0),
        ),
        clipBehavior: Clip.antiAlias,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: dialogMaxHeight),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Fixed App Theme Header
              Padding(
                padding: resolvedHeaderPadding,
                child: Row(
                  children: [
                    // Icon badge container
                    if (headerIconWidget != null) ...[
                      headerIconWidget!,
                      const SizedBox(width: 10.0),
                    ] else if (headerIcon != null) ...[
                      Container(
                        padding: const EdgeInsets.all(8.0),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10.0),
                        ),
                        child: Icon(headerIcon, color: AppColors.primary, size: 20.0),
                      ),
                      const SizedBox(width: 10.0),
                    ],

                    // Title & Subtitle / Title Widget
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (titleWidget != null)
                            titleWidget!
                          else if (title != null)
                            Text(
                              title!,
                              style: AppTextStyles.heading3.copyWith(
                                fontWeight: FontWeight.bold,
                                fontSize: 17.0,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          if (subtitle != null && subtitle!.trim().isNotEmpty) ...[
                            const SizedBox(height: 2.0),
                            Text(
                              subtitle!,
                              style: AppTextStyles.caption.copyWith(
                                color: AppColors.textSecondary,
                                fontSize: 11.5,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ],
                      ),
                    ),

                    // Header Actions (if any)
                    if (headerActions != null && headerActions!.isNotEmpty) ...[
                      const SizedBox(width: 8.0),
                      Row(mainAxisSize: MainAxisSize.min, children: headerActions!),
                    ],

                    // Close button icon
                    if (showCloseButton) ...[
                      const SizedBox(width: 8.0),
                      IconButton(
                        onPressed: isCloseDisabled ? null : (onClose ?? () => Navigator.of(context).pop()),
                        icon: const Icon(Icons.close_rounded, color: AppColors.textSecondary, size: 22.0),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        tooltip: 'Close',
                      ),
                    ],
                  ],
                ),
              ),

              // Header Divider Line (Full Width)
              if (showDivider) const Divider(height: 1.0, thickness: 1.0, color: AppColors.border),

              // 2. Body Content
              Flexible(
                child: Padding(
                  padding: resolvedContentPadding,
                  child: isScrollable ? SingleChildScrollView(child: content) : content,
                ),
              ),

              // 3. Fixed Footer (if provided)
              if (footer != null) ...[
                if (showFooterDivider) const Divider(height: 1.0, thickness: 1.0, color: AppColors.border),
                Padding(padding: resolvedFooterPadding, child: footer!),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
