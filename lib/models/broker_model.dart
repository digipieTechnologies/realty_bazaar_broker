import 'package:equatable/equatable.dart';
import 'address_model.dart';

class BrokerModel extends Equatable {
  static String tableName = "brokers";

  final String? id;
  final String? businessName;
  final AddressModel? addressId;
  final String? plan;
  final String? onboardingStatus;
  final bool? isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final bool? isDeleted;
  final DateTime? deletedAt;
  final bool? autoApproveVideoRequests;

  static const String onboardingStatusPending = 'pending';
  static const String onboardingStatusInProgress = 'in_progress';
  static const String onboardingStatusCompleted = 'completed';

  const BrokerModel({
    this.id,
    this.businessName,
    this.addressId,
    this.plan,
    this.onboardingStatus,
    this.isActive,
    this.createdAt,
    this.updatedAt,
    this.isDeleted,
    this.deletedAt,
    this.autoApproveVideoRequests,
  });

  static BrokerModel fromJson(dynamic json) {
    if (json is! Map) {
      return BrokerModel(id: json?.toString());
    }
    return BrokerModel(
      id: json['id']?.toString(),
      businessName: json['business_name']?.toString() ?? '',
      addressId: json['address_id'] != null
          ? AddressModel.fromJson(json['address_id'])
          : null,
      plan: json['plan']?.toString(),
      onboardingStatus:
          json['onboarding_status']?.toString() ?? onboardingStatusPending,
      isActive: json['is_active'] as bool? ?? true,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())?.toLocal()
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'].toString())?.toLocal()
          : null,
      isDeleted: json['is_deleted'] as bool? ?? false,
      deletedAt: json['deleted_at'] != null
          ? DateTime.tryParse(json['deleted_at'].toString())?.toLocal()
          : null,
      autoApproveVideoRequests: json['auto_approve_video_requests'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    if (id != null) data['id'] = id;
    data['business_name'] = businessName;
    data['address_id'] = addressId?.id;
    data['plan'] = plan;
    data['onboarding_status'] = onboardingStatus;
    data['is_active'] = isActive;
    if (createdAt != null) {
      data['created_at'] = createdAt?.toUtc().toIso8601String();
    }
    if (updatedAt != null) {
      data['updated_at'] = updatedAt?.toUtc().toIso8601String();
    }
    data['is_deleted'] = isDeleted;
    if (deletedAt != null) {
      data['deleted_at'] = deletedAt?.toUtc().toIso8601String();
    }
    data['auto_approve_video_requests'] = autoApproveVideoRequests ?? false;
    return data;
  }

  BrokerModel copyWith({
    String? id,
    String? businessName,
    AddressModel? addressId,
    String? plan,
    String? onboardingStatus,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isDeleted,
    DateTime? deletedAt,
    bool? autoApproveVideoRequests,
  }) {
    return BrokerModel(
      id: id ?? this.id,
      businessName: businessName ?? this.businessName,
      addressId: addressId ?? this.addressId,
      plan: plan ?? this.plan,
      onboardingStatus: onboardingStatus ?? this.onboardingStatus,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isDeleted: isDeleted ?? this.isDeleted,
      deletedAt: deletedAt ?? this.deletedAt,
      autoApproveVideoRequests: autoApproveVideoRequests ?? this.autoApproveVideoRequests,
    );
  }

  @override
  List<Object?> get props => [
    id,
    businessName,
    addressId,
    plan,
    onboardingStatus,
    isActive,
    createdAt,
    updatedAt,
    isDeleted,
    deletedAt,
    autoApproveVideoRequests,
  ];
}
