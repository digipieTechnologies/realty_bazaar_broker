// File: lib/modules/subscription/widgets/package_duration_selector.dart
// Purpose: Horizontal duration option selector chips/cards for SubscriptionPackageDetailScreen.

// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../app/app_colors.dart';
import '../../../app/app_text_styles.dart';
import '../../../models/models.dart';

class PackageDurationSelector extends StatelessWidget {
  final List<PlanDurationOption> options;
  final PlanDurationOption selectedOption;
  final ValueChanged<PlanDurationOption> onOptionSelected;

  const PackageDurationSelector({
    super.key,
    required this.options,
    required this.selectedOption,
    required this.onOptionSelected,
  });

  String _formatAmount(double amount) {
    final formatter = NumberFormat('#,##,###', 'en_IN');
    return '₹${formatter.format(amount.toInt())}';
  }

  @override
  Widget build(BuildContext context) {
    if (options.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4.0),
          child: Text(
            'Select Package Duration',
            style: AppTextStyles.heading3.copyWith(
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
              fontSize: 16.0,
            ),
          ),
        ),
        const SizedBox(height: 12.0),
        SizedBox(
          height: 110.0,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: options.length,
            separatorBuilder: (_, _) => const SizedBox(width: 12.0),
            itemBuilder: (context, index) {
              final option = options[index];
              final bool isSelected = option.code == selectedOption.code ||
                  (option.days == selectedOption.days && option.days > 0);
              final bool isRecommended = option.days == 30;

              return InkWell(
                onTap: () => onOptionSelected(option),
                borderRadius: BorderRadius.circular(16.0),
                child: Container(
                  width: 125.0,
                  padding: const EdgeInsets.all(12.0),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFFEFF6FF)
                        : AppColors.surface,
                    borderRadius: BorderRadius.circular(16.0),
                    border: Border.all(
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.border,
                      width: isSelected ? 2.0 : 1.0,
                    ),
                    boxShadow: [
                      if (isSelected)
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.15),
                          blurRadius: 10.0,
                          offset: const Offset(0, 4),
                        ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (isRecommended)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 2.0),
                          margin: const EdgeInsets.only(bottom: 4.0),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(6.0),
                          ),
                          child: Text(
                            'Recommended',
                            style: AppTextStyles.caption.copyWith(
                              color: Colors.white,
                              fontSize: 9.0,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      Text(
                        option.title.isNotEmpty ? option.title : '${option.days} Days',
                        style: AppTextStyles.body1.copyWith(
                          fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                          color: isSelected ? AppColors.primary : AppColors.textPrimary,
                          fontSize: 14.0,
                        ),
                      ),
                      const SizedBox(height: 4.0),
                      Text(
                        _formatAmount(option.amount),
                        style: AppTextStyles.body2.copyWith(
                          fontWeight: FontWeight.w700,
                          color: isSelected ? AppColors.primary : AppColors.textSecondary,
                          fontSize: 13.0,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
