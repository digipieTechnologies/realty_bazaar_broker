// File: lib/widgets/shimmer/grow_plan_shimmer_widget.dart
// Purpose: Reusable shimmer skeleton placeholder for the Grow tab plan cards, responsive across mobile, tablet, and desktop.

import 'package:flutter/material.dart';

import '../../app/app_colors.dart';
import 'app_shimmer_container.dart';

class GrowPlanShimmerWidget extends StatelessWidget {
  const GrowPlanShimmerWidget({super.key});

  Widget _buildShimmerCard({required double width}) {
    return Container(
      width: width,
      margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 10.0),
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(22.0),
        border: Border.all(color: AppColors.border, width: 1.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12.0,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title Badge shimmer
          const AppShimmerContainer(width: 120.0, height: 24.0, borderRadius: 20.0),
          const SizedBox(height: 14.0),

          // Amount & Period shimmer
          const Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              AppShimmerContainer(width: 110.0, height: 32.0, borderRadius: 8.0),
              SizedBox(width: 6.0),
              AppShimmerContainer(width: 50.0, height: 14.0, borderRadius: 4.0),
            ],
          ),
          const SizedBox(height: 10.0),

          // Description shimmer
          const AppShimmerContainer(width: double.infinity, height: 12.0, borderRadius: 4.0),
          const SizedBox(height: 6.0),
          const AppShimmerContainer(width: 170.0, height: 12.0, borderRadius: 4.0),
          const SizedBox(height: 16.0),

          // Divider shimmer
          const AppShimmerContainer(width: double.infinity, height: 1.0, borderRadius: 0.0),
          const SizedBox(height: 16.0),

          // Benefits List shimmer
          Expanded(
            child: Column(
              children: List.generate(
                4,
                (index) => Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: Row(
                    children: [
                      const AppShimmerContainer(width: 20.0, height: 20.0, borderRadius: 10.0),
                      const SizedBox(width: 10.0),
                      Expanded(
                        child: AppShimmerContainer(width: double.infinity, height: 12.0, borderRadius: 4.0),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 12.0),

          // CTA Button shimmer
          const AppShimmerContainer(width: double.infinity, height: 48.0, borderRadius: 12.0),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double maxWidth = constraints.maxWidth;
        final bool isMobile = maxWidth < 600;
        final bool isTablet = maxWidth >= 600 && maxWidth < 1024;
        const double containerHeight = 540.0;

        if (isMobile) {
          return SizedBox(
            height: containerHeight,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12.0),
              itemCount: 3,
              itemBuilder: (context, index) {
                final cardWidth = maxWidth * 0.80;
                return _buildShimmerCard(width: cardWidth);
              },
            ),
          );
        }

        if (isTablet) {
          return SizedBox(
            height: containerHeight,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              itemCount: 3,
              itemBuilder: (context, index) {
                final cardWidth = maxWidth * 0.46;
                return _buildShimmerCard(width: cardWidth);
              },
            ),
          );
        }

        // Desktop
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: SizedBox(
            height: containerHeight,
            child: Row(
              children: List.generate(
                4,
                (index) => Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(right: index < 3 ? 10.0 : 0.0),
                    child: _buildShimmerCard(width: double.infinity),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
