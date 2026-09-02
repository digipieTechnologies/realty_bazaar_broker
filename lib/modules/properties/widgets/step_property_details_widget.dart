import 'package:flutter/material.dart';

import '../../../app/app_colors.dart';
import '../../../app/app_text_styles.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/localization/property_localizer.dart';
import '../../../core/utils/property_amenity_helper.dart';
import '../../../models/media_model.dart';
import '../../../models/property_enums.dart';
import '../../../util/common_ext.dart';
import '../../../widgets/inputs/app_dropdown.dart';
import '../../../widgets/inputs/app_square_media_picker.dart';
import '../../../widgets/inputs/app_textfield.dart';
import 'field_info_dialog.dart';

class StepPropertyDetailsWidget extends StatefulWidget {
  final ListingType listingType;
  final ValueChanged<ListingType> onListingTypeChanged;

  final ConstructionStatus constructionStatus;
  final ValueChanged<ConstructionStatus> onConstructionStatusChanged;

  final TextEditingController titleController;
  final TextEditingController descriptionController;
  final TextEditingController priceController;
  final TextEditingController areaController;

  final AreaUnit areaUnit;
  final ValueChanged<AreaUnit> onAreaUnitChanged;

  final int bedrooms;
  final ValueChanged<int> onBedroomsChanged;

  final int bathrooms;
  final ValueChanged<int> onBathroomsChanged;

  final int balconies;
  final ValueChanged<int> onBalconiesChanged;

  final int parking;
  final ValueChanged<int> onParkingChanged;

  final TextEditingController floorNumberController;
  final TextEditingController totalFloorsController;

  final FacingDirection? facing;
  final ValueChanged<FacingDirection?> onFacingChanged;

  final FurnishingStatus furnishingStatus;
  final ValueChanged<FurnishingStatus> onFurnishingStatusChanged;

  final List<String> selectedAmenities;
  final ValueChanged<List<String>> onAmenitiesChanged;

  final List<MediaModel> medias;
  final ValueChanged<List<MediaModel>> onMediasChanged;

  const StepPropertyDetailsWidget({
    super.key,
    required this.listingType,
    required this.onListingTypeChanged,
    required this.constructionStatus,
    required this.onConstructionStatusChanged,
    required this.titleController,
    required this.descriptionController,
    required this.priceController,
    required this.areaController,
    required this.areaUnit,
    required this.onAreaUnitChanged,
    required this.bedrooms,
    required this.onBedroomsChanged,
    required this.bathrooms,
    required this.onBathroomsChanged,
    required this.balconies,
    required this.onBalconiesChanged,
    required this.parking,
    required this.onParkingChanged,
    required this.floorNumberController,
    required this.totalFloorsController,
    required this.facing,
    required this.onFacingChanged,
    required this.furnishingStatus,
    required this.onFurnishingStatusChanged,
    required this.selectedAmenities,
    required this.onAmenitiesChanged,
    required this.medias,
    required this.onMediasChanged,
  });

  @override
  State<StepPropertyDetailsWidget> createState() => _StepPropertyDetailsWidgetState();
}

class AmenityItem {
  final String name;
  final IconData icon;

  const AmenityItem(this.name, this.icon);
}

class _StepPropertyDetailsWidgetState extends State<StepPropertyDetailsWidget> {
  static final List<AmenityItem> availableAmenities = PropertyAmenityHelper.availableAmenityNames
      .map((name) => AmenityItem(name, PropertyAmenityHelper.getIcon(name)))
      .toList();

