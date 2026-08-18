// File: lib/modules/dashboard/widgets/recent_posts_widget.dart
// Purpose: Dashboard widget displaying top 3 recent social media posts (Facebook & Instagram) in a horizontal scrolling list using SocialPostCard with minimal card view and shimmer loading.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../app/app_colors.dart';
import '../../../app/app_text_styles.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../models/social_post_model.dart';
import '../../../providers/auth/auth_provider.dart';
import '../../../providers/social/social_provider.dart';
import '../../../widgets/common/app_card_container.dart';
import '../../../widgets/common/app_empty_state_widget.dart';
import '../../../widgets/common/app_section_header.dart';
import '../../../widgets/shimmer/post_list_horizontal_shimmer_widget.dart';
import 'social_post_card.dart';

class RecentPostsWidget extends StatefulWidget {
  const RecentPostsWidget({super.key});

  @override
  State<RecentPostsWidget> createState() => _RecentPostsWidgetState();
}

class _RecentPostsWidgetState extends State<RecentPostsWidget> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final brokerId = authProvider.userProfile?.brokerId?.id;
      final socialProvider = Provider.of<SocialProvider>(context, listen: false);

      if (brokerId != null && brokerId.isNotEmpty) {
        if (!socialProvider.isFetchingFacebookPosts) {
          socialProvider.fetchFacebookPosts(brokerId, page: 1);
        }
        if (!socialProvider.isFetchingInstagramPosts) {
          socialProvider.fetchInstagramPosts(brokerId, page: 1);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final socialProvider = context.watch<SocialProvider>();

    // Combine posts from both Facebook and Instagram, sort by publishedAt/createdAt descending, and take latest 3
    final List<SocialPostModel> combinedPosts = [
      ...socialProvider.facebookPosts,
      ...socialProvider.instagramPosts,
    ];
    combinedPosts.sort((a, b) {
      final dateA = a.publishedAt ?? a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final dateB = b.publishedAt ?? b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      return dateB.compareTo(dateA);
    });

    final recentPosts = combinedPosts.take(3).toList();
    final isLoading = (socialProvider.isFetchingFacebookPosts || socialProvider.isFetchingInstagramPosts) &&
        combinedPosts.isEmpty;

    return AppCardContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row: Section Header Badge & View All Button
          AppSectionHeader(
            title: context.tr('recent_posts'),
            icon: Icons.dynamic_feed_rounded,
            padding: const EdgeInsets.fromLTRB(16.0, 12.0, 12.0, 12.0),
            trailing: InkWell(
              onTap: () => context.go('/posts'),
              borderRadius: BorderRadius.circular(6.0),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 6.0,
                  vertical: 3.0,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      context.tr('view_all'),
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 12.0,
                      ),
                    ),
                    const SizedBox(width: 2.0),
                    const Icon(
                      Icons.chevron_right_rounded,
                      size: 16.0,
                      color: AppColors.primary,
                    ),
                  ],
                ),
              ),
            ),
          ),
          const Divider(height: 1.0, color: AppColors.border),

          // Content Area: Loading, Empty, or Horizontal Post List
          if (isLoading)
            const Padding(
              padding: EdgeInsets.all(12.0),
              child: PostListHorizontalShimmerWidget(count: 3),
            )
          else if (recentPosts.isEmpty)
            AppEmptyStateWidget(
              icon: Icons.dynamic_feed_rounded,
              title: context.tr('no_posts_found'),
              description: context.tr('no_posts_empty_desc'),
            )
          else
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12.0),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 12.0),
                child: IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: recentPosts.map((post) {
                      return SizedBox(
                        width: 260.0,
                        child: Padding(
                          padding: const EdgeInsets.only(right: 12.0),
                          child: SocialPostCard(
                            post: post,
                            isMinimalView: true,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
