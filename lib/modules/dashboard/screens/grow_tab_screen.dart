// File: lib/modules/dashboard/screens/grow_tab_screen.dart
// Purpose: Grow tab screen with dynamic plan cards fetched from Supabase.
// Displays shimmer while loading, then shows responsive plan carousel/grid.

// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';

import '../../../app/app_colors.dart';
import '../../../app/app_routes.dart';
import '../../../app/app_text_styles.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../providers/subscription/subscription_provider.dart';
import '../../../widgets/shimmer/grow_plan_shimmer_widget.dart';
import '../widgets/grow_plan_carousel_widget.dart';

class GrowTabScreen extends StatefulWidget {
  const GrowTabScreen({super.key});

  @override
  State<GrowTabScreen> createState() => _GrowTabScreenState();
}

class _GrowTabScreenState extends State<GrowTabScreen> {
  @override
  void initState() {
    super.initState();
    // Fetch active plans on screen load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<SubscriptionProvider>();
      if (provider.plans.isEmpty && !provider.isLoading) {
        provider.fetchActiveSubscriptionPlans();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Consumer<SubscriptionProvider>(
        builder: (context, provider, child) {
          final bool isMobile = MediaQuery.of(context).size.width < 600;

          return SingleChildScrollView(
            padding: EdgeInsets.symmetric(vertical: isMobile ? 12.0 : 20.0),
            child: Column(
              children: [
                // Header Section
                _buildHeader(context),
                SizedBox(height: context.height * 0.06),

                // Plans Section
                if (provider.isLoading)
                  const GrowPlanShimmerWidget()
                else if (provider.plans.isNotEmpty)
                  GrowPlanCarouselWidget(
                    plans: provider.plans,
                    onSelectPlan: (plan) {
                      provider.setSelectedPlan(plan);
                      AppRoutes.navigateToSubscriptionPackageDetail(context, plan);
                    },
                  )
                else
                  _buildEmptyState(context),

                const SizedBox(height: 24.0),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isMobile = constraints.maxWidth < 600;

        return Padding(
          padding: EdgeInsets.symmetric(horizontal: isMobile ? 24.0 : 40.0),
          child: Column(
            children: [
              // Top Sparkle Badge Pill
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: isMobile ? 12.0 : 14.0,
                  vertical: isMobile ? 5.0 : 6.0,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(20.0),
                  border: Border.all(color: const Color(0xFFBFDBFE), width: 1.0),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.auto_awesome_rounded, size: isMobile ? 13.0 : 14.0, color: AppColors.primary),
                    const SizedBox(width: 6.0),
                    Text(
                      context.tr('grow_header_badge'),
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                        fontSize: isMobile ? 11.5 : 12.0,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: isMobile ? 18.0 : 24.0),

              // Title
              ConstrainedBox(
                constraints: BoxConstraints(maxWidth: isMobile ? double.infinity : 680.0),
                child: Text(
                  context.tr('grow_header_title'),
                  style: AppTextStyles.heading1.copyWith(
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF0F172A),
                    fontSize: isMobile ? 20.0 : 32.0,
                    letterSpacing: -0.5,
                    height: 1.25,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              SizedBox(height: isMobile ? 16.0 : 20.0),

              // Subtitle
              ConstrainedBox(
                constraints: BoxConstraints(maxWidth: isMobile ? double.infinity : 620.0),
                child: Text(
                  context.tr('grow_header_subtitle'),
                  style: AppTextStyles.body1.copyWith(
                    color: AppColors.textSecondary,
                    fontSize: isMobile ? 13.0 : 15.0,
                    height: 1.45,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40.0),
      child: Column(
        children: [
          Icon(Icons.inbox_rounded, size: 48.0, color: AppColors.textMuted.withValues(alpha: 0.5)),
          const SizedBox(height: 12.0),
          Text(
            context.tr('grow_no_options'),
            style: AppTextStyles.body1.copyWith(color: AppColors.textSecondary, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 4.0),
          Text(
            context.tr('grow_check_back'),
            style: AppTextStyles.caption.copyWith(color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }
}
