// File: lib/modules/dashboard/widgets/grow_plan_card_widget.dart
// Purpose: Premium plan card widget for Grow tab. Renders a modern, vibrant plan card
// with glassmorphism accents, floating popular badge, benefits list, multi-layer shadows, and responsive sizing.

// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../app/app_colors.dart';
import '../../../app/app_text_styles.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../models/models.dart';
import '../../../widgets/buttons/app_button.dart';

class GrowPlanCardWidget extends StatelessWidget {
  final SubscriptionPlanModel plan;
  final VoidCallback? onSelect;
  final double? cardWidth;

  const GrowPlanCardWidget({
    super.key,
    required this.plan,
    this.onSelect,
    this.cardWidth,
  });

  /// Format amount to Indian currency: ₹4,499
  String _formatAmount(double amount) {
    if (amount <= 0) return '';
    final formatter = NumberFormat('#,##,###', 'en_IN');
    final formatted = formatter.format(amount.toInt());
    return '₹$formatted';
  }

  /// Returns gradient colors based on plan duration
  List<Color> _getCardGradient() {
    if (plan.isPopular) {
      return [
        const Color(0xFF0B1A3B),
        const Color(0xFF132D5E),
        const Color(0xFF1A3F7A),
      ];
    }
    return [AppColors.surface, AppColors.surface];
  }

  /// Returns accent color for non-popular cards
  Color _getAccentColor() {
    switch (plan.billingType) {
      case PlanBillingType.oneTime:
        return AppColors.accentTeal;
      case PlanBillingType.recurring:
        return AppColors.primary;
      case PlanBillingType.custom:
        return AppColors.posterGold;
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isPopular = plan.isPopular;
    final accent = _getAccentColor();
    final gradient = _getCardGradient();

    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Main Container Card
        Container(
          width: cardWidth,
          margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 12.0),
          decoration: BoxDecoration(
            gradient: isPopular
                ? LinearGradient(
                    colors: gradient,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
            color: isPopular ? null : AppColors.surface,
            borderRadius: BorderRadius.circular(22.0),
            border: Border.all(
              color: isPopular
                  ? AppColors.primary300
                  : accent.withValues(alpha: 0.22),
              width: isPopular ? 1.5 : 1.2,
            ),
            boxShadow: [
              if (isPopular)
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.25),
                  blurRadius: 28.0,
                  spreadRadius: 2.0,
                  offset: const Offset(0, 10),
                )
              else ...[
                BoxShadow(
                  color: const Color(0xFF0F172A).withValues(alpha: 0.08),
                  blurRadius: 22.0,
                  spreadRadius: 0,
                  offset: const Offset(0, 8),
                ),
                BoxShadow(
                  color: accent.withValues(alpha: 0.06),
                  blurRadius: 10.0,
                  spreadRadius: 1,
                  offset: const Offset(0, 2),
                ),
              ],
            ],
          ),
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              20.0,
              isPopular ? 24.0 : 20.0,
              20.0,
              20.0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title Badge
                _buildTitleBadge(context, accent),
                const SizedBox(height: 14.0),

                // Amount & Period
                _buildAmountSection(context, accent),
                const SizedBox(height: 10.0),

                // Description
                Text(
                  plan.description,
                  style: AppTextStyles.caption.copyWith(
                    color: isPopular
                        ? AppColors.slate400
                        : AppColors.textSecondary,
                    height: 1.45,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 16.0),

                // Divider
                Container(
                  height: 1.0,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isPopular
                          ? [
                              Colors.white.withValues(alpha: 0.05),
                              Colors.white.withValues(alpha: 0.15),
                              Colors.white.withValues(alpha: 0.05),
                            ]
                          : [
                              accent.withValues(alpha: 0.1),
                              accent.withValues(alpha: 0.25),
                              accent.withValues(alpha: 0.1),
                            ],
                    ),
                  ),
                ),
                const SizedBox(height: 16.0),

                // Benefits List
                Expanded(
                  child: _buildBenefitsList(context),
                ),

                const SizedBox(height: 16.0),

