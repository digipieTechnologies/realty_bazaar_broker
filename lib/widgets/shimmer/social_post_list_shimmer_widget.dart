// File: lib/widgets/shimmer/social_post_list_shimmer_widget.dart
// Purpose: Reusable shimmer placeholder loading widget for the Social Posts feed in mobile list & web grid layouts.

import 'package:flutter/material.dart';

import '../../app/app_colors.dart';
import 'app_shimmer_container.dart';

class SocialPostListShimmerWidget extends StatelessWidget {
  final bool isMobile;
  final int count;

  const SocialPostListShimmerWidget({super.key, this.isMobile = false, this.count = 4});

  Widget _buildShimmerCard() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16.0),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: AppColors.border, width: 1.0),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Image Stack Shimmer (230px height) with Floating Date & Open Pill Shimmers
          SizedBox(
            height: 230.0,
            width: double.infinity,
            child: Stack(
              children: const [
                Positioned.fill(
                  child: AppShimmerContainer(width: double.infinity, height: 230.0, borderRadius: 0.0),
                ),
                // Top-Right Date Pill Overlay Shimmer
                Positioned(
                  top: 10.0,
                  right: 10.0,
                  child: AppShimmerContainer(width: 70.0, height: 22.0, borderRadius: 20.0),
                ),
                // Bottom-Right Open Icon Pill Overlay Shimmer
                Positioned(
                  bottom: 10.0,
                  right: 10.0,
                  child: AppShimmerContainer(width: 28.0, height: 28.0, borderRadius: 14.0),
                ),
              ],
            ),
          ),

          // 2. Caption & Bottom Metrics / Action Row Shimmer
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                // Caption Lines
                AppShimmerContainer(width: double.infinity, height: 12.0, borderRadius: 4.0),
                SizedBox(height: 6.0),
                AppShimmerContainer(width: 180.0, height: 12.0, borderRadius: 4.0),
                SizedBox(height: 14.0),

                // Metrics & Action Button Row
                Row(
                  children: [
                    AppShimmerContainer(width: 35.0, height: 16.0, borderRadius: 4.0),
                    SizedBox(width: 10.0),
                    AppShimmerContainer(width: 35.0, height: 16.0, borderRadius: 4.0),
                    Spacer(),
                    AppShimmerContainer(width: 120.0, height: 34.0, borderRadius: 8.0),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isMobile) {
      return ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: count,
        itemBuilder: (context, index) => _buildShimmerCard(),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final int crossAxisCount = width >= 1024 ? 3 : 2;

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: count,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 16.0,
            mainAxisSpacing: 16.0,
            mainAxisExtent: 360.0,
          ),
          itemBuilder: (context, index) => _buildShimmerCard(),
        );
      },
    );
  }
}
