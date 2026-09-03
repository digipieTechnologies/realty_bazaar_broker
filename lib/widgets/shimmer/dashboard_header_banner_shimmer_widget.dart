// File: lib/widgets/shimmer/dashboard_header_banner_shimmer_widget.dart
// Purpose: Shimmer skeleton placeholder for the Dashboard top welcome header banner widget.

import 'package:flutter/material.dart';

import '../../app/app_colors.dart';
import '../../util/common_ext.dart';
import 'app_shimmer_container.dart';

class DashboardHeaderBannerShimmerWidget extends StatelessWidget {
  const DashboardHeaderBannerShimmerWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final isMobile = context.isMobile;

    return Container(
      width: double.infinity,
      margin: EdgeInsets.only(bottom: isMobile ? 12.0 : 20.0),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(22.0),
        border: Border.all(color: AppColors.border, width: 1.0),
      ),
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 14.0 : 22.0, vertical: isMobile ? 14.0 : 20.0),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Category Pill Tag Skeleton
                AppShimmerContainer(
                  width: isMobile ? 110 : 140,
                  height: isMobile ? 18 : 22,
                  borderRadius: 20.0,
                ),
                SizedBox(height: isMobile ? 8.0 : 12.0),
                // Greeting Title Skeleton
                AppShimmerContainer(
                  width: isMobile ? 160 : 240,
                  height: isMobile ? 20 : 26,
                  borderRadius: 6.0,
                ),
                const SizedBox(height: 6.0),
                // Subtitle Line Skeleton
                AppShimmerContainer(
                  width: isMobile ? 210 : 300,
                  height: isMobile ? 12 : 14,
                  borderRadius: 4.0,
                ),
              ],
            ),
          ),
          SizedBox(width: isMobile ? 10.0 : 16.0),
          // Verified Avatar Circle Skeleton
          AppShimmerContainer(width: isMobile ? 44 : 56, height: isMobile ? 44 : 56, borderRadius: 28.0),
        ],
      ),
    );
  }
}
