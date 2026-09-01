// File: lib/modules/subscription/widgets/package_duration_selector.dart
// Purpose: Grid duration option selector cards (sorted low-to-high) with stacked floating recommended badge for SubscriptionPackageDetailScreen.

// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import '../../../app/app_colors.dart';
import '../../../app/app_text_styles.dart';
import '../../../models/models.dart';
import '../../../util/currency_formatter.dart';

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
    return CurrencyFormatter.format(amount);
  }

  @override
  Widget build(BuildContext context) {
    if (options.isEmpty) return const SizedBox.shrink();

    // Sort options Low to High (e.g. 7 Days -> 15 Days -> 30 Days)
    final sortedOptions = List<PlanDurationOption>.from(options)
      ..sort((a, b) => a.days.compareTo(b.days));

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
        const SizedBox(height: 14.0),
        LayoutBuilder(
          builder: (context, constraints) {
            final double availableWidth = constraints.maxWidth;
            int crossAxisCount = 3;
            if (availableWidth < 340) {
              crossAxisCount = 2;
            } else if (availableWidth >= 650) {
              crossAxisCount = sortedOptions.length > 4 ? 4 : sortedOptions.length;
            }

            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.only(top: 8.0, bottom: 4.0),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                mainAxisSpacing: 14.0,
                crossAxisSpacing: 12.0,
                mainAxisExtent: 102.0, // Fixed height for clean grid layout
              ),
              itemCount: sortedOptions.length,
              itemBuilder: (context, index) {
                final option = sortedOptions[index];
                final bool isSelected = option.code == selectedOption.code ||
                    (option.days == selectedOption.days && option.days > 0);
                final bool isRecommended = option.isRecommended;

                return InkWell(
                  onTap: () => onOptionSelected(option),
                  borderRadius: BorderRadius.circular(18.0),
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      // Main Card Container
                      Container(
                        width: double.infinity,
                        margin: const EdgeInsets.only(top: 6.0),
                        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 12.0),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.primaryLight
                              : AppColors.surface,
                          gradient: isSelected
                              ? const LinearGradient(
                                  colors: [AppColors.primary50, AppColors.primary100],
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                )
                              : null,
                          borderRadius: BorderRadius.circular(18.0),
                          border: Border.all(
                            color: isSelected
                                ? AppColors.primary
                                : AppColors.border,
                            width: isSelected ? 2.0 : 1.2,
                          ),
                          boxShadow: [
                            if (isSelected)
                              BoxShadow(
                                color: AppColors.primary.withValues(alpha: 0.18),
                                blurRadius: 12.0,
                                offset: const Offset(0, 4),
                              )
                            else
                              BoxShadow(
                                color: AppColors.shadow.withValues(alpha: 0.04),
                                blurRadius: 8.0,
                                offset: const Offset(0, 2),
                              ),
                          ],
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              option.title.isNotEmpty ? option.title : '${option.days} Days',
                              style: AppTextStyles.body1.copyWith(
                                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w700,
                                color: isSelected ? AppColors.primary : AppColors.textPrimary,
                                fontSize: 14.5,
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4.0),
                            Text(
                              _formatAmount(option.amount),
                              style: AppTextStyles.body2.copyWith(
                                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                                color: isSelected ? AppColors.primary : AppColors.textSecondary,
                                fontSize: 13.0,
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),

                      // Floating Stacked Recommended Badge on Top Edge
                      if (isRecommended)
                        Positioned(
                          top: -3.0,
                          left: 0,
                          right: 0,
                          child: Center(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 3.5),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [AppColors.primary, AppColors.primaryDark],
                                ),
                                borderRadius: BorderRadius.circular(10.0),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.primary.withValues(alpha: 0.35),
                                    blurRadius: 6.0,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Text(
                                'RECOMMENDED',
                                style: AppTextStyles.caption.copyWith(
                                  color: AppColors.white,
                                  fontSize: 8.5,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }
}
