// File: lib/modules/properties/widgets/web/property_web_grid_card.dart
// Purpose: High-fidelity Web Property Grid Card matching therealtybazaar.com design.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../app/app_colors.dart';
import '../../../../app/app_routes.dart';
import '../../../../app/app_text_styles.dart';
import '../../../../core/localization/property_localizer.dart';
import '../../../../models/property_enums.dart';
import '../../../../models/property_model.dart';
import '../../../../widgets/common/app_card_container.dart';
import '../../../../widgets/common/currency_text.dart';
import '../../../../widgets/images/cached_image.dart';
import '../../../../widgets/toast/app_toast.dart';
import '../../screens/add_edit_property_screen.dart';

class PropertyWebGridCard extends StatelessWidget {
  final PropertyModel property;
  final VoidCallback? onEditTap;

  const PropertyWebGridCard({
    super.key,
    required this.property,
    this.onEditTap,
  });

  void _handleCardTap(BuildContext context) {
    AppRoutes.navigateToPropertyDetails(context, property);
  }

  void _handleShare(BuildContext context) {
    final identifier = property.propertyCode?.isNotEmpty == true
        ? property.propertyCode!
        : (property.id ?? '');
    final url = 'https://therealtybazaar.com/properties/$identifier';
    Clipboard.setData(ClipboardData(text: url));
    AppToast.showSuccess('Property link copied to clipboard!');
  }

