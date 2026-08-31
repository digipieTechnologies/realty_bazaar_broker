// File: lib/modules/subscription/screens/subscription_package_detail_screen.dart
// Purpose: Standalone, fully responsive Subscription Package Detail Screen with package options, estimated results, horizontal features, FAQ accordion, and sticky bottom CTA.

// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../app/app_colors.dart';
import '../../../app/app_text_styles.dart';
import '../../../models/models.dart';
import '../../../util/common_ext.dart';
import '../../../widgets/common/common_app_bar.dart';
import '../../../widgets/toast/app_toast.dart';
import '../widgets/estimated_results_card.dart';
import '../widgets/package_duration_selector.dart';
import '../widgets/package_summary_hero_card.dart';
import '../widgets/platforms_covered_widget.dart';
import '../widgets/sticky_subscription_cta.dart';
import '../widgets/subscription_faq_section.dart';
import '../widgets/subscription_feature_section.dart';

class SubscriptionPackageDetailScreen extends StatefulWidget {
  final SubscriptionPlanModel initialPlan;

  const SubscriptionPackageDetailScreen({
    super.key,
    required this.initialPlan,
  });

  @override
  State<SubscriptionPackageDetailScreen> createState() =>
      _SubscriptionPackageDetailScreenState();
}

class _SubscriptionPackageDetailScreenState
    extends State<SubscriptionPackageDetailScreen> {
  late SubscriptionPlanModel _currentPlan;
  late PlanDurationOption _selectedOption;

  @override
  void initState() {
    super.initState();
    _currentPlan = widget.initialPlan;

    // Default to initial duration options or construct default fallback options
    if (_currentPlan.durationOptions.isNotEmpty) {
      // Find 30 days or recommended option
      final recommended = _currentPlan.durationOptions.firstWhere(
        (opt) => opt.days == 30,
        orElse: () => _currentPlan.durationOptions.first,
      );
      _selectedOption = recommended;
    } else {
      _selectedOption = PlanDurationOption(
        code: '${_currentPlan.title.replaceAll(' ', '').toUpperCase()}30DAYS',
        amount: _currentPlan.amount,
        days: 30,
        title: '30 Days',
      );
    }
  }

  void _onDurationSelected(PlanDurationOption option) {
    setState(() {
      _selectedOption = option;
    });
  }

  Future<void> _makeSupportCall() async {
    final Uri telUri = Uri(scheme: 'tel', path: '+918758262263');
    try {
      if (await canLaunchUrl(telUri)) {
        await launchUrl(telUri);
      } else {
        AppToast.showSuccess('Support Call', 'Call +91 87582 62263 for package assistance.');
      }
    } catch (e) {
      AppToast.showSuccess('Support Call', 'Call +91 87582 62263 for package assistance.');
    }
  }

  void _handlePurchase() {
    AppToast.showSuccess(
      'Package Selected',
      'Proceeding with ${_selectedOption.title.isNotEmpty ? _selectedOption.title : "${_selectedOption.days} Days"} package.',
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isDesktop = ContextX.isDesktopWidth(MediaQuery.of(context).size.width);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: CommonAppBar(
        title: _currentPlan.title.isNotEmpty ? _currentPlan.title : 'Explore Package',
        showBackButton: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: TextButton.icon(
              onPressed: _makeSupportCall,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20.0),
                  side: const BorderSide(color: AppColors.border),
                ),
              ),
              icon: const Icon(Icons.call_rounded, size: 14.0, color: AppColors.primary),
              label: Text(
                'Help?',
                style: AppTextStyles.caption.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
            ),
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: isDesktop ? 800.0 : double.infinity,
          ),
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 100.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Package Summary Hero Card
                PackageSummaryHeroCard(
                  plan: _currentPlan,
                  selectedOption: _selectedOption,
                ),

                const SizedBox(height: 24.0),

                // 2. Package Duration Option Selector
                if (_currentPlan.durationOptions.isNotEmpty) ...[
                  PackageDurationSelector(
                    options: _currentPlan.durationOptions,
                    selectedOption: _selectedOption,
                    onOptionSelected: _onDurationSelected,
                  ),
                  const SizedBox(height: 24.0),
                ],

                // 3. Platforms Covered Widget
                const PlatformsCoveredWidget(),

                const SizedBox(height: 24.0),

                // 4. Estimated Results Metric Card
                EstimatedResultsCard(
                  planAmount: _selectedOption.amount > 0 ? _selectedOption.amount : _currentPlan.amount,
                  days: _selectedOption.days > 0 ? _selectedOption.days : 30,
                ),

                const SizedBox(height: 24.0),

                // 5. Subscription Features Horizontal Section
                const SubscriptionFeatureSection(features: []),

                const SizedBox(height: 24.0),

                // 6. Frequently Asked Questions Accordion
                const SubscriptionFaqSection(),

                const SizedBox(height: 24.0),

                // 7. Free Consultation Banner
                _buildConsultationBanner(context),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: StickySubscriptionCta(
        plan: _currentPlan,
        selectedOption: _selectedOption,
        onContinuePressed: _handlePurchase,
      ),
    );
  }

  Widget _buildConsultationBanner(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFEFF6FF), Color(0xFFDBEAFE)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20.0),
        border: Border.all(color: const Color(0xFFBFDBFE)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Need help choosing a package?',
                  style: AppTextStyles.body1.copyWith(
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF1E3A8A),
                    fontSize: 15.0,
                  ),
                ),
                const SizedBox(height: 4.0),
                Text(
                  'Get free consultation with our campaign strategist.',
                  style: AppTextStyles.caption.copyWith(
                    color: const Color(0xFF3B82F6),
                    fontSize: 12.0,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12.0),
          ElevatedButton.icon(
            onPressed: _makeSupportCall,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 10.0),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.0),
              ),
            ),
            icon: const Icon(Icons.phone_in_talk_rounded, size: 15.0),
            label: const Text('CALL NOW'),
          ),
        ],
      ),
    );
  }
}
