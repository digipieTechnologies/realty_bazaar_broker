// File: lib/widgets/shimmer/social_connect_shimmer_widget.dart
// Purpose: Dedicated shimmer loader placeholder for Facebook & Instagram social connect cards with vertical, horizontal, and compact mobile support.

import 'package:flutter/material.dart';
import '../../app/app_colors.dart';
import '../../util/common_ext.dart';
import 'app_shimmer_container.dart';

class SocialConnectShimmerWidget extends StatelessWidget {
  final bool isVertical;

  const SocialConnectShimmerWidget({
    super.key,
    this.isVertical = true,
  });

  @override
  Widget build(BuildContext context) {
    final isDesktop = context.isDesktopUI;

    if (!isVertical && isDesktop) {
      return const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: SingleSocialConnectCardSkeleton(isMobile: false)),
          SizedBox(width: 16.0),
          Expanded(child: SingleSocialConnectCardSkeleton(isMobile: false)),
        ],
      );
    }

    return Column(
      children: [
        SingleSocialConnectCardSkeleton(isMobile: !isDesktop),
        SizedBox(height: !isDesktop ? 10.0 : 16.0),
        SingleSocialConnectCardSkeleton(isMobile: !isDesktop),
      ],
    );
  }
}

class SingleSocialConnectCardSkeleton extends StatelessWidget {
  final bool isMobile;

  const SingleSocialConnectCardSkeleton({
    super.key,
    this.isMobile = true,
  });

  @override
  Widget build(BuildContext context) {
    // Compact collapsed card skeleton (~56px height) matching compact default closed SocialConnectCard
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14.0),
        border: Border.all(color: AppColors.border, width: 1.0),
      ),
      padding: const EdgeInsets.all(14.0),
      child: const Row(
        children: [
          AppShimmerContainer(width: 36, height: 36, borderRadius: 10.0),
          SizedBox(width: 10.0),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                AppShimmerContainer(width: 120, height: 16),
                SizedBox(height: 4.0),
                AppShimmerContainer(width: 80, height: 10),
              ],
            ),
          ),
          SizedBox(width: 8.0),
          AppShimmerContainer(width: 70, height: 20, borderRadius: 6.0),
          SizedBox(width: 6.0),
          AppShimmerContainer(width: 16, height: 16, borderRadius: 8.0),
        ],
      ),
    );
  }
}
