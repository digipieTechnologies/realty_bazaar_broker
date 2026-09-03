import 'package:equatable/equatable.dart';

import 'broker_model.dart';
import 'lead_status_enum.dart';
import 'social_post_model.dart';

class SocialLeadModel extends Equatable {
  static String tableName = "social_leads";

  final String? id;
  final String userName;
  final String? notes;
  final String? propertyDetails;
  final String phone;
  final String? phoneCountryCode;
  final String? phoneCountryIso;
  final SocialPostModel? socialPostId;
  final BrokerModel? brokerId;
  final LeadStatus status;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  // Backward compatibility getters for UI components
  String get contactNumber {
    final code = phoneCountryCode ?? '91';
    return '+$code $phone';
  }

  String get whatsappNumber => phone;

  String buildWhatsappUrl() {
    final cleanPhone = (phoneCountryCode ?? '91') + phone.replaceAll(RegExp(r'\D'), '');
    final property = socialPost?.propertyId;
    final propertyName = property?.propertyTitle.isNotEmpty == true
        ? property!.propertyTitle
        : (propertyDetails ?? socialPost?.caption ?? '');
    final address = property?.address?.fullAddress ?? '';

    final StringBuffer msgBuffer = StringBuffer();
    msgBuffer.writeln('Hello ${userName.isNotEmpty ? userName : 'there'},');
    msgBuffer.writeln('Thanks for connecting with us!');

    if (propertyName.isNotEmpty) {
      msgBuffer.writeln('\nHere are the property details:');
      msgBuffer.writeln('📌 Property: $propertyName');
      if (address.isNotEmpty) {
        msgBuffer.writeln('📍 Location: $address');
      }
    } else if (notes != null && notes!.trim().isNotEmpty) {
      msgBuffer.writeln('\nRegarding your inquiry: ${notes!.trim()}');
    }

    msgBuffer.writeln(
      '\nPlease let us know if you have any questions or when you would like to schedule a site visit.',
    );

    final encodedText = Uri.encodeComponent(msgBuffer.toString());
    return 'https://wa.me/$cleanPhone?text=$encodedText';
  }

  SocialPostModel? get socialPost => socialPostId;

  const SocialLeadModel({
    this.id,
    this.userName = '',
    this.notes,
    this.propertyDetails,
    this.phone = '',
    this.phoneCountryCode = '91',
    this.phoneCountryIso = 'IN',
    SocialPostModel? socialPostId,
    SocialPostModel? socialPost,
    this.brokerId,
    this.status = LeadStatus.pending,
    this.createdAt,
    this.updatedAt,
  }) : socialPostId = socialPostId ?? socialPost;

  static SocialLeadModel fromJson(dynamic json) {
    if (json is! Map) {
      return SocialLeadModel(id: json?.toString());
    }

    SocialPostModel? parsedSocialPost;
    if (json['social_posts'] != null) {
      parsedSocialPost = SocialPostModel.fromJson(json['social_posts']);
    } else if (json['social_post'] != null) {
      parsedSocialPost = SocialPostModel.fromJson(json['social_post']);
    } else if (json['social_post_id'] != null) {
      parsedSocialPost = SocialPostModel.fromJson(json['social_post_id']);
    }

    final rawPhone =
        json['phone']?.toString() ??
        json['contact_number']?.toString() ??
        json['whatsapp_number']?.toString() ??
        '';

    return SocialLeadModel(
      id: json['id']?.toString(),
      userName: json['user_name']?.toString() ?? '',
      notes: json['notes']?.toString(),
      propertyDetails: json['property_details']?.toString(),
      phone: rawPhone,
      phoneCountryCode: json['phone_country_code']?.toString() ?? '91',
      phoneCountryIso: json['phone_country_iso']?.toString() ?? 'IN',
      socialPostId: parsedSocialPost,
      brokerId: json['broker_id'] != null ? BrokerModel.fromJson(json['broker_id']) : null,
      status: LeadStatus.fromString(json['status']?.toString()),
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
    data['user_name'] = userName;
    data['notes'] = notes;
    data['property_details'] = propertyDetails;
    data['phone'] = phone;
    data['phone_country_code'] = phoneCountryCode ?? '91';
    data['phone_country_iso'] = phoneCountryIso ?? 'IN';
    data['social_post_id'] = socialPostId?.id;
    data['broker_id'] = brokerId?.id;
    data['status'] = status.apiValue;
    if (createdAt != null) {
      data['created_at'] = createdAt?.toUtc().toIso8601String();
    }
    return data;
  }

  SocialLeadModel copyWith({
    String? id,
    String? userName,
    String? notes,
    String? propertyDetails,
    String? phone,
    String? phoneCountryCode,
    String? phoneCountryIso,
    SocialPostModel? socialPostId,
    BrokerModel? brokerId,
    LeadStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return SocialLeadModel(
      id: id ?? this.id,
      userName: userName ?? this.userName,
      notes: notes ?? this.notes,
      propertyDetails: propertyDetails ?? this.propertyDetails,
      phone: phone ?? this.phone,
      phoneCountryCode: phoneCountryCode ?? this.phoneCountryCode,
      phoneCountryIso: phoneCountryIso ?? this.phoneCountryIso,
      socialPostId: socialPostId ?? this.socialPostId,
      brokerId: brokerId ?? this.brokerId,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
    id,
    userName,
    notes,
    propertyDetails,
    phone,
    phoneCountryCode,
    phoneCountryIso,
    socialPostId,
    brokerId,
    status,
    createdAt,
    updatedAt,
  ];
}
