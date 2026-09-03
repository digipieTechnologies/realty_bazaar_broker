// File: lib/modules/visits/widgets/visit_history_timeline.dart
// Purpose: Chronological audit trail timeline displaying past status transitions,
//          reschedules with reasons, and milestone dates for a site visit.

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../app/app_colors.dart';
import '../../../../app/app_text_styles.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../models/property_visit_history_model.dart';
import '../../../../util/app_date_utils.dart';

class VisitHistoryTimelineWidget extends StatelessWidget {
  final List<PropertyVisitHistoryModel> history;

  const VisitHistoryTimelineWidget({super.key, required this.history});

  @override
  Widget build(BuildContext context) {
    if (history.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16.0),
          border: Border.all(color: AppColors.border),
        ),
        child: Text(
          'No history recorded yet.',
          style: AppTextStyles.body2.copyWith(color: AppColors.textSecondary),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20.0),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.history_rounded, size: 20.0, color: AppColors.primary),
              const SizedBox(width: 8.0),
              Text(
                context.tr('visit_history_title'),
                style: AppTextStyles.heading3.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 16.0),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: history.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12.0),
            itemBuilder: (context, index) {
              final item = history[index];
              return _buildTimelineItem(context, item, isLast: index == history.length - 1);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineItem(BuildContext context, PropertyVisitHistoryModel item, {required bool isLast}) {
    Color iconColor;
    IconData icon;
    String title;
    String? subtitle;

    switch (item.action.toLowerCase()) {
      case 'created':
        iconColor = const Color(0xFF2563EB);
        icon = Icons.add_circle_outline_rounded;
        title = 'Visit Request Created';
        subtitle = item.newVisitDate != null
            ? 'Scheduled for ${AppDateUtils.formatDate(item.newVisitDate)} (${item.newTimeSlot ?? ''})'
            : null;
        break;
      case 'rescheduled':
        iconColor = const Color(0xFF7E22CE);
        icon = Icons.update_rounded;
        title = 'Visit Rescheduled';
        final newDateStr = item.newVisitDate != null ? AppDateUtils.formatDate(item.newVisitDate) : '';
        subtitle = 'Moved to $newDateStr (${item.newTimeSlot ?? ''})';
        if (item.reason != null && item.reason!.isNotEmpty) {
          subtitle += '\nReason: "${item.reason}"';
        }
        break;
      case 'confirmed':
        iconColor = const Color(0xFF0369A1);
        icon = Icons.check_circle_outline_rounded;
        title = 'Visit Confirmed by Broker';
        break;
      case 'completed':
        iconColor = const Color(0xFF15803D);
        icon = Icons.task_alt_rounded;
        title = 'Visit Marked Completed';
        break;
      case 'cancelled':
        iconColor = const Color(0xFFBE123C);
        icon = Icons.cancel_outlined;
        title = 'Visit Cancelled';
        if (item.reason != null && item.reason!.isNotEmpty) {
          subtitle = 'Reason: "${item.reason}"';
        }
        break;
      case 'no_show':
        iconColor = const Color(0xFF475569);
        icon = Icons.person_off_outlined;
        title = 'Marked as No-Show';
        break;
      default:
        iconColor = AppColors.textSecondary;
        icon = Icons.circle_outlined;
        title = 'Status changed to ${item.newStatus ?? 'updated'}';
        break;
    }

    final timeStr = item.createdAt != null
        ? DateFormat('dd-MMM-yyyy, hh:mm a').format(item.createdAt!.toLocal())
        : '';

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              padding: const EdgeInsets.all(6.0),
              decoration: BoxDecoration(color: iconColor.withValues(alpha: 0.12), shape: BoxShape.circle),
              child: Icon(icon, size: 16.0, color: iconColor),
            ),
            if (!isLast) Container(width: 2.0, height: 32.0, color: AppColors.border),
          ],
        ),
        const SizedBox(width: 12.0),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(title, style: AppTextStyles.body2.copyWith(fontWeight: FontWeight.w600)),
                  ),
                  if (timeStr.isNotEmpty)
                    Text(
                      timeStr,
                      style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary, fontSize: 11.0),
                    ),
                ],
              ),
              if (subtitle != null && subtitle.isNotEmpty) ...[
                const SizedBox(height: 4.0),
                Text(
                  subtitle,
                  style: AppTextStyles.body2.copyWith(color: AppColors.textSecondary, fontSize: 13.0),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
