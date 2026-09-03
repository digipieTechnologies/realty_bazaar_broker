// File: lib/modules/subscription/screens/subscription_package_detail_screen.dart
// Purpose: Standalone, fully responsive Subscription Package Detail Screen with package options, estimated results, horizontal features, FAQ accordion, and sticky bottom CTA.

// ignore_for_file: deprecated_member_use

import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:the_realty_bazaar/modules/subscription/widgets/sticky_subscription_cta.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../app/app_colors.dart';
import '../../../app/app_constants.dart';
import '../../../app/app_navigator.dart';
import '../../../app/app_text_styles.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/services/razorpay_service.dart';
import '../../../models/models.dart';
import '../../../providers/auth/auth_provider.dart';
import '../../../providers/subscription/subscription_provider.dart';
import '../../../util/common_ext.dart';
import '../../../widgets/buttons/app_button.dart';
import '../../../widgets/common/common_app_bar.dart';
import '../../../widgets/toast/app_toast.dart';
import '../widgets/estimated_results_card.dart';
import '../widgets/package_duration_selector.dart';
import '../widgets/package_summary_hero_card.dart';
import '../widgets/platforms_covered_widget.dart';
import '../widgets/subscription_faq_section.dart';
import '../widgets/subscription_feature_section.dart';

class SubscriptionPackageDetailScreen extends StatefulWidget {
  final SubscriptionPlanModel initialPlan;

  const SubscriptionPackageDetailScreen({super.key, required this.initialPlan});

  @override
  State<SubscriptionPackageDetailScreen> createState() => _SubscriptionPackageDetailScreenState();
}

class _SubscriptionPackageDetailScreenState extends State<SubscriptionPackageDetailScreen> {
  late SubscriptionPlanModel _currentPlan;
  late PlanDurationOption _selectedOption;
  late RazorpayService _razorpayService;
  bool _isProcessingPayment = false;

