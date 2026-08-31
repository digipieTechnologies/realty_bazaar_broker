// File: lib/modules/dashboard/widgets/video_requests/video_request_tile_widget.dart
// Purpose: Modular tile widget supporting both desktop table row & mobile card layouts for video shoot requests.

// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';

import '../../../../app/app_colors.dart';
import '../../../../app/app_text_styles.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../models/models.dart';
import '../../../../util/app_date_utils.dart';
import '../../../../widgets/buttons/app_popup_menu_button.dart';
import '../../../../widgets/dialogs/video_request_dialog.dart';

class VideoRequestTileWidget extends StatelessWidget {
  final VideoRequestModel req;
  final bool isMobile;
  final VoidCallback? onCancelPressed;

  const VideoRequestTileWidget({super.key, required this.req, this.isMobile = false, this.onCancelPressed});

  Color _getStatusColor(VideoRequestStatus status) {
    switch (status) {
      case VideoRequestStatus.pending:
        return AppColors.warning;
      case VideoRequestStatus.inProgress:
        return AppColors.info;
      case VideoRequestStatus.completed:
        return AppColors.success;
      case VideoRequestStatus.cancelled:
        return AppColors.error;
      default:
        return AppColors.textMuted;
    }
  }

  String _getStatusLabel(BuildContext context, VideoRequestStatus status) {
    switch (status) {
      case VideoRequestStatus.pending:
        return context.tr('pending');
      case VideoRequestStatus.inProgress:
        return context.tr('in_progress');
      case VideoRequestStatus.completed:
        return context.tr('completed');
      case VideoRequestStatus.cancelled:
        return context.tr('cancelled');
      default:
        return status.toString().split('.').last.toUpperCase();
    }
  }

  String _formatDate(DateTime dateTime) {
    return AppDateUtils.formatDate(dateTime);
  }

  @override
  Widget build(BuildContext context) {
    if (isMobile) {
      return _buildRequestCard(context);
    }
    return _buildRequestRow(context);
  }

  // --- MOBILE CARD LAYOUT ---
  Widget _buildRequestCard(BuildContext context) {
    final statusColor = _getStatusColor(req.status);
    final statusLabel = _getStatusLabel(context, req.status);
    final formattedDate = _formatDate(req.createdAt);

    final addressStr = () {
      final addr = req.property?.address;
      if (addr == null) return 'No Address';
      if (addr.fullAddress.trim().isNotEmpty) {
        return addr.fullAddress.trim();
      }
      final parts = [addr.city, addr.state].where((e) => e != null && e.trim().isNotEmpty).join(', ');
      return parts.isNotEmpty ? parts : 'No Address';
    }();

    return Card(
      margin: const EdgeInsets.only(bottom: 12.0),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14.0),
        side: const BorderSide(color: AppColors.border, width: 1.0),
      ),
      color: AppColors.surface,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: Icon, Title, Status & Actions Menu
            Row(
              children: [
                Container(
                  width: 32.0,
                  height: 32.0,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: const Icon(Icons.apartment_rounded, color: AppColors.primary, size: 16.0),
                ),
                const SizedBox(width: 10.0),
                Expanded(
                  child: Text(
                    req.property?.title ?? 'Unknown Property',
                    style: AppTextStyles.body1.copyWith(
                      fontSize: 14.0,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 2.0),
                _buildPopupMenu(context),
              ],
            ),
            const SizedBox(height: 8.0),

            // Address Line
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 2.0),
                  child: Icon(Icons.location_on_outlined, size: 14.0, color: AppColors.error),
                ),
                const SizedBox(width: 4.0),
                Expanded(
                  child: Text(
                    addressStr,
                    style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary, fontSize: 12.0),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8.0),

            // Date & Status Badge Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Created Date
                Row(
                  children: [
                    const Icon(Icons.calendar_today_outlined, size: 12.0, color: AppColors.textSecondary),
                    const SizedBox(width: 4.0),
                    Text(
                      formattedDate,
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textSecondary,
                        fontSize: 11.0,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                // Status Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 3.0),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6.0),
                  ),
                  child: Text(
                    statusLabel,
                    style: AppTextStyles.caption.copyWith(
                      fontWeight: FontWeight.bold,
                      color: statusColor,
                      fontSize: 10.5,
                    ),
                  ),
                ),
              ],
            ),

            if (req.notes != null && req.notes!.trim().isNotEmpty) ...[
              const SizedBox(height: 10.0),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 8.0),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(8.0),
                  border: Border.all(color: AppColors.border.withValues(alpha: 0.6)),
                ),
                child: Text(
                  req.notes!,
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textSecondary,
                    fontSize: 12.0,
                    height: 1.3,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // --- DESKTOP TABLE ROW LAYOUT ---
  Widget _buildRequestRow(BuildContext context) {
    final statusColor = _getStatusColor(req.status);
    final statusLabel = _getStatusLabel(context, req.status);
    final formattedDate = _formatDate(req.createdAt);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 14.0),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.border, width: 1.0)),
      ),
      child: Row(
        children: [
          // Property Details
          Expanded(
            flex: 3,
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                  child: const Icon(Icons.apartment_outlined, color: AppColors.primary, size: 20),
                ),
                const SizedBox(width: 14.0),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        req.property?.title ?? 'Unknown Property',
                        style: AppTextStyles.heading3.copyWith(
                          fontSize: 13.5,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2.0),
                      Text(
                        req.property?.address?.fullAddress ?? 'No Address',
                        style: AppTextStyles.caption.copyWith(color: AppColors.textMuted, fontSize: 12.0),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Status Badge
          Expanded(
            flex: 2,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 4.0),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6.0),
                ),
                child: Text(
                  statusLabel,
                  style: AppTextStyles.caption.copyWith(
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                    fontSize: 11.0,
                  ),
                ),
              ),
            ),
          ),

          // Notes
          Expanded(
            flex: 4,
            child: Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: Text(
                req.notes == null || req.notes!.trim().isEmpty ? '--' : req.notes!,
                style: AppTextStyles.body2.copyWith(color: AppColors.textSecondary, fontSize: 13.0),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),

          // Created Date
          Expanded(
            flex: 2,
            child: Text(
              formattedDate,
              style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary, fontSize: 12.0),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),

          // Action Menu
          SizedBox(width: 40, child: _buildPopupMenu(context)),
        ],
      ),
    );
  }

  Widget _buildPopupMenu(BuildContext context) {
    final showCancel = req.status == VideoRequestStatus.pending;

    return AppPopupMenuButton<String>(
      triggerIconColor: AppColors.textSecondary,
      onSelected: (value) {
        if (value == 'cancel' && onCancelPressed != null) {
          onCancelPressed!();
        } else if (value == 'view_details') {
          showDialog(
            context: context,
            builder: (dialogCtx) =>
                VideoRequestDialog(propertyId: req.propertyId ?? '', brokerId: req.brokerId ?? ''),
          );
        }
      },
      items: [
        AppPopupMenuItem<String>(
          value: 'view_details',
          iconData: Icons.info_outline_rounded,
          label: context.tr('view_details'),
        ),
        if (showCancel)
          AppPopupMenuItem<String>(
            value: 'cancel',
            iconData: Icons.cancel_outlined,
            iconColor: AppColors.error,
            label: context.tr('cancel_request'),
          ),
      ],
    );
  }
}
