// File: lib/widgets/shimmer/post_list_horizontal_shimmer_widget.dart
// Purpose: Dedicated horizontal shimmer loader placeholder for recent social post cards on dashboard.

import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart' as package_shimmer;

import '../../app/app_colors.dart';

class PostListHorizontalShimmerWidget extends StatelessWidget {
  final int count;
  final double cardWidth;
  final double height;

  const PostListHorizontalShimmerWidget({
    super.key,
    this.count = 3,
    this.cardWidth = 260.0,
    this.height = 195.0,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: List.generate(count, (index) {
          return SizedBox(
            width: cardWidth,
            child: Padding(padding: const EdgeInsets.only(right: 14.0), child: _buildPostCardSkeleton()),
          );
        }),
      ),
    );
  }

  Widget _buildPostCardSkeleton() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14.0),
        border: Border.all(color: AppColors.border, width: 1.0),
      ),
      child: package_shimmer.Shimmer.fromColors(
        baseColor: AppColors.shimmerBase,
        highlightColor: AppColors.shimmerHighlight,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Minimal Image Skeleton (Height: 120.0px)
            Container(
              height: 120.0,
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(14.0)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Caption Skeletons
                  Container(height: 13.0, width: 180.0, color: Colors.white),
                  const SizedBox(height: 4.0),
                  Container(height: 13.0, width: 120.0, color: Colors.white),
                  const SizedBox(height: 10.0),
                  // Metrics Row Skeleton
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(height: 12.0, width: 70.0, color: Colors.white),
                      Container(height: 10.0, width: 50.0, color: Colors.white),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
