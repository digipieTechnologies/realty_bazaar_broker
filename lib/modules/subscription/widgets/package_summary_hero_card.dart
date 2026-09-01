// File: lib/modules/subscription/widgets/package_summary_hero_card.dart
// Purpose: Compact, premium hero summary card for selected subscription package with price, discount savings badge, and recommended pill.

// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';

import '../../../app/app_colors.dart';
import '../../../app/app_text_styles.dart';
import '../../../models/models.dart';
import '../../../util/currency_formatter.dart';

class PackageSummaryHeroCard extends StatelessWidget {
  final SubscriptionPlanModel plan;
  final PlanDurationOption selectedOption;

  const PackageSummaryHeroCard({
    super.key,
    required this.plan,
    required this.selectedOption,
  });

  String _formatAmount(double amount) {
    return CurrencyFormatter.format(amount);
  }

  @override
  Widget build(BuildContext context) {
    final double displayAmount = selectedOption.amount > 0
        ? selectedOption.amount
        : plan.amount;
    final double originalAmount =
        displayAmount * 1.25; // 25% original savings value reference
    final double savingsAmount = originalAmount - displayAmount;

    final bool isRecommended = selectedOption.isRecommended;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 18.0),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.shadow, AppColors.heroDarkBgEnd],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20.0),
        border: Border.all(
          color: AppColors.heroDarkBorder.withValues(alpha: 0.4),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.heroDarkBgEnd.withValues(alpha: 0.25),
            blurRadius: 16.0,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Row: Plan Title & Icon + Recommended Pill
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(7.0),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.25),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.rocket_launch_rounded,
                  size: 16.0,
                  color: AppColors.heroAccentBlue,
                ),
              ),
              const SizedBox(width: 10.0),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      plan.title.toUpperCase(),
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.heroSubtextBlue,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.0,
                        fontSize: 12.0,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 1.0),
                    Text(
                      '${selectedOption.title.isNotEmpty ? selectedOption.title : "${selectedOption.days} Days"} Campaign',
                      style: AppTextStyles.body2.copyWith(
                        color: AppColors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 14.5,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (isRecommended) ...[
                const SizedBox(width: 8.0),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10.0,
                    vertical: 4.0,
                  ),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.primary, AppColors.primary700],
                    ),
                    borderRadius: BorderRadius.circular(12.0),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.3),
                        blurRadius: 6.0,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.star_rounded,
                        size: 12.0,
                        color: AppColors.white,
                      ),
                      const SizedBox(width: 4.0),
                      Text(
                        'RECOMMENDED',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.white,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                          fontSize: 9.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),

          const SizedBox(height: 14.0),
          const Divider(height: 1.0, thickness: 1.0, color: Colors.white12),
          const SizedBox(height: 14.0),

          // Price Row: Big Price + Was Slashed Price + Savings Badge
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            alignment: WrapAlignment.start,
            spacing: 10.0,
            runSpacing: 6.0,
            children: [
              Text(
                _formatAmount(displayAmount),
                style: AppTextStyles.heading1.copyWith(
                  color: AppColors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 32.0,
                  letterSpacing: -0.5,
                ),
              ),
              Text(
                _formatAmount(originalAmount),
                style: AppTextStyles.body2.copyWith(
                  color: AppColors.slate400,
                  decoration: TextDecoration.lineThrough,
                  decorationColor: AppColors.slate400,
                  fontSize: 13.0,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8.0,
                  vertical: 3.0,
                ),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8.0),
                  border: Border.all(
                    color: AppColors.success.withValues(alpha: 0.6),
                  ),
                ),
                child: Text(
                  'Save ${_formatAmount(savingsAmount)}',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.emeraldTextLight,
                    fontWeight: FontWeight.w700,
                    fontSize: 11.0,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