  @override
  Widget build(BuildContext context) {
    final isMobile = context.isMobile;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. MEDIA ATTACHMENTS (PHOTOS & VIDEOS - MEESHO STYLE PICKERS)
        _buildSectionHeader(
          context,
          title: context.tr('section_media'),
          dialogTitle: context.tr('section_media'),
          dialogDesc: 'Upload property photos (Max 6) and walkthrough videos (Max 2).',
          examples: const [
            'Photos: Select up to 6 high quality property images.',
            'Videos: Select up to 2 property walkthrough videos.',
          ],
        ),
        const SizedBox(height: 16.0),

        AppSquareMediaPicker(medias: widget.medias, onMediasChanged: widget.onMediasChanged),
        const SizedBox(height: 42.0),

        // 2. BASIC DETAILS & PRICING
        _buildSectionHeader(
          context,
          title: context.tr('section_basic_info'),
          dialogTitle: context.tr('section_basic_info'),
          dialogDesc:
              'Enter a clear, descriptive property title and price in INR (₹). A descriptive title includes BHK count, project name, and area landmark.',
          examples: const [
            '3 BHK Sun Empress Luxury Apartment in Bhatar',
            '4 BHK Independent Lawn Villa in Vesu',
          ],
        ),
        const SizedBox(height: 12.0),

        AppTextField(
          controller: widget.titleController,
          label: '${context.tr('property_title_label')} *',
          hint: context.tr('property_title_hint'),
          prefixIcon: const Icon(Icons.home_outlined),
        ),
        const SizedBox(height: 14.0),

        AppTextField(
          controller: widget.descriptionController,
          label: context.tr('property_desc_label'),
          hint: context.tr('property_desc_hint'),
          maxLines: 3,
        ),
        const SizedBox(height: 14.0),

        if (isMobile) ...[
          AppTextField(
            controller: widget.priceController,
            label: '${context.tr('price_label')} *',
            hint: context.tr('price_hint'),
            keyboardType: TextInputType.number,
            prefixIcon: const Icon(Icons.currency_rupee_rounded),
          ),
          const SizedBox(height: 14.0),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 3,
                child: AppTextField(
                  controller: widget.areaController,
                  label: '${context.tr('super_area_label')} *',
                  hint: context.tr('area_hint'),
                  keyboardType: TextInputType.number,
                  prefixIcon: const Icon(Icons.square_foot_rounded),
                ),
              ),
              const SizedBox(width: 12.0),
              Expanded(
                flex: 2,
                child: AppDropdown<String>(
                  label: context.tr('area_unit'),
                  value: widget.areaUnit.displayName,
                  items: AreaUnit.values
                      .where((u) => u != AreaUnit.unknown)
                      .map(
                        (u) => DropdownMenuItem(
                          value: u.displayName,
                          child: Text(
                            PropertyLocalizer.getLocalizedAreaUnit(context, u),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (val) {
                    if (val != null) {
                      widget.onAreaUnitChanged(AreaUnit.values.firstWhere((u) => u.displayName == val));
                    }
                  },
                ),
              ),
            ],
          ),
        ] else ...[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 3,
                child: AppTextField(
                  controller: widget.priceController,
                  label: '${context.tr('price_label')} *',
                  hint: context.tr('price_hint'),
                  keyboardType: TextInputType.number,
                  prefixIcon: const Icon(Icons.currency_rupee_rounded),
                ),
              ),
              const SizedBox(width: 12.0),
              Expanded(
                flex: 3,
                child: AppTextField(
                  controller: widget.areaController,
                  label: '${context.tr('super_area_label')} *',
                  hint: context.tr('area_hint'),
                  keyboardType: TextInputType.number,
                  prefixIcon: const Icon(Icons.square_foot_rounded),
                ),
              ),
              const SizedBox(width: 12.0),
              Expanded(
                flex: 2,
                child: AppDropdown<String>(
                  label: context.tr('area_unit'),
                  value: widget.areaUnit.displayName,
                  items: AreaUnit.values
                      .where((u) => u != AreaUnit.unknown)
                      .map(
                        (u) => DropdownMenuItem(
                          value: u.displayName,
                          child: Text(
                            PropertyLocalizer.getLocalizedAreaUnit(context, u),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (val) {
                    if (val != null) {
                      widget.onAreaUnitChanged(AreaUnit.values.firstWhere((u) => u.displayName == val));
                    }
                  },
                ),
              ),
            ],
          ),
        ],
        const SizedBox(height: 42.0),

        // 3. LISTING TYPE & CONSTRUCTION STATUS
        _buildSectionHeader(
          context,
          title: context.tr('section_listing_purpose'),
          dialogTitle: context.tr('section_listing_purpose'),
          dialogDesc:
              'Specify whether this property is available for Sale, Rent, or Lease, along with its current completion status.',
          examples: const [
            'Sale: Property for full purchase.',
            'Rent: Monthly rental listing.',
            'Ready to Move: Fully constructed & ready for occupancy.',
          ],
        ),
        const SizedBox(height: 16.0),

        if (isMobile) ...[
          AppDropdown<String>(
            label: context.tr('listing_type'),
            hint: 'Select Listing Type',
            value: widget.listingType.displayName,
            prefixIcon: const Icon(Icons.sell_outlined, size: 20.0),
            items: ['Sale', 'Rent', 'Lease'].map((type) {
              return DropdownMenuItem<String>(
                value: type,
                child: Text(PropertyLocalizer.getLocalizedListingType(context, type)),
              );
            }).toList(),
            onChanged: (val) {
              if (val != null) {
                widget.onListingTypeChanged(ListingType.values.firstWhere((u) => u.displayName == val));
              }
            },
          ),
          const SizedBox(height: 14.0),
          AppDropdown<String>(
            label: context.tr('construction_status'),
            hint: 'Select Status',
            value: widget.constructionStatus.displayName,
            prefixIcon: const Icon(Icons.construction_rounded, size: 20.0),
            items: ['Ready to Move', 'Under Construction', 'New Launch'].map((st) {
              return DropdownMenuItem<String>(
                value: st,
                child: Text(PropertyLocalizer.getLocalizedConstructionStatus(context, st)),
              );
            }).toList(),
            onChanged: (val) {
              if (val != null) {
                widget.onConstructionStatusChanged(
                  ConstructionStatus.values.firstWhere((u) => u.displayName == val),
                );
              }
            },
          ),
        ] else ...[
          Row(
            children: [
              Expanded(
                child: AppDropdown<String>(
                  label: context.tr('listing_type'),
                  hint: 'Select Listing Type',
                  value: widget.listingType.displayName,
                  prefixIcon: const Icon(Icons.sell_outlined, size: 20.0),
                  items: ['Sale', 'Rent', 'Lease'].map((type) {
                    return DropdownMenuItem<String>(
                      value: type,
                      child: Text(PropertyLocalizer.getLocalizedListingType(context, type)),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      widget.onListingTypeChanged(ListingType.values.firstWhere((u) => u.displayName == val));
                    }
                  },
                ),
              ),
              const SizedBox(width: 12.0),
              Expanded(
                child: AppDropdown<String>(
                  label: context.tr('construction_status'),
                  hint: 'Select Status',
                  value: widget.constructionStatus.displayName,
                  prefixIcon: const Icon(Icons.construction_rounded, size: 20.0),
                  items: ['Ready to Move', 'Under Construction', 'New Launch'].map((st) {
                    return DropdownMenuItem<String>(
                      value: st,
                      child: Text(PropertyLocalizer.getLocalizedConstructionStatus(context, st)),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      widget.onConstructionStatusChanged(
                        ConstructionStatus.values.firstWhere((u) => u.displayName == val),
                      );
                    }
                  },
                ),
              ),
            ],
          ),
        ],
        const SizedBox(height: 42.0),

        // 3. ROOM SPECIFICATIONS
        _buildSectionHeader(
          context,
          title: context.tr('section_room_specs'),
          dialogTitle: context.tr('section_room_specs'),
          dialogDesc:
              'Select bedroom, bathroom, balcony, parking counts, floor details, and Vastu facing direction.',
          examples: const ['Bedrooms: 3', 'Bathrooms: 3', 'Facing: East / North-East'],
        ),
        const SizedBox(height: 12.0),

        if (isMobile) ...[
          Row(
            children: [
              Expanded(
                child: _buildSpecCounterCard(
                  context: context,
                  title: context.tr('bedrooms_label'),
                  assetPath: 'assets/images/property/bedroom.png',
                  count: widget.bedrooms,
                  onChanged: widget.onBedroomsChanged,
                ),
              ),
              const SizedBox(width: 12.0),
              Expanded(
                child: _buildSpecCounterCard(
                  context: context,
                  title: context.tr('bathrooms_label'),
                  assetPath: 'assets/images/property/bathroom.png',
                  count: widget.bathrooms,
                  onChanged: widget.onBathroomsChanged,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12.0),
          Row(
            children: [
              Expanded(
                child: _buildSpecCounterCard(
                  context: context,
                  title: context.tr('balconies_label'),
                  assetPath: 'assets/images/property/balcony.png',
                  count: widget.balconies,
                  onChanged: widget.onBalconiesChanged,
                ),
              ),
              const SizedBox(width: 12.0),
              Expanded(
                child: _buildSpecCounterCard(
                  context: context,
                  title: context.tr('parking_label'),
                  assetPath: 'assets/images/property/parking.png',
                  count: widget.parking,
                  onChanged: widget.onParkingChanged,
                ),
              ),
            ],
          ),
        ] else ...[
          Row(
            children: [
              Expanded(
                child: _buildSpecCounterCard(
                  context: context,
                  title: context.tr('bedrooms_label'),
                  assetPath: 'assets/images/property/bedroom.png',
                  count: widget.bedrooms,
                  onChanged: widget.onBedroomsChanged,
                ),
              ),
              const SizedBox(width: 12.0),
              Expanded(
                child: _buildSpecCounterCard(
                  context: context,
                  title: context.tr('bathrooms_label'),
                  assetPath: 'assets/images/property/bathroom.png',
                  count: widget.bathrooms,
                  onChanged: widget.onBathroomsChanged,
                ),
              ),
              const SizedBox(width: 12.0),
              Expanded(
                child: _buildSpecCounterCard(
                  context: context,
                  title: context.tr('balconies_label'),
                  assetPath: 'assets/images/property/balcony.png',
                  count: widget.balconies,
                  onChanged: widget.onBalconiesChanged,
                ),
              ),
              const SizedBox(width: 12.0),
              Expanded(
                child: _buildSpecCounterCard(
                  context: context,
                  title: context.tr('parking_label'),
                  assetPath: 'assets/images/property/parking.png',
                  count: widget.parking,
                  onChanged: widget.onParkingChanged,
                ),
              ),
            ],
          ),
        ],
        const SizedBox(height: 14.0),

        if (isMobile) ...[
          Row(
            children: [
              Expanded(
                child: AppTextField(
                  controller: widget.floorNumberController,
                  label: context.tr('floor_number_label'),
                  hint: 'e.g. 5',
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(width: 12.0),
              Expanded(
                child: AppTextField(
                  controller: widget.totalFloorsController,
                  label: context.tr('total_floors_label'),
                  hint: 'e.g. 14',
                  keyboardType: TextInputType.number,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14.0),
          AppDropdown<String>(
            label: context.tr('facing_label'),
            hint: context.tr('facing_label'),
            value: widget.facing?.displayName,
            prefixIcon: const Icon(Icons.explore_outlined, size: 20.0),
            items: FacingDirection.values
                .where((f) => f != FacingDirection.unknown)
                .map(
                  (f) => DropdownMenuItem(
                    value: f.displayName,
                    child: Text(PropertyLocalizer.getLocalizedFacing(context, f)),
                  ),
                )
                .toList(),
            onChanged: (val) {
              if (val != null) {
                widget.onFacingChanged(FacingDirection.values.firstWhere((f) => f.displayName == val));
              }
            },
          ),
        ] else ...[
          Row(
            children: [
              Expanded(
                child: AppTextField(
                  controller: widget.floorNumberController,
                  label: context.tr('floor_number_label'),
                  hint: 'e.g. 5',
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(width: 12.0),
              Expanded(
                child: AppTextField(
                  controller: widget.totalFloorsController,
                  label: context.tr('total_floors_label'),
                  hint: 'e.g. 14',
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(width: 12.0),
              Expanded(
                child: AppDropdown<String>(
                  label: context.tr('facing_label'),
                  hint: context.tr('facing_label'),
                  value: widget.facing?.displayName,
                  prefixIcon: const Icon(Icons.explore_outlined, size: 20.0),
                  items: FacingDirection.values
                      .where((f) => f != FacingDirection.unknown)
                      .map(
                        (f) => DropdownMenuItem(
                          value: f.displayName,
                          child: Text(PropertyLocalizer.getLocalizedFacing(context, f)),
                        ),
                      )
                      .toList(),
                  onChanged: (val) {
                    if (val != null) {
                      widget.onFacingChanged(FacingDirection.values.firstWhere((f) => f.displayName == val));
                    }
                  },
                ),
              ),
            ],
          ),
        ],
        const SizedBox(height: 42.0),

        // 4. FURNISHING STATUS (VISUAL SELECTION CARDS)
        _buildSectionHeader(
          context,
          title: context.tr('section_furnishing'),
          dialogTitle: context.tr('section_furnishing'),
          dialogDesc:
              'Select furnishing level with visual room previews to help buyers understand included furniture & fittings.',
          examples: const [
            'Fully Furnished: Includes sofa, TV, beds, AC, wardrobes.',
            'Semi-Furnished: Fitted kitchen cabinets, lights, fans.',
            'Unfurnished: Empty bare room structure.',
          ],
        ),
        const SizedBox(height: 12.0),

        LayoutBuilder(
          builder: (context, constraints) {
            final isMobile = constraints.maxWidth < 550;
            if (isMobile) {
              return Column(
                children: [
                  _buildFurnishingCardMobile(
                    context,
                    'Fully Furnished',
                    'assets/images/property/fully_furnished.png',
                    'Includes sofa, beds, AC & wardrobes',
                  ),
                  const SizedBox(height: 10.0),
                  _buildFurnishingCardMobile(
                    context,
                    'Semi-Furnished',
                    'assets/images/property/semi_furnished.png',
                    'Fitted cabinets, lights & fans',
                  ),
                  const SizedBox(height: 10.0),
                  _buildFurnishingCardMobile(
                    context,
                    'Unfurnished',
                    'assets/images/property/unfurnished.png',
                    'Bare room structure without furniture',
                  ),
                ],
              );
            }
            return Row(
              children: [
                _buildFurnishingCard(
                  context,
                  'Fully Furnished',
                  'assets/images/property/fully_furnished.png',
                ),
                const SizedBox(width: 12.0),
                _buildFurnishingCard(context, 'Semi-Furnished', 'assets/images/property/semi_furnished.png'),
                const SizedBox(width: 12.0),
                _buildFurnishingCard(context, 'Unfurnished', 'assets/images/property/unfurnished.png'),
              ],
            );
          },
        ),
        const SizedBox(height: 42.0),

        // 5. AMENITIES SELECTION
        _buildSectionHeader(
          context,
          title: context.tr('section_amenities'),
          dialogTitle: context.tr('section_amenities'),
          dialogDesc: 'Check all available building and apartment amenities for buyer filtering.',
        ),
        const SizedBox(height: 12.0),

        Wrap(
          spacing: 8.0,
          runSpacing: 8.0,
          children: availableAmenities.map((amenity) {
            final isSel = widget.selectedAmenities.contains(amenity.name);

            return MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                onTap: () {
                  final updated = List<String>.from(widget.selectedAmenities);
                  if (isSel) {
                    updated.remove(amenity.name);
                  } else {
                    updated.add(amenity.name);
                  }
                  widget.onAmenitiesChanged(updated);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 6.0),
                  decoration: BoxDecoration(
                    color: isSel ? AppColors.primary : AppColors.surface,
                    borderRadius: BorderRadius.circular(8.0),
                    border: Border.all(color: isSel ? AppColors.primary : AppColors.border, width: 1.0),
                    boxShadow: isSel
                        ? [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.25),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.02),
                              blurRadius: 3,
                              offset: const Offset(0, 1),
                            ),
                          ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(4.0),
                        decoration: BoxDecoration(
                          color: isSel
                              ? Colors.white.withValues(alpha: 0.2)
                              : AppColors.primary.withValues(alpha: 0.08),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          amenity.icon,
                          size: 14.0,
                          color: isSel ? Colors.white : AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 6.0),
                      Text(
                        PropertyLocalizer.getLocalizedAmenity(context, amenity.name),
                        style: AppTextStyles.body2.copyWith(
                          fontWeight: FontWeight.w600,
                          color: isSel ? Colors.white : AppColors.textPrimary,
                          fontSize: 12.0,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 32.0),
      ],
    );
  }

  Widget _buildSectionHeader(
    BuildContext context, {
    required String title,
    required String dialogTitle,
    required String dialogDesc,
    List<String> examples = const [],
  }) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: AppTextStyles.heading3.copyWith(fontWeight: FontWeight.bold, color: AppColors.textPrimary),
          ),
        ),
        const SizedBox(width: 8.0),
        MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            onTap: () {
              FieldInfoDialog.show(context, title: dialogTitle, description: dialogDesc, examples: examples);
            },
            child: const Icon(Icons.info_outline_rounded, color: AppColors.primary, size: 18.0),
          ),
        ),
      ],
    );
  }

  Widget _buildSpecCounterCard({
    required BuildContext context,
    required String title,
    required String assetPath,
    required int count,
    required ValueChanged<int> onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14.0),
        border: Border.all(color: AppColors.border, width: 1.0),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 8, offset: const Offset(0, 3)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Visual Image Thumbnail
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(13.0)),
            child: SizedBox(
              height: 72.0,
              child: Image.asset(
                assetPath,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  color: AppColors.surfaceLight,
                  child: const Icon(Icons.broken_image_outlined, color: AppColors.textMuted),
                ),
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 8.0),
            child: Column(
              children: [
                // Label
                Text(
                  title,
                  style: AppTextStyles.caption.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                    fontSize: 12.0,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8.0),

                // Counter Buttons
                Container(
                  height: 36.0,
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(8.0),
                    border: Border.all(color: AppColors.border, width: 1.0),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Minus Button
                      IconButton(
                        onPressed: count > 0 ? () => onChanged(count - 1) : null,
                        icon: const Icon(Icons.remove_rounded, size: 14.0),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        style: IconButton.styleFrom(
                          minimumSize: const Size(28.0, 28.0),
                          padding: EdgeInsets.zero,
                        ),
                      ),

                      // Value text
                      Text(
                        '$count',
                        style: AppTextStyles.body2.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),

                      // Plus Button
                      IconButton(
                        onPressed: () => onChanged(count + 1),
                        icon: const Icon(Icons.add_rounded, size: 14.0),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        style: IconButton.styleFrom(
                          minimumSize: const Size(28.0, 28.0),
                          padding: EdgeInsets.zero,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFurnishingCard(BuildContext context, String status, String assetPath) {
    final localizedStatus = PropertyLocalizer.getLocalizedFurnishingStatus(context, status);
    final isSelected = widget.furnishingStatus.displayName.toLowerCase() == status.toLowerCase();

    return Expanded(
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: () => widget.onFurnishingStatusChanged(
            FurnishingStatus.values.firstWhere((f) => f.displayName.toLowerCase() == status.toLowerCase()),
          ),
          child: Container(
            height: 130.0,
            decoration: BoxDecoration(
              color: isSelected ? AppColors.primary.withValues(alpha: 0.05) : AppColors.surface,
              borderRadius: BorderRadius.circular(12.0),
              border: Border.all(
                color: isSelected ? AppColors.primary : AppColors.border,
                width: isSelected ? 2.5 : 1.0,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(11.0),
              child: Column(
                children: [
                  Expanded(
                    child: Image.asset(
                      assetPath,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      errorBuilder: (context, error, stackTrace) => Container(
                        color: AppColors.background,
                        child: const Icon(Icons.chair, color: AppColors.textMuted),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
                    child: Text(
                      localizedStatus,
                      style: AppTextStyles.caption.copyWith(
                        fontWeight: FontWeight.bold,
                        color: isSelected ? AppColors.primary : AppColors.textPrimary,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFurnishingCardMobile(BuildContext context, String status, String assetPath, String subtitle) {
    final localizedStatus = PropertyLocalizer.getLocalizedFurnishingStatus(context, status);
    final isSelected = widget.furnishingStatus.displayName.toLowerCase() == status.toLowerCase();

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => widget.onFurnishingStatusChanged(
          FurnishingStatus.values.firstWhere((f) => f.displayName.toLowerCase() == status.toLowerCase()),
        ),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: 80.0,
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary.withValues(alpha: 0.05) : AppColors.surface,
            borderRadius: BorderRadius.circular(14.0),
            border: Border.all(
              color: isSelected ? AppColors.primary : AppColors.border,
              width: isSelected ? 2.0 : 1.0,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.15),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ]
                : [],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(13.0),
            child: Row(
              children: [
                // Left Image Thumbnail
                SizedBox(
                  width: 110.0,
                  height: double.infinity,
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: Image.asset(
                          assetPath,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Container(
                            color: AppColors.background,
                            child: const Icon(Icons.chair, color: AppColors.textMuted),
                          ),
                        ),
                      ),
                      if (isSelected)
                        Positioned(
                          top: 8,
                          left: 8,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                            child: const Icon(Icons.check_rounded, color: Colors.white, size: 14),
                          ),
                        ),
                    ],
                  ),
                ),
                // Right Details
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          localizedStatus,
                          style: AppTextStyles.body1.copyWith(
                            fontWeight: FontWeight.bold,
                            color: isSelected ? AppColors.primary : AppColors.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4.0),
                        Text(
                          subtitle,
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.textSecondary,
                            fontSize: 11.5,
                          ),
                          maxLines: 1,
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
  }
}
