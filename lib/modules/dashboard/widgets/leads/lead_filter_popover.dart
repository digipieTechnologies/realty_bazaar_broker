// File: lib/modules/dashboard/widgets/leads/lead_filter_popover.dart
// Purpose: Separate modular filter widget for lead platform filtering with multi-select checkboxes in a Wrap layout.

import 'package:flutter/material.dart';
import '../../../../app/app_colors.dart';
import '../../../../app/app_text_styles.dart';

class LeadFilterPopover extends StatelessWidget {
  final List<String> selectedPlatforms;
  final ValueChanged<List<String>> onPlatformsChanged;

  const LeadFilterPopover({
    super.key,
    required this.selectedPlatforms,
    required this.onPlatformsChanged,
  });

  void _togglePlatform(String platform) {
    final updated = List<String>.from(selectedPlatforms);
    if (updated.contains(platform)) {
      updated.remove(platform);
    } else {
      updated.add(platform);
    }
    onPlatformsChanged(updated);
  }

  void _selectAll() {
    onPlatformsChanged([]);
  }

  @override
  Widget build(BuildContext context) {
    final isAllSelected = selectedPlatforms.isEmpty;

    final platformOptions = <Map<String, String>>[
      {
        'label': 'Facebook',
        'value': 'facebook',
      },
      {
        'label': 'Instagram',
        'value': 'instagram',
      },
      {
        'label': 'Other',
        'value': 'other',
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 10.0),
          child: Text(
            'PLATFORM',
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
            for (final opt in platformOptions)
              _buildCheckboxRow(
                label: opt['label']!,
                isChecked: selectedPlatforms.contains(opt['value']),
                onTap: () => _togglePlatform(opt['value']!),
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
