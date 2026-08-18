import 'package:equatable/equatable.dart';
import 'broker_model.dart';
import 'social_enums.dart';

class SocialAccountModel extends Equatable {
  static const String tableName = "social_accounts";

  final String? id;
  final BrokerModel? brokerId;
  final SocialPlatform? platform;
  final String? facebookUserId;
  final String? pageId;
  final String? pageName;
  final String? pageAccessToken;
  final String? instagramAccountId;
  final String? instagramUsername;
  final String? adAccountId;
  final String? accessToken;
  final DateTime? expiresAt;
  final String? profilePictureUrl;
  final bool? isConnected;
  final bool? isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const SocialAccountModel({
    this.id,
    this.brokerId,
    this.platform,
    this.facebookUserId,
    this.pageId,
    this.pageName,
    this.pageAccessToken,
    this.instagramAccountId,
    this.instagramUsername,
    this.adAccountId,
    this.accessToken,
    this.expiresAt,
    this.profilePictureUrl,
    this.isConnected,
    this.isActive,
    this.createdAt,
    this.updatedAt,
  });

  static SocialAccountModel fromJson(dynamic json) {
    if (json is! Map) {
      return SocialAccountModel(id: json?.toString());
    }
    return SocialAccountModel(
      id: json['id']?.toString(),
      brokerId: json['broker_id'] != null
          ? BrokerModel.fromJson(json['broker_id'])
          : null,
      platform: json['platform'] != null
          ? SocialPlatform.fromDbValue(json['platform'].toString())
          : null,
      facebookUserId: json['facebook_user_id']?.toString(),
      pageId: json['page_id']?.toString(),
      pageName: json['page_name']?.toString(),
      pageAccessToken: json['page_access_token']?.toString(),
      instagramAccountId: json['instagram_account_id']?.toString(),
      instagramUsername: json['instagram_username']?.toString(),
      adAccountId: json['ad_account_id']?.toString(),
      accessToken: json['access_token']?.toString(),
      expiresAt: json['expires_at'] != null
          ? DateTime.tryParse(json['expires_at'].toString())?.toLocal()
          : null,
      profilePictureUrl: json['profile_picture_url']?.toString(),
      isConnected: json['is_connected'] as bool? ?? (json['is_active'] as bool? ?? true),
      isActive: json['is_active'] as bool? ?? true,
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
    if (platform != null) data['platform'] = platform?.dbValue;
    data['facebook_user_id'] = facebookUserId;
    data['page_id'] = pageId;
    data['page_name'] = pageName;
    data['page_access_token'] = pageAccessToken;
    data['instagram_account_id'] = instagramAccountId;
    data['instagram_username'] = instagramUsername;
    data['ad_account_id'] = adAccountId;
    if (accessToken != null) data['access_token'] = accessToken;
    if (expiresAt != null) {
      data['expires_at'] = expiresAt?.toUtc().toIso8601String();
    }
    if (profilePictureUrl != null) {
      data['profile_picture_url'] = profilePictureUrl;
    }
    data['is_connected'] = isConnected;
    data['is_active'] = isActive;
    if (createdAt != null) {
      data['created_at'] = createdAt?.toUtc().toIso8601String();
    }
    if (updatedAt != null) {
      data['updated_at'] = updatedAt?.toUtc().toIso8601String();
    }
    return data;
  }

  SocialAccountModel copyWith({
    String? id,
    BrokerModel? brokerId,
    SocialPlatform? platform,
    String? facebookUserId,
    String? pageId,
    String? pageName,
    String? pageAccessToken,
    String? instagramAccountId,
    String? instagramUsername,
    String? adAccountId,
    String? accessToken,
    DateTime? expiresAt,
    String? profilePictureUrl,
    bool? isConnected,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return SocialAccountModel(
      id: id ?? this.id,
      brokerId: brokerId ?? this.brokerId,
      platform: platform ?? this.platform,
      facebookUserId: facebookUserId ?? this.facebookUserId,
      pageId: pageId ?? this.pageId,
      pageName: pageName ?? this.pageName,
      pageAccessToken: pageAccessToken ?? this.pageAccessToken,
      instagramAccountId: instagramAccountId ?? this.instagramAccountId,
      instagramUsername: instagramUsername ?? this.instagramUsername,
      adAccountId: adAccountId ?? this.adAccountId,
      accessToken: accessToken ?? this.accessToken,
      expiresAt: expiresAt ?? this.expiresAt,
      profilePictureUrl: profilePictureUrl ?? this.profilePictureUrl,
      isConnected: isConnected ?? this.isConnected,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        brokerId,
        platform,
        facebookUserId,
        pageId,
        pageName,
        pageAccessToken,
        instagramAccountId,
        instagramUsername,
        adAccountId,
        accessToken,
        expiresAt,
        profilePictureUrl,
        isConnected,
        isActive,
        createdAt,
        updatedAt,
      ];
}
