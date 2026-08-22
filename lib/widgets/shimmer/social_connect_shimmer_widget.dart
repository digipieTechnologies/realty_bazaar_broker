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
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18.0),
        border: Border.all(color: AppColors.border, width: 1.2),
      ),
      padding: EdgeInsets.all(isMobile ? 12.0 : 16.0),
      child: Row(
        children: [
          // Logo Badge Circle Skeleton
          AppShimmerContainer(
            width: isMobile ? 32.0 : 38.0,
            height: isMobile ? 32.0 : 38.0,
            borderRadius: 19.0,
          ),
          const SizedBox(width: 12.0),
          // Title & Username Lines Skeleton
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                AppShimmerContainer(width: 120, height: 15, borderRadius: 4.0),
                SizedBox(height: 4.0),
                AppShimmerContainer(width: 80, height: 11, borderRadius: 4.0),
              ],
            ),
          ),
          const SizedBox(width: 8.0),
          // Live Status Badge Pill Skeleton
          const AppShimmerContainer(width: 86, height: 22, borderRadius: 12.0),
          const SizedBox(width: 6.0),
          // Chevron Circle Button Skeleton
          const AppShimmerContainer(width: 24, height: 24, borderRadius: 12.0),
        ],
      ),
    );
  }
}
