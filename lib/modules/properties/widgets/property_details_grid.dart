// File: lib/modules/properties/widgets/property_details_grid.dart
// Purpose: Reusable property details key-value list widget shared across property view and preview dialogs.

import 'package:flutter/material.dart';

import '../../../app/app_colors.dart';
import '../../../app/app_text_styles.dart';
import '../../../core/localization/property_localizer.dart';
import '../../../models/property_model.dart';

class PropertyDetailsGrid extends StatelessWidget {
  final PropertyModel property;

  const PropertyDetailsGrid({super.key, required this.property});

  @override
  Widget build(BuildContext context) {
    final details = <_DetailItem>[
      if (property.propertyCode != null && property.propertyCode!.isNotEmpty)
        _DetailItem(icon: Icons.code_outlined, label: 'Code', value: property.propertyCode!),
      _DetailItem(
        icon: Icons.chair_outlined,
        label: 'Furnishing',
        value: PropertyLocalizer.getLocalizedFurnishingStatus(context, property.furnishingStatus),
      ),
      _DetailItem(
        icon: Icons.construction_outlined,
        label: 'Construction',
        value: PropertyLocalizer.getLocalizedConstructionStatus(context, property.constructionStatus),
      ),
      if (property.floorNumber != null)
        _DetailItem(
          icon: Icons.layers_outlined,
          label: 'Floor',
          value: property.totalFloors != null
              ? '${property.floorNumber} of ${property.totalFloors}'
              : '${property.floorNumber}',
        ),
      if (property.totalFloors != null && property.floorNumber == null)
        _DetailItem(icon: Icons.apartment_outlined, label: 'Total Floors', value: '${property.totalFloors}'),
      _DetailItem(
        icon: Icons.category_outlined,
        label: 'Property Type',
        value: PropertyLocalizer.getLocalizedPropertyType(context, property.propertyType),
      ),
      _DetailItem(
        icon: Icons.sell_outlined,
        label: 'Listing Type',
        value: PropertyLocalizer.getLocalizedListingType(context, property.listingType),
      ),
      _DetailItem(
        icon: Icons.verified_outlined,
        label: 'Status',
        value: PropertyLocalizer.getLocalizedPropertyStatus(context, property.propertyStatus),
      ),
    ];

    return Column(
      children: details.map((item) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8.0),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(10.0),
                ),
                child: Icon(item.icon, size: 18.0, color: AppColors.primary),
              ),
              const SizedBox(width: 14.0),
              Expanded(
                child: Text(item.label, style: AppTextStyles.body2.copyWith(color: AppColors.textSecondary)),
              ),
              SelectableText(
                item.value,
                style: AppTextStyles.body2.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _DetailItem {
  final IconData icon;
  final String label;
  final String value;
  const _DetailItem({required this.icon, required this.label, required this.value});
}