  void _openEditScreen(BuildContext context) {
    if (onEditTap != null) {
      onEditTap!();
    } else {
      Navigator.of(context, rootNavigator: true).push(
        MaterialPageRoute(
          builder: (context) => AddEditPropertyScreen(propertyToEdit: property),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final imageUrl = property.medias.isNotEmpty ? property.medias.first.url : null;
    final addressText = property.address?.fullAddress ??
        '${property.address?.city ?? "Surat"}, ${property.address?.state ?? "Gujarat"}';
    final listingLabel = property.listingType == ListingType.rent ? 'For Rent' : 'For Sale';
    final typeName = PropertyLocalizer.getLocalizedPropertyType(context, property.propertyType);

    // Calculate sqft rate
    final double areaValue = property.area > 0 ? property.area : 1;
    final double ratePerUnit = property.price / areaValue;
    final String unitLabel = property.areaUnit == AreaUnit.sqyd
        ? 'sq yd'
        : (property.areaUnit == AreaUnit.sqm ? 'sq m' : 'sq ft');

    return AppCardContainer(
      borderRadius: 18.0,
      padding: EdgeInsets.zero,
      onTap: () => _handleCardTap(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // -------------------------------------------------------------------
          // 1. TOP MEDIA SECTION
          // -------------------------------------------------------------------
          Stack(
            children: [
              // Property Image
              CachedImage(
                imageUrl,
                height: 190.0,
                width: double.infinity,
                fit: BoxFit.cover,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(18.0)),
              ),

              // Top-Left Badge: "For Sale" / "For Rent"
              Positioned(
                top: 12.0,
                left: 12.0,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 5.0),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.95),
                    borderRadius: BorderRadius.circular(20.0),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 8.0,
                        offset: const Offset(0, 2.0),
                      ),
                    ],
                  ),
                  child: Text(
                    listingLabel,
                    style: const TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ),

              // Top-Right Action Buttons: Share & Edit/Options
              Positioned(
                top: 12.0,
                right: 12.0,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Share Button
                    _buildCircleActionButton(
                      icon: Icons.share_outlined,
                      tooltip: 'Share Property',
                      onPressed: () => _handleShare(context),
                    ),
                    const SizedBox(width: 6.0),
                    // Edit/Manage Menu Button
                    _buildCircleActionButton(
                      icon: Icons.edit_outlined,
                      tooltip: 'Edit Property',
                      onPressed: () => _openEditScreen(context),
                    ),
                  ],
                ),
              ),

              // Bottom-Left Overlay Pill: Property Type (e.g. Row_house, Apartment, Villa)
              Positioned(
                bottom: 10.0,
                left: 12.0,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(6.0),
                  ),
                  child: Text(
                    typeName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11.0,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
              ),

              // Bottom-Right Photo Counter Badge
              if (property.medias.isNotEmpty)
                Positioned(
                  bottom: 10.0,
                  right: 12.0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7.0, vertical: 3.5),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.65),
                      borderRadius: BorderRadius.circular(6.0),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.photo_camera_outlined, color: Colors.white, size: 11.5),
                        const SizedBox(width: 3.5),
                        Text(
                          '${property.medias.length}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),

          // -------------------------------------------------------------------
          // 2. CARD CONTENT SECTION (Auto-aligns height to content)
          // -------------------------------------------------------------------
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(14.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Upper Block: Price, Title, Location, Specs
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Price & Rate Row
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Expanded(
                            child: CurrencyText(
                              amount: property.price,
                              style: AppTextStyles.heading2.copyWith(
                                fontSize: 18.5,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                          Text(
                            '₹ ${ratePerUnit.toStringAsFixed(0)}/$unitLabel',
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.textMuted,
                              fontSize: 11.5,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6.0),

                      // Title
                      Text(
                        property.propertyTitle,
                        style: AppTextStyles.body1.copyWith(
                          fontWeight: FontWeight.w700,
                          fontSize: 14.0,
                          color: AppColors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4.0),

                      // Location / Address
                      Row(
                        children: [
                          const Icon(
                            Icons.location_on_rounded,
                            size: 14.0,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 4.0),
                          Expanded(
                            child: Text(
                              addressText,
                              style: AppTextStyles.caption.copyWith(
                                color: AppColors.textSecondary,
                                fontSize: 12.0,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10.0),

                      // Specs Container (Bedrooms, Bathrooms, Area)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 6.5),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(8.0),
                          border: Border.all(color: AppColors.border.withValues(alpha: 0.6), width: 1.0),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: _buildSpecsList(context, unitLabel),
                        ),
                      ),
                    ],
                  ),

                  // Bottom Block: Divider + Verified Broker & View Details Button
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Divider(height: 1.0, thickness: 1.0, color: AppColors.border),
                      const SizedBox(height: 10.0),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Verified Broker Badge
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.verified_rounded,
                                size: 15.0,
                                color: AppColors.primary,
                              ),
                              const SizedBox(width: 4.0),
                              Text(
                                'Verified Broker',
                                style: AppTextStyles.caption.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textSecondary,
                                  fontSize: 11.5,
                                ),
                              ),
                            ],
                          ),

                          // View Details Button with Arrow
                          InkWell(
                            onTap: () => _handleCardTap(context),
                            borderRadius: BorderRadius.circular(20.0),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 5.0),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(20.0),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'View Details',
                                    style: AppTextStyles.caption.copyWith(
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.primary,
                                      fontSize: 11.5,
                                    ),
                                  ),
                                  const SizedBox(width: 3.0),
                                  const Icon(
                                    Icons.north_east_rounded,
                                    size: 13.0,
                                    color: AppColors.primary,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Action Button on Top-Right of image
  Widget _buildCircleActionButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onPressed,
  }) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(16.0),
        child: Container(
          width: 32.0,
          height: 32.0,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.92),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.12),
                blurRadius: 6.0,
                offset: const Offset(0, 2.0),
              ),
            ],
          ),
          child: Icon(
            icon,
            size: 16.0,
            color: AppColors.textPrimary,
          ),
        ),
      ),
    );
  }

  // Specs Item Row (Bedrooms, Bathrooms, Area)
  List<Widget> _buildSpecsList(BuildContext context, String unitLabel) {
    final List<Widget> items = [];

    if (property.bedrooms > 0) {
      items.add(_buildSpecItem(Icons.bed_rounded, '${property.bedrooms} BHK'));
    }

    final int baths = property.bathrooms > 0
        ? property.bathrooms
        : (property.bedrooms > 0 ? property.bedrooms : 0);
    if (baths > 0) {
      items.add(_buildSpecItem(Icons.bathtub_outlined, '$baths Bath'));
    }

    if (property.area > 0) {
      items.add(_buildSpecItem(
        Icons.square_foot_rounded,
        '${property.area.toStringAsFixed(0)} $unitLabel',
      ));
    } else if (items.isEmpty) {
      items.add(_buildSpecItem(Icons.apartment_rounded, property.propertyType.displayName));
    }

    return items;
  }

  Widget _buildSpecItem(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14.0, color: AppColors.primary),
        const SizedBox(width: 4.0),
        Text(
          text,
          style: AppTextStyles.caption.copyWith(
            fontWeight: FontWeight.w600,
            fontSize: 11.5,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}
