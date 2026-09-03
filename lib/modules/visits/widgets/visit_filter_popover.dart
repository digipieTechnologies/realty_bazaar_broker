// File: lib/modules/visits/widgets/visit_filter_popover.dart
// Purpose: Status filter popover with multi-select checkboxes for site visits.

import 'package:flutter/material.dart';

import '../../../../app/app_colors.dart';
import '../../../../app/app_text_styles.dart';
import '../../../../core/localization/app_localizations.dart';

class VisitFilterPopover extends StatelessWidget {
  final List<String> selectedStatuses;
  final ValueChanged<List<String>> onStatusesChanged;

  const VisitFilterPopover({
    super.key,
    required this.selectedStatuses,
    required this.onStatusesChanged,
  });

  void _toggleStatus(String status) {
    final updated = List<String>.from(selectedStatuses);
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

    final statusOptions = <Map<String, String>>[
      {'labelKey': 'status_pending', 'value': 'pending'},
      {'labelKey': 'status_confirmed', 'value': 'confirmed'},
      {'labelKey': 'status_rescheduled', 'value': 'rescheduled'},
      {'labelKey': 'status_completed', 'value': 'completed'},
      {'labelKey': 'status_cancelled', 'value': 'cancelled'},
      {'labelKey': 'status_no_show', 'value': 'no_show'},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 10.0),
          child: Text(
            context.tr('visit_status').toUpperCase(),
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
              label: context.tr('filter_all'),
              isChecked: isAllSelected,
              onTap: _selectAll,
            ),
            for (final opt in statusOptions)
              _buildCheckboxRow(
                label: context.tr(opt['labelKey']!),
                isChecked: selectedStatuses.contains(opt['value']),
                onTap: () => _toggleStatus(opt['value']!),
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
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4.0)),
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
