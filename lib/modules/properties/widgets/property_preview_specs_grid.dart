// File: lib/modules/properties/widgets/property_preview_specs_grid.dart
// Purpose: A clean layout container rendering property specifications in a structured grid.

import 'package:flutter/material.dart';

import '../../../app/app_colors.dart';
import '../../../app/app_text_styles.dart';
import '../../../core/localization/property_localizer.dart';
import '../../../models/property_model.dart';

class PropertyPreviewSpecsGrid extends StatelessWidget {
  final PropertyModel property;

  const PropertyPreviewSpecsGrid({super.key, required this.property});

  @override
  Widget build(BuildContext context) {
    final formattedArea =
        '${property.area.toStringAsFixed(0)} ${PropertyLocalizer.getLocalizedAreaUnit(context, property.areaUnit)}';

    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(14.0),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Row(
            children: [
              _buildSpecItem(label: 'Bedrooms', value: '${property.bedrooms}'),
              _buildSpecItem(
                label: 'Bathrooms',
                value: '${property.bathrooms}',
                crossAxisAlignment: CrossAxisAlignment.center,
              ),
              _buildSpecItem(
                label: 'Balconies',
                value: '${property.balconies}',
                crossAxisAlignment: CrossAxisAlignment.end,
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12.0),
            child: Divider(color: AppColors.border, height: 1.0),
          ),
          Row(
            children: [
              _buildSpecItem(label: 'Area', value: formattedArea),
              _buildSpecItem(
                label: 'Facing',
                value: PropertyLocalizer.getLocalizedFacing(context, property.facing ?? ''),
                crossAxisAlignment: CrossAxisAlignment.center,
              ),
              _buildSpecItem(
                label: 'Parking',
                value: '${property.parking}',
                crossAxisAlignment: CrossAxisAlignment.end,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSpecItem({
    required String label,
    required String value,
    CrossAxisAlignment crossAxisAlignment = CrossAxisAlignment.start,
  }) {
    return Expanded(
      child: Column(
        crossAxisAlignment: crossAxisAlignment,
        children: [
          Text(label, style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary)),
          const SizedBox(height: 2.0),
          Text(value, style: AppTextStyles.body2.copyWith(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
