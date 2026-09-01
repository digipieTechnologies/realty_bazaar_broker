// File: lib/widgets/shimmer/ad_campaign_settings_shimmer_widget.dart
// Purpose: Premium responsive shimmer loading UI component for Ad Campaign Settings screen,
// optimized for both Desktop (2-column grid) and Mobile (stacked column) layouts.

import 'package:flutter/material.dart';

import '../../app/app_colors.dart';
import '../../app/app_constants.dart';
import '../../util/common_ext.dart';
import 'app_shimmer_container.dart';

class AdCampaignSettingsShimmerWidget extends StatelessWidget {
  const AdCampaignSettingsShimmerWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final isDesktop = context.isDesktop;

    return SingleChildScrollView(
      padding: AppConstants.getTabPadding(context),
      child: Center(
        child: Container(
          constraints: BoxConstraints(maxWidth: isDesktop ? 900.0 : 600.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Desktop 2-column or Mobile 1-column layout
              if (isDesktop)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Left Column (Target Areas & Map Banner)
                    Expanded(
                      flex: 6,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildGenderShimmer(),
                          const SizedBox(height: 24.0),
                          _buildTargetAreasShimmer(),
                          const SizedBox(height: 24.0),
                          _buildMapBannerShimmer(),
                        ],
                      ),
                    ),
                    const SizedBox(width: 24.0),

                    // Right Column (Suggestions & Advanced Settings)
                    Expanded(
                      flex: 6,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildTargetingSuggestionsShimmer(),
                          const SizedBox(height: 24.0),
                          _buildAdvancedSettingsShimmer(),
                        ],
                      ),
                    ),
                  ],
                )
              else
                // Mobile Stacked Column
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildGenderShimmer(),
                    const SizedBox(height: 20.0),
                    _buildTargetAreasShimmer(),
                    const SizedBox(height: 20.0),
                    _buildMapBannerShimmer(),
                    const SizedBox(height: 24.0),
                    _buildTargetingSuggestionsShimmer(),
                    const SizedBox(height: 24.0),
                    _buildAdvancedSettingsShimmer(),
                  ],
                ),

              const SizedBox(height: 32.0),

              // Primary Save Button Shimmer
              const AppShimmerContainer(width: double.infinity, height: 50.0, borderRadius: 14.0),
            ],
          ),
        ),
      ),
    );
  }

  // --- Gender Radios Shimmer ---
  Widget _buildGenderShimmer() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const AppShimmerContainer(width: 130, height: 18, borderRadius: 4),
        const SizedBox(height: 12.0),
        Row(
          children: const [
            AppShimmerContainer(width: 70, height: 32, borderRadius: 16),
            SizedBox(width: 16.0),
            AppShimmerContainer(width: 70, height: 32, borderRadius: 16),
            SizedBox(width: 16.0),
            AppShimmerContainer(width: 70, height: 32, borderRadius: 16),
          ],
        ),
      ],
    );
  }

  // --- Target Areas Input & Chip Placeholders Shimmer ---
  Widget _buildTargetAreasShimmer() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const AppShimmerContainer(width: 160, height: 18, borderRadius: 4),
        const SizedBox(height: 6.0),
        const AppShimmerContainer(width: 260, height: 14, borderRadius: 4),
        const SizedBox(height: 12.0),
        // Active Area Chips Shimmer
        Row(
          children: const [
            AppShimmerContainer(width: 140, height: 30, borderRadius: 8),
            SizedBox(width: 8.0),
            AppShimmerContainer(width: 120, height: 30, borderRadius: 8),
          ],
        ),
        const SizedBox(height: 10.0),
        // Search Input Box Shimmer
        const AppShimmerContainer(width: double.infinity, height: 48.0, borderRadius: 10.0),
      ],
    );
  }

  // --- Map Banner Card Shimmer ---
  Widget _buildMapBannerShimmer() {
    return const AppShimmerContainer(width: double.infinity, height: 160.0, borderRadius: 16.0);
  }

  // --- Targeting Suggestions Shimmer ---
  Widget _buildTargetingSuggestionsShimmer() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const AppShimmerContainer(width: 170, height: 18, borderRadius: 4),
        const SizedBox(height: 6.0),
        const AppShimmerContainer(width: 240, height: 14, borderRadius: 4),
        const SizedBox(height: 12.0),
        const AppShimmerContainer(width: double.infinity, height: 48.0, borderRadius: 10.0),
        const SizedBox(height: 12.0),
        // Tag Pills Shimmer
        Wrap(
          spacing: 8.0,
          runSpacing: 8.0,
          children: const [
            AppShimmerContainer(width: 90, height: 28, borderRadius: 8),
            AppShimmerContainer(width: 60, height: 28, borderRadius: 8),
            AppShimmerContainer(width: 80, height: 28, borderRadius: 8),
            AppShimmerContainer(width: 100, height: 28, borderRadius: 8),
          ],
        ),
      ],
    );
  }

  // --- Advanced Settings Container Shimmer ---
  Widget _buildAdvancedSettingsShimmer() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: AppColors.border, width: 1.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AppShimmerContainer(width: 160, height: 20, borderRadius: 4),
          const SizedBox(height: 20.0),
          // Age Slider Header & Track Shimmer
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              AppShimmerContainer(width: 90, height: 16, borderRadius: 4),
              AppShimmerContainer(width: 70, height: 22, borderRadius: 10),
            ],
          ),
          const SizedBox(height: 10.0),
          const AppShimmerContainer(width: double.infinity, height: 16, borderRadius: 8),
          const SizedBox(height: 24.0),

          // Time Schedule Header & Track Shimmer
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              AppShimmerContainer(width: 110, height: 16, borderRadius: 4),
              AppShimmerContainer(width: 130, height: 22, borderRadius: 10),
            ],
          ),
          const SizedBox(height: 10.0),
          Row(
            children: const [
              AppShimmerContainer(width: 20, height: 20, borderRadius: 4),
              SizedBox(width: 8.0),
              AppShimmerContainer(width: 80, height: 14, borderRadius: 4),
            ],
          ),
          const SizedBox(height: 10.0),
          const AppShimmerContainer(width: double.infinity, height: 16, borderRadius: 8),
        ],
      ),
    );
  }
}
