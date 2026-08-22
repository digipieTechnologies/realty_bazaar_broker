// File: lib/widgets/shimmer/stat_card_shimmer_widget.dart
// Purpose: Standalone reusable shimmer skeleton placeholder for stat overview cards.

import 'package:flutter/material.dart';
import '../../app/app_colors.dart';
import 'app_shimmer_container.dart';

class StatCardSkeleton extends StatelessWidget {
  final bool isDesktop;

  const StatCardSkeleton({
    super.key,
    this.isDesktop = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(isDesktop ? 16.0 : 12.0),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(isDesktop ? 18.0 : 14.0),
        border: Border.all(color: AppColors.border, width: 1.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Circle Icon Skeleton
              AppShimmerContainer(
                width: isDesktop ? 34 : 27,
                height: isDesktop ? 34 : 27,
                borderRadius: 17.0,
              ),
              // Right Tag Pill Skeleton
              AppShimmerContainer(
                width: isDesktop ? 55 : 44,
                height: isDesktop ? 20 : 16,
                borderRadius: 12.0,
              ),
            ],
          ),
          SizedBox(height: isDesktop ? 12.0 : 8.0),
          // Metric Value Line Skeleton
          AppShimmerContainer(
            width: isDesktop ? 70 : 50,
            height: isDesktop ? 24 : 19,
            borderRadius: 6.0,
          ),
          const SizedBox(height: 5.0),
          // Subtitle Text Line Skeleton
          AppShimmerContainer(
            width: isDesktop ? 100 : 80,
            height: isDesktop ? 12 : 11,
            borderRadius: 4.0,
          ),
        ],
      ),
    );
  }
}
