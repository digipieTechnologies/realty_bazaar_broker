// File: lib/modules/properties/widgets/property_preview_specs_grid.dart
// Purpose: A clean layout container rendering property specifications in a structured grid.

import 'package:flutter/material.dart';
import '../../../models/property_model.dart';
import '../../../app/app_colors.dart';
import '../../../app/app_text_styles.dart';
import '../../../core/localization/property_localizer.dart';

class PropertyPreviewSpecsGrid extends StatelessWidget {
  final PropertyModel property;

  const PropertyPreviewSpecsGrid({
    super.key,
    required this.property,
  });

  @override
  Widget build(BuildContext context) {
    final formattedArea =
        '${property.area.toStringAsFixed(0)} ${PropertyLocalizer.getLocalizedAreaUnit(context, property.areaUnit)}';

    return Container(
      padding: const EdgeInsets.all(14.0),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildSpecItem('Bedrooms', '${property.bedrooms}'),
              _buildSpecItem('Bathrooms', '${property.bathrooms}'),
              _buildSpecItem('Balconies', '${property.balconies}'),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12.0),
            child: Divider(color: AppColors.border, height: 1.0),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildSpecItem('Area', formattedArea),
              _buildSpecItem(
                  'Facing',
                  PropertyLocalizer.getLocalizedFacing(
                      context, property.facing ?? '')),
              _buildSpecItem('Parking', '${property.parking}'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSpecItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: 2.0),
        Text(
          value,
          style: AppTextStyles.body2.copyWith(fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}
