// File: lib/modules/subscription/screens/subscription_success_screen.dart
// Purpose: Modern light-themed Subscription Purchase Success screen using AppConstants.getTabPadding(context) for standard app screen padding.

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../app/app_colors.dart';
import '../../../app/app_constants.dart';
import '../../../app/app_navigator.dart';
import '../../../app/app_text_styles.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../util/common_ext.dart';
import '../../../widgets/buttons/app_button.dart';
import '../../../widgets/common/app_3d_badge.dart';
import '../widgets/plan_amount_card.dart';
import '../widgets/plan_benefits_card.dart';
import '../widgets/plan_receipt_details_card.dart';

class SubscriptionSuccessScreen extends StatelessWidget {
  final String planName;
  final double amount;
  final DateTime startDate;
  final DateTime endDate;
  final String paymentId;
  final String durationTitle;
  final List<String> benefits;

  const SubscriptionSuccessScreen({
    super.key,
    required this.planName,
    required this.amount,
    required this.startDate,
    required this.endDate,
    required this.paymentId,
    this.durationTitle = '30 Days',
    this.benefits = const [],
  });

  void _goToHome(BuildContext context) {
    AppNavigator.navigateToHome(context);
  }

  @override
  Widget build(BuildContext context) {
    final String startDateStr = DateFormat('dd MMM yyyy').format(startDate);
    final String endDateStr = DateFormat('dd MMM yyyy').format(endDate);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.mintGradientStart, AppColors.background, AppColors.skyGradientEnd],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          top: true,
          bottom: true,
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: context.screenWidth800),
              child: Column(
                children: [
                  // Scrollable Main Content using standard AppConstants.getTabPadding(context)
                  Expanded(
                    child: SingleChildScrollView(
                      padding: AppConstants.getTabPadding(context),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // 2. 3D Badge Centerpiece
                          const Hero(
                            tag: 'success_badge_3d',
                            child: App3DBadge(
                              icon: Icons.check_rounded,
                              size: 180.0,
                              primaryColor: AppColors.success,
                              secondaryColor: AppColors.skyBlueAccent,
                              shadowDarkColor: AppColors.emeraldDark,
                              innerGradientColors: [
                                AppColors.emeraldTextLight,
                                AppColors.success,
                                AppColors.statusSuccessText,
                                AppColors.emeraldDark,
                              ],
                              showConfetti: true,
                            ),
                          ),
                          const SizedBox(height: 24.0),

                          // 2. Star Active Plan Tag
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 10.0),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [AppColors.mintBadgeBgStart, AppColors.mintBadgeBgEnd],
                              ),
                              borderRadius: BorderRadius.circular(30.0),
                              border: Border.all(color: AppColors.primary300.withValues(alpha: 0.6)),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primary500.withValues(alpha: 0.08),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(4.0),
                                  decoration: const BoxDecoration(color: AppColors.goldStarBg, shape: BoxShape.circle),
                                  child: const Icon(Icons.star_rounded, color: AppColors.goldStarIcon, size: 16.0),
                                ),
                                const SizedBox(width: 8.0),
                                Text(
                                  planName.isNotEmpty ? planName : context.tr('active_plan'),
                                  style: AppTextStyles.body2.copyWith(
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.primary900,
                                    fontSize: 14.5,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 16.0),

                          // 3. Payment Successful Heading
                          Text(
                            context.tr('payment_successful'),
                            style: AppTextStyles.heading1.copyWith(
                              fontSize: 28.0,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                              letterSpacing: -0.5,
                            ),
                            textAlign: TextAlign.center,
                          ),

                          const SizedBox(height: 24.0),

                          // 4. Hero Amount Display Card using CurrencyText Widget
                          PlanAmountCard(amount: amount, title: context.tr('total_amount_paid')),

                          const SizedBox(height: 20.0),

                          // 5. Receipt Details Card
                          PlanReceiptDetailsCard(
                            startDateStr: startDateStr,
                            endDateStr: endDateStr,
                            totalDurationStr: durationTitle,
                            paymentIdStr: paymentId,
                          ),

                          const SizedBox(height: 20.0),

                          // 6. Plan Features Unlocked Section
                          PlanBenefitsCard(benefits: benefits, title: context.tr('features_unlocked_plan')),

                          const SizedBox(height: 24.0),
                        ],
                      ),
                    ),
                  ),

                  // Bottom Action Button Container
                  Container(
                    padding: const EdgeInsets.all(20.0),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.shadow.withValues(alpha: 0.05),
                          blurRadius: 16,
                          offset: const Offset(0, -4),
                        ),
                      ],
                    ),
                    child: AppButton.gradient(
                      text: context.tr('go_to_home'),
                      onPressed: () => _goToHome(context),
                      height: 52.0,
                      borderRadius: 16.0,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
