// File: lib/widgets/shimmer/video_request_shimmer_widget.dart
// Purpose: Shimmer placeholder widget matching the video request shoot dialog form.

import 'package:flutter/material.dart';
import './app_shimmer_container.dart';

class VideoRequestShimmerWidget extends StatelessWidget {
  const VideoRequestShimmerWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header Shimmer
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: const [
            AppShimmerContainer(height: 22.0, width: 180.0),
            AppShimmerContainer(height: 24.0, width: 24.0, borderRadius: 12.0),
          ],
        ),
        const SizedBox(height: 16.0),
        // Description Shimmer
        const AppShimmerContainer(height: 12.0, width: double.infinity),
        const SizedBox(height: 6.0),
        const AppShimmerContainer(height: 12.0, width: 300.0),
        const SizedBox(height: 20.0),
        
        // Option 1 Shimmer Row
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const AppShimmerContainer(height: 20.0, width: 20.0, borderRadius: 10.0),
            const SizedBox(width: 10.0),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  AppShimmerContainer(height: 14.0, width: 140.0),
                  SizedBox(height: 6.0),
                  AppShimmerContainer(height: 11.0, width: double.infinity),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16.0),

        // Option 2 Shimmer Row
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const AppShimmerContainer(height: 20.0, width: 20.0, borderRadius: 10.0),
            const SizedBox(width: 10.0),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  AppShimmerContainer(height: 14.0, width: 160.0),
                  SizedBox(height: 6.0),
                  AppShimmerContainer(height: 11.0, width: double.infinity),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 20.0),

        // Input Label Shimmer
        const AppShimmerContainer(height: 14.0, width: 260.0),
        const SizedBox(height: 8.0),

        // Input Box Shimmer
        const AppShimmerContainer(height: 56.0, borderRadius: 10.0),
        const SizedBox(height: 24.0),

        // Button Shimmer
        const AppShimmerContainer(height: 46.0, borderRadius: 10.0),
      ],
    );
  }
}
