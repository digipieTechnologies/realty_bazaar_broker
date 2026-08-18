// File: lib/modules/dashboard/widgets/dashboard_summary_widget.dart
// Purpose: Reusable dashboard summary widget displaying 4 key metrics (Today's Leads, Total Leads, Total Properties, Active Video Requests) powered by Supabase RPC with compact responsive heights.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../app/app_colors.dart';
import '../../../app/app_text_styles.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../providers/auth/auth_provider.dart';
import '../../../providers/dashboard/dashboard_provider.dart';
import '../../../util/common_ext.dart';
import '../../../widgets/common/app_card_container.dart';
import '../../../widgets/shimmer/dashboard_summary_shimmer_widget.dart';

class DashboardSummaryWidget extends StatefulWidget {
  const DashboardSummaryWidget({super.key});

  @override
  State<DashboardSummaryWidget> createState() => _DashboardSummaryWidgetState();
}

class _DashboardSummaryWidgetState extends State<DashboardSummaryWidget> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final brokerId = authProvider.userProfile?.brokerId?.id;
      final dashboardProvider = Provider.of<DashboardProvider>(context, listen: false);
      
      if (brokerId != null && brokerId.isNotEmpty) {
        dashboardProvider.fetchDashboardSummary(brokerId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final dashboardProvider = context.watch<DashboardProvider>();
    final summary = dashboardProvider.summary;
    final isLoading = dashboardProvider.isLoadingSummary && summary == null;
    final isDesktop = context.isDesktopUI;

    if (isLoading) {
      return const DashboardSummaryShimmerWidget();
    }

    final todaysLeads = summary?.todaysLeads ?? 0;
    final growthStr = summary?.todaysLeadsGrowth ?? '+0%';
    final totalLeads = summary?.totalLeads ?? 0;
    final totalProperties = summary?.totalProperties ?? 0;
    final videoRequests = summary?.videoRequests ?? 0;

    final cards = [
      _StatItemData(
        title: context.tr('todays_leads'),
        value: '$todaysLeads',
        tagText: growthStr,
        tagColor: AppColors.success,
        icon: Icons.trending_up_rounded,
        iconBgColor: AppColors.primary.withValues(alpha: 0.1),
        iconColor: AppColors.primary,
      ),
      _StatItemData(
        title: context.tr('total_leads'),
        value: '$totalLeads',
        tagText: context.tr('filter_all'),
        tagColor: AppColors.info,
        icon: Icons.people_alt_rounded,
        iconBgColor: AppColors.success.withValues(alpha: 0.1),
        iconColor: AppColors.success,
      ),
      _StatItemData(
        title: context.tr('properties'),
        value: '$totalProperties',
        tagText: context.tr('prop_status_available'),
        tagColor: AppColors.warning,
        icon: Icons.apartment_rounded,
        iconBgColor: AppColors.warning.withValues(alpha: 0.1),
        iconColor: AppColors.warning,
      ),
      _StatItemData(
        title: context.tr('video_requests'),
        value: '$videoRequests',
        tagText: context.tr('pending'),
        tagColor: AppColors.primary,
        icon: Icons.videocam_rounded,
        iconBgColor: AppColors.primary.withValues(alpha: 0.1),
        iconColor: AppColors.primary,
      ),
    ];

    if (isDesktop) {
      return Row(
        children: cards
            .map((item) => Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(right: 12.0),
                    child: _StatCard(data: item, isDesktop: true),
                  ),
                ))
            .toList()
          ..removeLast()
          ..add(Expanded(child: _StatCard(data: cards.last, isDesktop: true))),
      );
    }

    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _StatCard(data: cards[0], isDesktop: false)),
            const SizedBox(width: 10.0),
            Expanded(child: _StatCard(data: cards[1], isDesktop: false)),
          ],
        ),
        const SizedBox(height: 10.0),
        Row(
          children: [
            Expanded(child: _StatCard(data: cards[2], isDesktop: false)),
            const SizedBox(width: 10.0),
            Expanded(child: _StatCard(data: cards[3], isDesktop: false)),
          ],
        ),
      ],
    );
  }
}

class _StatItemData {
  final String title;
  final String value;
  final String tagText;
  final Color tagColor;
  final IconData icon;
  final Color iconBgColor;
  final Color iconColor;

  const _StatItemData({
    required this.title,
    required this.value,
    required this.tagText,
    required this.tagColor,
    required this.icon,
    required this.iconBgColor,
    required this.iconColor,
  });
}

class _StatCard extends StatelessWidget {
  final _StatItemData data;
  final bool isDesktop;

  const _StatCard({
    required this.data,
    required this.isDesktop,
  });

  @override
  Widget build(BuildContext context) {
    return AppCardContainer(
      borderRadius: isDesktop ? 16.0 : 12.0,
      padding: EdgeInsets.fromLTRB(
        isDesktop ? 16.0 : 12.0,
        isDesktop ? 14.0 : 10.0,
        isDesktop ? 16.0 : 12.0,
        isDesktop ? 14.0 : 10.0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: EdgeInsets.all(isDesktop ? 8.0 : 5.0),
                decoration: BoxDecoration(
                  color: data.iconBgColor,
                  borderRadius: BorderRadius.circular(isDesktop ? 10.0 : 7.0),
                ),
                child: Icon(
                  data.icon,
                  color: data.iconColor,
                  size: isDesktop ? 18.0 : 14.0,
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: isDesktop ? 8.0 : 6.0,
                  vertical: isDesktop ? 3.0 : 2.0,
                ),
                decoration: BoxDecoration(
                  color: data.tagColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10.0),
                ),
                child: Text(
                  data.tagText,
                  style: AppTextStyles.caption.copyWith(
                    color: data.tagColor,
                    fontWeight: FontWeight.w700,
                    fontSize: isDesktop ? 11.0 : 10.0,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: isDesktop ? 10.0 : 6.0),
          Text(
            data.value,
            style: AppTextStyles.heading1.copyWith(
              fontSize: isDesktop ? 22.0 : 17.0,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 2.0),
          Text(
            data.title,
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
              fontSize: isDesktop ? 12.0 : 11.0,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
