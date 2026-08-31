// File: lib/modules/subscription/widgets/sticky_subscription_cta.dart
// Purpose: Sticky bottom CTA bar with responsive max-width constraint matching main screen content.

// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../app/app_colors.dart';
import '../../../models/models.dart';
import '../../../widgets/buttons/app_button.dart';

class StickySubscriptionCta extends StatelessWidget {
  final SubscriptionPlanModel plan;
  final PlanDurationOption selectedOption;
  final VoidCallback onContinuePressed;

  const StickySubscriptionCta({
    super.key,
    required this.plan,
    required this.selectedOption,
    required this.onContinuePressed,
  });

  String _formatAmount(double amount) {
    final formatter = NumberFormat('#,##,###', 'en_IN');
    return '₹${formatter.format(amount.toInt())}';
  }

  @override
  Widget build(BuildContext context) {
    final double displayAmount =
        selectedOption.amount > 0 ? selectedOption.amount : plan.amount;
    final String durationText = selectedOption.title.isNotEmpty
        ? selectedOption.title
        : '${selectedOption.days} Days';

    final String buttonLabel = 'Continue with $durationText • ${_formatAmount(displayAmount)}';

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(22.0)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.12),
            blurRadius: 20.0,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800.0),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 14.0),
              child: AppButton.gradient(
                text: buttonLabel,
                onPressed: onContinuePressed,
                height: 52.0,
                borderRadius: 14.0,
                gradientColors: const [Color(0xFF2563EB), Color(0xFF1D4ED8)],
                iconData: Icons.arrow_forward_rounded,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
