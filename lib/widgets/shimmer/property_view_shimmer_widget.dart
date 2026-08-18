// File: lib/widgets/shimmer/property_view_shimmer_widget.dart
// Purpose: Dedicated shimmer loading placeholder for ViewPropertyDialog detailing media gallery, specs, location, and amenities.

import 'package:flutter/material.dart';
import 'app_shimmer_container.dart';

class PropertyViewShimmerWidget extends StatelessWidget {
  const PropertyViewShimmerWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // 1. Media Gallery Shimmer Placeholder
        const AppShimmerContainer(
          height: 240.0,
          borderRadius: 16.0,
        ),
        const SizedBox(height: 20.0),

        // 2. Badges Row Shimmer
        const Row(
          children: [
            AppShimmerContainer(width: 84.0, height: 26.0, borderRadius: 20.0),
            SizedBox(width: 8.0),
            AppShimmerContainer(width: 76.0, height: 26.0, borderRadius: 20.0),
            SizedBox(width: 8.0),
            AppShimmerContainer(width: 100.0, height: 26.0, borderRadius: 20.0),
          ],
        ),
        const SizedBox(height: 16.0),

        // 3. Price Tag & Title Shimmer
        const AppShimmerContainer(width: 160.0, height: 28.0, borderRadius: 6.0),
        const SizedBox(height: 8.0),
        const AppShimmerContainer(width: 260.0, height: 20.0, borderRadius: 6.0),
        const SizedBox(height: 20.0),

        // 4. Specs Grid Shimmer (4 Cards Grid)
        const Row(
          children: [
            Expanded(child: AppShimmerContainer(height: 64.0, borderRadius: 12.0)),
            SizedBox(width: 12.0),
            Expanded(child: AppShimmerContainer(height: 64.0, borderRadius: 12.0)),
          ],
        ),
        const SizedBox(height: 12.0),
        const Row(
          children: [
            Expanded(child: AppShimmerContainer(height: 64.0, borderRadius: 12.0)),
            SizedBox(width: 12.0),
            Expanded(child: AppShimmerContainer(height: 64.0, borderRadius: 12.0)),
          ],
        ),
        const SizedBox(height: 20.0),

        // 5. Location Card Shimmer
        const AppShimmerContainer(height: 72.0, borderRadius: 14.0),
        const SizedBox(height: 20.0),

        // 6. Amenities Wrap Shimmer
        const Wrap(
          spacing: 8.0,
          runSpacing: 8.0,
          children: [
            AppShimmerContainer(width: 90.0, height: 32.0, borderRadius: 20.0),
            AppShimmerContainer(width: 110.0, height: 32.0, borderRadius: 20.0),
            AppShimmerContainer(width: 80.0, height: 32.0, borderRadius: 20.0),
            AppShimmerContainer(width: 120.0, height: 32.0, borderRadius: 20.0),
          ],
        ),
      ],
    );
  }
}
