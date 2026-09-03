/// Enum representing property types in the system.
enum PropertyType { apartment, villa, rowHouse, penthouse, commercial, plot, unknown }

extension PropertyTypeParser on String? {
  PropertyType get asPropertyType {
    switch (this?.toLowerCase().trim()) {
      case 'apartment':
      case 'flat':
        return PropertyType.apartment;
      case 'villa':
      case 'bungalow':
        return PropertyType.villa;
      case 'row_house':
      case 'rowhouse':
      case 'row house':
        return PropertyType.rowHouse;
      case 'penthouse':
        return PropertyType.penthouse;
      case 'commercial':
      case 'office':
      case 'shop':
        return PropertyType.commercial;
      case 'plot':
      case 'land':
      case 'industrial':
        return PropertyType.plot;
      default:
        return PropertyType.unknown;
    }
  }
}

extension PropertyTypeExtensions on PropertyType {
  bool get isApartment => this == PropertyType.apartment;

  bool get isVilla => this == PropertyType.villa;

  bool get isRowHouse => this == PropertyType.rowHouse;

  bool get isPenthouse => this == PropertyType.penthouse;

  bool get isCommercial => this == PropertyType.commercial;

  bool get isPlot => this == PropertyType.plot;

  String get displayName {
    switch (this) {
      case PropertyType.apartment:
        return 'Apartment';
      case PropertyType.villa:
        return 'Villa';
      case PropertyType.rowHouse:
        return 'Row House';
      case PropertyType.penthouse:
        return 'Penthouse';
      case PropertyType.commercial:
        return 'Commercial';
      case PropertyType.plot:
        return 'Plot';
      case PropertyType.unknown:
        return 'Unknown';
    }
  }

  String get apiValue {
    switch (this) {
      case PropertyType.apartment:
        return 'apartment';
      case PropertyType.villa:
        return 'villa';
      case PropertyType.rowHouse:
        return 'row_house';
      case PropertyType.penthouse:
        return 'penthouse';
      case PropertyType.commercial:
        return 'commercial';
      case PropertyType.plot:
        return 'plot';
      case PropertyType.unknown:
        return 'unknown';
    }
  }

  String? get apiValueForList => this == PropertyType.unknown ? null : apiValue;
}

/// Enum representing listing types in the system.
enum ListingType { sale, rent, lease, unknown }

extension ListingTypeParser on String? {
  ListingType get asListingType {
    switch (this?.toLowerCase().trim()) {
      case 'sale':
        return ListingType.sale;
      case 'rent':
        return ListingType.rent;
      case 'lease':
        return ListingType.lease;
      default:
        return ListingType.unknown;
    }
  }
}

extension ListingTypeExtensions on ListingType {
  bool get isSale => this == ListingType.sale;

  bool get isRent => this == ListingType.rent;

  bool get isLease => this == ListingType.lease;

  String get displayName {
    switch (this) {
      case ListingType.sale:
        return 'Sale';
      case ListingType.rent:
        return 'Rent';
      case ListingType.lease:
        return 'Lease';
      case ListingType.unknown:
        return 'Unknown';
    }
  }

  String get apiValue {
    switch (this) {
      case ListingType.sale:
        return 'sale';
      case ListingType.rent:
        return 'rent';
      case ListingType.lease:
        return 'lease';
      case ListingType.unknown:
        return 'unknown';
    }
  }

  String? get apiValueForList => this == ListingType.unknown ? null : apiValue;
}

/// Enum representing construction status.
enum ConstructionStatus { readyToMove, underConstruction, newLaunch, unknown }

extension ConstructionStatusParser on String? {
  ConstructionStatus get asConstructionStatus {
    switch (this?.toLowerCase().trim()) {
      case 'ready_to_move':
      case 'ready to move':
      case 'ready':
        return ConstructionStatus.readyToMove;
      case 'under_construction':
      case 'under construction':
      case 'under':
        return ConstructionStatus.underConstruction;
      case 'new_launch':
      case 'new launch':
      case 'new':
        return ConstructionStatus.newLaunch;
      default:
        return ConstructionStatus.unknown;
    }
  }
}

