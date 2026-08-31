import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../app/app_colors.dart';
import '../../../../app/app_text_styles.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../providers/dashboard/dashboard_provider.dart';
import '../../../../widgets/toast/app_toast.dart';

class LearningCenterCard extends StatelessWidget {
  const LearningCenterCard({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DashboardProvider>();
    final items = provider.learningItems;

    return Card(
      elevation: 0,
      color: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.0),
        side: const BorderSide(color: AppColors.border, width: 1.0),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.tr('learning_center'),
              style: AppTextStyles.heading3.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16.0),

            // List of guide links
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: items.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12.0),
              itemBuilder: (context, index) {
                final item = items[index];
                final String itemKey = 'learn_${item.title.toLowerCase().replaceAll(' ', '_')}';
                return InkWell(
                  onTap: () {
                    AppToast.showSuccess(
                      context.tr('tutorial'),
                      context.tr('opening_guide', arguments: {'title': context.tr(itemKey)}),
                    );
                  },
                  borderRadius: BorderRadius.circular(8.0),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 12.0),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(8.0),
                      border: Border.all(color: AppColors.border, width: 1.0),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            context.tr(itemKey),
                            style: AppTextStyles.body2.copyWith(
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const Icon(Icons.chevron_right_rounded, size: 18.0, color: AppColors.textSecondary),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
