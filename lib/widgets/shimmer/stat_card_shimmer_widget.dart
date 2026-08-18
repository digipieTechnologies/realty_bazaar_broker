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
      padding: EdgeInsets.fromLTRB(
        isDesktop ? 16.0 : 12.0,
        isDesktop ? 14.0 : 10.0,
        isDesktop ? 16.0 : 12.0,
        isDesktop ? 14.0 : 10.0,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(isDesktop ? 16.0 : 12.0),
        border: Border.all(color: AppColors.border, width: 1.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              AppShimmerContainer(width: 36, height: 36, borderRadius: 10.0),
              AppShimmerContainer(width: 50, height: 18, borderRadius: 10.0),
            ],
          ),
          SizedBox(height: isDesktop ? 12.0 : 8.0),
          AppShimmerContainer(width: 60, height: isDesktop ? 24 : 20, borderRadius: 6.0),
          const SizedBox(height: 4.0),
          const AppShimmerContainer(width: 90, height: 11, borderRadius: 4.0),
        ],
      ),
    );
  }
}