extension ConstructionStatusExtensions on ConstructionStatus {
  bool get isReadyToMove => this == ConstructionStatus.readyToMove;

  bool get isUnderConstruction => this == ConstructionStatus.underConstruction;

  bool get isNewLaunch => this == ConstructionStatus.newLaunch;

  String get displayName {
    switch (this) {
      case ConstructionStatus.readyToMove:
        return 'Ready to Move';
      case ConstructionStatus.underConstruction:
        return 'Under Construction';
      case ConstructionStatus.newLaunch:
        return 'New Launch';
      case ConstructionStatus.unknown:
        return 'Unknown';
    }
  }

  String get apiValue {
    switch (this) {
      case ConstructionStatus.readyToMove:
        return 'ready_to_move';
      case ConstructionStatus.underConstruction:
        return 'under_construction';
      case ConstructionStatus.newLaunch:
        return 'new_launch';
      case ConstructionStatus.unknown:
        return 'unknown';
    }
  }

  String? get apiValueForList => this == ConstructionStatus.unknown ? null : apiValue;
}

/// Enum representing furnishing status.
enum FurnishingStatus { unfurnished, semiFurnished, fullyFurnished, unknown }

extension FurnishingStatusParser on String? {
  FurnishingStatus get asFurnishingStatus {
    switch (this?.toLowerCase().trim()) {
      case 'unfurnished':
        return FurnishingStatus.unfurnished;
      case 'semi_furnished':
      case 'semi-furnished':
      case 'semi furnished':
      case 'semi':
        return FurnishingStatus.semiFurnished;
      case 'fully_furnished':
      case 'fully-furnished':
      case 'fully furnished':
      case 'fully':
        return FurnishingStatus.fullyFurnished;
      default:
        return FurnishingStatus.unknown;
    }
  }
}

extension FurnishingStatusExtensions on FurnishingStatus {
  bool get isUnfurnished => this == FurnishingStatus.unfurnished;

  bool get isSemiFurnished => this == FurnishingStatus.semiFurnished;

  bool get isFullyFurnished => this == FurnishingStatus.fullyFurnished;

  String get displayName {
    switch (this) {
      case FurnishingStatus.unfurnished:
        return 'Unfurnished';
      case FurnishingStatus.semiFurnished:
        return 'Semi-Furnished';
      case FurnishingStatus.fullyFurnished:
        return 'Fully Furnished';
      case FurnishingStatus.unknown:
        return 'Unknown';
    }
  }

  String get apiValue {
    switch (this) {
      case FurnishingStatus.unfurnished:
        return 'unfurnished';
      case FurnishingStatus.semiFurnished:
        return 'semi_furnished';
      case FurnishingStatus.fullyFurnished:
        return 'fully_furnished';
      case FurnishingStatus.unknown:
        return 'unknown';
    }
  }

  String? get apiValueForList => this == FurnishingStatus.unknown ? null : apiValue;
}

/// Enum representing property status.
enum PropertyStatus { available, sold, rented, underOffer, unknown }

extension PropertyStatusParser on String? {
  PropertyStatus get asPropertyStatus {
    switch (this?.toLowerCase().trim()) {
      case 'available':
        return PropertyStatus.available;
      case 'sold':
        return PropertyStatus.sold;
      case 'rented':
        return PropertyStatus.rented;
      case 'under_offer':
      case 'under offer':
        return PropertyStatus.underOffer;
      default:
        return PropertyStatus.unknown;
    }
  }
}

extension PropertyStatusExtensions on PropertyStatus {
  bool get isAvailable => this == PropertyStatus.available;

  bool get isSold => this == PropertyStatus.sold;

  bool get isRented => this == PropertyStatus.rented;

  bool get isUnderOffer => this == PropertyStatus.underOffer;

  String get displayName {
    switch (this) {
      case PropertyStatus.available:
        return 'Available';
      case PropertyStatus.sold:
        return 'Sold';
      case PropertyStatus.rented:
        return 'Rented';
      case PropertyStatus.underOffer:
        return 'Under Offer';
      case PropertyStatus.unknown:
        return 'Unknown';
    }
  }

