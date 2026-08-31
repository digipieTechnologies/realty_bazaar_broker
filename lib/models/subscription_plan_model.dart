// File: lib/models/subscription_plan_model.dart
// Purpose: Model class representing subscription plans in database (Supabase subscription_plans table) with duration options support.

import 'package:equatable/equatable.dart';
import 'subscription_enums.dart';

class PlanDurationOption extends Equatable {
  final String code;
  final double amount;
  final int days;
  final String title;

  const PlanDurationOption({
    this.code = '',
    this.amount = 0.0,
    this.days = 30,
    this.title = '',
  });

  static PlanDurationOption fromJson(dynamic json) {
    if (json is! Map) {
      return const PlanDurationOption();
    }
    return PlanDurationOption(
      code: json['code']?.toString() ?? '',
      amount: double.tryParse(json['amount']?.toString() ?? '0') ?? 0.0,
      days: int.tryParse(json['days']?.toString() ?? '30') ?? 30,
      title: json['title']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'code': code,
      'amount': amount,
      'days': days,
      if (title.isNotEmpty) 'title': title,
    };
  }

  @override
  List<Object?> get props => [code, amount, days, title];
}

class SubscriptionPlanModel extends Equatable {
  static const String tableName = 'subscription_plans';

  final String? id;
  final String title;
  final double amount;
  final PlanBillingType billingType;
  final String description;
  final List<String> benefits;
  final List<PlanDurationOption> durationOptions;
  final bool isActive;
  final bool isPopular;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  /// Backward compatibility getter for duration
  PlanBillingType get duration => billingType;

  const SubscriptionPlanModel({
    this.id,
    this.title = '',
    this.amount = 0.0,
    this.billingType = PlanBillingType.recurring,
    this.description = '',
    this.benefits = const [],
    this.durationOptions = const [],
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
      parsedBenefits = (json['benefits'] as List)
          .map((e) => e.toString())
          .toList();
    }

    List<PlanDurationOption> parsedDurationOptions = [];
    if (json['duration_options'] != null && json['duration_options'] is List) {
      parsedDurationOptions = (json['duration_options'] as List)
          .map((e) => PlanDurationOption.fromJson(e))
          .toList();
    }

    return SubscriptionPlanModel(
      id: json['id']?.toString(),
      title: json['title']?.toString() ?? '',
      amount: double.tryParse(json['amount']?.toString() ?? '0') ?? 0.0,
      billingType: PlanBillingType.fromDbValue(json['billing_type'] ?? json['duration']),
      description: json['description']?.toString() ?? '',
      benefits: parsedBenefits,
      durationOptions: parsedDurationOptions,
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
    data['billing_type'] = billingType.dbValue;
    data['description'] = description;
    data['benefits'] = benefits;
    data['duration_options'] = durationOptions.map((e) => e.toJson()).toList();
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
    PlanBillingType? billingType,
    PlanBillingType? duration,
    String? description,
    List<String>? benefits,
    List<PlanDurationOption>? durationOptions,
    bool? isActive,
    bool? isPopular,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return SubscriptionPlanModel(
      id: id ?? this.id,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      billingType: billingType ?? duration ?? this.billingType,
      description: description ?? this.description,
      benefits: benefits ?? this.benefits,
      durationOptions: durationOptions ?? this.durationOptions,
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
        billingType,
        description,
        benefits,
        durationOptions,
        isActive,
        isPopular,
        createdAt,
        updatedAt,
      ];
}
