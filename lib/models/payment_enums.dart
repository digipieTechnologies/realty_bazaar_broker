// File: lib/models/payment_enums.dart
// Purpose: Type-safe enums for user payment records.

enum PaymentPurpose {
  buySubscription;

  String get dbValue {
    switch (this) {
      case PaymentPurpose.buySubscription:
        return 'buy_subscription';
    }
  }

  String get displayName {
    switch (this) {
      case PaymentPurpose.buySubscription:
        return 'Subscription Purchase';
    }
  }

  static PaymentPurpose fromDbValue(dynamic value) {
    if (value == null) return PaymentPurpose.buySubscription;
    if (value is PaymentPurpose) return value;
    final str = value.toString().toLowerCase().trim();
    if (str == 'buy_subscription') {
      return PaymentPurpose.buySubscription;
    }
    return PaymentPurpose.buySubscription; // default fallback
  }
}

enum PaymentStatus {
  pending,
  completed,
  failed,
  cancelled;

  String get dbValue {
    switch (this) {
      case PaymentStatus.pending:
        return 'pending';
      case PaymentStatus.completed:
        return 'completed';
      case PaymentStatus.failed:
        return 'failed';
      case PaymentStatus.cancelled:
        return 'cancelled';
    }
  }

  String get displayName {
    switch (this) {
      case PaymentStatus.pending:
        return 'Pending';
      case PaymentStatus.completed:
        return 'Completed';
      case PaymentStatus.failed:
        return 'Failed';
      case PaymentStatus.cancelled:
        return 'Cancelled';
    }
  }

  static PaymentStatus fromDbValue(dynamic value) {
    if (value == null) return PaymentStatus.pending;
    if (value is PaymentStatus) return value;
    final str = value.toString().toLowerCase().trim();
    if (str == 'completed') {
      return PaymentStatus.completed;
    } else if (str == 'failed') {
      return PaymentStatus.failed;
    } else if (str == 'cancelled') {
      return PaymentStatus.cancelled;
    }
    return PaymentStatus.pending; // default fallback
  }
}

enum PaymentProviderEnum {
  razorpay,
  inAppPurchase;

  String get dbValue {
    switch (this) {
      case PaymentProviderEnum.razorpay:
        return 'razorpay';
      case PaymentProviderEnum.inAppPurchase:
        return 'in_app_purchase';
    }
  }

  String get displayName {
    switch (this) {
      case PaymentProviderEnum.razorpay:
        return 'Razorpay';
      case PaymentProviderEnum.inAppPurchase:
        return 'In-App Purchase';
    }
  }

  static PaymentProviderEnum fromDbValue(dynamic value) {
    if (value == null) return PaymentProviderEnum.razorpay;
    if (value is PaymentProviderEnum) return value;
    final str = value.toString().toLowerCase().trim();
    if (str == 'in_app_purchase' || str == 'inapppurchase') {
      return PaymentProviderEnum.inAppPurchase;
    }
    return PaymentProviderEnum.razorpay; // default fallback
  }
}