  String get apiValue {
    switch (this) {
      case PropertyStatus.available:
        return 'available';
      case PropertyStatus.sold:
        return 'sold';
      case PropertyStatus.rented:
        return 'rented';
      case PropertyStatus.underOffer:
        return 'under_offer';
      case PropertyStatus.unknown:
        return 'unknown';
    }
  }

  String? get apiValueForList => this == PropertyStatus.unknown ? null : apiValue;
}

/// Enum representing property facing directions.
enum FacingDirection { east, west, north, south, northEast, northWest, southEast, southWest, unknown }

extension FacingDirectionParser on String? {
  FacingDirection get asFacingDirection {
    switch (this?.toLowerCase().trim()) {
      case 'east':
        return FacingDirection.east;
      case 'west':
        return FacingDirection.west;
      case 'north':
        return FacingDirection.north;
      case 'south':
        return FacingDirection.south;
      case 'north_east':
      case 'north-east':
      case 'ne':
        return FacingDirection.northEast;
      case 'north_west':
      case 'north-west':
      case 'nw':
        return FacingDirection.northWest;
      case 'south_east':
      case 'south-east':
      case 'se':
        return FacingDirection.southEast;
      case 'south_west':
      case 'south-west':
      case 'sw':
        return FacingDirection.southWest;
      default:
        return FacingDirection.unknown;
    }
  }
}

extension FacingDirectionExtensions on FacingDirection {
  String get displayName {
    switch (this) {
      case FacingDirection.east:
        return 'East';
      case FacingDirection.west:
        return 'West';
      case FacingDirection.north:
        return 'North';
      case FacingDirection.south:
        return 'South';
      case FacingDirection.northEast:
        return 'North-East';
      case FacingDirection.northWest:
        return 'North-West';
      case FacingDirection.southEast:
        return 'South-East';
      case FacingDirection.southWest:
        return 'South-West';
      case FacingDirection.unknown:
        return 'Unknown';
    }
  }

  String get apiValue {
    switch (this) {
      case FacingDirection.east:
        return 'east';
      case FacingDirection.west:
        return 'west';
      case FacingDirection.north:
        return 'north';
      case FacingDirection.south:
        return 'south';
      case FacingDirection.northEast:
        return 'north_east';
      case FacingDirection.northWest:
        return 'north_west';
      case FacingDirection.southEast:
        return 'south_east';
      case FacingDirection.southWest:
        return 'south_west';
      case FacingDirection.unknown:
        return 'unknown';
    }
  }

  String? get apiValueForList => this == FacingDirection.unknown ? null : apiValue;
}

/// Enum representing area units.
enum AreaUnit { sqft, sqyd, sqm, acre, unknown }

extension AreaUnitParser on String? {
  AreaUnit get asAreaUnit {
    switch (this?.toLowerCase().trim()) {
      case 'sqft':
        return AreaUnit.sqft;
      case 'sqyd':
        return AreaUnit.sqyd;
      case 'sqm':
        return AreaUnit.sqm;
      case 'acre':
        return AreaUnit.acre;
      default:
        return AreaUnit.unknown;
    }
  }
}

extension AreaUnitExtensions on AreaUnit {
  String get displayName {
    switch (this) {
      case AreaUnit.sqft:
        return 'sqft';
      case AreaUnit.sqyd:
        return 'sqyd';
      case AreaUnit.sqm:
        return 'sqm';
      case AreaUnit.acre:
        return 'acre';
      case AreaUnit.unknown:
        return 'unknown';
    }
  }

  String get apiValue {
    switch (this) {
      case AreaUnit.sqft:
        return 'sqft';
      case AreaUnit.sqyd:
        return 'sqyd';
      case AreaUnit.sqm:
        return 'sqm';
      case AreaUnit.acre:
        return 'acre';
      case AreaUnit.unknown:
        return 'unknown';
    }
  }

  String? get apiValueForList => this == AreaUnit.unknown ? null : apiValue;
}
