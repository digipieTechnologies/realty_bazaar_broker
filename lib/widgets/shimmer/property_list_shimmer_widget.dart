import 'package:flutter/material.dart';

import '../../app/app_colors.dart';
import 'app_shimmer_container.dart';

class PropertyListShimmerWidget extends StatelessWidget {
  final int count;

  const PropertyListShimmerWidget({super.key, this.count = 4});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWeb = constraints.maxWidth >= 768;

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: count,
          itemBuilder: (context, index) {
            return isWeb ? _buildWebShimmerCard() : _buildMobileShimmerCard();
          },
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // WEB / DESKTOP HORIZONTAL SHIMMER CARD
  // ---------------------------------------------------------------------------
  Widget _buildWebShimmerCard() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16.0),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: AppColors.border, width: 1.0),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left Image Shimmer (Matches 260px wide PropertyCardWeb image)
          AppShimmerContainer(width: 260.0, height: 180.0, borderRadius: 12.0),
          SizedBox(width: 20.0),

          // Right Content Column Shimmer
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title Shimmer
                    AppShimmerContainer(width: 280.0, height: 22.0, borderRadius: 4.0),
                    SizedBox(height: 10.0),

                    // Address Shimmer
                    AppShimmerContainer(width: 190.0, height: 14.0, borderRadius: 4.0),
                    SizedBox(height: 14.0),

                    // Amenities / Status Chips Row Shimmer
                    Row(
                      children: [
                        AppShimmerContainer(width: 76.0, height: 26.0, borderRadius: 8.0),
                        SizedBox(width: 8.0),
                        AppShimmerContainer(width: 84.0, height: 26.0, borderRadius: 8.0),
                        SizedBox(width: 8.0),
                        AppShimmerContainer(width: 100.0, height: 26.0, borderRadius: 8.0),
                      ],
                    ),
                  ],
                ),
                SizedBox(height: 16.0),

                // Footer Row: Price + Specs Shimmer
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // Specs Shimmer
                    Row(
                      children: [
                        AppShimmerContainer(width: 65.0, height: 16.0, borderRadius: 4.0),
                        SizedBox(width: 14.0),
                        AppShimmerContainer(width: 65.0, height: 16.0, borderRadius: 4.0),
                        SizedBox(width: 14.0),
                        AppShimmerContainer(width: 85.0, height: 16.0, borderRadius: 4.0),
                      ],
                    ),

                    // Price Tag Shimmer
                    AppShimmerContainer(width: 120.0, height: 24.0, borderRadius: 6.0),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // MOBILE VERTICAL SHIMMER CARD
  // ---------------------------------------------------------------------------
  Widget _buildMobileShimmerCard() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16.0),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: AppColors.border, width: 1.0),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image Shimmer
          AppShimmerContainer(width: double.infinity, height: 200.0, borderRadius: 12.0),
          SizedBox(height: 16.0),

          // Title Shimmer
          AppShimmerContainer(width: 220.0, height: 20.0, borderRadius: 4.0),
          SizedBox(height: 8.0),

          // Address Shimmer
          AppShimmerContainer(width: 160.0, height: 14.0, borderRadius: 4.0),
          SizedBox(height: 14.0),

          // Chips Row Shimmer
          Row(
            children: [
              Expanded(child: AppShimmerContainer(height: 26.0, borderRadius: 8.0)),
              SizedBox(width: 8.0),
              Expanded(child: AppShimmerContainer(height: 26.0, borderRadius: 8.0)),
              SizedBox(width: 8.0),
              Expanded(child: AppShimmerContainer(height: 26.0, borderRadius: 8.0)),
            ],
          ),
          SizedBox(height: 14.0),

          // Specs Row Shimmer
          Row(
            children: [
              Expanded(child: AppShimmerContainer(height: 16.0, borderRadius: 4.0)),
              SizedBox(width: 10.0),
              Expanded(child: AppShimmerContainer(height: 16.0, borderRadius: 4.0)),
              SizedBox(width: 10.0),
              Expanded(child: AppShimmerContainer(height: 16.0, borderRadius: 4.0)),
            ],
          ),
        ],
      ),
    );
  }
}
