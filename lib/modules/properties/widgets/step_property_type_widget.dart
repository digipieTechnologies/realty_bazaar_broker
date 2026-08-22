import 'package:flutter/material.dart';

import '../../../app/app_colors.dart';
import '../../../app/app_text_styles.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../models/property_enums.dart';
import 'field_info_dialog.dart';

class PropertyTypeOption {
  final PropertyType type;
  final String titleKey;
  final String descriptionKey;
  final String assetImage;

  const PropertyTypeOption({
    required this.type,
    required this.titleKey,
    required this.descriptionKey,
    required this.assetImage,
  });

  String get value => type.apiValue;
}

class StepPropertyTypeWidget extends StatelessWidget {
  final PropertyType selectedType;
  final ValueChanged<PropertyType> onTypeSelected;

  static const List<PropertyTypeOption> propertyTypes = [
    PropertyTypeOption(
      type: PropertyType.apartment,
      titleKey: 'prop_type_flat',
      descriptionKey: 'prop_type_flat_desc',
      assetImage: 'assets/images/property/apartment_flat.png',
    ),
    PropertyTypeOption(
      type: PropertyType.villa,
      titleKey: 'prop_type_villa',
      descriptionKey: 'prop_type_villa_desc',
      assetImage: 'assets/images/property/villa_bungalow.png',
    ),
    PropertyTypeOption(
      type: PropertyType.rowHouse,
      titleKey: 'prop_type_row_house',
      descriptionKey: 'prop_type_row_house_desc',
      assetImage: 'assets/images/property/row_house.png',
    ),
    PropertyTypeOption(
      type: PropertyType.penthouse,
      titleKey: 'prop_type_penthouse',
      descriptionKey: 'prop_type_penthouse_desc',
      assetImage: 'assets/images/property/penthouse.png',
    ),
    PropertyTypeOption(
      type: PropertyType.commercial,
      titleKey: 'prop_type_commercial',
      descriptionKey: 'prop_type_commercial_desc',
      assetImage: 'assets/images/property/commercial_office.png',
    ),
    PropertyTypeOption(
      type: PropertyType.plot,
      titleKey: 'prop_type_plot',
      descriptionKey: 'prop_type_plot_desc',
      assetImage: 'assets/images/property/plot_industrial.png',
    ),
  ];

