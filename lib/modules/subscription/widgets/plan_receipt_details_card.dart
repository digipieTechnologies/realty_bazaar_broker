// File: lib/modules/subscription/widgets/plan_receipt_details_card.dart
// Purpose: Shared receipt details card widget used across subscription success and active plan detail screens.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../app/app_colors.dart';
import '../../../app/app_text_styles.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../widgets/toast/app_toast.dart';

class PlanReceiptDetailsCard extends StatelessWidget {
  final String startDateStr;
  final String endDateStr;
  final String? totalDurationStr;
  final String? planCode;
  final String paymentIdStr;

  const PlanReceiptDetailsCard({
    super.key,
    required this.startDateStr,
    required this.endDateStr,
    this.totalDurationStr,
    this.planCode,
    required this.paymentIdStr,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
          if (totalDurationStr != null) ...[
            _buildReceiptRow(
              icon: Icons.calendar_month_rounded,
              iconColor: AppColors.primary500,
              label: context.tr('start_date'),
              value: startDateStr,
            ),
            const SizedBox(height: 14.0),
            _buildReceiptRow(
              icon: Icons.event_rounded,
              iconColor: AppColors.warning,
              label: context.tr('expiry_date'),
              value: endDateStr,
            ),
            const SizedBox(height: 14.0),
            _buildReceiptRow(
              icon: Icons.timelapse_rounded,
              iconColor: AppColors.success,
              label: context.tr('total_duration'),
              value: totalDurationStr!,
            ),
          ] else ...[
            // Legacy Date to Date format
            _buildReceiptRow(
              icon: Icons.calendar_month_rounded,
              iconColor: AppColors.primary500,
              label: context.tr('validity_period'),
              value: '$startDateStr – $endDateStr',
            ),
          ],
          
          if (planCode != null && planCode!.isNotEmpty) ...[
            const SizedBox(height: 14.0),
            _buildReceiptRow(
              icon: Icons.label_rounded,
              iconColor: AppColors.tagIndigo,
              label: context.tr('plan_code'),
              value: planCode!.toUpperCase(),
            ),
          ],
          
          if (paymentIdStr.isNotEmpty) ...[
            const SizedBox(height: 14.0),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6.0),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceLight,
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: const Icon(Icons.tag_rounded, size: 16.0, color: AppColors.textSecondary),
                ),
                const SizedBox(width: 10.0),
                Text(
                  context.tr('payment_id'),
                  style: AppTextStyles.body2.copyWith(color: AppColors.textSecondary, fontSize: 13.5),
                ),
                const Spacer(),
                SelectableText(
                  paymentIdStr,
                  style: AppTextStyles.body2.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                    fontSize: 13.0,
                  ),
                ),
                const SizedBox(width: 6.0),
                InkWell(
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: paymentIdStr));
                    AppToast.showSuccess(context.tr('copied'), context.tr('payment_id_copied'));
                  },
                  borderRadius: BorderRadius.circular(6.0),
                  child: Padding(
                    padding: const EdgeInsets.all(4.0),
                    child: Icon(Icons.copy_rounded, size: 15.0, color: AppColors.primary500),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildReceiptRow({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6.0),
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8.0),
          ),
          child: Icon(icon, size: 16.0, color: iconColor),
        ),
        const SizedBox(width: 10.0),
        Text(label, style: AppTextStyles.body2.copyWith(color: AppColors.textSecondary, fontSize: 13.5)),
        const Spacer(),
        Text(
          value,
          style: AppTextStyles.body2.copyWith(fontWeight: FontWeight.w700, color: AppColors.textPrimary, fontSize: 13.5),
        ),
      ],
    );
  }
}
