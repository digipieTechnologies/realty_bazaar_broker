// File: lib/modules/dashboard/widgets/video_requests/video_request_filter_popover.dart
// Purpose: Separate modular filter widget for video request status filtering with multi-select checkboxes in a Wrap layout.

import 'package:flutter/material.dart';
import '../../../../app/app_colors.dart';
import '../../../../app/app_text_styles.dart';
import '../../../../models/models.dart';

class VideoRequestFilterPopover extends StatelessWidget {
  final List<VideoRequestStatus> selectedStatuses;
  final ValueChanged<List<VideoRequestStatus>> onStatusesChanged;

  const VideoRequestFilterPopover({
    super.key,
    required this.selectedStatuses,
    required this.onStatusesChanged,
  });

  void _toggleStatus(VideoRequestStatus status) {
    final updated = List<VideoRequestStatus>.from(selectedStatuses);
    if (updated.contains(status)) {
      updated.remove(status);
    } else {
      updated.add(status);
    }
    onStatusesChanged(updated);
  }

  void _selectAll() {
    onStatusesChanged([]);
  }

  @override
  Widget build(BuildContext context) {
    final isAllSelected = selectedStatuses.isEmpty;

    final statusOptions = <Map<String, dynamic>>[
      {
        'label': 'Pending',
        'status': VideoRequestStatus.pending,
      },
      {
        'label': 'In Progress',
        'status': VideoRequestStatus.inProgress,
      },
      {
        'label': 'Completed',
        'status': VideoRequestStatus.completed,
      },
      {
        'label': 'Cancelled',
        'status': VideoRequestStatus.cancelled,
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 10.0),
          child: Text(
            'STATUS',
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.bold,
              fontSize: 11.0,
              letterSpacing: 0.8,
            ),
          ),
        ),
        
        Wrap(
          spacing: 12.0,
          runSpacing: 10.0,
          children: [
            _buildCheckboxRow(
              label: 'All',
              isChecked: isAllSelected,
              onTap: _selectAll,
            ),
            for (final opt in statusOptions)
              _buildCheckboxRow(
                label: opt['label'] as String,
                isChecked: selectedStatuses.contains(opt['status'] as VideoRequestStatus),
                onTap: () => _toggleStatus(opt['status'] as VideoRequestStatus),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildCheckboxRow({
    required String label,
    required bool isChecked,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6.0),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2.0, horizontal: 2.0),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: 20.0,
              width: 20.0,
              child: Checkbox(
                value: isChecked,
                onChanged: (_) => onTap(),
                activeColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4.0),
                ),
                side: const BorderSide(color: AppColors.border, width: 1.5),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
            const SizedBox(width: 6.0),
            Text(
              label,
              style: AppTextStyles.body2.copyWith(
                color: isChecked ? AppColors.textPrimary : AppColors.textSecondary,
                fontWeight: isChecked ? FontWeight.bold : FontWeight.w500,
                fontSize: 13.0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
