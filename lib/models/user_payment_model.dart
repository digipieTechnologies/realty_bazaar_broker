import 'package:equatable/equatable.dart';

import 'broker_model.dart';
import 'payment_enums.dart';
import 'subscription_plan_model.dart';

class UserPaymentModel extends Equatable {
  static const String tableName = 'user_payments';

  final String id;

  // Mapped as Model objects following project convention
  final BrokerModel? brokerId;
  final SubscriptionPlanModel? subscriptionPlanId;

  final double amount;
  final PaymentPurpose purpose;
  final PaymentStatus status;
  final PaymentProviderEnum paymentProvider; // e.g. razorpay

  final String? paymentId;
  final Map<String, dynamic>? metadata;

  final DateTime createdAt;
  final DateTime updatedAt;

  const UserPaymentModel({
    required this.id,
    this.brokerId,
    this.subscriptionPlanId,
    required this.amount,
    required this.purpose,
    required this.status,
    required this.paymentProvider,
    this.paymentId,
    this.metadata,
    required this.createdAt,
    required this.updatedAt,
  });

  static UserPaymentModel fromJson(dynamic json) {
    if (json is! Map) {
      return UserPaymentModel(
        id: json?.toString() ?? '',
        amount: 0.0,
        purpose: PaymentPurpose.buySubscription,
        status: PaymentStatus.pending,
        paymentProvider: PaymentProviderEnum.razorpay,
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

    return UserPaymentModel(
      id: json['id']?.toString() ?? '',
      brokerId: parsedBroker,
      subscriptionPlanId: parsedPlan,
      amount: double.tryParse(json['amount']?.toString() ?? '0') ?? 0.0,
      purpose: PaymentPurpose.fromDbValue(json['purpose']),
      status: PaymentStatus.fromDbValue(json['status']),
      paymentProvider: PaymentProviderEnum.fromDbValue(json['payment_provider']),
      paymentId: json['payment_id']?.toString(),
      metadata: json['metadata'] as Map<String, dynamic>?,
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at'].toString()) : DateTime.now(),
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at'].toString()) : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      'id': id,
      'broker_id': brokerId?.id,
      'subscription_plan_id': subscriptionPlanId?.id,
      'amount': amount,
      'purpose': purpose.dbValue,
      'status': status.dbValue,
      'payment_provider': paymentProvider.dbValue,
      'payment_id': paymentId,
      'metadata': metadata,
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
    subscriptionPlanId,
    amount,
    purpose,
    status,
    paymentProvider,
    paymentId,
    metadata,
    createdAt,
    updatedAt,
  ];
}
