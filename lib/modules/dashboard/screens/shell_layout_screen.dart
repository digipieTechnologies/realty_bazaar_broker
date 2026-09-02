// File: lib/modules/dashboard/screens/shell_layout_screen.dart
// Purpose: Responsive navigation shell layout supporting Sidebar on desktop/web/macOS
// and Bottom Navigation Bar + Drawer on mobile, with dynamic user profile bindings and overlays.

// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get_storage/get_storage.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:the_realty_bazaar/app/app_navigator.dart';

import '../../../app/app_assets.dart';
import '../../../app/app_colors.dart';
import '../../../app/app_strings.dart';
import '../../../app/app_text_styles.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../providers/auth/auth_provider.dart';
import '../../../util/common_ext.dart';
import '../../../widgets/brand/app_logo.dart';
import '../../../widgets/buttons/language_selector_button.dart';
import '../../../widgets/common/common_app_bar.dart';
import '../../../widgets/navigation/app_bottom_navigation_bar.dart';
import '../../../widgets/shimmer/app_shimmer_container.dart';
import '../../../widgets/shimmer/dashboard_shimmer_widget.dart';
import '../widgets/compact_setup_progress_widget.dart';

class ShellLayoutScreen extends StatefulWidget {
  final Widget child;

  const ShellLayoutScreen({super.key, required this.child});

  @override
  State<ShellLayoutScreen> createState() => _ShellLayoutScreenState();
}

