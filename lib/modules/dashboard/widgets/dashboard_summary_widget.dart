import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../app/app_assets.dart';
import '../../../app/app_colors.dart';
import '../../../app/app_routes.dart';
import '../../../app/app_text_styles.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../providers/auth/auth_provider.dart';
import '../../../providers/dashboard/dashboard_provider.dart';
import '../../../util/common_ext.dart';
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
        tagColor: AppColors.accentCoral,
        icon: Icons.trending_up_rounded,
        iconBgColor: AppColors.accentCoral,
        iconColor: Colors.white,
        cardBgColor: AppColors.accentCoralLight,
        onTap: () => context.go('/leads'),
      ),
      _StatItemData(
        title: context.tr('total_leads'),
        value: '$totalLeads',
        tagText: context.tr('filter_all'),
        tagColor: AppColors.primary700,
        svgAsset: AppAssets.icLeadsFilled,
        iconBgColor: AppColors.primary500,
        iconColor: Colors.white,
        cardBgColor: AppColors.primary50,
        onTap: () => context.go('/leads'),
      ),
      _StatItemData(
        title: context.tr('properties'),
        value: '$totalProperties',
        tagText: context.tr('prop_status_available'),
        tagColor: AppColors.tagAmber,
        svgAsset: AppAssets.icPropertiesFilled,
        iconBgColor: AppColors.accentGold,
        iconColor: Colors.white,
        cardBgColor: AppColors.accentGoldLight,
        onTap: () => context.go('/properties'),
      ),
      _StatItemData(
        title: context.tr('video_requests'),
        value: '$videoRequests',
        tagText: context.tr('pending'),
        tagColor: AppColors.tagTeal,
        svgAsset: AppAssets.icVideoFilled,
        iconBgColor: AppColors.accentTeal,
        iconColor: Colors.white,
        cardBgColor: AppColors.accentTealLight,
        onTap: () => AppRoutes.navigateToVideoRequests(context),
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
  final IconData? icon;
  final String? svgAsset;
  final Color iconBgColor;
  final Color iconColor;
  final Color cardBgColor;
  final VoidCallback? onTap;

  const _StatItemData({
    required this.title,
    required this.value,
    required this.tagText,
    required this.tagColor,
    this.icon,
    this.svgAsset,
    required this.iconBgColor,
    required this.iconColor,
    required this.cardBgColor,
    this.onTap,
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
    final borderRadius = BorderRadius.circular(isDesktop ? 18.0 : 14.0);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: data.onTap,
        borderRadius: borderRadius,
        child: Ink(
          decoration: BoxDecoration(
            color: data.cardBgColor,
            borderRadius: borderRadius,
            border: Border.all(color: data.iconBgColor.withValues(alpha: 0.25), width: 1.0),
            boxShadow: [
              BoxShadow(
                color: data.iconBgColor.withValues(alpha: 0.08),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          padding: EdgeInsets.all(isDesktop ? 16.0 : 12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: EdgeInsets.all(isDesktop ? 8.0 : 6.0),
                    decoration: BoxDecoration(
                      color: data.iconBgColor,
                      shape: BoxShape.circle,
                    ),
                    child: data.svgAsset != null
                        ? SvgPicture.asset(
                            data.svgAsset!,
                            width: isDesktop ? 18.0 : 15.0,
                            height: isDesktop ? 18.0 : 15.0,
                            colorFilter: ColorFilter.mode(
                              data.iconColor,
                              BlendMode.srcIn,
                            ),
                          )
                        : Icon(
                            data.icon,
                            color: data.iconColor,
                            size: isDesktop ? 18.0 : 15.0,
                          ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: isDesktop ? 9.0 : 7.0,
                      vertical: isDesktop ? 4.0 : 3.0,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    child: Text(
                      data.tagText,
                      style: AppTextStyles.caption.copyWith(
                        color: data.tagColor,
                        fontWeight: FontWeight.w800,
                        fontSize: isDesktop ? 11.0 : 10.0,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: isDesktop ? 12.0 : 8.0),
              Text(
                data.value,
                style: AppTextStyles.heading1.copyWith(
                  fontSize: isDesktop ? 24.0 : 19.0,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 3.0),
              Text(
                data.title,
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                  fontSize: isDesktop ? 12.5 : 11.5,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
