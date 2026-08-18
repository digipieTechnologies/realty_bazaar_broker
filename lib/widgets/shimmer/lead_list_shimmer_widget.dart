// File: lib/widgets/shimmer/lead_list_shimmer_widget.dart
// Purpose: Reusable shimmer loader widget with solid card container border and synchronized inner content shimmer.

import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart' as package_shimmer;
import '../../app/app_colors.dart';
import '../../util/common_ext.dart';

class LeadListShimmerWidget extends StatelessWidget {
  final int count;

  const LeadListShimmerWidget({
    super.key,
    this.count = 4,
  });

  @override
  Widget build(BuildContext context) {
    final isMobile = context.isMobileUI;

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: isMobile
          ? const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0)
          : EdgeInsets.zero,
      itemCount: count,
      itemBuilder: (context, index) {
        return isMobile ? _buildMobileTileShimmer() : _buildDesktopRowShimmer();
      },
    );
  }

  Widget _buildMobileTileShimmer() {
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
              // Top Row: Avatar + Name + Platform Badge & Date + Popup Menu
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 40.0,
                    height: 40.0,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 12.0),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(height: 14.0, width: 140.0, color: Colors.white),
                        const SizedBox(height: 6.0),
                        Row(
                          children: [
                            Container(width: 16.0, height: 16.0, decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle)),
                            const SizedBox(width: 6.0),
                            Container(height: 11.0, width: 80.0, color: Colors.white),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 24.0,
                    height: 24.0,
                    decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                  ),
                ],
              ),
              const SizedBox(height: 10.0),
              // Contact Number Box & Quick Action Icons
              Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 34.0,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8.0),
                  Container(width: 32.0, height: 32.0, decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle)),
                  const SizedBox(width: 4.0),
                  Container(width: 32.0, height: 32.0, decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle)),
                ],
              ),
              const SizedBox(height: 10.0),
              // Property Details Box
              Container(
                height: 38.0,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8.0),
                ),
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
        border: Border(
          bottom: BorderSide(color: AppColors.border, width: 1.0),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 14.0),
      child: package_shimmer.Shimmer.fromColors(
        baseColor: AppColors.shimmerBase,
        highlightColor: AppColors.shimmerHighlight,
        child: Row(
          children: [
            // Client Info
            Expanded(
              flex: 3,
              child: Row(
                children: [
                  Container(
                    width: 40.0,
                    height: 40.0,
                    decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 12.0),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(height: 14.0, width: 130.0, color: Colors.white),
                        const SizedBox(height: 6.0),
                        Container(height: 12.0, width: 90.0, color: Colors.white),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12.0),

            // Platform / Source
            Expanded(
              flex: 2,
              child: Align(
                alignment: Alignment.center,
                child: Container(
                  width: 20.0,
                  height: 20.0,
                  decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                ),
              ),
            ),
            const SizedBox(width: 12.0),

            // Property Details & Notes
            Expanded(
              flex: 4,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(height: 13.0, width: double.infinity, color: Colors.white),
                  const SizedBox(height: 6.0),
                  Container(height: 11.0, width: 160.0, color: Colors.white),
                ],
              ),
            ),
            const SizedBox(width: 12.0),

            // Created At
            Expanded(
              flex: 2,
              child: Container(height: 12.0, width: 90.0, color: Colors.white),
            ),

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
