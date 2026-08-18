// File: lib/widgets/shimmer/app_shimmer_container.dart
// Purpose: Reference shimmer loader placeholder.

import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart' as package_shimmer;
import '../containers/container_corner.dart';
import '../../app/app_colors.dart';

// Wrapper class to ensure the user's requested syntax for Shimmer works perfectly
// with the third-party package:shimmer/shimmer.dart package.
class Shimmer extends StatelessWidget {
  final Color color;
  final Widget child;

  const Shimmer({super.key, required this.color, required this.child});

  @override
  Widget build(BuildContext context) {
    return package_shimmer.Shimmer.fromColors(
      baseColor: color,
      highlightColor: AppColors.shimmerHighlight,
      child: child,
    );
  }
}

class AppShimmerContainer extends StatelessWidget {
  final double width;
  final double height;
  final double borderRadius;
  final Color? borderColor;
  final BorderRadius? borderRadiusShape;
  final EdgeInsets? margin;

  const AppShimmerContainer({
    super.key,
    this.width = double.infinity,
    required this.height,
    this.borderRadius = 8,
    this.borderColor,
    this.borderRadiusShape,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: margin ?? EdgeInsets.zero,
      child: ClipRRect(
        borderRadius: borderRadiusShape ?? BorderRadius.circular(borderRadius),
        child: ContainerCorner(
          borderWidth: 1.5,
          borderColor: borderColor,
          borderRadius: borderRadius,
          borderRadiusShape: borderRadiusShape,
          child: Shimmer(
            color: AppColors.shimmerBase,
            child: ContainerCorner(
              height: height,
              width: width,
              color: Colors.grey.shade300,
              borderRadius: borderRadius,
              borderRadiusShape: borderRadiusShape,
            ),
          ),
        ),
      ),
    );
  }
}
