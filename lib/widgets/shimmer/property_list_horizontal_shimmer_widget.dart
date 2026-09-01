// File: lib/widgets/shimmer/property_list_horizontal_shimmer_widget.dart
// Purpose: Dedicated horizontal shimmer loader placeholder for recent property cards on dashboard.

import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart' as package_shimmer;

import '../../app/app_colors.dart';

class PropertyListHorizontalShimmerWidget extends StatelessWidget {
  final int count;
  final double cardWidth;
  final double height;

  const PropertyListHorizontalShimmerWidget({
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
            child: Padding(padding: const EdgeInsets.only(right: 14.0), child: _buildPropertyCardSkeleton()),
          );
        }),
      ),
    );
  }

  Widget _buildPropertyCardSkeleton() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14.0),
        border: Border.all(color: AppColors.border, width: 1.0),
      ),
      child: package_shimmer.Shimmer.fromColors(
        baseColor: AppColors.shimmerBase,
        highlightColor: AppColors.background,
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
                  // Title Skeleton
                  Container(height: 14.0, width: 140.0, color: Colors.white),
                  const SizedBox(height: 4.0),
                  // Price Skeleton
                  Container(height: 14.0, width: 80.0, color: Colors.white),
                  const SizedBox(height: 5.0),
                  // Location Line Skeleton
                  Container(height: 11.0, width: 160.0, color: Colors.white),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
