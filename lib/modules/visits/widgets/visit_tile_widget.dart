// File: lib/modules/visits/widgets/visit_tile_widget.dart
// Purpose: Polished card/tile widget for site visit items in mobile view or responsive layouts,
//          with status badge, property pill, time slot indicator, and direct WhatsApp/Call action buttons.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../app/app_colors.dart';
import '../../../../app/app_text_styles.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../models/property_visit_model.dart';
import '../../../../providers/visit/visit_provider.dart';
import '../../../../util/app_date_utils.dart';
import '../../../../widgets/common/user_avatar_widget.dart';
import '../../../../widgets/toast/app_toast.dart';
import '../screens/view_visit_screen.dart';
import 'cancel_visit_dialog.dart';
import 'reschedule_visit_dialog.dart';
import 'visit_status_badge.dart';

class VisitTileWidget extends StatelessWidget {
  final PropertyVisitModel visit;
  final bool isMobile;
  final VoidCallback? onTap;

  const VisitTileWidget({
    super.key,
    required this.visit,
    this.isMobile = false,
    this.onTap,
  });

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint('[VisitTileWidget] Error launching url: $e');
    }
  }

  void _handleMenuAction(BuildContext context, String action) async {
    final provider = context.read<VisitProvider>();

    switch (action) {
      case 'confirm':
        await provider.updateVisitStatus(visitId: visit.id!, newStatus: 'confirmed');
        if (context.mounted) {
          AppToast.showSuccess(context.tr('site_visits'), context.tr('visit_status_updated_success'));
        }
        break;
      case 'complete':
        await provider.updateVisitStatus(visitId: visit.id!, newStatus: 'completed');
        if (context.mounted) {
          AppToast.showSuccess(context.tr('site_visits'), context.tr('visit_status_updated_success'));
        }
        break;
      case 'no_show':
        await provider.updateVisitStatus(visitId: visit.id!, newStatus: 'no_show');
        if (context.mounted) {
          AppToast.showSuccess(context.tr('site_visits'), context.tr('visit_status_updated_success'));
        }
        break;
      case 'reschedule':
        showDialog(
          context: context,
          builder: (context) => RescheduleVisitDialog(visit: visit),
        );
        break;
      case 'cancel':
        showDialog(
          context: context,
          builder: (context) => CancelVisitDialog(visit: visit),
        );
        break;
      case 'view':
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => ViewVisitScreen(visit: visit, visitId: visit.id),
          ),
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final propertyTitle = visit.property?.propertyTitle ?? 'Property Visit';
    final dateStr = AppDateUtils.formatDate(visit.visitDate);

    return Container(
      margin: const EdgeInsets.only(bottom: 12.0),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20.0),
        border: Border.all(color: AppColors.border, width: 1.0),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20.0),
        child: InkWell(
          onTap: onTap ??
              () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => ViewVisitScreen(visit: visit, visitId: visit.id),
                  ),
                );
              },
          borderRadius: BorderRadius.circular(20.0),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top row: Avatar + Name + Status Badge
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    UserAvatarWidget(name: visit.clientName, radius: 22.0),
                    const SizedBox(width: 12.0),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            visit.clientName.isNotEmpty ? visit.clientName : 'Client',
                            style: AppTextStyles.heading3.copyWith(fontWeight: FontWeight.bold),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2.0),
                          Text(
                            visit.contactNumber,
                            style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8.0),
                    VisitStatusBadge(status: visit.status, isCompact: true),
                  ],
                ),
                const SizedBox(height: 12.0),

                // Schedule banner: Date & Time slot
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(12.0),
                    border: Border.all(color: AppColors.border.withValues(alpha: 0.6)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today_outlined, size: 14.0, color: AppColors.primary),
                      const SizedBox(width: 6.0),
                      Text(
                        dateStr,
                        style: AppTextStyles.caption.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(width: 12.0),
                      const Icon(Icons.access_time_rounded, size: 14.0, color: AppColors.primary),
                      const SizedBox(width: 6.0),
                      Expanded(
                        child: Text(
                          visit.timeSlot,
                          style: AppTextStyles.caption.copyWith(
                            fontWeight: FontWeight.w500,
                            color: AppColors.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (visit.rescheduleCount > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 2.0),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF3E8FF),
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                          child: Text(
                            'Rescheduled (${visit.rescheduleCount})',
                            style: AppTextStyles.caption.copyWith(
                              color: const Color(0xFF7E22CE),
                              fontSize: 10.0,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 12.0),

                // Property pill & action buttons
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 6.0),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(10.0),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.business_outlined, size: 14.0, color: AppColors.primary),
                            const SizedBox(width: 6.0),
                            Flexible(
                              child: Text(
                                propertyTitle,
                                style: AppTextStyles.caption.copyWith(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8.0),

                    // WhatsApp Action
                    IconButton(
                      icon: const Icon(Icons.chat_bubble_outline_rounded, size: 18.0, color: Color(0xFF16A34A)),
                      onPressed: () => _launchUrl(visit.buildWhatsappUrl()),
                      tooltip: 'WhatsApp',
                      style: IconButton.styleFrom(
                        backgroundColor: const Color(0xFFDCFCE7),
                        padding: const EdgeInsets.all(8.0),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
                      ),
                    ),
                    const SizedBox(width: 6.0),

                    // Phone Call Action
                    IconButton(
                      icon: const Icon(Icons.phone_outlined, size: 18.0, color: AppColors.primary),
                      onPressed: () => _launchUrl('tel:${visit.clientPhone}'),
                      tooltip: 'Call',
                      style: IconButton.styleFrom(
                        backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                        padding: const EdgeInsets.all(8.0),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
                      ),
                    ),
                    const SizedBox(width: 6.0),

                    // Popup Menu for more actions
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert_rounded, size: 18.0, color: AppColors.textSecondary),
                      onSelected: (action) => _handleMenuAction(context, action),
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          value: 'view',
                          child: Row(
                            children: [
                              const Icon(Icons.visibility_outlined, size: 16.0),
                              const SizedBox(width: 8.0),
                              Text(context.tr('visit_details')),
                            ],
                          ),
                        ),
                        if (visit.isPending)
                          PopupMenuItem(
                            value: 'confirm',
                            child: Row(
                              children: [
                                const Icon(Icons.check_circle_outline, size: 16.0, color: Color(0xFF0369A1)),
                                const SizedBox(width: 8.0),
                                Text(context.tr('confirm_visit')),
                              ],
                            ),
                          ),
                        if (!visit.isCompleted && !visit.isCancelled) ...[
                          PopupMenuItem(
                            value: 'reschedule',
                            child: Row(
                              children: [
                                const Icon(Icons.update_rounded, size: 16.0, color: Color(0xFF7E22CE)),
                                const SizedBox(width: 8.0),
                                Text(context.tr('reschedule_site_visit')),
                              ],
                            ),
                          ),
                          PopupMenuItem(
                            value: 'complete',
                            child: Row(
                              children: [
                                const Icon(Icons.task_alt_rounded, size: 16.0, color: Color(0xFF15803D)),
                                const SizedBox(width: 8.0),
                                Text(context.tr('mark_completed')),
                              ],
                            ),
                          ),
                          PopupMenuItem(
                            value: 'no_show',
                            child: Row(
                              children: [
                                const Icon(Icons.person_off_outlined, size: 16.0, color: Color(0xFF475569)),
                                const SizedBox(width: 8.0),
                                Text(context.tr('mark_no_show')),
                              ],
                            ),
                          ),
                          PopupMenuItem(
                            value: 'cancel',
                            child: Row(
                              children: [
                                const Icon(Icons.cancel_outlined, size: 16.0, color: Color(0xFFBE123C)),
                                const SizedBox(width: 8.0),
                                Text(context.tr('cancel_visit')),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
