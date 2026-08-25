import 'package:equatable/equatable.dart';

import 'broker_model.dart';
import 'campaign_enums.dart';
import 'target_area_model.dart';

class AdCampaignSettingsModel extends Equatable {
  static const String tableName = "ad_campaign_settings";

  final String? id;
  final BrokerModel? brokerId;
  final CampaignGender gender;
  final List<TargetAreaModel> areaDetails;
  final List<String> targetingSuggestions;
  final int startAgeRange;
  final int endAgeRange;
  final String? campaignStartTime;
  final String? campaignEndTime;
  final bool campaignIsAllDay;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const AdCampaignSettingsModel({
    this.id,
    this.brokerId,
    this.gender = CampaignGender.all,
    this.areaDetails = const [],
    this.targetingSuggestions = const [],
    this.startAgeRange = 18,
    this.endAgeRange = 65,
    this.campaignStartTime,
    this.campaignEndTime,
    this.campaignIsAllDay = true,
    this.createdAt,
    this.updatedAt,
  });

  static AdCampaignSettingsModel fromJson(dynamic json) {
    if (json is! Map) {
      return const AdCampaignSettingsModel();
    }

    List<TargetAreaModel> parsedAreas = [];
    if (json['area_details'] != null && json['area_details'] is List) {
      parsedAreas = (json['area_details'] as List)
          .map((e) => TargetAreaModel.fromJson(e))
          .toList();
    }

    List<String> parsedSuggestions = [];
    if (json['targeting_suggestions'] != null && json['targeting_suggestions'] is List) {
      parsedSuggestions = (json['targeting_suggestions'] as List)
          .map((e) => e.toString())
          .toList();
    }

    BrokerModel? parsedBroker;
    if (json['brokers'] != null) {
      parsedBroker = BrokerModel.fromJson(json['brokers']);
    } else if (json['broker'] != null) {
      parsedBroker = BrokerModel.fromJson(json['broker']);
    } else if (json['broker_id'] != null) {
      parsedBroker = BrokerModel.fromJson(json['broker_id']);
    }

    return AdCampaignSettingsModel(
      id: json['id']?.toString(),
      brokerId: parsedBroker,
      gender: CampaignGender.fromDbValue(json['gender']),
      areaDetails: parsedAreas,
      targetingSuggestions: parsedSuggestions,
      startAgeRange: int.tryParse(json['start_age_range']?.toString() ?? '18') ?? 18,
      endAgeRange: int.tryParse(json['end_age_range']?.toString() ?? '65') ?? 65,
      campaignStartTime: json['campaign_start_time']?.toString(),
      campaignEndTime: json['campaign_end_time']?.toString(),
      campaignIsAllDay: json['campaign_is_all_day'] as bool? ?? true,
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
    if (id != null && id!.isNotEmpty) data['id'] = id;
    if (brokerId?.id != null) data['broker_id'] = brokerId!.id;
    data['gender'] = gender.dbValue;
    data['area_details'] = areaDetails.map((e) => e.toJson()).toList();
    data['targeting_suggestions'] = targetingSuggestions;
    data['start_age_range'] = startAgeRange;
    data['end_age_range'] = endAgeRange;
    data['campaign_start_time'] = campaignIsAllDay ? null : campaignStartTime;
    data['campaign_end_time'] = campaignIsAllDay ? null : campaignEndTime;
    data['campaign_is_all_day'] = campaignIsAllDay;
    if (createdAt != null) data['created_at'] = createdAt?.toUtc().toIso8601String();
    if (updatedAt != null) data['updated_at'] = updatedAt?.toUtc().toIso8601String();
    return data;
  }

  AdCampaignSettingsModel copyWith({
    String? id,
    BrokerModel? brokerId,
    CampaignGender? gender,
    List<TargetAreaModel>? areaDetails,
    List<String>? targetingSuggestions,
    int? startAgeRange,
    int? endAgeRange,
    String? campaignStartTime,
    String? campaignEndTime,
    bool? campaignIsAllDay,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AdCampaignSettingsModel(
      id: id ?? this.id,
      brokerId: brokerId ?? this.brokerId,
      gender: gender ?? this.gender,
      areaDetails: areaDetails ?? this.areaDetails,
      targetingSuggestions: targetingSuggestions ?? this.targetingSuggestions,
      startAgeRange: startAgeRange ?? this.startAgeRange,
      endAgeRange: endAgeRange ?? this.endAgeRange,
      campaignStartTime: campaignStartTime ?? this.campaignStartTime,
      campaignEndTime: campaignEndTime ?? this.campaignEndTime,
      campaignIsAllDay: campaignIsAllDay ?? this.campaignIsAllDay,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        brokerId,
        gender,
        areaDetails,
        targetingSuggestions,
        startAgeRange,
        endAgeRange,
        campaignStartTime,
        campaignEndTime,
        campaignIsAllDay,
        createdAt,
        updatedAt,
      ];
}
