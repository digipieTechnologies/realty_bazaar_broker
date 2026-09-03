// File: lib/modules/subscription/screens/active_plan_detail_screen.dart
// Purpose: Modern, professional Active Plan Detail screen showing full subscription info, progress, and benefits.

// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:the_realty_bazaar/app/app_navigator.dart';

import '../../../app/app_colors.dart';
import '../../../app/app_constants.dart';
import '../../../app/app_text_styles.dart';
import '../../../providers/auth/auth_provider.dart';
import '../../../util/common_ext.dart';
import '../../../widgets/buttons/app_button.dart';
import '../../../widgets/common/app_3d_badge.dart';
import '../../../widgets/common/common_app_bar.dart';
import '../widgets/plan_amount_card.dart';
import '../widgets/plan_benefits_card.dart';
import '../widgets/plan_receipt_details_card.dart';

class ActivePlanDetailScreen extends StatelessWidget {
  const ActivePlanDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final subscription = context.watch<AuthProvider>().activeSubscription;

    if (subscription == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: const CommonAppBar(title: 'Your Subscription', showBackButton: true),
        body: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.warningLight, AppColors.background],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: context.screenWidth800),
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const App3DBadge(
                      icon: Icons.info_outline_rounded,
                      size: 150.0,
                      primaryColor: AppColors.warning,
                      secondaryColor: AppColors.warningDark,
                      shadowDarkColor: AppColors.warningDark,
                      innerGradientColors: [AppColors.warningBorder, AppColors.warning, AppColors.warningAmberDark],
                      showConfetti: false,
                    ),
                    const SizedBox(height: 32.0),
                    Text(
                      'No Active Subscription',
                      style: AppTextStyles.heading1.copyWith(color: AppColors.primary900, fontSize: 24.0),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12.0),
                    Text(
                      'Unlock powerful tools, higher reach, and AI features by subscribing to one of our premium plans.',
                      style: AppTextStyles.body1.copyWith(color: AppColors.textSecondary),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 40.0),
                    AppButton.gradient(
                      text: 'EXPLORE PLANS',
                      onPressed: () {
                        AppNavigator.navigateToGrowTab(context);
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    final plan = subscription.subscriptionPlanId;
    final payment = subscription.paymentId;

    final String planName = plan?.title.isNotEmpty == true
        ? plan!.title
        : (subscription.planCode.isNotEmpty ? subscription.planCode.toUpperCase() : 'Active Plan');
    final String planDescription = plan?.description ?? '';
    final List<String> benefits = plan?.benefits ?? [];

    final String startDateStr = DateFormat('dd MMM yyyy').format(subscription.startDate);
    final String endDateStr = DateFormat('dd MMM yyyy').format(subscription.endDate);

    // Calculate remaining days
    final now = DateTime.now();
    final remaining = subscription.endDate.difference(now);
    final int remainingDays = remaining.isNegative ? 0 : remaining.inDays;
    final bool isExpired = remainingDays <= 0;

    // Progress fraction
    final int totalDays = subscription.totalDays > 0 ? subscription.totalDays : 30;
    final int usedDays = totalDays - remainingDays;
    final double progress = (usedDays / totalDays).clamp(0.0, 1.0);

    final String paymentIdStr = payment?.paymentId ?? '';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const CommonAppBar(title: 'Plan Details', showBackButton: true),
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
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: context.screenWidth800),
            child: SingleChildScrollView(
              padding: AppConstants.getTabPadding(context),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 8.0),

                  // 1. 3D Plan Badge
                  App3DBadge(
                    icon: isExpired ? Icons.timer_off_rounded : Icons.workspace_premium_rounded,
                    primaryColor: isExpired ? AppColors.error : AppColors.success,
                    secondaryColor: AppColors.skyBlueAccent,
                    shadowDarkColor: isExpired ? const Color(0xFFB91C1C) : AppColors.emeraldDark,
                    innerGradientColors: isExpired
                        ? const [Color(0xFFFCA5A5), AppColors.error, Color(0xFFB91C1C)]
                        : const [
                            AppColors.emeraldTextLight,
                            AppColors.success,
                            AppColors.statusSuccessText,
                            AppColors.emeraldDark,
                          ],
                    showConfetti: true,
                  ),

                  const SizedBox(height: 20.0),

                  // 2. Plan Name Tag
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 10.0),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: isExpired
                            ? [AppColors.errorLight, AppColors.warningLight]
                            : [AppColors.mintBadgeBgStart, AppColors.mintBadgeBgEnd],
                      ),
                      borderRadius: BorderRadius.circular(30.0),
                      border: Border.all(
                        color: isExpired
                            ? AppColors.error.withValues(alpha: 0.3)
                            : AppColors.primary300.withValues(alpha: 0.6),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: (isExpired ? AppColors.error : AppColors.primary500).withValues(alpha: 0.08),
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
                          decoration: BoxDecoration(
                            color: isExpired ? AppColors.errorLight : AppColors.goldStarBg,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            isExpired ? Icons.timer_off_rounded : Icons.workspace_premium_rounded,
                            color: isExpired ? AppColors.error : AppColors.goldStarIcon,
                            size: 16.0,
                          ),
                        ),
                        const SizedBox(width: 8.0),
                        Text(
                          isExpired ? 'Expired' : planName,
                          style: AppTextStyles.body2.copyWith(
                            fontWeight: FontWeight.w800,
                            color: isExpired ? AppColors.error : AppColors.primary900,
                            fontSize: 14.5,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 8.0),

                  // Plan Description
                  if (planDescription.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Text(
                        planDescription,
                        textAlign: TextAlign.center,
                        style: AppTextStyles.body2.copyWith(color: AppColors.textSecondary, fontSize: 13.0),
                      ),
                    ),

                  const SizedBox(height: 20.0),

                  // 3. Amount Card
                  PlanAmountCard(amount: subscription.amount),

                  const SizedBox(height: 20.0),

                  // 4. Remaining Days Progress Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20.0),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(22.0),
                      border: Border.all(color: AppColors.border, width: 1.2),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.shadow.withValues(alpha: 0.04),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8.0),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: isExpired
                                      ? [AppColors.error.withValues(alpha: 0.15), AppColors.errorLight]
                                      : [AppColors.success.withValues(alpha: 0.15), AppColors.successLight],
                                ),
                                borderRadius: BorderRadius.circular(12.0),
                              ),
                              child: Icon(
                                isExpired ? Icons.hourglass_disabled_rounded : Icons.hourglass_bottom_rounded,
                                size: 22.0,
                                color: isExpired ? AppColors.error : AppColors.success,
                              ),
                            ),
                            const SizedBox(width: 14.0),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    isExpired ? 'Plan Expired' : '$remainingDays Days Remaining',
                                    style: AppTextStyles.body1.copyWith(
                                      fontWeight: FontWeight.w800,
                                      color: isExpired ? AppColors.error : AppColors.textPrimary,
                                      fontSize: 16.0,
                                    ),
                                  ),
                                  const SizedBox(height: 2.0),
                                  Text(
                                    'out of $totalDays days total',
                                    style: AppTextStyles.caption.copyWith(
                                      color: AppColors.textSecondary,
                                      fontSize: 12.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
                              decoration: BoxDecoration(
                                color: isExpired
                                    ? AppColors.error.withValues(alpha: 0.1)
                                    : AppColors.success.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(20.0),
                              ),
                              child: Text(
                                isExpired ? 'Expired' : '${(progress * 100).toInt()}% Used',
                                style: AppTextStyles.caption.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: isExpired ? AppColors.error : AppColors.success,
                                  fontSize: 12.0,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16.0),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6.0),
                          child: LinearProgressIndicator(
                            value: progress,
                            minHeight: 8.0,
                            backgroundColor: AppColors.surfaceLight,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              isExpired ? AppColors.error : (progress > 0.75 ? AppColors.warning : AppColors.success),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20.0),

                  // 5. Receipt Details Card
                  PlanReceiptDetailsCard(
                    startDateStr: startDateStr,
                    endDateStr: endDateStr,
                    totalDurationStr: '$totalDays Days',
                    planCode: subscription.planCode,
                    paymentIdStr: paymentIdStr,
                  ),

                  const SizedBox(height: 20.0),

                  // 6. Benefits Card (shared widget)
                  PlanBenefitsCard(benefits: benefits, title: 'Features Included'),

                  const SizedBox(height: 32.0),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
