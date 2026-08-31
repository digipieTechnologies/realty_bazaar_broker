import 'package:equatable/equatable.dart';

class AddressModel extends Equatable {
  static String tableName = "addresses";

  final String? id;
  final String fullAddress;
  final double? latitude;
  final double? longitude;
  final String? city;
  final String? pincode;
  final String? state;
  final String? country;
  final String? landmark;
  final String entityType;
  final String? entityId;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const AddressModel({
    this.id,
    required this.fullAddress,
    this.latitude,
    this.longitude,
    this.city,
    this.pincode,
    this.state,
    this.country,
    this.landmark,
    required this.entityType,
    this.entityId,
    this.createdAt,
    this.updatedAt,
  });

  static AddressModel fromJson(dynamic json) {
    if (json is! Map) {
      return AddressModel(id: json?.toString(), fullAddress: '', entityType: 'broker', entityId: null);
    }
    return AddressModel(
      id: json['id']?.toString(),
      fullAddress: json['full_address']?.toString() ?? '',
      latitude: json['latitude'] != null ? double.tryParse(json['latitude'].toString()) : null,
      longitude: json['longitude'] != null ? double.tryParse(json['longitude'].toString()) : null,
      city: json['city']?.toString(),
      pincode: json['pincode']?.toString(),
      state: json['state']?.toString(),
      country: json['country']?.toString(),
      landmark: json['landmark']?.toString(),
      entityType: json['entity_type']?.toString() ?? 'broker',
      entityId: json['entity_id']?.toString(),
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
    data['full_address'] = fullAddress;
    data['latitude'] = latitude;
    data['longitude'] = longitude;
    data['city'] = city;
    data['pincode'] = pincode;
    data['state'] = state;
    data['country'] = country;
    data['landmark'] = landmark;
    data['entity_type'] = entityType;
    if (entityId != null) data['entity_id'] = entityId;
    if (createdAt != null) {
      data['created_at'] = createdAt?.toUtc().toIso8601String();
    }
    if (updatedAt != null) {
      data['updated_at'] = updatedAt?.toUtc().toIso8601String();
    }
    return data;
  }

  AddressModel copyWith({
    String? id,
    String? fullAddress,
    double? latitude,
    double? longitude,
    String? city,
    String? pincode,
    String? state,
    String? country,
    String? landmark,
    String? entityType,
    String? entityId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AddressModel(
      id: id ?? this.id,
      fullAddress: fullAddress ?? this.fullAddress,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      city: city ?? this.city,
      pincode: pincode ?? this.pincode,
      state: state ?? this.state,
      country: country ?? this.country,
      landmark: landmark ?? this.landmark,
      entityType: entityType ?? this.entityType,
      entityId: entityId ?? this.entityId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
    id,
    fullAddress,
    latitude,
    longitude,
    city,
    pincode,
    state,
    country,
    landmark,
    entityType,
    entityId,
    createdAt,
    updatedAt,
  ];
}
