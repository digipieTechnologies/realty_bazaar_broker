// File: lib/widgets/shimmer/video_request_list_shimmer_widget.dart
// Purpose: Reusable shimmer loader widget with solid card container border and synchronized inner content shimmer.

import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart' as package_shimmer;

import '../../app/app_colors.dart';
import '../../util/common_ext.dart';

/// Shimmer loader for the list of video request row items inside the table container.
class VideoRequestListShimmerWidget extends StatelessWidget {
  final int count;

  const VideoRequestListShimmerWidget({super.key, this.count = 3});

  @override
  Widget build(BuildContext context) {
    final isMobile = context.isMobileUI;

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: isMobile ? const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0) : EdgeInsets.zero,
      itemCount: count,
      itemBuilder: (context, index) {
        return isMobile ? _buildMobileCardShimmer() : _buildDesktopRowShimmer();
      },
    );
  }

  Widget _buildMobileCardShimmer() {
    return Container(
      margin: const EdgeInsets.only(bottom: 10.0),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: AppColors.border, width: 1.0),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: package_shimmer.Shimmer.fromColors(
          baseColor: AppColors.shimmerBase,
          highlightColor: AppColors.shimmerHighlight,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Row: Property Icon Box + Title + Menu Icon
              Row(
                children: [
                  Container(
                    width: 32.0,
                    height: 32.0,
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8.0)),
                  ),
                  const SizedBox(width: 10.0),
                  Expanded(child: Container(height: 14.0, width: 160.0, color: Colors.white)),
                  const SizedBox(width: 6.0),
                  Container(
                    width: 24.0,
                    height: 24.0,
                    decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                  ),
                ],
              ),
              const SizedBox(height: 8.0),
              // Address Line
              Row(
                children: [
                  Container(
                    width: 14.0,
                    height: 14.0,
                    decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 6.0),
                  Expanded(
                    child: Container(height: 12.0, width: double.infinity, color: Colors.white),
                  ),
                ],
              ),
              const SizedBox(height: 8.0),
              // Broker Line
              Row(
                children: [
                  Container(
                    width: 14.0,
                    height: 14.0,
                    decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 6.0),
                  Container(height: 11.5, width: 120.0, color: Colors.white),
                ],
              ),
              const SizedBox(height: 8.0),
              // Created Date & Status Badge Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 12.0,
                        height: 12.0,
                        decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 4.0),
                      Container(height: 11.0, width: 80.0, color: Colors.white),
                    ],
                  ),
                  Container(
                    height: 22.0,
                    width: 70.0,
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(6.0)),
                  ),
                ],
              ),
              const SizedBox(height: 8.0),
              // Notes Box
              Container(
                height: 36.0,
                width: double.infinity,
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8.0)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDesktopRowShimmer() {
    return Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.border, width: 1.0)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 14.0),
      child: package_shimmer.Shimmer.fromColors(
        baseColor: AppColors.shimmerBase,
        highlightColor: AppColors.shimmerHighlight,
        child: Row(
          children: [
            // Flex 3: Property Details
            Expanded(
              flex: 3,
              child: Row(
                children: [
                  Container(
                    width: 36.0,
                    height: 36.0,
                    decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 12.0),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(height: 14.0, width: 140.0, color: Colors.white),
                        const SizedBox(height: 6.0),
                        Container(height: 11.0, width: 110.0, color: Colors.white),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12.0),

            // Flex 2: Status
            Expanded(
              flex: 2,
              child: Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  height: 24.0,
                  width: 70.0,
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(6.0)),
                ),
              ),
            ),
            const SizedBox(width: 12.0),

            // Flex 4: Notes
            Expanded(
              flex: 4,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(height: 12.0, width: double.infinity, color: Colors.white),
                  const SizedBox(height: 6.0),
                  Container(height: 12.0, width: 120.0, color: Colors.white),
                ],
              ),
            ),
            const SizedBox(width: 12.0),

            // Flex 2: Created At
            Expanded(flex: 2, child: Container(height: 12.0, width: 80.0, color: Colors.white)),

            // Action Menu
            SizedBox(
              width: 40.0,
              child: Align(
                alignment: Alignment.centerRight,
                child: Container(
                  width: 20.0,
                  height: 20.0,
                  decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Shimmer loader for the metric stats cards at the top of the video requests screen.
class VideoRequestStatsShimmerWidget extends StatelessWidget {
  const VideoRequestStatsShimmerWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final isMobile = context.isMobileUI;
    final isDesktop = context.isDesktop;

    if (isMobile) {
      return GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: 4,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 10.0,
          mainAxisSpacing: 10.0,
          mainAxisExtent: 76.0,
        ),
        itemBuilder: (context, index) => Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12.0),
            border: Border.all(color: AppColors.border, width: 1.0),
          ),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: package_shimmer.Shimmer.fromColors(
              baseColor: AppColors.shimmerBase,
              highlightColor: AppColors.shimmerHighlight,
              child: Row(
                children: [
                  Container(
                    width: 24.0,
                    height: 24.0,
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(6.0)),
                  ),
                  const SizedBox(width: 6.0),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(height: 10.0, width: 60.0, color: Colors.white),
                        const SizedBox(height: 4.0),
                        Container(height: 14.0, width: 30.0, color: Colors.white),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    final crossAxisCount = isDesktop ? 4 : 2;
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 4,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 16.0,
        mainAxisSpacing: 16.0,
        mainAxisExtent: 130.0,
      ),
      itemBuilder: (context, index) => Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16.0),
          border: Border.all(color: AppColors.border, width: 1.0),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: package_shimmer.Shimmer.fromColors(
            baseColor: AppColors.shimmerBase,
            highlightColor: AppColors.shimmerHighlight,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(height: 12.0, width: 100.0, color: Colors.white),
                Container(height: 24.0, width: 60.0, color: Colors.white),
                Container(height: 10.0, width: 120.0, color: Colors.white),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
