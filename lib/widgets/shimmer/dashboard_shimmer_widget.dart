// File: lib/widgets/shimmer/dashboard_shimmer_widget.dart
// Purpose: Complete dashboard shimmer skeleton layout for initial dashboard loading on desktop & mobile views with proper SingleChildScrollView and padding.

import 'package:flutter/material.dart';
import '../../app/app_colors.dart';
import '../../app/app_constants.dart';
import '../../util/common_ext.dart';
import '../../widgets/common/app_card_container.dart';
import '../../widgets/common/app_section_header.dart';
import 'dashboard_summary_shimmer_widget.dart';
import 'lead_list_shimmer_widget.dart';
import 'post_list_horizontal_shimmer_widget.dart';
import 'property_list_horizontal_shimmer_widget.dart';
import 'social_connect_shimmer_widget.dart';

class DashboardShimmerWidget extends StatelessWidget {
  const DashboardShimmerWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final isDesktop = context.isDesktopUI;

    return SingleChildScrollView(
      padding: AppConstants.getTabPadding(context),
      child: isDesktop
          ? const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left Column (Flex 7)
                Expanded(
                  flex: 7,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppSectionHeader(
                        title: 'Overview Performance',
                        icon: Icons.insights_rounded,
                      ),
                      DashboardSummaryShimmerWidget(),
                      SizedBox(height: 24.0),
                      Divider(height: 1.0, color: AppColors.border),
                      SizedBox(height: 24.0),

                      // Recent Properties Shimmer Section
                      AppCardContainer(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            AppSectionHeader(
                              title: 'Recent Properties',
                              icon: Icons.apartment_rounded,
                              padding: EdgeInsets.fromLTRB(16.0, 12.0, 12.0, 12.0),
                            ),
                            Divider(height: 1.0, color: AppColors.border),
                            Padding(
                              padding: EdgeInsets.symmetric(vertical: 12.0),
                              child: PropertyListHorizontalShimmerWidget(count: 3),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 24.0),
                      Divider(height: 1.0, color: AppColors.border),
                      SizedBox(height: 24.0),

                      // Recent Posts Shimmer Section
                      AppCardContainer(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            AppSectionHeader(
                              title: 'Recent Posts',
                              icon: Icons.dynamic_feed_rounded,
                              padding: EdgeInsets.fromLTRB(16.0, 12.0, 12.0, 12.0),
                            ),
                            Divider(height: 1.0, color: AppColors.border),
                            Padding(
                              padding: EdgeInsets.symmetric(vertical: 12.0),
                              child: PostListHorizontalShimmerWidget(count: 3),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 24.0),

                // Right Column (Flex 3)
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppSectionHeader(
                        title: 'Connected Channels',
                        icon: Icons.link_rounded,
                      ),
                      SocialConnectShimmerWidget(isVertical: true),
                      SizedBox(height: 24.0),
                      Divider(height: 1.0, color: AppColors.border),
                      SizedBox(height: 24.0),

                      // Recent Leads Shimmer Section
                      AppCardContainer(
                        child: Column(
                          children: [
                            AppSectionHeader(
                              title: 'Recent Leads',
                              icon: Icons.people_alt_rounded,
                              padding: EdgeInsets.fromLTRB(16.0, 12.0, 12.0, 12.0),
                            ),
                            Divider(height: 1.0, color: AppColors.border),
                            Padding(
                              padding: EdgeInsets.all(12.0),
                              child: LeadListShimmerWidget(count: 3),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            )
          : const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Summary
                AppSectionHeader(
                  title: 'Overview Performance',
                  icon: Icons.insights_rounded,
                ),
                DashboardSummaryShimmerWidget(),
                SizedBox(height: 24.0),
                Divider(height: 1.0, color: AppColors.border),
                SizedBox(height: 24.0),

                // 2. Connected Channels
                AppSectionHeader(
                  title: 'Connected Channels',
                  icon: Icons.link_rounded,
                ),
                SocialConnectShimmerWidget(isVertical: true),
                SizedBox(height: 24.0),
                Divider(height: 1.0, color: AppColors.border),
                SizedBox(height: 24.0),

                // 3. Recent Leads
                AppCardContainer(
                  child: Column(
                    children: [
                      AppSectionHeader(
                        title: 'Recent Leads',
                        icon: Icons.people_alt_rounded,
                        padding: EdgeInsets.fromLTRB(16.0, 12.0, 12.0, 12.0),
                      ),
                      Divider(height: 1.0, color: AppColors.border),
                      Padding(
                        padding: EdgeInsets.all(12.0),
                        child: LeadListShimmerWidget(count: 3),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 24.0),
                Divider(height: 1.0, color: AppColors.border),
                SizedBox(height: 24.0),

                // 4. Recent Posts
                AppCardContainer(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppSectionHeader(
                        title: 'Recent Posts',
                        icon: Icons.dynamic_feed_rounded,
                        padding: EdgeInsets.fromLTRB(16.0, 12.0, 12.0, 12.0),
                      ),
                      Divider(height: 1.0, color: AppColors.border),
                      Padding(
                        padding: EdgeInsets.symmetric(vertical: 12.0),
                        child: PostListHorizontalShimmerWidget(count: 3),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 24.0),
                Divider(height: 1.0, color: AppColors.border),
                SizedBox(height: 24.0),

                // 5. Recent Properties
                AppCardContainer(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppSectionHeader(
                        title: 'Recent Properties',
                        icon: Icons.apartment_rounded,
                        padding: EdgeInsets.fromLTRB(16.0, 12.0, 12.0, 12.0),
                      ),
                      Divider(height: 1.0, color: AppColors.border),
                      Padding(
                        padding: EdgeInsets.symmetric(vertical: 12.0),
                        child: PropertyListHorizontalShimmerWidget(count: 3),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
