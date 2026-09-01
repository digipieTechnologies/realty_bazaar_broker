// File: lib/core/localization/property_localizer.dart
// Purpose: Helper class for localizing property model values to user's preferred language using Property Enums or String fallback.

import 'package:flutter/material.dart';

import '../../models/property_enums.dart';
import 'app_localizations.dart';

class PropertyLocalizer {
  PropertyLocalizer._();

  /// Gets localized display text for Property Type
  static String getLocalizedPropertyType(BuildContext context, dynamic propertyTypeInput) {
    final PropertyType type = propertyTypeInput is PropertyType
        ? propertyTypeInput
        : (propertyTypeInput?.toString()).asPropertyType;

    switch (type) {
      case PropertyType.apartment:
        return context.tr('prop_type_flat');
      case PropertyType.villa:
        return context.tr('prop_type_villa');
      case PropertyType.rowHouse:
        return context.tr('prop_type_row_house');
      case PropertyType.penthouse:
        return context.tr('prop_type_penthouse');
      case PropertyType.commercial:
        return context.tr('prop_type_commercial');
      case PropertyType.plot:
        return context.tr('prop_type_plot');
      case PropertyType.unknown:
        return propertyTypeInput?.toString() ?? '';
    }
  }

  /// Gets localized display text for Listing Type
  static String getLocalizedListingType(BuildContext context, dynamic listingTypeInput) {
    final ListingType type = listingTypeInput is ListingType
        ? listingTypeInput
        : (listingTypeInput?.toString()).asListingType;

    switch (type) {
      case ListingType.sale:
        return context.tr('prop_listing_sale');
      case ListingType.rent:
        return context.tr('prop_listing_rent');
      case ListingType.lease:
        return context.tr('prop_listing_lease');
      case ListingType.unknown:
        return listingTypeInput?.toString() ?? '';
    }
  }

  /// Gets localized display text for Construction Status
  static String getLocalizedConstructionStatus(BuildContext context, dynamic statusInput) {
    final ConstructionStatus status = statusInput is ConstructionStatus
        ? statusInput
        : (statusInput?.toString()).asConstructionStatus;

    switch (status) {
      case ConstructionStatus.readyToMove:
        return context.tr('prop_const_ready');
      case ConstructionStatus.underConstruction:
        return context.tr('prop_const_under');
      case ConstructionStatus.newLaunch:
        return context.tr('prop_const_new');
      case ConstructionStatus.unknown:
        return statusInput?.toString() ?? '';
    }
  }

  /// Gets localized display text for Furnishing Status
  static String getLocalizedFurnishingStatus(BuildContext context, dynamic furnishingInput) {
    final FurnishingStatus status = furnishingInput is FurnishingStatus
        ? furnishingInput
        : (furnishingInput?.toString()).asFurnishingStatus;

    switch (status) {
      case FurnishingStatus.fullyFurnished:
        return context.tr('prop_furn_fully');
      case FurnishingStatus.semiFurnished:
        return context.tr('prop_furn_semi');
      case FurnishingStatus.unfurnished:
        return context.tr('prop_furn_unfurnished');
      case FurnishingStatus.unknown:
        return furnishingInput?.toString() ?? '';
    }
  }

  /// Gets localized display text for Facing Direction
  static String getLocalizedFacing(BuildContext context, dynamic facingInput) {
    final FacingDirection facing = facingInput is FacingDirection
        ? facingInput
        : (facingInput?.toString()).asFacingDirection;

    switch (facing) {
      case FacingDirection.east:
        return context.tr('prop_facing_east');
      case FacingDirection.west:
        return context.tr('prop_facing_west');
      case FacingDirection.north:
        return context.tr('prop_facing_north');
      case FacingDirection.south:
        return context.tr('prop_facing_south');
      case FacingDirection.northEast:
        return context.tr('prop_facing_ne');
      case FacingDirection.northWest:
        return context.tr('prop_facing_nw');
      case FacingDirection.southEast:
        return context.tr('prop_facing_se');
      case FacingDirection.southWest:
        return context.tr('prop_facing_sw');
      case FacingDirection.unknown:
        return facingInput?.toString() ?? '';
    }
  }

  /// Gets localized display text for Amenities
  static String getLocalizedAmenity(BuildContext context, String englishAmenity) {
    if (englishAmenity.isEmpty) return '';
    final lower = englishAmenity.trim().toLowerCase();
    if (lower.contains('pool')) return context.tr('amenity_pool');
    if (lower.contains('gym') || lower.contains('fitness')) return context.tr('amenity_gym');
    if (lower.contains('security') && !lower.contains('cctv')) return context.tr('amenity_security');
    if (lower.contains('garden')) return context.tr('amenity_garden');
    if (lower.contains('power') || lower.contains('backup')) return context.tr('amenity_power_backup');
    if (lower.contains('club')) return context.tr('amenity_clubhouse');
    if (lower.contains('elevator') || lower.contains('lift')) return context.tr('amenity_elevator');
    if (lower.contains('parking')) return context.tr('amenity_parking');
    if (lower.contains('cctv')) return context.tr('amenity_cctv');
    if (lower.contains('children') || lower.contains('play') || lower.contains('kids'))
      return context.tr('amenity_play_area');
    return englishAmenity;
  }

  /// Gets localized display text for Property Status
  static String getLocalizedPropertyStatus(BuildContext context, dynamic statusInput) {
    final PropertyStatus status = statusInput is PropertyStatus
        ? statusInput
        : (statusInput?.toString()).asPropertyStatus;

    switch (status) {
      case PropertyStatus.available:
        return context.tr('prop_status_available');
      case PropertyStatus.sold:
        return context.tr('prop_status_sold');
      case PropertyStatus.rented:
        return context.tr('prop_status_rented');
      case PropertyStatus.underOffer:
        return context.tr('prop_status_available');
      case PropertyStatus.unknown:
        return statusInput?.toString() ?? '';
    }
  }

  /// Gets localized display text for Area Unit
  static String getLocalizedAreaUnit(BuildContext context, dynamic unitInput) {
    final AreaUnit unit = unitInput is AreaUnit ? unitInput : (unitInput?.toString()).asAreaUnit;

    switch (unit) {
      case AreaUnit.sqft:
        return context.tr('unit_sqft');
      case AreaUnit.sqyd:
        return context.tr('unit_sqyd');
      case AreaUnit.sqm:
        return context.tr('unit_sqm');
      case AreaUnit.acre:
        return context.tr('unit_acre');
      case AreaUnit.unknown:
        return unitInput?.toString() ?? '';
    }
  }
}
