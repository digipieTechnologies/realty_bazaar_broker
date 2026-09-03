// File: lib/models/video_request_model.dart
// Purpose: Type-safe model representing video request records along with nested property & broker objects.

import 'package:equatable/equatable.dart';

import 'address_model.dart';
import 'media_model.dart';
import 'user_model.dart';
import 'video_request_enums.dart';

class VideoRequestModel extends Equatable {
  final String id;
  final VideoRequestStatus status;
  final VideoRequestApprovalStatus adminApprovalStatus;
  final String? notes;
  final String? cancelReason;
  final String? adminCancelReason;
  final UserModel? cancelledByUserId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? completedAt;

  // Direct nested models
  final PropertyDetails? property;
  final BrokerDetails? broker;

  String? get propertyId => property?.id;

  String? get brokerId => broker?.id;

  const VideoRequestModel({
    required this.id,
    required this.status,
    required this.adminApprovalStatus,
    this.notes,
    this.cancelReason,
    this.adminCancelReason,
    this.cancelledByUserId,
    required this.createdAt,
    required this.updatedAt,
    this.completedAt,
    this.property,
    this.broker,
  });

  static VideoRequestModel fromJson(dynamic json) {
    if (json is! Map) {
      return VideoRequestModel(
        id: json?.toString() ?? '',
        status: VideoRequestStatus.pending,
        adminApprovalStatus: VideoRequestApprovalStatus.pending,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    }

    PropertyDetails? parsedProperty;
    if (json['property'] != null) {
      parsedProperty = PropertyDetails.fromJson(json['property']);
    } else if (json['property_id'] != null) {
      parsedProperty = PropertyDetails.fromJson(json['property_id']);
    }

    BrokerDetails? parsedBroker;
    if (json['broker'] != null) {
      parsedBroker = BrokerDetails.fromJson(json['broker']);
    } else if (json['broker_id'] != null) {
      parsedBroker = BrokerDetails.fromJson(json['broker_id']);
    }

    return VideoRequestModel(
      id: json['id']?.toString() ?? '',
      status: VideoRequestStatus.fromDbValue(json['status']?.toString()),
      adminApprovalStatus: VideoRequestApprovalStatus.fromDbValue(json['admin_approval_status']?.toString()),
      notes: json['notes']?.toString(),
      cancelReason: json['cancel_reason']?.toString(),
      adminCancelReason: json['admin_cancel_reason']?.toString(),
      cancelledByUserId: json['cancelled_by_user_id'] != null
          ? UserModel.fromJson(json['cancelled_by_user_id'])
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())?.toLocal() ?? DateTime.now()
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'].toString())?.toLocal() ?? DateTime.now()
          : DateTime.now(),
      completedAt: json['completed_at'] != null
          ? DateTime.tryParse(json['completed_at'].toString())?.toLocal()
          : null,
      property: parsedProperty,
      broker: parsedBroker,
    );
  }

  @override
  List<Object?> get props => [
    id,
    status,
    adminApprovalStatus,
    notes,
    cancelReason,
    adminCancelReason,
    cancelledByUserId,
    createdAt,
    updatedAt,
    completedAt,
    property,
    broker,
  ];
}

class PropertyDetails extends Equatable {
  final String id;
  final String title;
  final String? propertyDescription;
  final String? propertyType;
  final String? listingType;
  final double price;
  final double area;
  final String? areaUnit;
  final int bedrooms;
  final int bathrooms;
  final int balconies;
  final int parking;
  final int? floorNumber;
  final int? totalFloors;
  final String? furnishingStatus;
  final String? propertyStatus;
  final String? constructionStatus;
  final String? facing;
  final List<String> amenities;
  final List<MediaModel> medias;
  final AddressModel? address;

  const PropertyDetails({
    required this.id,
    required this.title,
    this.propertyDescription,
    this.propertyType,
    this.listingType,
    required this.price,
    required this.area,
    this.areaUnit,
    this.bedrooms = 0,
    this.bathrooms = 0,
    this.balconies = 0,
    this.parking = 0,
    this.floorNumber,
    this.totalFloors,
    this.furnishingStatus,
    this.propertyStatus,
    this.constructionStatus,
    this.facing,
    this.amenities = const [],
    this.medias = const [],
    this.address,
  });

  static PropertyDetails fromJson(dynamic json) {
    if (json is! Map) {
      return const PropertyDetails(id: '', title: '', price: 0, area: 0);
    }

    List<MediaModel> parsedMedias = [];
    if (json['medias'] != null && json['medias'] is List) {
      parsedMedias = (json['medias'] as List).map((e) => MediaModel.fromJson(e)).toList();
    }

    List<String> parsedAmenities = [];
    if (json['amenities'] != null && json['amenities'] is List) {
      parsedAmenities = (json['amenities'] as List).map((e) => e.toString()).toList();
    }

    return PropertyDetails(
      id: json['id']?.toString() ?? '',
      title: json['property_title']?.toString() ?? json['title']?.toString() ?? '',
      propertyDescription: json['property_description']?.toString(),
      propertyType: json['property_type']?.toString(),
      listingType: json['listing_type']?.toString(),
      price: double.tryParse(json['price']?.toString() ?? '0') ?? 0.0,
      area: double.tryParse(json['area']?.toString() ?? '0') ?? 0.0,
      areaUnit: json['area_unit']?.toString(),
      bedrooms: int.tryParse(json['bedrooms']?.toString() ?? '0') ?? 0,
      bathrooms: int.tryParse(json['bathrooms']?.toString() ?? '0') ?? 0,
      balconies: int.tryParse(json['balconies']?.toString() ?? '0') ?? 0,
      parking: int.tryParse(json['parking']?.toString() ?? '0') ?? 0,
      floorNumber: int.tryParse(json['floor_number']?.toString() ?? ''),
      totalFloors: int.tryParse(json['total_floors']?.toString() ?? ''),
      furnishingStatus: json['furnishing_status']?.toString(),
      propertyStatus: json['property_status']?.toString(),
      constructionStatus: json['construction_status']?.toString(),
      facing: json['facing']?.toString(),
      amenities: parsedAmenities,
      medias: parsedMedias,
      address: json['address'] != null ? AddressModel.fromJson(json['address']) : null,
    );
  }

  @override
  List<Object?> get props => [
    id,
    title,
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
    address,
  ];
}

class BrokerDetails extends Equatable {
  final String id;
  final String businessName;
  final AddressModel? address;

  const BrokerDetails({required this.id, required this.businessName, this.address});

  static BrokerDetails fromJson(dynamic json) {
    if (json is! Map) {
      return const BrokerDetails(id: '', businessName: '');
    }

    return BrokerDetails(
      id: json['id']?.toString() ?? '',
      businessName: json['business_name']?.toString() ?? '',
      address: json['address'] != null ? AddressModel.fromJson(json['address']) : null,
    );
  }

  @override
  List<Object?> get props => [id, businessName, address];
}