  const StepPropertyTypeWidget({
    super.key,
    required this.selectedType,
    required this.onTypeSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Title with Info Icon
        Row(
          children: [
            Flexible(
              child: Text(
                context.tr('select_property_category'),
                style: AppTextStyles.heading2.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            const SizedBox(width: 8.0),
            MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                onTap: () {
                  FieldInfoDialog.show(
                    context,
                    title: context.tr('select_property_category'),
                    description: context.tr('select_property_category_desc'),
                    examples: [
                      '${context.tr('prop_type_flat')}: ${context.tr('prop_type_flat_desc')}',
                      '${context.tr('prop_type_villa')}: ${context.tr('prop_type_villa_desc')}',
                      '${context.tr('prop_type_commercial')}: ${context.tr('prop_type_commercial_desc')}',
                    ],
                    tip: 'Selecting the correct property type improves buyer match accuracy.',
                  );
                },
                child: const Icon(
                  Icons.info_outline_rounded,
                  color: AppColors.primary,
                  size: 20.0,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6.0),
        Text(
          context.tr('select_property_category_desc'),
          style: AppTextStyles.body2.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: 24.0),

        // Grid of Property Type Cards (Responsive 1 column on mobile, 2 on tablet, 3 on desktop)
        LayoutBuilder(
          builder: (context, constraints) {
            final isDesktop = constraints.maxWidth >= 850;
            final isTablet = constraints.maxWidth >= 520 && constraints.maxWidth < 850;
            final isMobile = constraints.maxWidth < 520;

            final crossAxisCount = isDesktop ? 3 : (isTablet ? 2 : 1);
            // Fixed height per card – independent of width
            final double cardHeight = isMobile ? 120.0 : (isTablet ? 220.0 : 240.0);

            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: propertyTypes.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: 14.0,
                mainAxisSpacing: 14.0,
                mainAxisExtent: cardHeight,
              ),
              itemBuilder: (context, index) {
                final option = propertyTypes[index];
                final isSelected = selectedType == option.type;
                return MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: GestureDetector(onTap: () => onTypeSelected(option.type),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.primary.withValues(alpha: 0.04)
                            : AppColors.surface,
                        borderRadius: BorderRadius.circular(16.0),
                        border: Border.all(
                          color: isSelected ? AppColors.primary : AppColors.border,
                          width: isSelected ? 2.5 : 1.0,
                        ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: AppColors.primary.withValues(alpha: 0.15),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ]
                            : [],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(14.0),
                        child: isMobile
                            ? Row(
                                children: [
                                  // Left Image Thumbnail for Mobile
                                  Expanded(
                                    flex: 4,
                                    child: Stack(
                                      children: [
                                        Positioned.fill(
                                          child: Image.asset(
                                            option.assetImage,
                                            fit: BoxFit.cover,
                                            errorBuilder: (context, error, stackTrace) => Container(
                                              color: AppColors.background,
                                              child: const Icon(Icons.apartment, size: 30, color: AppColors.textMuted),
                                            ),
                                          ),
                                        ),
                                        if (isSelected)
                                          Positioned(
                                            top: 8,
                                            left: 8,
                                            child: Container(
                                              padding: const EdgeInsets.all(4),
                                              decoration: const BoxDecoration(
                                                color: AppColors.primary,
                                                shape: BoxShape.circle,
                                              ),
                                              child: const Icon(
                                                Icons.check_rounded,
                                                color: Colors.white,
                                                size: 14,
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),

                                  // Right Text Details for Mobile
                                  Expanded(
                                    flex: 6,
                                    child: Padding(
                                      padding: const EdgeInsets.all(12.0),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            context.tr(option.titleKey),
                                            style: AppTextStyles.body1.copyWith(
                                              fontWeight: FontWeight.bold,
                                              color: isSelected
                                                  ? AppColors.primary
                                                  : AppColors.textPrimary,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 4.0),
                                          Text(
                                            context.tr(option.descriptionKey),
                                            style: AppTextStyles.caption.copyWith(
                                              color: AppColors.textSecondary,
                                              fontSize: 11.5,
                                            ),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              )
                            : Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Card Asset Image
                                  Expanded(
                                    flex: 6,
                                    child: Stack(
                                      children: [
                                        Positioned.fill(
                                          child: Image.asset(
                                            option.assetImage,
                                            fit: BoxFit.cover,
                                            errorBuilder: (context, error, stackTrace) => Container(
                                              color: AppColors.background,
                                              child: const Icon(Icons.apartment, size: 40, color: AppColors.textMuted),
                                            ),
                                          ),
                                        ),
                                        if (isSelected)
                                          Positioned(
                                            top: 10,
                                            right: 10,
                                            child: Container(
                                              padding: const EdgeInsets.all(4),
                                              decoration: const BoxDecoration(
                                                color: AppColors.primary,
                                                shape: BoxShape.circle,
                                              ),
                                              child: const Icon(
                                                Icons.check_rounded,
                                                color: Colors.white,
                                                size: 16,
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),

                                  // Card Title & Description
                                  Expanded(
                                    flex: 5,
                                    child: Padding(
                                      padding: const EdgeInsets.all(12.0),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            context.tr(option.titleKey),
                                            style: AppTextStyles.body1.copyWith(
                                              fontWeight: FontWeight.bold,
                                              color: isSelected
                                                  ? AppColors.primary
                                                  : AppColors.textPrimary,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 4.0),
                                          Text(
                                            context.tr(option.descriptionKey),
                                            style: AppTextStyles.caption.copyWith(
                                              color: AppColors.textSecondary,
                                              fontSize: 11.5,
                                            ),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }
}
