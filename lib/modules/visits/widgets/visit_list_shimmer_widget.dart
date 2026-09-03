// File: lib/modules/visits/widgets/visit_list_shimmer_widget.dart
// Purpose: Reusable shimmer skeleton loader for site visits table and tile lists.

import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart' as package_shimmer;

import '../../../../app/app_colors.dart';
import '../../../../util/common_ext.dart';

class VisitListShimmerWidget extends StatelessWidget {
  final int count;
  final bool? isCompact;

  const VisitListShimmerWidget({super.key, this.count = 4, this.isCompact});

  @override
  Widget build(BuildContext context) {
    final useMobileTile = isCompact ?? context.isMobile;

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
      margin: const EdgeInsets.only(bottom: 12.0),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20.0),
        border: Border.all(color: AppColors.border, width: 1.0),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: package_shimmer.Shimmer.fromColors(
          baseColor: AppColors.shimmerBase,
          highlightColor: AppColors.background,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 44.0,
                    height: 44.0,
                    decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 12.0),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(width: 120, height: 14, color: Colors.white),
                        const SizedBox(height: 6),
                        Container(width: 80, height: 10, color: Colors.white),
                      ],
                    ),
                  ),
                  Container(width: 70, height: 24, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12))),
                ],
              ),
              const SizedBox(height: 14.0),
              Container(
                height: 36.0,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10.0),
                ),
              ),
              const SizedBox(height: 12.0),
              Row(
                children: [
                  Expanded(child: Container(height: 32.0, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)))),
                  const SizedBox(width: 10),
                  Container(width: 36, height: 36, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8))),
                  const SizedBox(width: 6),
                  Container(width: 36, height: 36, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8))),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDesktopRowShimmer() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.border, width: 0.8)),
      ),
      child: package_shimmer.Shimmer.fromColors(
        baseColor: AppColors.shimmerBase,
        highlightColor: AppColors.background,
        child: Row(
          children: [
            Container(width: 36, height: 36, decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle)),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(width: 130, height: 12, color: Colors.white),
                  const SizedBox(height: 4),
                  Container(width: 90, height: 10, color: Colors.white),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              flex: 3,
              child: Container(height: 14, color: Colors.white),
            ),
            const SizedBox(width: 16),
            Expanded(
              flex: 2,
              child: Container(height: 14, color: Colors.white),
            ),
            const SizedBox(width: 16),
            Container(width: 80, height: 26, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12))),
            const SizedBox(width: 16),
            Container(width: 60, height: 32, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8))),
          ],
        ),
      ),
    );
  }
}
