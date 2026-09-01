// File: lib/widgets/shimmer/lead_list_shimmer_widget.dart
// Purpose: Reusable shimmer loader widget with solid card container border and synchronized inner content shimmer.

import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart' as package_shimmer;

import '../../app/app_colors.dart';
import '../../util/common_ext.dart';

class LeadListShimmerWidget extends StatelessWidget {
  final int count;
  final bool? isCompact;

  const LeadListShimmerWidget({super.key, this.count = 4, this.isCompact});

  @override
  Widget build(BuildContext context) {
    final useMobileTile = isCompact ?? context.isMobileUI;

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: useMobileTile ? const EdgeInsets.symmetric(horizontal: 4.0, vertical: 4.0) : EdgeInsets.zero,
      itemCount: count,
      itemBuilder: (context, index) {
        return useMobileTile ? _buildMobileTileShimmer() : _buildDesktopRowShimmer();
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
        padding: const EdgeInsets.all(10.0),
        child: package_shimmer.Shimmer.fromColors(
          baseColor: AppColors.shimmerBase,
          highlightColor: AppColors.background,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Row: Avatar + Name + Platform Badge & Date
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 36.0,
                    height: 36.0,
                    decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 10.0),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(height: 13.0, width: 110.0, color: Colors.white),
                        const SizedBox(height: 5.0),
                        Row(
                          children: [
                            Container(
                              width: 14.0,
                              height: 14.0,
                              decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                            ),
                            const SizedBox(width: 6.0),
                            Container(height: 10.0, width: 60.0, color: Colors.white),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8.0),
              // Contact Number Box & Quick Action Icons
              Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 28.0,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(6.0),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6.0),
                  Container(
                    width: 26.0,
                    height: 26.0,
                    decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 4.0),
                  Container(
                    width: 26.0,
                    height: 26.0,
                    decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                  ),
                ],
              ),
              const SizedBox(height: 8.0),
              // Property Details Box
              Container(
                height: 30.0,
                width: double.infinity,
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(6.0)),
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
        highlightColor: AppColors.background,
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
            Expanded(flex: 2, child: Container(height: 12.0, width: 90.0, color: Colors.white)),

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
