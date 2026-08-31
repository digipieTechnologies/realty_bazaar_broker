import 'package:flutter/material.dart';
import '../../app/app_assets.dart';
import '../../app/app_colors.dart';
import '../../app/app_constants.dart';
import '../../util/common_ext.dart';
import '../../widgets/common/app_card_container.dart';
import '../../widgets/common/app_section_header.dart';
import 'dashboard_header_banner_shimmer_widget.dart';
import 'dashboard_summary_shimmer_widget.dart';
import 'lead_list_shimmer_widget.dart';
import 'post_list_horizontal_shimmer_widget.dart';
import 'property_list_horizontal_shimmer_widget.dart';
import 'social_connect_shimmer_widget.dart';

class DashboardShimmerWidget extends StatelessWidget {
  const DashboardShimmerWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final isMobile = context.isMobileUI;

    return SingleChildScrollView(
      padding: AppConstants.getTabPadding(
        context,
        bottomExtra: isMobile ? 80.0 : 24.0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Top Welcome Header Banner Shimmer Skeleton
          const DashboardHeaderBannerShimmerWidget(),

          // 2. Responsive Main Content Layout Skeleton
          LayoutBuilder(
            builder: (context, constraints) {
              final isDesktop = ContextX.isDesktopWidth(constraints.maxWidth);

              if (isDesktop) {
                return const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Left Column (Flex 7 - ~65% Width)
                    Expanded(
                      flex: 7,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AppSectionHeader(
                            title: 'Overview Performance',
                            svgAsset: AppAssets.icDashboardFilled,
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

                    // Right Column (Flex 3 - ~35% Width)
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
                                  child: LeadListShimmerWidget(
                                    count: 3,
                                    isCompact: true,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              }

              return const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Section 1: Summary / Overview Performance
                  AppSectionHeader(
                    title: 'Overview Performance',
                    svgAsset: AppAssets.icDashboardFilled,
                  ),
                  DashboardSummaryShimmerWidget(),
                  SizedBox(height: 14.0),
                  Divider(height: 1.0, color: AppColors.border),
                  SizedBox(height: 14.0),

                  // Section 2: Connected Channels (Social Channels)
                  AppSectionHeader(
                    title: 'Connected Channels',
                    icon: Icons.link_rounded,
                  ),
                  SocialConnectShimmerWidget(isVertical: true),
                  SizedBox(height: 14.0),
                  Divider(height: 1.0, color: AppColors.border),
                  SizedBox(height: 14.0),

                  // Section 3: Recent Leads Widget
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
                          child: LeadListShimmerWidget(
                            count: 3,
                            isCompact: true,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 14.0),
                  Divider(height: 1.0, color: AppColors.border),
                  SizedBox(height: 14.0),

                  // Section 4: Recent Posts Widget
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
                  SizedBox(height: 14.0),
                  Divider(height: 1.0, color: AppColors.border),
                  SizedBox(height: 14.0),

                  // Section 5: Recent Properties Widget
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
              );
            },
          ),
        ],
      ),
    );
  }
}
