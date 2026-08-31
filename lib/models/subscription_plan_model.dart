// File: lib/models/subscription_plan_model.dart
// Purpose: Model class representing subscription plans in database (Supabase subscription_plans table).

import 'package:equatable/equatable.dart';

import 'subscription_enums.dart';

class SubscriptionPlanModel extends Equatable {
  static const String tableName = 'subscription_plans';

  final String? id;
  final String title;
  final double amount;
  final SubscriptionDuration duration;
  final String description;
  final List<String> benefits;
  final bool isActive;
  final bool isPopular;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const SubscriptionPlanModel({
    this.id,
    this.title = '',
    this.amount = 0.0,
    this.duration = SubscriptionDuration.month,
    this.description = '',
    this.benefits = const [],
    this.isActive = true,
    this.isPopular = false,
    this.createdAt,
    this.updatedAt,
  });

  static SubscriptionPlanModel fromJson(dynamic json) {
    if (json is! Map) {
      return const SubscriptionPlanModel();
    }

    List<String> parsedBenefits = [];
    if (json['benefits'] != null && json['benefits'] is List) {
      parsedBenefits = (json['benefits'] as List).map((e) => e.toString()).toList();
    }

    return SubscriptionPlanModel(
      id: json['id']?.toString(),
      title: json['title']?.toString() ?? '',
      amount: double.tryParse(json['amount']?.toString() ?? '0') ?? 0.0,
      duration: SubscriptionDuration.fromDbValue(json['duration']),
      description: json['description']?.toString() ?? '',
      benefits: parsedBenefits,
      isActive: json['is_active'] as bool? ?? true,
      isPopular: json['is_popular'] as bool? ?? false,
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
    data['title'] = title;
    data['amount'] = amount;
    data['duration'] = duration.dbValue;
    data['description'] = description;
    data['benefits'] = benefits;
    data['is_active'] = isActive;
    data['is_popular'] = isPopular;
    if (createdAt != null) data['created_at'] = createdAt?.toUtc().toIso8601String();
    if (updatedAt != null) data['updated_at'] = updatedAt?.toUtc().toIso8601String();
    return data;
  }

  SubscriptionPlanModel copyWith({
    String? id,
    String? title,
    double? amount,
    SubscriptionDuration? duration,
    String? description,
    List<String>? benefits,
    bool? isActive,
    bool? isPopular,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return SubscriptionPlanModel(
      id: id ?? this.id,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      duration: duration ?? this.duration,
      description: description ?? this.description,
      benefits: benefits ?? this.benefits,
      isActive: isActive ?? this.isActive,
      isPopular: isPopular ?? this.isPopular,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
    id,
    title,
    amount,
    duration,
    description,
    benefits,
    isActive,
    isPopular,
    createdAt,
    updatedAt,
  ];
}
