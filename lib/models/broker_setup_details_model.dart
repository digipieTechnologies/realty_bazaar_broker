// File: lib/models/broker_setup_details_model.dart
// Purpose: Standalone Equatable model for broker setup details JSONB configuration.

import 'package:equatable/equatable.dart';

class BrokerSetupDetailsModel extends Equatable {
  final bool accountCreated;
  final bool businessInfoAdded;
  final bool facebookConnected;
  final bool instagramConnected;
  final bool propertiesImported;

  const BrokerSetupDetailsModel({
    this.accountCreated = true,
    this.businessInfoAdded = false,
    this.facebookConnected = false,
    this.instagramConnected = false,
    this.propertiesImported = false,
  });

  factory BrokerSetupDetailsModel.fromJson(dynamic json) {
    if (json is! Map) return const BrokerSetupDetailsModel();
    return BrokerSetupDetailsModel(
      accountCreated: json['account_created'] as bool? ?? true,
      businessInfoAdded: json['business_info_added'] as bool? ?? false,
      facebookConnected: json['facebook_connected'] as bool? ?? false,
      instagramConnected: json['instagram_connected'] as bool? ?? false,
      propertiesImported: json['properties_imported'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
    'account_created': accountCreated,
    'business_info_added': businessInfoAdded,
    'facebook_connected': facebookConnected,
    'instagram_connected': instagramConnected,
    'properties_imported': propertiesImported,
  };

  BrokerSetupDetailsModel copyWith({
    bool? accountCreated,
    bool? businessInfoAdded,
    bool? facebookConnected,
    bool? instagramConnected,
    bool? propertiesImported,
  }) {
    return BrokerSetupDetailsModel(
      accountCreated: accountCreated ?? this.accountCreated,
      businessInfoAdded: businessInfoAdded ?? this.businessInfoAdded,
      facebookConnected: facebookConnected ?? this.facebookConnected,
      instagramConnected: instagramConnected ?? this.instagramConnected,
      propertiesImported: propertiesImported ?? this.propertiesImported,
    );
  }

  @override
  List<Object?> get props => [
    accountCreated,
    businessInfoAdded,
    facebookConnected,
    instagramConnected,
    propertiesImported,
  ];
}
