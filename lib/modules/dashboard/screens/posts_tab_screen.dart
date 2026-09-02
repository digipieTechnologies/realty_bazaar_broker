// File: lib/modules/dashboard/screens/posts_tab_screen.dart
// Purpose: Posts tab screen with generic AppTabBarWidget (FB & IG), live Edge Function post feeds, 10-item pagination, and connection states.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:the_realty_bazaar/util/common_ext.dart';

import '../../../app/app_colors.dart';
import '../../../app/app_constants.dart';
import '../../../app/app_text_styles.dart';
import '../../../models/social_enums.dart';
import '../../../providers/auth/auth_provider.dart';
import '../../../providers/social/social_provider.dart';
import '../../../widgets/buttons/app_button.dart';
import '../../../widgets/common/app_card_container.dart';
import '../../../widgets/common/app_pagination_widget.dart';
import '../../../widgets/common/app_tab_bar_widget.dart';
import '../../../widgets/shimmer/social_post_list_shimmer_widget.dart';
import '../widgets/social_post_card.dart';

class PostsTabScreen extends StatefulWidget {
  const PostsTabScreen({super.key});

  @override
  State<PostsTabScreen> createState() => _PostsTabScreenState();
}

class _PostsTabScreenState extends State<PostsTabScreen> {
  String? _lastBrokerId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final authProvider = Provider.of<AuthProvider>(context);
    final brokerId = authProvider.userProfile?.brokerId?.id;
    if (brokerId != null && brokerId != _lastBrokerId) {
      _lastBrokerId = brokerId;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final socialProvider = Provider.of<SocialProvider>(context, listen: false);
        if (socialProvider.selectedPlatformTab == SocialPlatform.facebook) {
          socialProvider.fetchFacebookPosts(brokerId, page: 1);
        } else {
          socialProvider.fetchInstagramPosts(brokerId, page: 1);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final socialProvider = context.watch<SocialProvider>();
    final brokerId = authProvider.userProfile?.brokerId?.id;
    final isMobile = context.isMobile;

    final isFacebookTab = socialProvider.selectedPlatformTab == SocialPlatform.facebook;
    final isConnected = isFacebookTab ? socialProvider.isFacebookConnected : socialProvider.isInstagramConnected;
    final isFetchingPosts = isFacebookTab
        ? socialProvider.isFetchingFacebookPosts
        : socialProvider.isFetchingInstagramPosts;
    final isFetchingInitial = !socialProvider.hasFetchedInitialConnections || socialProvider.isFetchingConnections;
    final isLoading = isFetchingPosts || isFetchingInitial;
    final posts = isFacebookTab ? socialProvider.facebookPosts : socialProvider.instagramPosts;
    final currentPage = isFacebookTab ? socialProvider.facebookCurrentPage : socialProvider.instagramCurrentPage;
    final totalPages = isFacebookTab ? socialProvider.facebookTotalPages : socialProvider.instagramTotalPages;
    final totalItems = isFacebookTab ? socialProvider.facebookTotalItems : socialProvider.instagramTotalItems;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: AppConstants.getTabPadding(context, bottomExtra: isMobile ? 80.0 : 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Generic App Tab Bar Widget (Title + Nullable Image / Icon)
              AppTabBarWidget<SocialPlatform>(
                isMobile: isMobile,
                selectedKey: socialProvider.selectedPlatformTab,
                onTabSelected: (tabKey) {
                  socialProvider.setSelectedPlatformTab(tabKey, brokerId: brokerId);
                },
                items: const [
                  AppTabItem(
                    key: SocialPlatform.facebook,
                    title: 'Facebook',
                    assetIcon: 'assets/icons/facebook.png',
                    brandColor: AppColors.facebook,
                  ),
                  AppTabItem(
                    key: SocialPlatform.instagram,
                    title: 'Instagram',
                    assetIcon: 'assets/icons/instagram.png',
                    brandColor: AppColors.instagramAlt,
                  ),
                ],
              ),
              const SizedBox(height: 20.0),

              // 2. Tab Content (Shimmer / Posts List / Not Connected State)
              if (isLoading)
                SocialPostListShimmerWidget(isMobile: isMobile, count: 4)
              else if (!isConnected)
                _buildNotConnectedState(context, isFacebookTab, socialProvider, brokerId)
              else if (posts.isEmpty)
                _buildEmptyFeedState(context, socialProvider, brokerId)
              else ...[
                // Posts Layout (Mobile List, Web Grid)
                if (isMobile)
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: posts.length,
                    itemBuilder: (context, index) {
                      final p = posts[index];
                      return SocialPostCard(key: ValueKey('${p.platformPostId ?? p.id}_${p.isStoredInDb}'), post: p);
                    },
                  )
                else
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final width = constraints.maxWidth;
                      final int crossAxisCount = width >= 1024 ? 3 : 2;
                      return GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: posts.length,
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: crossAxisCount,
                          crossAxisSpacing: 16.0,
                          mainAxisSpacing: 16.0,
                          mainAxisExtent: 360.0,
                        ),
                        itemBuilder: (context, index) {
                          final p = posts[index];
                          return SocialPostCard(
                            key: ValueKey('${p.platformPostId ?? p.id}_${p.isStoredInDb}'),
                            post: p,
                          );
                        },
                      );
                    },
                  ),
                const SizedBox(height: 16.0),

                // 10-Item Per Page Pagination Controls
                AppPaginationWidget(
                  currentPage: currentPage,
                  totalPages: totalPages,
                  totalItems: totalItems,
                  onPageChanged: (newPage) {
                    if (brokerId != null) {
                      if (isFacebookTab) {
                        socialProvider.fetchFacebookPosts(brokerId, page: newPage);
                      } else {
                        socialProvider.fetchInstagramPosts(brokerId, page: newPage);
                      }
                    }
                  },
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNotConnectedState(BuildContext context, bool isFacebook, SocialProvider provider, String? brokerId) {
    final platformName = isFacebook ? 'Facebook Page' : 'Instagram Business';
    final assetIcon = isFacebook ? 'assets/icons/facebook.png' : 'assets/icons/instagram.png';
    final buttonColor = isFacebook ? AppColors.facebook : AppColors.instagramAlt;

    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 460.0),
        margin: const EdgeInsets.symmetric(vertical: 40.0),
        child: AppCardContainer(
          padding: const EdgeInsets.all(32.0),
          borderRadius: 20.0,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20.0),
                decoration: BoxDecoration(color: buttonColor.withValues(alpha: 0.08), shape: BoxShape.circle),
                child: Image.asset(
                  assetIcon,
                  width: 48.0,
                  height: 48.0,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) =>
                      Icon(isFacebook ? Icons.facebook : Icons.camera_alt_rounded, size: 48.0, color: buttonColor),
                ),
              ),
              const SizedBox(height: 20.0),
              Text(
                '$platformName Not Connected',
                style: AppTextStyles.heading2.copyWith(fontWeight: FontWeight.bold, fontSize: 18.0),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8.0),
              Text(
                'Connect your $platformName account to view live posts, reels, impressions, engagement, and reach metrics in real time.',
                style: AppTextStyles.body2.copyWith(color: AppColors.textSecondary, height: 1.5, fontSize: 13.0),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24.0),
              AppButton.solid(
                text: 'Connect $platformName',
                iconData: Icons.link_rounded,
                height: 46.0,
                borderRadius: 10.0,
                color: buttonColor,
                onPressed: () {
                  if (brokerId != null) {
                    if (isFacebook) {
                      provider.connectFacebook(brokerId);
                    } else {
                      provider.connectInstagramDirectly(brokerId);
                    }
                  } else {
                    context.go('/dashboard');
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyFeedState(BuildContext context, SocialProvider provider, String? brokerId) {
    final isFB = provider.selectedPlatformTab == SocialPlatform.facebook;
    final platformName = isFB ? 'Facebook Page' : 'Instagram Business';

    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 420.0),
        padding: const EdgeInsets.symmetric(vertical: 48.0, horizontal: 24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.08), shape: BoxShape.circle),
              child: const Icon(Icons.post_add_rounded, size: 40.0, color: AppColors.primary),
            ),
            const SizedBox(height: 20.0),
            Text(
              'No Posts Found',
              style: AppTextStyles.heading3.copyWith(fontWeight: FontWeight.bold, fontSize: 17.0),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8.0),
            Text(
              'No published posts were found on your connected $platformName account.',
              style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary, fontSize: 13.0),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
