// File: lib/modules/subscription/widgets/sticky_subscription_cta.dart
// Purpose: Sticky bottom CTA bar with safe area padding and dynamic purchase button.

// ignore_for_file: deprecated_member_use

import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

import '../../../app/app_colors.dart';
import '../../../models/models.dart';
import '../../../util/common_ext.dart';
import '../../../util/currency_formatter.dart';
import '../../../widgets/buttons/app_button.dart';

class StickySubscriptionCta extends StatelessWidget {
  final SubscriptionPlanModel plan;
  final PlanDurationOption selectedOption;
  final VoidCallback onContinuePressed;
  final bool isLoading;

  const StickySubscriptionCta({
    super.key,
    required this.plan,
    required this.selectedOption,
    required this.onContinuePressed,
    this.isLoading = false,
  });

  String _formatAmount(double amount) {
    return CurrencyFormatter.format(amount);
  }

  @override
  Widget build(BuildContext context) {
    final bool isMobileNative = !kIsWeb && (Platform.isAndroid || Platform.isIOS);

    final double displayAmount = selectedOption.amount > 0 ? selectedOption.amount : plan.amount;
    final String durationText = selectedOption.title.isNotEmpty ? selectedOption.title : '${selectedOption.days} Days';

    final String buttonLabel = isMobileNative
        ? 'Continue with $durationText • ${_formatAmount(displayAmount)}'
        : 'Subscribe on Mobile App • ${_formatAmount(displayAmount)}';

    return Container(
      width: double.infinity,
      height: 80,
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 14.0),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(22.0)),
        boxShadow: [
          BoxShadow(color: AppColors.shadow.withValues(alpha: 0.12), blurRadius: 20.0, offset: const Offset(0, -4)),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: context.screenWidth800),
            child: AppButton.gradient(
              text: buttonLabel,
              onPressed: onContinuePressed,
              height: 52.0,
              borderRadius: 14.0,
              gradientColors: const [AppColors.primary, AppColors.primary700],
              isLoading: isLoading,
            ),
          ),
        ),
      ),
    );
  }
}
