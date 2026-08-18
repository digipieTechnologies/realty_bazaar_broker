import 'package:equatable/equatable.dart';
import 'address_model.dart';
import 'broker_model.dart';
import 'media_model.dart';
import 'property_enums.dart';

class PropertyModel extends Equatable {
  static const String tableName = "properties";

  final String? id;
  final BrokerModel? brokerId;
  final AddressModel? addressId;
  final String propertyTitle;
  final String? propertyDescription;
  final PropertyType propertyType;
  final ListingType listingType;
  final double price;
  final double area;
  final AreaUnit areaUnit;
  final int bedrooms;
  final int bathrooms;
  final int balconies;
  final int parking;
  final int? floorNumber;
  final int? totalFloors;
  final FurnishingStatus furnishingStatus;
  final PropertyStatus propertyStatus;
  final ConstructionStatus constructionStatus;
  final FacingDirection? facing;
  final List<String> amenities;
  final List<MediaModel> medias;
  final bool isActive;
  final bool isDeleted;
  final DateTime? deletedAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  // Getter for address backward compatibility
  AddressModel? get address => addressId;

  const PropertyModel({
    this.id,
    this.brokerId,
    this.addressId,
    required this.propertyTitle,
    this.propertyDescription,
    this.propertyType = PropertyType.apartment,
    this.listingType = ListingType.sale,
    required this.price,
    required this.area,
    this.areaUnit = AreaUnit.sqft,
    this.bedrooms = 0,
    this.bathrooms = 0,
    this.balconies = 0,
    this.parking = 0,
    this.floorNumber,
    this.totalFloors,
    this.furnishingStatus = FurnishingStatus.unfurnished,
    this.propertyStatus = PropertyStatus.available,
    this.constructionStatus = ConstructionStatus.readyToMove,
    this.facing,
    this.amenities = const [],
    this.medias = const [],
    this.isActive = true,
    this.isDeleted = false,
    this.deletedAt,
    this.createdAt,
    this.updatedAt,
  });

  static PropertyModel fromJson(dynamic json) {
    if (json is! Map) {
      return PropertyModel(
        id: json?.toString(),
        propertyTitle: '',
        propertyType: PropertyType.apartment,
        listingType: ListingType.sale,
        price: 0,
        area: 0,
      );
    }

    List<String> parsedAmenities = [];
    if (json['amenities'] != null && json['amenities'] is List) {
      parsedAmenities = (json['amenities'] as List).map((e) => e.toString()).toList();
    }

    List<MediaModel> parsedMedias = [];
    if (json['medias'] != null && json['medias'] is List) {
      parsedMedias = (json['medias'] as List).map((e) => MediaModel.fromJson(e)).toList();
    }

    AddressModel? parsedAddress;
    if (json['address'] != null) {
      parsedAddress = AddressModel.fromJson(json['address']);
    } else if (json['address_id'] != null) {
      parsedAddress = AddressModel.fromJson(json['address_id']);
    }

    return PropertyModel(
      id: json['id']?.toString(),
      brokerId: json['broker_id'] != null
          ? BrokerModel.fromJson(json['broker_id'])
          : null,
      addressId: parsedAddress,
      propertyTitle: json['property_title']?.toString() ?? '',
      propertyDescription: json['property_description']?.toString(),
      propertyType: (json['property_type']?.toString()).asPropertyType,
      listingType: (json['listing_type']?.toString()).asListingType,
      price: double.tryParse(json['price']?.toString() ?? '0') ?? 0.0,
      area: double.tryParse(json['area']?.toString() ?? '0') ?? 0.0,
      areaUnit: (json['area_unit']?.toString()).asAreaUnit,
      bedrooms: int.tryParse(json['bedrooms']?.toString() ?? '0') ?? 0,
      bathrooms: int.tryParse(json['bathrooms']?.toString() ?? '0') ?? 0,
      balconies: int.tryParse(json['balconies']?.toString() ?? '0') ?? 0,
      parking: int.tryParse(json['parking']?.toString() ?? '0') ?? 0,
      floorNumber: int.tryParse(json['floor_number']?.toString() ?? ''),
      totalFloors: int.tryParse(json['total_floors']?.toString() ?? ''),
      furnishingStatus: (json['furnishing_status']?.toString()).asFurnishingStatus,
      propertyStatus: (json['property_status']?.toString()).asPropertyStatus,
      constructionStatus: (json['construction_status']?.toString()).asConstructionStatus,
      facing: json['facing'] != null ? (json['facing']?.toString()).asFacingDirection : null,
      amenities: parsedAmenities,
      medias: parsedMedias,
      isActive: json['is_active'] as bool? ?? true,
      isDeleted: json['is_deleted'] as bool? ?? false,
      deletedAt: json['deleted_at'] != null
          ? DateTime.tryParse(json['deleted_at'].toString())?.toLocal()
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())?.toLocal()
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'].toString())?.toLocal()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    if (id != null) data['id'] = id;
    data['broker_id'] = brokerId?.id;
    data['address_id'] = addressId?.id;
    data['property_title'] = propertyTitle;
    data['property_description'] = propertyDescription;
    data['property_type'] = propertyType.apiValue;
    data['listing_type'] = listingType.apiValue;
    data['price'] = price;
    data['area'] = area;
    data['area_unit'] = areaUnit.apiValue;
    data['bedrooms'] = bedrooms;
    data['bathrooms'] = bathrooms;
    data['balconies'] = balconies;
    data['parking'] = parking;
    data['floor_number'] = floorNumber;
    data['total_floors'] = totalFloors;
    data['furnishing_status'] = furnishingStatus.apiValue;
    data['property_status'] = propertyStatus.apiValue;
    data['construction_status'] = constructionStatus.apiValue;
    if (facing != null) data['facing'] = facing!.apiValue;
    data['amenities'] = amenities;
    data['medias'] = medias.map((e) => e.toJson()).toList();
    if (addressId != null) data['address'] = addressId!.toJson();
    data['is_active'] = isActive;
    data['is_deleted'] = isDeleted;
    if (deletedAt != null) data['deleted_at'] = deletedAt?.toUtc().toIso8601String();
    if (createdAt != null) data['created_at'] = createdAt?.toUtc().toIso8601String();
    if (updatedAt != null) data['updated_at'] = updatedAt?.toUtc().toIso8601String();
    return data;
  }

