// File: lib/widgets/buttons/app_popup_menu_button.dart
// Purpose: Unified popup menu helper and button widget across the application with accurate widget bounds positioning, upward opening support, and themed styling.

import 'package:flutter/material.dart';

import '../../app/app_colors.dart';
import '../../app/app_text_styles.dart';

class AppPopupMenuItem<T> {
  final T value;
  final String label;
  final IconData? iconData;
  final Widget? icon;
  final Color? textColor;
  final Color? iconColor;

  const AppPopupMenuItem({
    required this.value,
    required this.label,
    this.iconData,
    this.icon,
    this.textColor,
    this.iconColor,
  });
}

class AppPopupMenu {
  AppPopupMenu._();

  /// Programmatically displays a styled App Popup Menu.
  /// Automatically calculates the target position from widget context or [targetKey].
  /// If [openAbove] is true, forces the menu to render above the target.
  static Future<T?> show<T>({
    required BuildContext context,
    required List<AppPopupMenuItem<T>> items,
    GlobalKey? targetKey,
    Offset? positionOffset,
    bool openAbove = false,
    double elevation = 8.0,
    double borderRadius = 14.0,
    Color? popupColor,
  }) async {
    final RenderBox? overlay = Overlay.of(context).context.findRenderObject() as RenderBox?;
    if (overlay == null) return null;

    RenderBox? button;
    if (targetKey != null && targetKey.currentContext != null) {
      button = targetKey.currentContext!.findRenderObject() as RenderBox?;
    } else {
      final obj = context.findRenderObject();
      if (obj is RenderBox) {
        button = obj;
      }
    }

    RelativeRect relativePosition;

    if (button != null && button.hasSize) {
      final Offset buttonPosition = button.localToGlobal(Offset.zero, ancestor: overlay);
      final Size buttonSize = button.size;

      if (openAbove) {
        relativePosition = RelativeRect.fromLTRB(
          buttonPosition.dx,
          buttonPosition.dy - 120.0,
          overlay.size.width - (buttonPosition.dx + buttonSize.width),
          overlay.size.height - buttonPosition.dy,
        );
      } else {
        relativePosition = RelativeRect.fromLTRB(
          buttonPosition.dx,
          buttonPosition.dy + buttonSize.height,
          overlay.size.width - (buttonPosition.dx + buttonSize.width),
          overlay.size.height - (buttonPosition.dy + buttonSize.height),
        );
      }
    } else if (positionOffset != null) {
      final double dy = positionOffset.dy;
      final double dx = positionOffset.dx;
      if (openAbove) {
        relativePosition = RelativeRect.fromLTRB(
          dx,
          dy - 120.0,
          overlay.size.width - dx,
          overlay.size.height - dy,
        );
      } else {
        relativePosition = RelativeRect.fromRect(Rect.fromLTWH(dx, dy, 0, 0), Offset.zero & overlay.size);
      }
    } else {
      relativePosition = RelativeRect.fromRect(
        Rect.fromLTWH(overlay.size.width / 2, overlay.size.height / 2, 0, 0),
        Offset.zero & overlay.size,
      );
    }

    return await showMenu<T>(
      context: context,
      position: relativePosition,
      elevation: elevation,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(borderRadius)),
      color: popupColor ?? AppColors.surface,
      items: items.map((item) {
        return PopupMenuItem<T>(
          value: item.value,
          height: 40.0,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (item.icon != null) ...[
                item.icon!,
                const SizedBox(width: 10.0),
              ] else if (item.iconData != null) ...[
                Icon(item.iconData, size: 18.0, color: item.iconColor ?? AppColors.primary),
                const SizedBox(width: 12.0),
              ],
              Text(
                item.label,
                style: AppTextStyles.body2.copyWith(
                  color: item.textColor ?? AppColors.textPrimary,
                  fontSize: 13.0,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class AppPopupMenuButton<T> extends StatelessWidget {
  final List<AppPopupMenuItem<T>> items;
  final ValueChanged<T>? onSelected;
  final Widget? triggerWidget;
  final IconData triggerIcon;
  final Color? triggerIconColor;
  final double triggerIconSize;
  final double borderRadius;
  final Color? popupColor;
  final double elevation;
  final EdgeInsets padding;
  final PopupMenuPosition position;

  const AppPopupMenuButton({
    super.key,
    required this.items,
    this.onSelected,
    this.triggerWidget,
    this.triggerIcon = Icons.more_vert_rounded,
    this.triggerIconColor,
    this.triggerIconSize = 20.0,
    this.borderRadius = 14.0,
    this.popupColor,
    this.elevation = 8.0,
    this.padding = EdgeInsets.zero,
    this.position = PopupMenuPosition.under,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: PopupMenuButton<T>(
        position: position,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(borderRadius)),
        color: popupColor ?? AppColors.surface,
        elevation: elevation,
        onSelected: onSelected,
        itemBuilder: (BuildContext context) {
          return items.map((item) {
            return PopupMenuItem<T>(
              value: item.value,
              height: 40.0,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (item.icon != null) ...[
                    item.icon!,
                    const SizedBox(width: 10.0),
                  ] else if (item.iconData != null) ...[
                    Icon(item.iconData, size: 18.0, color: item.iconColor ?? AppColors.primary),
                    const SizedBox(width: 12.0),
                  ],
                  Text(
                    item.label,
                    style: AppTextStyles.body2.copyWith(
                      color: item.textColor ?? AppColors.textPrimary,
                      fontSize: 13.0,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            );
          }).toList();
        },
        child:
            triggerWidget ??
            Icon(triggerIcon, size: triggerIconSize, color: triggerIconColor ?? AppColors.textPrimary),
      ),
    );
  }
}
