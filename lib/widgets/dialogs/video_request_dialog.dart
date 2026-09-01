import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../app/app_colors.dart';
import '../../../app/app_text_styles.dart';
import '../../../app/app_utils.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../models/models.dart';
import '../../../providers/video_request/video_request_provider.dart';
import '../../../widgets/buttons/app_button.dart';
import '../../../widgets/shimmer/video_request_shimmer_widget.dart';
import '../../../widgets/toast/app_toast.dart';
import '../../modules/chat/chat.dart';
import 'app_base_dialog.dart';

class VideoRequestDialog extends StatefulWidget {
  final String propertyId;
  final String brokerId;

  const VideoRequestDialog({super.key, required this.propertyId, required this.brokerId});

  @override
  State<VideoRequestDialog> createState() => _VideoRequestDialogState();
}

class _VideoRequestDialogState extends State<VideoRequestDialog> {
  bool _isLoading = true;
  bool _isSubmitting = false;
  VideoRequestModel? _existingRequest;
  PropertyModel? _propertyData;
  final TextEditingController _notesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _checkExistingRequest();
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _checkExistingRequest() async {
    try {
      final provider = Provider.of<VideoRequestProvider>(context, listen: false);
      final details = await provider.fetchVideoRequestDetails(propertyId: widget.propertyId);

      if (mounted) {
        setState(() {
          _existingRequest = details.videoRequest;
          _propertyData = details.property;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('[VideoRequestDialog] Error checking request: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _submitRequest() async {
    AppUtils.hideKeyboard(context);
    setState(() => _isSubmitting = true);
    try {
      final provider = Provider.of<VideoRequestProvider>(context, listen: false);
      final notes = _notesController.text.trim();

      final result = await provider.submitRequest(
        brokerId: widget.brokerId,
        propertyId: widget.propertyId,
        notes: notes,
      );

      if (result != null) {
        setState(() {
          _existingRequest = result;
        });
        AppToast.showSuccess('Request Submitted', 'Video request submitted successfully!');
      } else {
        AppToast.showError('Submission Failed', 'Could not submit video request.');
      }
    } catch (e) {
      debugPrint('[VideoRequestDialog] Error submitting request: $e');
      AppToast.showError('Submission Failed', e.toString());
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  Future<void> _cancelRequest() async {
    if (_existingRequest == null) return;
    setState(() => _isSubmitting = true);

    try {
      final provider = Provider.of<VideoRequestProvider>(context, listen: false);
      final updated = await provider.cancelRequestWithModel(_existingRequest!.id, brokerId: widget.brokerId);

      if (updated != null) {
        setState(() {
          _existingRequest = updated;
        });
        AppToast.showSuccess('Request Cancelled', 'Your video request has been cancelled.');
      } else {
        AppToast.showError('Cancellation Failed', 'Could not cancel video request.');
      }
    } catch (e) {
      debugPrint('[VideoRequestDialog] Error cancelling request: $e');
      AppToast.showError('Cancellation Failed', e.toString());
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  String _formatDateTime(String? isoString) {
    return AppUtils.formatDateTime(isoString);
  }

  Widget _buildPropertyHeader() {
    if (_propertyData == null && _existingRequest?.property == null) {
      return const SizedBox.shrink();
    }

    final title = _propertyData?.propertyTitle ?? _existingRequest?.property?.title ?? 'Property Details';
    final addr = _propertyData?.address ?? _existingRequest?.property?.address;

    String addressStr = 'No address details';
    if (addr != null) {
      if (addr.fullAddress.trim().isNotEmpty) {
        addressStr = addr.fullAddress.trim();
      } else {
        final parts = [addr.city, addr.state].where((e) => e != null && e.isNotEmpty).join(', ');
        if (parts.isNotEmpty) addressStr = parts;
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16.0),
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: AppColors.border, width: 1.0),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8.0),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10.0),
            ),
            child: const Icon(Icons.apartment_rounded, color: AppColors.primary, size: 22.0),
          ),
          const SizedBox(width: 12.0),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.body1.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                    fontSize: 14.0,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2.0),
                Row(
                  children: [
                    const Icon(Icons.location_on_outlined, size: 13.0, color: AppColors.textSecondary),
                    const SizedBox(width: 4.0),
                    Expanded(
                      child: Text(
                        addressStr,
                        style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary, fontSize: 12.0),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepItem({required String stepNumber, required String title, required String desc}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 20.0,
            height: 20.0,
            decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
            child: Center(
              child: Text(
                stepNumber,
                style: const TextStyle(color: Colors.white, fontSize: 10.0, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(width: 10.0),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.body2.copyWith(fontWeight: FontWeight.bold, fontSize: 13.0)),
                const SizedBox(height: 1.0),
                Text(desc, style: const TextStyle(color: AppColors.textMuted, fontSize: 11.5, height: 1.3)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return AppBaseDialog(
        headerIcon: Icons.videocam_rounded,
        title: context.tr('video_request'),
        maxWidth: 500.0,
        content: const VideoRequestShimmerWidget(),
      );
    }
    return _buildContent();
  }

  Widget _buildContent() {
    final status = _existingRequest?.status;

    if (_existingRequest == null) {
      // 1. Submit Request View
      return AppBaseDialog(
        headerIcon: Icons.videocam_rounded,
        title: context.tr('request_video'),
        maxWidth: 520.0,
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildPropertyHeader(),
            Text(
              context.tr('video_request_desc'),
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 13.0),
            ),
            const SizedBox(height: 16.0),
            _buildStepItem(
              stepNumber: '1',
              title: context.tr('video_request_step1_title'),
              desc: context.tr('video_request_step1_desc'),
            ),
            _buildStepItem(
              stepNumber: '2',
              title: context.tr('video_request_step2_title'),
              desc: context.tr('video_request_step2_desc'),
            ),
            const SizedBox(height: 12.0),
            Text(
              context.tr('special_instructions_label'),
              style: AppTextStyles.body2.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6.0),
            TextField(
              controller: _notesController,
              minLines: 3,
              maxLines: 5,
              maxLength: 250,
              style: const TextStyle(fontSize: 13.0),
              decoration: InputDecoration(
                hintText: context.tr('special_instructions_hint'),
                hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 12.0),
                contentPadding: const EdgeInsets.all(10.0),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10.0),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10.0),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10.0),
                  borderSide: const BorderSide(color: AppColors.primary),
                ),
              ),
            ),
            const SizedBox(height: 20.0),
            AppButton.solid(
              text: context.tr('submit_request'),
              isLoading: _isSubmitting,
              height: 46.0,
              borderRadius: 10.0,
              color: AppColors.primary,
              onPressed: _isSubmitting ? null : _submitRequest,
            ),
          ],
        ),
      );
    }

    // 2. Status Views
    Color statusColor;
    String statusTitle;
    String statusDesc;
    IconData statusIcon;

    switch (status) {
      case VideoRequestStatus.pending:
        statusColor = Colors.orange;
        statusIcon = Icons.pending_actions_rounded;
        statusTitle = context.tr('status_pending_title');
        statusDesc = context.tr('status_pending_desc');
        break;
      case VideoRequestStatus.assigned:
      case VideoRequestStatus.inProgress:
        statusColor = AppColors.primary;
        statusIcon = Icons.movie_filter_rounded;
        statusTitle = context.tr('status_in_progress_title');
        statusDesc = context.tr('status_in_progress_desc');
        break;
      case VideoRequestStatus.completed:
        statusColor = Colors.green;
        statusIcon = Icons.check_circle_rounded;
        statusTitle = context.tr('status_completed_title');
        final completedDate = _existingRequest?.completedAt?.toIso8601String();
        final formattedDate = _formatDateTime(completedDate);
        statusDesc =
            '${context.tr('status_completed_desc')}${formattedDate.isNotEmpty ? "\n\nUploaded on: $formattedDate" : ""}';
        break;
      case VideoRequestStatus.cancelled:
        statusColor = AppColors.error;
        statusIcon = Icons.cancel_rounded;
        final cancelReasonStr = _existingRequest?.cancelReason ?? _existingRequest?.adminCancelReason;

        statusTitle = context.tr('status_cancelled_title');
        statusDesc = cancelReasonStr != null && cancelReasonStr.trim().isNotEmpty
            ? 'Reason for cancellation:\n"$cancelReasonStr"'
            : context.tr('status_cancelled_desc');
        break;
      default:
        statusColor = AppColors.textSecondary;
        statusIcon = Icons.info_outline_rounded;
        statusTitle = 'Request Update';
        statusDesc = 'Your video request is in status: ${status?.toString().split('.').last ?? ''}.';
    }

    return AppBaseDialog(
      headerIcon: Icons.videocam_rounded,
      title: context.tr('video_request_status'),
      maxWidth: 520.0,
      headerActions: [
        IconButton(
          icon: const Icon(Icons.chat_bubble_outline_rounded, color: AppColors.primary),
          tooltip: context.tr('video_request_chat'),
          onPressed: () {
            showDialog(
              context: context,
              builder: (_) => ChatDialog(
                videoRequestId: _existingRequest!.id,
                brokerId: widget.brokerId,
                currentUserId: widget.brokerId,
                currentUserType: 'broker',
                chatTitle: 'Marketing Team',
                propertyTitle: _propertyData?.propertyTitle ?? _existingRequest?.property?.title,
                propertyAddress: _propertyData?.propertyTitle ?? _existingRequest?.property?.title,
              ),
            );
          },
        ),
      ],
      content: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.08), shape: BoxShape.circle),
            child: Icon(statusIcon, color: statusColor, size: 48.0),
          ),
          const SizedBox(height: 18.0),
          Text(
            statusTitle,
            style: AppTextStyles.heading3.copyWith(fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12.0),
          Text(
            statusDesc,
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 13.0, height: 1.4),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20.0),
          _buildPropertyHeader(),
          const SizedBox(height: 16.0),
          if (status == VideoRequestStatus.pending)
            AppButton.outline(
              text: 'Cancel Request',
              isLoading: _isSubmitting,
              height: 46.0,
              borderRadius: 10.0,
              borderColor: Colors.red,
              textColor: Colors.red,
              onPressed: _isSubmitting ? null : _cancelRequest,
            )
          else if (status == VideoRequestStatus.cancelled)
            Row(
              children: [
                Expanded(
                  child: AppButton.outline(
                    text: context.tr('close_button'),
                    height: 46.0,
                    borderRadius: 10.0,
                    borderColor: AppColors.border,
                    textColor: AppColors.textPrimary,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
                const SizedBox(width: 10.0),
                Expanded(
                  child: AppButton.solid(
                    text: context.tr('request_again'),
                    height: 46.0,
                    borderRadius: 10.0,
                    color: AppColors.primary,
                    onPressed: () {
                      setState(() {
                        _existingRequest = null;
                      });
                    },
                  ),
                ),
              ],
            )
          else
            AppButton.solid(
              text: 'OK',
              height: 46.0,
              borderRadius: 10.0,
              color: AppColors.primary,
              onPressed: () => Navigator.of(context).pop(),
            ),
        ],
      ),
    );
  }
}
