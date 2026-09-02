import 'package:flutter/material.dart';

import '../../../app/app_colors.dart';
import '../../../app/app_text_styles.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../widgets/common/currency_text.dart';

class PlanAmountCard extends StatelessWidget {
  final double amount;
  final String? title;
  final String symbol;

  const PlanAmountCard({
    super.key,
    required this.amount,
    this.title,
    this.symbol = '₹',
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 18.0),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary50, AppColors.mintBadgeBgEnd],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22.0),
        border: Border.all(color: AppColors.primary200, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary500.withValues(alpha: 0.08),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            title ?? context.tr('plan_amount'),
            style: AppTextStyles.caption.copyWith(
              fontWeight: FontWeight.w800,
              color: AppColors.primary800,
              letterSpacing: 1.2,
              fontSize: 11.5,
            ),
          ),
          const SizedBox(height: 4.0),
          CurrencyText(
            amount: amount,
            style: AppTextStyles.heading1.copyWith(
              fontSize: 34.0,
              fontWeight: FontWeight.w900,
              color: AppColors.primary900,
              letterSpacing: -0.5,
            ),
            symbol: symbol,
          ),
        ],
      ),
    );
  }
}
