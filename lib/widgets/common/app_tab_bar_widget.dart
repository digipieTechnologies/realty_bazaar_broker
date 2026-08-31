// File: lib/widgets/common/app_tab_bar_widget.dart
// Purpose: Generic reusable segment tab bar widget supporting title, nullable asset image/icon, soft selected color styling, and responsive layouts.

import 'package:flutter/material.dart';

import '../../app/app_colors.dart';
import '../../app/app_text_styles.dart';

class AppTabItem<T> {
  final T key;
  final String title;
  final String? assetIcon;
  final IconData? icon;
  final Color? brandColor;

  const AppTabItem({required this.key, required this.title, this.assetIcon, this.icon, this.brandColor});
}

class AppTabBarWidget<T> extends StatelessWidget {
  final List<AppTabItem<T>> items;
  final T selectedKey;
  final ValueChanged<T> onTabSelected;
  final bool isMobile;
  final Color? activeTabColor;

  const AppTabBarWidget({
    super.key,
    required this.items,
    required this.selectedKey,
    required this.onTabSelected,
    this.isMobile = false,
    this.activeTabColor,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();

    final tabButtons = items.map((item) {
      final isSelected = item.key == selectedKey;
      return _buildTabButton(
        context: context,
        item: item,
        isSelected: isSelected,
        onTap: () => onTabSelected(item.key),
      );
    }).toList();

    if (isMobile) {
      return Container(
        padding: const EdgeInsets.all(4.0),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(16.0),
          border: Border.all(color: AppColors.border, width: 1.0),
        ),
        child: Row(children: tabButtons.map((btn) => Expanded(child: btn)).toList()),
      );
    }

    return Container(
      padding: const EdgeInsets.all(4.0),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: AppColors.border, width: 1.0),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: tabButtons),
    );
  }

  Widget _buildTabButton({
    required BuildContext context,
    required AppTabItem<T> item,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final hasAsset = item.assetIcon != null && item.assetIcon!.trim().isNotEmpty;
    final hasIcon = item.icon != null;

    final effectiveBrandColor = activeTabColor ?? item.brandColor ?? AppColors.primary;
    final softSelectedBg = effectiveBrandColor.withValues(alpha: 0.10);
    final softSelectedBorder = effectiveBrandColor.withValues(alpha: 0.30);

    return Container(
      height: 44.0,
      margin: const EdgeInsets.symmetric(horizontal: 2.0),
      decoration: BoxDecoration(
        color: isSelected ? softSelectedBg : Colors.transparent,
        borderRadius: BorderRadius.circular(12.0),
        border: isSelected
            ? Border.all(color: softSelectedBorder, width: 1.0)
            : Border.all(color: Colors.transparent, width: 1.0),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12.0),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: isMobile ? 8.0 : 16.0, vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: isMobile ? MainAxisSize.max : MainAxisSize.min,
            children: [
              if (hasAsset) ...[
                Image.asset(
                  item.assetIcon!,
                  width: 18.0,
                  height: 18.0,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => Icon(
                    item.icon ?? Icons.tab_rounded,
                    size: 18.0,
                    color: isSelected ? effectiveBrandColor : AppColors.textSecondary,
                  ),
                ),
                SizedBox(width: isMobile ? 6.0 : 8.0),
              ] else if (hasIcon) ...[
                Icon(
                  item.icon!,
                  size: 18.0,
                  color: isSelected ? effectiveBrandColor : AppColors.textSecondary,
                ),
                SizedBox(width: isMobile ? 6.0 : 8.0),
              ],
              Flexible(
                child: Text(
                  item.title,
                  style: AppTextStyles.body2.copyWith(
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    color: isSelected ? effectiveBrandColor : AppColors.textSecondary,
                    fontSize: isMobile ? 13.0 : 13.5,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