  @override
  void initState() {
    super.initState();
    _currentPlan = widget.initialPlan;

    // Default to initial duration options or construct default fallback options
    if (_currentPlan.durationOptions.isNotEmpty) {
      // Find server option marked as isRecommended
      final recommended = _currentPlan.durationOptions.firstWhere(
        (opt) => opt.isRecommended,
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

    _razorpayService = RazorpayService(
      onSuccess: (response) async {
        final authProvider = context.read<AuthProvider>();
        final subProvider = context.read<SubscriptionProvider>();
        final currentUser = authProvider.userProfile;
        final actualBrokerId = currentUser?.brokerId?.id;

        if (actualBrokerId != null) {
          final success = await subProvider.processSubscriptionPayment(
            brokerId: actualBrokerId,
            subscriptionPlanId: _currentPlan.id ?? '',
            amount: _selectedOption.amount,
            paymentId: response.paymentId ?? '',
            paymentProvider: 'razorpay',
            totalDays: _selectedOption.days,
            planCode: _selectedOption.code,
          );

          if (success) {
            // Fetch ONLY updated subscription from RPC and sync AuthProvider state (no full profile re-fetch)
            final updatedSub = await authProvider.fetchActiveBrokerSubscription(actualBrokerId);
            authProvider.updateUserSubscriptionLocally(updatedSub);

            final now = DateTime.now();
            final daysCount = _selectedOption.days > 0 ? _selectedOption.days : 30;
            final endDate = now.add(Duration(days: daysCount));

            if (mounted) {
              AppNavigator.navigateToSubscriptionSuccess(
                context,
                planName: _currentPlan.title,
                amount: _selectedOption.amount > 0 ? _selectedOption.amount : _currentPlan.amount,
                startDate: now,
                endDate: endDate,
                paymentId: response.paymentId ?? '',
                durationTitle: _selectedOption.title,
                benefits: _currentPlan.benefits,
              );
            }
          } else {
            if (mounted) {
              AppToast.showError(context.tr('update_failed'), context.tr('payment_success_update_failed'));
            }
          }
        }
        if (mounted) {
          setState(() => _isProcessingPayment = false);
        }
      },
      onFailure: (response) {
        if (mounted) {
          setState(() => _isProcessingPayment = false);
          AppToast.showError(context.tr('payment_failed'), response.message ?? context.tr('payment_error_default'));
        }
      },
      onExternalWallet: (response) {
        if (mounted) {
          setState(() => _isProcessingPayment = false);
          AppToast.showSuccess(
            context.tr('external_wallet'),
            context.tr('wallet_selected').replaceAll('{wallet}', response.walletName ?? ''),
          );
        }
      },
    );
  }

  @override
  void dispose() {
    _razorpayService.dispose();
    super.dispose();
  }

  void _onDurationSelected(PlanDurationOption option) {
    setState(() {
      _selectedOption = option;
    });
  }

  Future<void> _makeSupportCall() async {
    final Uri telUri = Uri(scheme: 'tel', path: AppConstants.supportPhoneNumber);
    try {
      if (await canLaunchUrl(telUri)) {
        await launchUrl(telUri);
      } else {
        if (mounted) {
          AppToast.showError(
            context.tr('support_call'),
            context.tr('support_call_desc').replaceAll('{phone}', AppConstants.supportPhoneDisplay),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        AppToast.showError(
          context.tr('support_call'),
          context.tr('support_call_desc').replaceAll('{phone}', AppConstants.supportPhoneDisplay),
        );
      }
    }
  }

  Future<void> _handlePurchase() async {
    final bool isMobileNative = !kIsWeb && (Platform.isAndroid || Platform.isIOS);
    if (!isMobileNative) {
      AppToast.showError(context.tr('mobile_app_required'), context.tr('mobile_app_required_desc'));
      return;
    }
    final isTrialUsed = _currentPlan.durationOptions.any((element) => element.isAlreadyUsed && element.isTrial);
    if (isTrialUsed) {
      final String desc = context.tr('trial_already_used_desc');

      AppToast.showError(context.tr('trial_already_used_title'), desc);
      return;
    }

    setState(() => _isProcessingPayment = true);

    final authProvider = context.read<AuthProvider>();
    final currentUser = authProvider.userProfile;

    if (currentUser == null) {
      setState(() => _isProcessingPayment = false);
      AppToast.showError(context.tr('error'), context.tr('login_required_subscribe'));
      return;
    }

    final activeSub = authProvider.activeSubscription;
    if (activeSub != null && !activeSub.isExpired) {
      setState(() => _isProcessingPayment = false);
      AppToast.showError(context.tr('active_plan_exists_title'), context.tr('active_plan_exists_desc'));
      return;
    }

    try {
      final actualBrokerId = currentUser.brokerId?.id;
      if (actualBrokerId == null) {
        AppToast.showError(context.tr('error'), context.tr('profile_required_subscribe'));
        return;
      }

      final amountInPaise = (_selectedOption.amount * 100).toInt();

      // 2. Open Razorpay checkout securely
      final launched = _razorpayService.openCheckout(
        amountInPaise: amountInPaise,
        name: context.tr('realty_bazaar_subscription'),
        description: '${_currentPlan.title} - ${_selectedOption.title}',
        contact: currentUser.phone ?? '',
        email: currentUser.email ?? '',
      );

      // If it failed to launch (e.g. missing plugin, missing keys), stop loader immediately
      if (!launched) {
        setState(() => _isProcessingPayment = false);
      }
    } catch (e) {
      debugPrint('Error creating order: $e');
      setState(() => _isProcessingPayment = false);
      AppToast.showError(context.tr('error'), context.tr('payment_init_error'));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: CommonAppBar(
        title: _currentPlan.title.isNotEmpty ? _currentPlan.title : context.tr('explore_package'),
        showBackButton: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: AppButton.outline(
              text: context.tr('help'),
              iconData: Icons.call_rounded,
              iconSize: 14.0,
              onPressed: _makeSupportCall,
              height: 34.0,
              borderRadius: 20.0,
              padding: const EdgeInsets.symmetric(horizontal: 12.0),
            ),
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: context.screenWidth800),
          child: SingleChildScrollView(
            padding: AppConstants.getTabPadding(context, bottomExtra: 100.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Package Summary Hero Card
                PackageSummaryHeroCard(plan: _currentPlan, selectedOption: _selectedOption),

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
        isLoading: _isProcessingPayment,
      ),
    );
  }

  Widget _buildConsultationBanner(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary50, AppColors.consultationBannerBgEnd],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20.0),
        border: Border.all(color: AppColors.consultationBannerBorder),
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
                    color: AppColors.consultationBannerText,
                    fontSize: 15.0,
                  ),
                ),
                const SizedBox(height: 4.0),
                Text(
                  'Get free consultation with our campaign strategist.',
                  style: AppTextStyles.caption.copyWith(color: AppColors.consultationBannerSubtext, fontSize: 12.0),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12.0),
          AppButton.solid(
            text: 'CALL NOW',
            iconData: Icons.phone_in_talk_rounded,
            iconSize: 15.0,
            onPressed: _makeSupportCall,
            height: 44.0,
            borderRadius: 12.0,
            color: AppColors.primary,
            padding: const EdgeInsets.symmetric(horizontal: 14.0),
          ),
        ],
      ),
    );
  }
}
