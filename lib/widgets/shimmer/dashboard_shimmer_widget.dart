import 'package:flutter/material.dart';

import '../../app/app_assets.dart';
import '../../app/app_colors.dart';
import '../../app/app_constants.dart';
import '../../core/localization/app_localizations.dart';
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
    final isMobile = context.isMobile;

    return SingleChildScrollView(
      padding: AppConstants.getTabPadding(context, bottomExtra: isMobile ? 80.0 : 24.0),
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
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Left Column (Flex 7 - ~65% Width)
                    Expanded(
                      flex: 7,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AppSectionHeader(
                            title: context.tr('overview_performance'),
                            svgAsset: AppAssets.icDashboardFilled,
                          ),
                          const DashboardSummaryShimmerWidget(),
                          const SizedBox(height: 24.0),
                          const Divider(height: 1.0, color: AppColors.border),
                          const SizedBox(height: 24.0),
                          const DashboardSummaryShimmerWidget(),
                          const SizedBox(height: 24.0),
                          const Divider(height: 1.0, color: AppColors.border),
                          const SizedBox(height: 24.0),

                          // Recent Properties Shimmer Section
                          AppCardContainer(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                AppSectionHeader(
                                  title: context.tr('recent_properties'),
                                  icon: Icons.apartment_rounded,
                                  padding: const EdgeInsets.fromLTRB(16.0, 12.0, 12.0, 12.0),
                                ),
                                const Divider(height: 1.0, color: AppColors.border),
                                const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 12.0),
                                  child: PropertyListHorizontalShimmerWidget(count: 3),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24.0),
                          const Divider(height: 1.0, color: AppColors.border),
                          const SizedBox(height: 24.0),

                          // Recent Posts Shimmer Section
                          AppCardContainer(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                AppSectionHeader(
                                  title: context.tr('recent_posts'),
                                  icon: Icons.dynamic_feed_rounded,
                                  padding: const EdgeInsets.fromLTRB(16.0, 12.0, 12.0, 12.0),
                                ),
                                const Divider(height: 1.0, color: AppColors.border),
                                const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 12.0),
                                  child: PostListHorizontalShimmerWidget(count: 3),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 24.0),

                    // Right Column (Flex 3 - ~35% Width)
                    Expanded(
                      flex: 3,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AppSectionHeader(title: context.tr('connected_channels'), icon: Icons.link_rounded),
                          const SocialConnectShimmerWidget(isVertical: true),
                          const SizedBox(height: 24.0),
                          const Divider(height: 1.0, color: AppColors.border),
                          const SizedBox(height: 24.0),

                          // Recent Leads Shimmer Section
                          AppCardContainer(
                            child: Column(
                              children: [
                                AppSectionHeader(
                                  title: context.tr('recent_leads'),
                                  icon: Icons.people_alt_rounded,
                                  padding: const EdgeInsets.fromLTRB(16.0, 12.0, 12.0, 12.0),
                                ),
                                const Divider(height: 1.0, color: AppColors.border),
                                const Padding(
                                  padding: EdgeInsets.all(12.0),
                                  child: LeadListShimmerWidget(count: 3, isCompact: true),
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

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Section 1: Summary / Overview Performance
                  AppSectionHeader(title: context.tr('overview_performance'), svgAsset: AppAssets.icDashboardFilled),
                  const DashboardSummaryShimmerWidget(),
                  const SizedBox(height: 14.0),
                  const Divider(height: 1.0, color: AppColors.border),
                  const SizedBox(height: 14.0),

                  // Section 2: Connected Channels (Social Channels)
                  AppSectionHeader(title: context.tr('connected_channels'), icon: Icons.link_rounded),
                  const SocialConnectShimmerWidget(isVertical: true),
                  const SizedBox(height: 14.0),
                  const Divider(height: 1.0, color: AppColors.border),
                  const SizedBox(height: 14.0),

                  // Section 3: Recent Leads Widget
                  AppCardContainer(
                    child: Column(
                      children: [
                        AppSectionHeader(
                          title: context.tr('recent_leads'),
                          icon: Icons.people_alt_rounded,
                          padding: const EdgeInsets.fromLTRB(16.0, 12.0, 12.0, 12.0),
                        ),
                        const Divider(height: 1.0, color: AppColors.border),
                        const Padding(
                          padding: EdgeInsets.all(12.0),
                          child: LeadListShimmerWidget(count: 3, isCompact: true),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14.0),
                  const Divider(height: 1.0, color: AppColors.border),
                  const SizedBox(height: 14.0),

                  // Section 4: Recent Posts Widget
                  AppCardContainer(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AppSectionHeader(
                          title: context.tr('recent_posts'),
                          icon: Icons.dynamic_feed_rounded,
                          padding: const EdgeInsets.fromLTRB(16.0, 12.0, 12.0, 12.0),
                        ),
                        const Divider(height: 1.0, color: AppColors.border),
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12.0),
                          child: PostListHorizontalShimmerWidget(count: 3),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14.0),
                  const Divider(height: 1.0, color: AppColors.border),
                  const SizedBox(height: 14.0),

                  // Section 5: Recent Properties Widget
                  AppCardContainer(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AppSectionHeader(
                          title: context.tr('recent_properties'),
                          icon: Icons.apartment_rounded,
                          padding: const EdgeInsets.fromLTRB(16.0, 12.0, 12.0, 12.0),
                        ),
                        const Divider(height: 1.0, color: AppColors.border),
                        const Padding(
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
