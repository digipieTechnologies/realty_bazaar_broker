import 'package:equatable/equatable.dart';

import 'broker_model.dart';
import 'subscription_plan_model.dart';
import 'user_payment_model.dart';

class UserSubscriptionModel extends Equatable {
  static const String tableName = 'user_subscriptions';

  final String id;

  // Mapped as Model objects following project convention
  final BrokerModel? brokerId;
  final UserPaymentModel? paymentId;
  final SubscriptionPlanModel? subscriptionPlanId;

  final DateTime startDate;
  final DateTime endDate;
  final bool isExpired;
  final int totalDays;
  final double amount;
  final String planCode;

  final DateTime createdAt;
  final DateTime updatedAt;

  const UserSubscriptionModel({
    required this.id,
    this.brokerId,
    this.paymentId,
    this.subscriptionPlanId,
    required this.startDate,
    required this.endDate,
    this.isExpired = false,
    required this.totalDays,
    required this.amount,
    required this.planCode,
    required this.createdAt,
    required this.updatedAt,
  });

  static UserSubscriptionModel fromJson(dynamic json) {
    if (json is! Map) {
      return UserSubscriptionModel(
        id: json?.toString() ?? '',
        startDate: DateTime.now(),
        endDate: DateTime.now(),
        totalDays: 0,
        amount: 0.0,
        planCode: '',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    }

    BrokerModel? parsedBroker;
    if (json['broker_id'] != null && json['broker_id'] is Map<String, dynamic>) {
      parsedBroker = BrokerModel.fromJson(json['broker_id']);
    } else if (json['brokers'] != null) {
      if (json['brokers'] is Map<String, dynamic>) {
        parsedBroker = BrokerModel.fromJson(json['brokers']);
      } else if (json['brokers'] is List && json['brokers'].isNotEmpty) {
        parsedBroker = BrokerModel.fromJson(json['brokers'][0]);
      }
    } else if (json['broker_id'] != null) {
      parsedBroker = BrokerModel(id: json['broker_id'].toString(), businessName: '', brokerCode: '');
    }

    UserPaymentModel? parsedPayment;
    if (json['payment_id'] != null && json['payment_id'] is Map<String, dynamic>) {
      parsedPayment = UserPaymentModel.fromJson(json['payment_id']);
    } else if (json['user_payments'] != null) {
      if (json['user_payments'] is Map<String, dynamic>) {
        parsedPayment = UserPaymentModel.fromJson(json['user_payments']);
      } else if (json['user_payments'] is List && json['user_payments'].isNotEmpty) {
        parsedPayment = UserPaymentModel.fromJson(json['user_payments'][0]);
      }
    } else if (json['payment_id'] != null) {
      parsedPayment = UserPaymentModel.fromJson({'id': json['payment_id']});
    }

    SubscriptionPlanModel? parsedPlan;
    if (json['subscription_plan_id'] != null && json['subscription_plan_id'] is Map<String, dynamic>) {
      parsedPlan = SubscriptionPlanModel.fromJson(json['subscription_plan_id']);
    } else if (json['subscription_plans'] != null) {
      if (json['subscription_plans'] is Map<String, dynamic>) {
        parsedPlan = SubscriptionPlanModel.fromJson(json['subscription_plans']);
      } else if (json['subscription_plans'] is List && json['subscription_plans'].isNotEmpty) {
        parsedPlan = SubscriptionPlanModel.fromJson(json['subscription_plans'][0]);
      }
    } else if (json['subscription_plan_id'] != null) {
      parsedPlan = SubscriptionPlanModel(
        id: json['subscription_plan_id'].toString(),
        title: '',
        description: '',
        amount: 0,
      );
    }

    return UserSubscriptionModel(
      id: json['id']?.toString() ?? '',
      brokerId: parsedBroker,
      paymentId: parsedPayment,
      subscriptionPlanId: parsedPlan,
      startDate: json['start_date'] != null ? DateTime.parse(json['start_date'].toString()) : DateTime.now(),
      endDate: json['end_date'] != null ? DateTime.parse(json['end_date'].toString()) : DateTime.now(),
      isExpired: json['is_expired'] as bool? ?? false,
      totalDays: int.tryParse(json['total_days']?.toString() ?? '0') ?? 0,
      amount: double.tryParse(json['amount']?.toString() ?? '0') ?? 0.0,
      planCode: json['plan_code']?.toString() ?? '',
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at'].toString()) : DateTime.now(),
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at'].toString()) : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      'id': id,
      'broker_id': brokerId?.id,
      'payment_id': paymentId?.id,
      'subscription_plan_id': subscriptionPlanId?.id,
      'start_date': startDate.toIso8601String(),
      'end_date': endDate.toIso8601String(),
      'is_expired': isExpired,
      'total_days': totalDays,
      'amount': amount,
      'plan_code': planCode,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };

    // Remove nulls before sending to database
    data.removeWhere((key, value) => value == null);

    return data;
  }

  @override
  List<Object?> get props => [
    id,
    brokerId,
    paymentId,
    subscriptionPlanId,
    startDate,
    endDate,
    isExpired,
    totalDays,
    amount,
    planCode,
    createdAt,
    updatedAt,
  ];
}
