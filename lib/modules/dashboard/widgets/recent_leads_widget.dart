// File: lib/modules/dashboard/widgets/recent_leads_widget.dart
// Purpose: Dashboard widget displaying top 5 recent social leads using LeadTileWidget with desktop table & mobile card view, live status, shimmer loading, and View All link.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../app/app_assets.dart';
import '../../../app/app_colors.dart';
import '../../../app/app_text_styles.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../providers/auth/auth_provider.dart';
import '../../../providers/lead/lead_provider.dart';
import '../../../widgets/common/app_card_container.dart';
import '../../../widgets/common/app_empty_state_widget.dart';
import '../../../widgets/common/app_section_header.dart';
import '../../../widgets/shimmer/lead_list_shimmer_widget.dart';
import 'leads/lead_tile_widget.dart';

class RecentLeadsWidget extends StatefulWidget {
  const RecentLeadsWidget({super.key});

  @override
  State<RecentLeadsWidget> createState() => _RecentLeadsWidgetState();
}

class _RecentLeadsWidgetState extends State<RecentLeadsWidget> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final brokerId = authProvider.userProfile?.brokerId?.id;
      final leadProvider = Provider.of<LeadProvider>(context, listen: false);

      if (brokerId != null && brokerId.isNotEmpty) {
        leadProvider.fetchLeads(brokerId: brokerId, page: 1);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final leadProvider = context.watch<LeadProvider>();
    final leads = leadProvider.leads.take(3).toList();
    final isLoading = leadProvider.isLoading && leadProvider.leads.isEmpty;

    return AppCardContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row: Section Header Badge & View All Button
          AppSectionHeader(
            title: context.tr('recent_leads'),
            svgAsset: AppAssets.icLeadsFilled,
            padding: const EdgeInsets.fromLTRB(16.0, 12.0, 12.0, 12.0),
            trailing: InkWell(
              onTap: () => context.go('/leads'),
              borderRadius: BorderRadius.circular(6.0),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 6.0,
                  vertical: 3.0,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      context.tr('view_all'),
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 12.0,
                      ),
                    ),
                    const SizedBox(width: 2.0),
                    const Icon(
                      Icons.chevron_right_rounded,
                      color: AppColors.primary,
                      size: 16.0,
                    ),
                  ],
                ),
              ),
            ),
          ),
          const Divider(height: 1.0, color: AppColors.border),

          // Content List
          if (isLoading)
            const Padding(
              padding: EdgeInsets.all(12.0),
              child: LeadListShimmerWidget(count: 3),
            )
          else if (leads.isEmpty)
            AppEmptyStateWidget(
              icon: Icons.group_off_rounded,
              title: context.tr('no_leads_found'),
              description: context.tr('no_leads_empty_desc'),
            )
          else
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: leads.length,
                itemBuilder: (context, index) {
                  final lead = leads[index];
                  return LeadTileWidget(
                    lead: lead,
                    isMobile: true,
                    isMinimalView: true,
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
