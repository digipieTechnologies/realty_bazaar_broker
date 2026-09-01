// File: lib/models/property_filter_model.dart
// Purpose: Filter and sorting model for the web properties directory and interactive filter popup modal.

import 'property_enums.dart';
import 'property_model.dart';

class PropertyFilterModel {
  final String searchKeyword;
  final String purpose; // 'all', 'sale', 'rent'
  final String city; // 'all' or specific city name
  final String propertyType; // 'all' or 'apartment', 'villa', 'row_house', 'penthouse', 'plot', 'commercial'
  final int? bedrooms; // null (Any), 1, 2, 3, 4 (4+)
  final String budgetRange; // 'any', 'under_50l', '50l_1cr', '1cr_2cr', '2cr_5cr', '5cr_plus'
  final String furnishing; // 'all', 'unfurnished', 'semi_furnished', 'fully_furnished'
  final bool verifiedOnly;
  final bool featuredOnly;
  final String sortOption; // 'price_asc', 'price_desc', 'newest', 'oldest'

  const PropertyFilterModel({
    this.searchKeyword = '',
    this.purpose = 'all',
    this.city = 'all',
    this.propertyType = 'all',
    this.bedrooms,
    this.budgetRange = 'any',
    this.furnishing = 'all',
    this.verifiedOnly = false,
    this.featuredOnly = false,
    this.sortOption = 'price_asc',
  });

  PropertyFilterModel copyWith({
    String? searchKeyword,
    String? purpose,
    String? city,
    String? propertyType,
    int? Function()? bedrooms,
    String? budgetRange,
    String? furnishing,
    bool? verifiedOnly,
    bool? featuredOnly,
    String? sortOption,
  }) {
    return PropertyFilterModel(
      searchKeyword: searchKeyword ?? this.searchKeyword,
      purpose: purpose ?? this.purpose,
      city: city ?? this.city,
      propertyType: propertyType ?? this.propertyType,
      bedrooms: bedrooms != null ? bedrooms() : this.bedrooms,
      budgetRange: budgetRange ?? this.budgetRange,
      furnishing: furnishing ?? this.furnishing,
      verifiedOnly: verifiedOnly ?? this.verifiedOnly,
      featuredOnly: featuredOnly ?? this.featuredOnly,
      sortOption: sortOption ?? this.sortOption,
    );
  }

  bool get hasActiveFilters {
    return (searchKeyword.trim().isNotEmpty) ||
        (purpose != 'all') ||
        (city != 'all') ||
        (propertyType != 'all') ||
        (bedrooms != null) ||
        (budgetRange != 'any') ||
        (furnishing != 'all') ||
        verifiedOnly ||
        featuredOnly;
  }

  int get activeFilterCount {
    int count = 0;
    if (searchKeyword.trim().isNotEmpty) count++;
    if (purpose != 'all') count++;
    if (city != 'all') count++;
    if (propertyType != 'all') count++;
    if (bedrooms != null) count++;
    if (budgetRange != 'any') count++;
    if (furnishing != 'all') count++;
    if (verifiedOnly) count++;
    if (featuredOnly) count++;
    return count;
  }

  /// Evaluates whether a [PropertyModel] matches this filter configuration.
  bool matches(PropertyModel property) {
    // 1. Keyword search (title, description, full address, city, state, code)
    if (searchKeyword.trim().isNotEmpty) {
      final query = searchKeyword.trim().toLowerCase();
      final title = property.propertyTitle.toLowerCase();
      final desc = property.propertyDescription?.toLowerCase() ?? '';
      final addr = property.address;
      final city = addr?.city?.toLowerCase() ?? '';
      final address = addr?.fullAddress.toLowerCase() ?? '';
      final state = addr?.state?.toLowerCase() ?? '';
      final code = property.propertyCode?.toLowerCase() ?? '';

      final matchesKeyword = title.contains(query) ||
          desc.contains(query) ||
          city.contains(query) ||
          address.contains(query) ||
          state.contains(query) ||
          code.contains(query);

      if (!matchesKeyword) return false;
    }

    // 2. Purpose (Sale / Rent)
    if (purpose != 'all') {
      if (purpose == 'sale' && property.listingType != ListingType.sale) {
        return false;
      }
      if (purpose == 'rent' && property.listingType != ListingType.rent) {
        return false;
      }
    }

    // 3. City
    if (city != 'all') {
      final propCity = property.address?.city?.trim().toLowerCase() ?? '';
      if (!propCity.contains(city.trim().toLowerCase())) {
        return false;
      }
    }

    // 4. Property Type
    if (propertyType != 'all') {
      final targetType = propertyType.asPropertyType;
      if (targetType != PropertyType.unknown && property.propertyType != targetType) {
        return false;
      }
    }

    // 5. Bedrooms
    if (bedrooms != null) {
      if (bedrooms == 4) {
        if (property.bedrooms < 4) return false;
      } else {
        if (property.bedrooms != bedrooms) return false;
      }
    }

    // 6. Budget Range
    if (budgetRange != 'any') {
      final price = property.price;
      switch (budgetRange) {
        case 'under_50l':
          if (price >= 5000000) return false;
          break;
        case '50l_1cr':
          if (price < 5000000 || price > 10000000) return false;
          break;
        case '1cr_2cr':
          if (price < 10000000 || price > 20000000) return false;
          break;
        case '2cr_5cr':
          if (price < 20000000 || price > 50000000) return false;
          break;
        case '5cr_plus':
          if (price < 50000000) return false;
          break;
      }
    }

    // 7. Furnishing
    if (furnishing != 'all') {
      final targetFurnishing = furnishing.asFurnishingStatus;
      if (targetFurnishing != FurnishingStatus.unknown &&
          property.furnishingStatus != targetFurnishing) {
        return false;
      }
    }

    return true;
  }

  /// Filters and sorts a list of properties according to this configuration.
  List<PropertyModel> applyTo(List<PropertyModel> source) {
    final filtered = source.where(matches).toList();

    switch (sortOption) {
      case 'price_asc':
        filtered.sort((a, b) => a.price.compareTo(b.price));
        break;
      case 'price_desc':
        filtered.sort((a, b) => b.price.compareTo(a.price));
        break;
      case 'newest':
        filtered.sort((a, b) {
          final aDate = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
          final bDate = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
          return bDate.compareTo(aDate);
        });
        break;
      case 'oldest':
        filtered.sort((a, b) {
          final aDate = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
          final bDate = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
          return aDate.compareTo(bDate);
        });
        break;
      default:
        break;
    }

    return filtered;
  }
}