  PropertyModel copyWith({
    String? id,
    BrokerModel? brokerId,
    AddressModel? addressId,
    String? propertyTitle,
    String? propertyDescription,
    PropertyType? propertyType,
    ListingType? listingType,
    double? price,
    double? area,
    AreaUnit? areaUnit,
    int? bedrooms,
    int? bathrooms,
    int? balconies,
    int? parking,
    int? floorNumber,
    int? totalFloors,
    FurnishingStatus? furnishingStatus,
    PropertyStatus? propertyStatus,
    ConstructionStatus? constructionStatus,
    FacingDirection? facing,
    List<String>? amenities,
    List<MediaModel>? medias,
    bool? isActive,
    bool? isDeleted,
    DateTime? deletedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PropertyModel(
      id: id ?? this.id,
      brokerId: brokerId ?? this.brokerId,
      addressId: addressId ?? this.addressId,
      propertyTitle: propertyTitle ?? this.propertyTitle,
      propertyDescription: propertyDescription ?? this.propertyDescription,
      propertyType: propertyType ?? this.propertyType,
      listingType: listingType ?? this.listingType,
      price: price ?? this.price,
      area: area ?? this.area,
      areaUnit: areaUnit ?? this.areaUnit,
      bedrooms: bedrooms ?? this.bedrooms,
      bathrooms: bathrooms ?? this.bathrooms,
      balconies: balconies ?? this.balconies,
      parking: parking ?? this.parking,
      floorNumber: floorNumber ?? this.floorNumber,
      totalFloors: totalFloors ?? this.totalFloors,
      furnishingStatus: furnishingStatus ?? this.furnishingStatus,
      propertyStatus: propertyStatus ?? this.propertyStatus,
      constructionStatus: constructionStatus ?? this.constructionStatus,
      facing: facing ?? this.facing,
      amenities: amenities ?? this.amenities,
      medias: medias ?? this.medias,
      isActive: isActive ?? this.isActive,
      isDeleted: isDeleted ?? this.isDeleted,
      deletedAt: deletedAt ?? this.deletedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        brokerId,
        addressId,
        propertyTitle,
        propertyDescription,
        propertyType,
        listingType,
        price,
        area,
        areaUnit,
        bedrooms,
        bathrooms,
        balconies,
        parking,
        floorNumber,
        totalFloors,
        furnishingStatus,
        propertyStatus,
        constructionStatus,
        facing,
        amenities,
        medias,
        isActive,
        isDeleted,
        deletedAt,
        createdAt,
        updatedAt,
      ];
}