class _ShellLayoutScreenState extends State<ShellLayoutScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // Definition of navigation items for desktop sidebar
  static const List<_NavigationItem> _navItems = [
    _NavigationItem(
      title: 'Dashboard',
      titleKey: 'dashboard',
      path: '/dashboard',
      filledIconAsset: AppAssets.icDashboardFilled,
      outlineIconAsset: AppAssets.icDashboardOutline,
    ),
    _NavigationItem(
      title: 'Posts',
      titleKey: 'posts',
      path: '/posts',
      filledIconAsset: AppAssets.icPostsFilled,
      outlineIconAsset: AppAssets.icPostsOutline,
    ),
    _NavigationItem(
      title: 'Leads',
      titleKey: 'leads',
      path: '/leads',
      filledIconAsset: AppAssets.icLeadsFilled,
      outlineIconAsset: AppAssets.icLeadsOutline,
    ),
    _NavigationItem(
      title: 'Properties',
      titleKey: 'properties',
      path: '/properties',
      filledIconAsset: AppAssets.icPropertiesFilled,
      outlineIconAsset: AppAssets.icPropertiesOutline,
    ),
    _NavigationItem(
      title: 'Grow',
      titleKey: 'grow',
      path: '/grow',
      filledIconAsset: AppAssets.icGrowFilled,
      outlineIconAsset: AppAssets.icGrowOutline,
    ),
    _NavigationItem(
      title: 'Request Video',
      titleKey: 'request_video',
      path: '/request-video',
      filledIconAsset: AppAssets.icVideoFilled,
      outlineIconAsset: AppAssets.icVideoOutline,
    ),
  ];

  @override
  void initState() {
    super.initState();
    // Load profile metadata on layout initialization
    _loadProfile();
  }

  void _loadProfile() {
    final userId = GetStorage().read<String>('user_id');
    if (userId != null && userId.isNotEmpty) {
      context.read<AuthProvider>().fetchCurrentUserProfile(userId);
    }
  }

  int _getCurrentIndex(String location) {
    if (location.startsWith('/profile')) {
      return -1;
    }
    for (int i = 0; i < _navItems.length; i++) {
      if (location.startsWith(_navItems[i].path)) {
        return i;
      }
    }
    return 0; // Default to Dashboard
  }

  void _onTabSelected(int index) {
    if (!mounted) return;
    context.go(_navItems[index].path);
  }

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    final currentIndex = _getCurrentIndex(location);
    final isDesktop = context.isDesktop;

    // Bind reactively to cached user profile from AuthProvider
    final profile = context.watch<AuthProvider>().userProfile;
    final String displayName = profile?.name ?? 'Alex Sterling';
    final String displayRole =
        (profile?.role?.displayName ?? 'Principal Broker').toUpperCase();
    final String displayEmail = profile?.email ?? 'alex@realtybazaar.com';

    if (isDesktop) {
      return Scaffold(
        key: _scaffoldKey,
        backgroundColor: AppColors.background,
        body: Row(
          children: [
            // Left Sidebar
            _buildSidebar(
              currentIndex,
              location.startsWith('/profile'),
              profile == null,
              displayName,
              displayRole,
              displayEmail,
            ),

            // Vertical Divider
            Container(width: 1.0, color: AppColors.border),

            // Main Panel Content Area
            Expanded(
              child: Column(
                children: [
                  if (profile == null)
                    const Expanded(child: DashboardShimmerWidget())
                  else ...[
                    // Top navigation search and metrics bar
                    _buildTopBar(
                      location,
                      displayName,
                      displayRole,
                      displayEmail,
                      isDesktop,
                    ),

                    // Embedded Route Content
                    Expanded(child: widget.child),
                  ],
                ],
              ),
            ),
          ],
        ),
      );
    }

    // Determine screen label for mobile/tablet AppBar title
    String mobileTitle = context.tr('dashboard');
    if (location.startsWith('/profile')) {
      mobileTitle = context.tr('action_profile');
    } else if (location.startsWith('/grow')) {
      mobileTitle = context.tr('grow');
    } else {
      for (final item in _navItems) {
        if (location.startsWith(item.path)) {
          mobileTitle = context.tr(item.titleKey);
          break;
        }
      }
    }

    // Mobile & Tablet layout with Bottom Navigation Bar (No Drawer)
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppColors.background,
      appBar: CommonAppBar(
        key: const ValueKey('mobile_appbar'),
        title: mobileTitle,
        showBackButton: false,
        leading: InkWell(
          onTap: () => AppNavigator.navigateToProfile(context),
          borderRadius: BorderRadius.circular(100),
          child: Padding(
            padding: const EdgeInsets.all(10.0),
            child: profile == null
                ? const AppShimmerContainer(width: 36, height: 36, borderRadius: 18.0)
                : CircleAvatar(
                    radius: 18,
                    backgroundColor: AppColors.primary.withOpacity(0.1),
                    child: Text(
                      displayName.substring(0, 1).toUpperCase(),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
          ),
        ),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 12.0),
            child: CompactSetupProgressWidget(),
          ),
        ],
      ),
      body: profile == null ? const DashboardShimmerWidget() : widget.child,
      bottomNavigationBar: AppBottomNavigationBar(currentPath: location),
    );
  }

  // --- DESKTOP SIDEBAR WIDGET ---
  Widget _buildSidebar(
    int currentIndex,
    bool isProfileSelected,
    bool isLoading,
    String name,
    String role,
    String email,
  ) {
    return Container(
      width: 260.0,
      color: AppColors.surface,
      padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 16.0),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Logo & Branding
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0),
              child: Row(
                children: [
                  const AppLogo(size: 36.0),
                  const SizedBox(width: 10.0),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppStrings.appName,
                          style: AppTextStyles.heading3.copyWith(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.2,
                            color: AppColors.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2.0),
                        Text(
                          context.tr('growth_platform'),
                          style: AppTextStyles.caption.copyWith(
                            fontSize: 8.5,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textMuted,
                            letterSpacing: 0.8,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32.0),

            // Navigation List Items
            Expanded(
              child: ListView.separated(
                itemCount: _navItems.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 4.0),
                itemBuilder: (context, index) {
                  final item = _navItems[index];
                  final isSelected = index == currentIndex;

                  return _buildSidebarItem(item, isSelected, index);
                },
              ),
            ),

            // Language selector button
            const LanguageSelectorButton(),
            const SizedBox(height: 12.0),

            // Footer User Profile Card
            _buildUserCard(name, role, email, isProfileSelected, isLoading),
          ],
        ),
      ),
    );
  }

  Widget _buildSidebarItem(_NavigationItem item, bool isSelected, int index) {
    return InkWell(
      onTap: () => _onTabSelected(index),
      borderRadius: BorderRadius.circular(8.0),
      child: Container(
        height: 44.0,
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withOpacity(0.06)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8.0),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Row(
              children: [
                const SizedBox(width: 12.0),
                SizedBox(
                  width: 20.0,
                  height: 20.0,
                  child: SvgPicture.asset(
                    isSelected ? item.filledIconAsset : item.outlineIconAsset,
                    width: 20.0,
                    height: 20.0,
                    colorFilter: ColorFilter.mode(
                      isSelected ? AppColors.primary : AppColors.textSecondary,
                      BlendMode.srcIn,
                    ),
                  ),
                ),
                const SizedBox(width: 14.0),
                Text(
                  context.tr(item.titleKey),
                  style: TextStyle(
                    fontSize: 14.0,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    color: isSelected
                        ? AppColors.primary
                        : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
            // Right thick indicator border matching design screenshot
            if (isSelected)
              Positioned(
                right: 0,
                top: 8.0,
                bottom: 8.0,
                child: Container(
                  width: 3.5,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(4.0),
                      bottomLeft: Radius.circular(4.0),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // --- FOOTER USER PROFILE COMPONENT ---
  Widget _buildUserCard(
    String name,
    String role,
    String email,
    bool isSelected,
    bool isLoading,
  ) {
    if (isLoading) {
      return Container(
        padding: const EdgeInsets.all(12.0),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(12.0),
          border: Border.all(color: AppColors.border, width: 1.0),
        ),
        child: const Row(
          children: [
            AppShimmerContainer(width: 36, height: 36, borderRadius: 18.0),
            SizedBox(width: 12.0),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  AppShimmerContainer(width: 80, height: 12),
                  SizedBox(height: 6.0),
                  AppShimmerContainer(width: 50, height: 8),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return InkWell(
      onTap: () {
        if (_scaffoldKey.currentState?.isDrawerOpen ?? false) {
          _scaffoldKey.currentState?.closeDrawer();
        }
        context.go('/profile');
      },
      borderRadius: BorderRadius.circular(12.0),
      child: Container(
        padding: const EdgeInsets.all(12.0),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withOpacity(0.06)
              : AppColors.background,
          borderRadius: BorderRadius.circular(12.0),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: 1.0,
          ),
        ),
        child: Row(
          children: [
            // User Avatar (Person Logo/Letter Badge)
            CircleAvatar(
              radius: 18,
              backgroundColor: AppColors.primary.withOpacity(0.1),
              child: Text(
                name.substring(0, 1).toUpperCase(),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ),
            const SizedBox(width: 12.0),

            // Name / Role
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    name,
                    style: AppTextStyles.body2.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2.0),
                  Text(
                    role,
                    style: AppTextStyles.caption.copyWith(
                      fontSize: 9.0,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- TOP NAVIGATION BAR COMPONENT ---
  Widget _buildTopBar(
    String location,
    String name,
    String role,
    String email,
    bool isDesktop,
  ) {
    // Determine screen label based on path
    String screenLabel = context.tr('dashboard');
    if (location.startsWith('/profile')) {
      screenLabel = context.tr('action_profile');
    } else {
      for (final item in _navItems) {
        if (location.startsWith(item.path)) {
          if (item.titleKey == 'dashboard') {
            screenLabel = context.tr('dashboard');
          } else if (item.titleKey == 'posts') {
            screenLabel = context.tr('posts');
          } else if (item.titleKey == 'settings') {
            screenLabel = context.tr('system_settings');
          } else if (item.titleKey == 'request_video') {
            screenLabel = context.tr('video_requests');
          } else if (item.titleKey == 'referrals') {
            screenLabel = context.tr('referral_network');
          } else if (item.titleKey == 'reports') {
            screenLabel = context.tr('performance_reports');
          } else if (item.titleKey == 'properties') {
            screenLabel = context.tr('properties_directory');
          } else if (item.titleKey == 'leads') {
            screenLabel = context.tr('leads_management');
          } else {
            screenLabel = context.tr(item.titleKey);
          }
          break;
        }
      }
    }

    return Container(
      height: 70.0,
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.border, width: 1.0)),
      ),
      child: Row(
        children: [
          // Screen Title
          Expanded(
            child: Text(
              screenLabel,
              style: AppTextStyles.heading2.copyWith(
                fontWeight: FontWeight.bold,
                letterSpacing: -0.3,
              ),
            ),
          ),
          const CompactSetupProgressWidget(),
        ],
      ),
    );
  }
}

class _NavigationItem {
  final String title;
  final String titleKey;
  final String path;
  final String filledIconAsset;
  final String outlineIconAsset;

  const _NavigationItem({
    required this.title,
    required this.titleKey,
    required this.path,
    required this.filledIconAsset,
    required this.outlineIconAsset,
  });
}