                // CTA Button
                _buildCTAButton(context, accent),
              ],
            ),
          ),
        ),

        // Floating Popular Pill Badge (Minor up on top boundary of card)
        if (isPopular)
          Positioned(
            top: 0.0,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 6.0,
                ),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF3B82F6), Color(0xFF2563EB)],
                  ),
                  borderRadius: BorderRadius.circular(20.0),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF3B82F6).withValues(alpha: 0.4),
                      blurRadius: 10.0,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.star_rounded,
                      size: 14.0,
                      color: Color(0xFFFBBF24),
                    ),
                    const SizedBox(width: 4.0),
                    Text(
                      context.tr('grow_most_popular'),
                      style: AppTextStyles.caption.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 11.0,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildTitleBadge(BuildContext context, Color accent) {
    final bool isPopular = plan.isPopular;

    IconData titleIcon;
    switch (plan.billingType) {
      case PlanBillingType.oneTime:
        titleIcon = Icons.bolt_rounded;
        break;
      case PlanBillingType.recurring:
        titleIcon = Icons.auto_awesome_rounded;
        break;
      case PlanBillingType.custom:
        titleIcon = Icons.corporate_fare_rounded;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 5.0),
      decoration: BoxDecoration(
        gradient: isPopular
            ? LinearGradient(
                colors: [
                  Colors.white.withValues(alpha: 0.15),
                  Colors.white.withValues(alpha: 0.05),
                ],
              )
            : LinearGradient(
                colors: [
                  accent.withValues(alpha: 0.12),
                  accent.withValues(alpha: 0.04),
                ],
              ),
        borderRadius: BorderRadius.circular(30.0),
        border: Border.all(
          color: isPopular
              ? Colors.white.withValues(alpha: 0.2)
              : accent.withValues(alpha: 0.25),
          width: 1.0,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            titleIcon,
            size: 13.0,
            color: isPopular ? const Color(0xFF93C5FD) : accent,
          ),
          const SizedBox(width: 5.0),
          Flexible(
            child: Text(
              plan.title.toUpperCase(),
              style: AppTextStyles.caption.copyWith(
                color: isPopular ? const Color(0xFF93C5FD) : accent,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
                fontSize: 11.0,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAmountSection(BuildContext context, Color accent) {
    final bool isPopular = plan.isPopular;
    final bool isCustom = plan.billingType == PlanBillingType.custom;

    if (isCustom) {
      return FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.centerLeft,
        child: Text(
          context.tr('grow_custom_label'),
          style: AppTextStyles.heading2.copyWith(
            color: isPopular ? Colors.white : AppColors.textPrimary,
            fontWeight: FontWeight.w800,
            fontSize: 28.0,
          ),
        ),
      );
    }

    final formattedAmount = _formatAmount(plan.amount);
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerLeft,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          Text(
            formattedAmount,
            style: AppTextStyles.heading1.copyWith(
              color: isPopular ? Colors.white : AppColors.textPrimary,
              fontWeight: FontWeight.w800,
              fontSize: 30.0,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(width: 4.0),
          Text(
            plan.billingType.periodDisplay,
            style: AppTextStyles.body2.copyWith(
              color: isPopular
                  ? AppColors.slate400
                  : AppColors.textMuted,
              fontWeight: FontWeight.w500,
              fontSize: 13.0,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBenefitsList(BuildContext context) {
    final bool isPopular = plan.isPopular;

    return ListView.separated(
      physics: const BouncingScrollPhysics(),
      itemCount: plan.benefits.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10.0),
      itemBuilder: (context, index) {
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 20.0,
              height: 20.0,
              decoration: BoxDecoration(
                color: isPopular
                    ? const Color(0xFF10B981).withValues(alpha: 0.15)
                    : AppColors.successLight,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_rounded,
                size: 13.0,
                color: AppColors.success,
              ),
            ),
            const SizedBox(width: 10.0),
            Expanded(
              child: Text(
                plan.benefits[index],
                style: AppTextStyles.body2.copyWith(
                  color: isPopular
                      ? const Color(0xFFE2E8F0)
                      : AppColors.textPrimary,
                  fontSize: 13.0,
                  height: 1.4,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  String _getCTAButtonText(BuildContext context) {
    if (plan.billingType == PlanBillingType.custom) {
      return context.tr('grow_contact_team');
    }

    if (plan.billingType == PlanBillingType.oneTime) {
      return 'Start Trial';
    }

    final titleUpper = plan.title.toUpperCase();
    if (titleUpper.contains('STARTER')) {
      return 'Explore Starter';
    }
    if (titleUpper.contains('GROWTH')) {
      return 'Explore Growth';
    }
    if (titleUpper.contains('ELITE') || titleUpper.contains('HIGH')) {
      return 'Explore Elite';
    }

    final titleParts = plan.title.trim().split(' ');
    final firstWord = titleParts.isNotEmpty ? titleParts.first : 'Package';
    final capitalized = '${firstWord[0].toUpperCase()}${firstWord.substring(1).toLowerCase()}';
    return 'Explore $capitalized';
  }

  Widget _buildCTAButton(BuildContext context, Color accent) {
    final bool isPopular = plan.isPopular;
    final bool isCustom = plan.billingType == PlanBillingType.custom;
    final String buttonText = _getCTAButtonText(context);

    if (isPopular) {
      return AppButton.gradient(
        text: buttonText,
        onPressed: onSelect,
        width: double.infinity,
        height: 48.0,
        borderRadius: 12.0,
        gradientColors: const [Color(0xFF3B82F6), Color(0xFF2563EB)],
        iconData: Icons.open_in_new_rounded,
        iconSize: 16.0,
      );
    }

    if (isCustom) {
      return AppButton.outline(
        text: buttonText,
        onPressed: onSelect,
        width: double.infinity,
        height: 48.0,
        borderRadius: 12.0,
        borderColor: const Color(0xFF1E293B),
        textColor: const Color(0xFF1E293B),
        iconData: Icons.arrow_forward_rounded,
        iconSize: 16.0,
      );
    }

    return AppButton.outline(
      text: buttonText,
      onPressed: onSelect,
      width: double.infinity,
      height: 48.0,
      borderRadius: 12.0,
      borderColor: AppColors.primary.withValues(alpha: 0.8),
      textColor: AppColors.primary,
      iconData: Icons.open_in_new_rounded,
      iconSize: 16.0,
    );
  }
}
