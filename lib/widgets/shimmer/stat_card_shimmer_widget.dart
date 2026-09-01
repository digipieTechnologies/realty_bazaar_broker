// File: lib/widgets/shimmer/stat_card_shimmer_widget.dart
// Purpose: Standalone reusable shimmer skeleton placeholder for stat overview cards.

import 'package:flutter/material.dart';

import '../../app/app_colors.dart';
import 'app_shimmer_container.dart';

class StatCardSkeleton extends StatelessWidget {
  final bool isDesktop;

  const StatCardSkeleton({super.key, this.isDesktop = true});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(isDesktop ? 12.0 : 10.0),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(isDesktop ? 16.0 : 14.0),
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
                width: isDesktop ? 30 : 25,
                height: isDesktop ? 30 : 25,
                borderRadius: 15.0,
              ),
              // Right Tag Pill Skeleton
              AppShimmerContainer(
                width: isDesktop ? 44 : 36,
                height: isDesktop ? 18 : 15,
                borderRadius: 10.0,
              ),
            ],
          ),
          SizedBox(height: isDesktop ? 10.0 : 8.0),
          // Metric Value Line Skeleton
          AppShimmerContainer(width: isDesktop ? 55 : 42, height: isDesktop ? 22 : 18, borderRadius: 6.0),
          const SizedBox(height: 5.0),
          // Subtitle Text Line Skeleton
          AppShimmerContainer(width: isDesktop ? 75 : 60, height: isDesktop ? 12 : 11, borderRadius: 4.0),
        ],
      ),
    );
  }
}
