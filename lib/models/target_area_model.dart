// File: lib/models/target_area_model.dart
// Purpose: Type-safe model representing target locations for ad campaigns, adhering to project model patterns.

import 'package:equatable/equatable.dart';

class TargetAreaModel extends Equatable {
  final String fullArea;
  final String area;
  final String city;
  final String state;
  final String county;
  final String pincode;
  final double latitude;
  final double longitude;

  const TargetAreaModel({
    required this.fullArea,
    required this.area,
    required this.city,
    required this.state,
    required this.county,
    required this.pincode,
    required this.latitude,
    required this.longitude,
  });

  static TargetAreaModel fromJson(dynamic json) {
    if (json is! Map) {
      return const TargetAreaModel(
        fullArea: '',
        area: '',
        city: '',
        state: '',
        county: '',
        pincode: '',
        latitude: 0.0,
        longitude: 0.0,
      );
    }

    return TargetAreaModel(
      fullArea: json['full_area']?.toString() ?? json['fullArea']?.toString() ?? '',
      area: json['area']?.toString() ?? '',
      city: json['city']?.toString() ?? '',
      state: json['state']?.toString() ?? '',
      county: json['county']?.toString() ?? '',
      pincode: json['pincode']?.toString() ?? '',
      latitude: double.tryParse(json['latitude']?.toString() ?? '0') ?? 0.0,
      longitude: double.tryParse(json['longitude']?.toString() ?? '0') ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'full_area': fullArea,
      'area': area,
      'city': city,
      'state': state,
      'county': county,
      'pincode': pincode,
      'latitude': latitude,
      'longitude': longitude,
    };
  }

  @override
  List<Object?> get props => [
        fullArea,
        area,
        city,
        state,
        county,
        pincode,
        latitude,
        longitude,
      ];
}
