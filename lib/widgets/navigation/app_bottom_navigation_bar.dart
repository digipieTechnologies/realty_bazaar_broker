// File: lib/widgets/navigation/app_bottom_navigation_bar.dart
// Purpose: Unified responsive bottom navigation bar for mobile and tablet views
// using SVG filled/outline icons, fixed icon sizing, and strict routing management.

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../app/app_assets.dart';
import '../../app/app_colors.dart';
import '../../app/app_text_styles.dart';
import '../../core/localization/app_localizations.dart';

class BottomNavItem {
  final String titleKey;
  final String path;
  final String filledIconAsset;
  final String outlineIconAsset;

  const BottomNavItem({
    required this.titleKey,
    required this.path,
    required this.filledIconAsset,
    required this.outlineIconAsset,
  });
}

class AppBottomNavigationBar extends StatelessWidget {
  final String currentPath;

  static const List<BottomNavItem> items = [
    BottomNavItem(
      titleKey: 'dashboard',
      path: '/dashboard',
      filledIconAsset: AppAssets.icDashboardFilled,
      outlineIconAsset: AppAssets.icDashboardOutline,
    ),
    BottomNavItem(
      titleKey: 'posts',
      path: '/posts',
      filledIconAsset: AppAssets.icPostsFilled,
      outlineIconAsset: AppAssets.icPostsOutline,
    ),
    BottomNavItem(
      titleKey: 'grow',
      path: '/grow',
      filledIconAsset: AppAssets.icGrowFilled,
      outlineIconAsset: AppAssets.icGrowOutline,
    ),
    BottomNavItem(
      titleKey: 'leads',
      path: '/leads',
      filledIconAsset: AppAssets.icLeadsFilled,
      outlineIconAsset: AppAssets.icLeadsOutline,
    ),
    BottomNavItem(
      titleKey: 'profile',
      path: '/profile',
      filledIconAsset: AppAssets.icProfileFilled,
      outlineIconAsset: AppAssets.icProfileOutline,
    ),
  ];

  const AppBottomNavigationBar({super.key, required this.currentPath});

  int get _selectedIndex {
    for (int i = 0; i < items.length; i++) {
      if (currentPath.startsWith(items[i].path)) {
        return i;
      }
    }
    return 0; // Default to Dashboard
  }

  @override
  Widget build(BuildContext context) {
    final selectedIndex = _selectedIndex;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border, width: 1.0)),
      ),
      child: SafeArea(
        top: false,
        child: Container(
          height: 64.0,
          padding: const EdgeInsets.symmetric(horizontal: 4.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(items.length, (index) {
              final item = items[index];
              final isSelected = index == selectedIndex;
              final Color activeColor = AppColors.primary;
              final Color inactiveColor = AppColors.textMuted;
              final Color iconColor = isSelected ? activeColor : inactiveColor;

              return Expanded(
                child: InkWell(
                  onTap: () {
                    if (currentPath != item.path) {
                      context.go(item.path);
                    }
                  },
                  splashColor: activeColor.withValues(alpha: 0.08),
                  highlightColor: Colors.transparent,
                  borderRadius: BorderRadius.circular(12.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.max,
                    children: [
                      // Fixed sized icon container to prevent jumping/shifting
                      SizedBox(
                        width: 24.0,
                        height: 24.0,
                        child: SvgPicture.asset(
                          isSelected
                              ? item.filledIconAsset
                              : item.outlineIconAsset,
                          width: 22.0,
                          height: 22.0,
                          colorFilter: ColorFilter.mode(
                            iconColor,
                            BlendMode.srcIn,
                          ),
                          fit: BoxFit.contain,
                        ),
                      ),
                      const SizedBox(height: 4.0),
                      Text(
                        context.tr(item.titleKey),
                        style: AppTextStyles.caption.copyWith(
                          fontSize: 11.0,
                          fontWeight: isSelected
                              ? FontWeight.w700
                              : FontWeight.w500,
                          color: isSelected
                              ? activeColor
                              : AppColors.textSecondary,
                          height: 1.0,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}
