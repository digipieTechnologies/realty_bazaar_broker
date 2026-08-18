// File: lib/modules/properties/widgets/property_amenities_wrap.dart
// Purpose: Reusable property amenities wrap widget shared across property preview and view dialogs.

import 'package:flutter/material.dart';
import '../../../app/app_colors.dart';
import '../../../app/app_text_styles.dart';
import '../../../core/localization/property_localizer.dart';
import '../../../core/utils/property_amenity_helper.dart';

class PropertyAmenitiesWrap extends StatelessWidget {
  final List<String> amenities;

  const PropertyAmenitiesWrap({
    super.key,
    required this.amenities,
  });

  @override
  Widget build(BuildContext context) {
    if (amenities.isEmpty) return const SizedBox.shrink();

    return Wrap(
      spacing: 8.0,
      runSpacing: 8.0,
      children: amenities.map((amenity) {
        final icon = PropertyAmenityHelper.getIcon(amenity);
        final localizedLabel = PropertyLocalizer.getLocalizedAmenity(context, amenity);

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(20.0),
            border: Border.all(color: AppColors.primary.withValues(alpha: 0.12)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: AppColors.primary, size: 14.0),
              const SizedBox(width: 6.0),
              Text(
                localizedLabel,
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
