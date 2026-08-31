// File: lib/modules/subscription/widgets/package_summary_hero_card.dart
// Purpose: Hero summary card for selected subscription package with price, discount savings badge, and recommended pill.

// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../app/app_colors.dart';
import '../../../app/app_text_styles.dart';
import '../../../models/models.dart';

class PackageSummaryHeroCard extends StatelessWidget {
  final SubscriptionPlanModel plan;
  final PlanDurationOption selectedOption;

  const PackageSummaryHeroCard({
    super.key,
    required this.plan,
    required this.selectedOption,
  });

  String _formatAmount(double amount) {
    final formatter = NumberFormat('#,##,###', 'en_IN');
    return '₹${formatter.format(amount.toInt())}';
  }

  @override
  Widget build(BuildContext context) {
    final double displayAmount =
        selectedOption.amount > 0 ? selectedOption.amount : plan.amount;
    final double originalAmount = displayAmount * 1.25; // 25% original savings value reference
    final double savingsAmount = originalAmount - displayAmount;

    final bool isRecommended = plan.isPopular || selectedOption.days == 30;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22.0),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF0F172A),
            Color(0xFF1E293B),
            Color(0xFF1E3A8A),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24.0),
        border: Border.all(
          color: AppColors.primary300,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.22),
            blurRadius: 24.0,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          // Top Recommended Badge
          if (isRecommended)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 6.0),
              margin: const EdgeInsets.only(bottom: 12.0),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF3B82F6), Color(0xFF2563EB)],
                ),
                borderRadius: BorderRadius.circular(20.0),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.withValues(alpha: 0.3),
                    blurRadius: 8.0,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.star_rounded, size: 14.0, color: Colors.white),
                  const SizedBox(width: 6.0),
                  Text(
                    'RECOMMENDED',
                    style: AppTextStyles.caption.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                      fontSize: 11.0,
                    ),
                  ),
                ],
              ),
            ),

          // Duration & Plan Title
          Text(
            '${selectedOption.title.isNotEmpty ? selectedOption.title : "${selectedOption.days} Days"} Package',
            style: AppTextStyles.heading2.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 22.0,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4.0),
          Text(
            plan.title,
            style: AppTextStyles.body2.copyWith(
              color: AppColors.slate300,
              fontSize: 13.0,
            ),
          ),

          const SizedBox(height: 16.0),

          // Main Display Amount
          Text(
            _formatAmount(displayAmount),
            style: AppTextStyles.heading1.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 36.0,
              letterSpacing: -1.0,
            ),
          ),

          const SizedBox(height: 8.0),

          // Slashed Original Price & Savings Pill
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Was ${_formatAmount(originalAmount)}',
                style: AppTextStyles.body2.copyWith(
                  color: AppColors.slate400,
                  decoration: TextDecoration.lineThrough,
                  decorationColor: AppColors.slate400,
                  fontSize: 13.0,
                ),
              ),
              const SizedBox(width: 10.0),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 4.0),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12.0),
                  border: Border.all(color: const Color(0xFF10B981), width: 1.0),
                ),
                child: Text(
                  'Save ${_formatAmount(savingsAmount)}',
                  style: AppTextStyles.caption.copyWith(
                    color: const Color(0xFF34D399),
                    fontWeight: FontWeight.w700,
                    fontSize: 11.5,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16.0),

          // Selected Check Pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 6.0),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20.0),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.check_circle_rounded, size: 14.0, color: Color(0xFF60A5FA)),
                const SizedBox(width: 6.0),
                Text(
                  'Selected Package',
                  style: AppTextStyles.caption.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 12.0,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
