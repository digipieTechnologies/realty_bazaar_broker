// File: lib/widgets/shimmer/dashboard_summary_shimmer_widget.dart
// Purpose: Dedicated shimmer skeleton placeholder for the 4 dashboard summary stat cards.

import 'package:flutter/material.dart';
import '../../util/common_ext.dart';
import 'stat_card_shimmer_widget.dart';

class DashboardSummaryShimmerWidget extends StatelessWidget {
  const DashboardSummaryShimmerWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final isDesktop = context.isDesktopUI;

    return isDesktop
        ? const Row(
            children: [
              Expanded(child: StatCardSkeleton(isDesktop: true)),
              SizedBox(width: 12.0),
              Expanded(child: StatCardSkeleton(isDesktop: true)),
              SizedBox(width: 12.0),
              Expanded(child: StatCardSkeleton(isDesktop: true)),
              SizedBox(width: 12.0),
              Expanded(child: StatCardSkeleton(isDesktop: true)),
            ],
          )
        : const Column(
            children: [
              Row(
                children: [
                  Expanded(child: StatCardSkeleton(isDesktop: false)),
                  SizedBox(width: 10.0),
                  Expanded(child: StatCardSkeleton(isDesktop: false)),
                ],
              ),
              SizedBox(height: 10.0),
              Row(
                children: [
                  Expanded(child: StatCardSkeleton(isDesktop: false)),
                  SizedBox(width: 10.0),
                  Expanded(child: StatCardSkeleton(isDesktop: false)),
                ],
              ),
            ],
          );
  }
}
