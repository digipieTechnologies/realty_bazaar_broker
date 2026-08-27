// File: lib/models/subscription_enums.dart
// Purpose: Type-safe enum representing subscription plan duration (month, year, one_time).

enum SubscriptionDuration {
  month,
  year,
  oneTime,
  custom;

  String get dbValue {
    switch (this) {
      case SubscriptionDuration.month:
        return 'month';
      case SubscriptionDuration.year:
        return 'year';
      case SubscriptionDuration.oneTime:
        return 'one_time';
      case SubscriptionDuration.custom:
        return 'custom';
    }
  }

  String get displayName {
    switch (this) {
      case SubscriptionDuration.month:
        return 'Monthly';
      case SubscriptionDuration.year:
        return 'Yearly';
      case SubscriptionDuration.oneTime:
        return 'One-Time';
      case SubscriptionDuration.custom:
        return 'Custom';
    }
  }

  String get periodDisplay {
    switch (this) {
      case SubscriptionDuration.month:
        return '/month';
      case SubscriptionDuration.year:
        return '/year';
      case SubscriptionDuration.oneTime:
        return 'one-time';
      case SubscriptionDuration.custom:
        return 'custom';
    }
  }

  static SubscriptionDuration fromDbValue(dynamic value) {
    if (value == null) return SubscriptionDuration.month;
    if (value is SubscriptionDuration) return value;
    final str = value.toString().toLowerCase().trim();
    if (str == 'year' || str == 'yearly') {
      return SubscriptionDuration.year;
    }
    if (str == 'one_time' || str == 'onetime' || str == 'one-time') {
      return SubscriptionDuration.oneTime;
    }
    if (str == 'custom') {
      return SubscriptionDuration.custom;
    }
    return SubscriptionDuration.month;
  }
}
