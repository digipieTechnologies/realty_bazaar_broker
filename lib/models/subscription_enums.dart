// File: lib/models/subscription_enums.dart
// Purpose: Type-safe enum representing plan billing types (recurring, one_time, custom).

enum PlanBillingType {
  recurring,
  oneTime,
  custom;

  String get dbValue {
    switch (this) {
      case PlanBillingType.recurring:
        return 'recurring';
      case PlanBillingType.oneTime:
        return 'one_time';
      case PlanBillingType.custom:
        return 'custom';
    }
  }

  String get displayName {
    switch (this) {
      case PlanBillingType.recurring:
        return 'Recurring';
      case PlanBillingType.oneTime:
        return 'One-Time';
      case PlanBillingType.custom:
        return 'Custom';
    }
  }

  String get periodDisplay {
    switch (this) {
      case PlanBillingType.recurring:
        return '/month';
      case PlanBillingType.oneTime:
        return 'one-time';
      case PlanBillingType.custom:
        return 'custom';
    }
  }

  static PlanBillingType fromDbValue(dynamic value) {
    if (value == null) return PlanBillingType.recurring;
    if (value is PlanBillingType) return value;
    final str = value.toString().toLowerCase().trim();
    if (str == 'one_time' || str == 'onetime' || str == 'one-time') {
      return PlanBillingType.oneTime;
    }
    if (str == 'custom') {
      return PlanBillingType.custom;
    }
    return PlanBillingType.recurring;
  }
}

/// Backward compatibility alias for SubscriptionDuration
typedef SubscriptionDuration = PlanBillingType;
