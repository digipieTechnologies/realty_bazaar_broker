import 'package:equatable/equatable.dart';

import 'broker_model.dart';
import 'user_enums.dart';
import 'user_subscription_model.dart';

class UserModel extends Equatable {
  static String tableName = "users";

  final String? id;
  final String? name;
  final String? email;
  final String? phone;
  final String? phoneCountryCode;
  final String? phoneCountryIso;
  final UserRole? role;
  final UserGender? gender;
  final bool? isActive;
  final bool? isDeleted;
  final bool? isEmailVerified;
  final BrokerModel? brokerId;
  final UserSubscriptionModel? userSubscription;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  String? get roleString => role?.dbValue;

  String? get genderString => gender?.dbValue;

  String get formattedPhone {
    final rawPhone = (phone ?? '').trim();
    if (rawPhone.isEmpty) return '';
    final code = (phoneCountryCode ?? '91').replaceAll('+', '').trim();
    final cleanPhone = rawPhone.replaceAll(RegExp(r'\D'), '');
    if (code.isNotEmpty && cleanPhone.startsWith(code) && cleanPhone.length > code.length + 8) {
      return '+$code-${cleanPhone.substring(code.length)}';
    }
    return '+$code-$cleanPhone';
  }

  const UserModel({
    this.id,
    this.name,
    this.email,
    this.phone,
    this.phoneCountryCode = '91',
    this.phoneCountryIso = 'IN',
    this.role = UserRole.broker,
    this.gender,
    this.isActive,
    this.isDeleted,
    this.isEmailVerified = false,
    this.brokerId,
    this.userSubscription,
    this.createdAt,
    this.updatedAt,
  });

  static UserModel fromJson(dynamic json) {
    if (json is! Map) {
      return UserModel(id: json?.toString());
    }
    return UserModel(
      id: json['id']?.toString(),
      name: json['name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      phone: json['phone']?.toString(),
      phoneCountryCode: json['phone_country_code']?.toString() ?? '91',
      phoneCountryIso: json['phone_country_iso']?.toString() ?? 'IN',
      role: json['role'] != null ? UserRole.fromDbValue(json['role']) : UserRole.broker,
      gender: json['gender'] != null ? UserGender.tryFromDbValue(json['gender']) : null,
      isActive: json['is_active'] as bool? ?? true,
      isDeleted: json['is_deleted'] as bool? ?? false,
      isEmailVerified: json['is_email_verified'] as bool? ?? false,
      brokerId: json['broker_id'] != null ? BrokerModel.fromJson(json['broker_id']) : null,
      userSubscription: json['user_subscription'] != null
          ? UserSubscriptionModel.fromJson(json['user_subscription'])
          : null,
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'].toString())?.toLocal() : null,
      updatedAt: json['updated_at'] != null ? DateTime.tryParse(json['updated_at'].toString())?.toLocal() : null,
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    if (id != null) data['id'] = id;
    data['name'] = name;
    data['email'] = email;
    data['phone'] = phone;
    data['phone_country_code'] = phoneCountryCode ?? '91';
    data['phone_country_iso'] = phoneCountryIso ?? 'IN';
    data['role'] = role?.dbValue ?? 'broker';
    if (gender != null) data['gender'] = gender!.dbValue;
    data['is_active'] = isActive;
    data['is_deleted'] = isDeleted;
    data['is_email_verified'] = isEmailVerified;
    data['broker_id'] = brokerId?.id;
    if (userSubscription != null) {
      data['user_subscription'] = userSubscription!.toJson();
    }
    if (createdAt != null) {
      data['created_at'] = createdAt?.toUtc().toIso8601String();
    }
    return data;
  }

  UserModel copyWith({
    String? id,
    String? name,
    String? email,
    String? phone,
    String? phoneCountryCode,
    String? phoneCountryIso,
    UserRole? role,
    UserGender? gender,
    bool? isActive,
    bool? isDeleted,
    bool? isEmailVerified,
    BrokerModel? brokerId,
    UserSubscriptionModel? userSubscription,
    bool clearUserSubscription = false,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      phoneCountryCode: phoneCountryCode ?? this.phoneCountryCode,
      phoneCountryIso: phoneCountryIso ?? this.phoneCountryIso,
      role: role ?? this.role,
      gender: gender ?? this.gender,
      isActive: isActive ?? this.isActive,
      isDeleted: isDeleted ?? this.isDeleted,
      isEmailVerified: isEmailVerified ?? this.isEmailVerified,
      brokerId: brokerId ?? this.brokerId,
      userSubscription: clearUserSubscription ? userSubscription : (userSubscription ?? this.userSubscription),
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
    id,
    name,
    email,
    phone,
    phoneCountryCode,
    phoneCountryIso,
    role,
    gender,
    isActive,
    isDeleted,
    isEmailVerified,
    brokerId,
    userSubscription,
    createdAt,
    updatedAt,
  ];
}
