// File: lib/models/user_enums.dart
// Purpose: Type-safe enums representing user role (super_admin, broker, marketing) and gender (male, female, other) for Supabase database sync.

enum UserRole {
  superAdmin('super_admin'),
  broker('broker'),
  marketing('marketing');

  final String dbValue;
  const UserRole(this.dbValue);

  String get displayName {
    switch (this) {
      case UserRole.superAdmin:
        return 'Super Admin';
      case UserRole.broker:
        return 'Broker';
      case UserRole.marketing:
        return 'Marketing';
    }
  }

  static UserRole fromDbValue(dynamic value) {
    if (value is UserRole) return value;
    final str = value?.toString().toLowerCase().trim();
    switch (str) {
      case 'super_admin':
      case 'superadmin':
      case 'admin':
        return UserRole.superAdmin;
      case 'marketing':
      case 'ads':
        return UserRole.marketing;
      case 'broker':
      default:
        return UserRole.broker;
    }
  }

  static UserRole? tryFromDbValue(dynamic value) {
    if (value == null) return null;
    return fromDbValue(value);
  }
}

enum UserGender {
  male('male'),
  female('female'),
  other('other');

  final String dbValue;
  const UserGender(this.dbValue);

  String get displayName {
    switch (this) {
      case UserGender.male:
        return 'Male';
      case UserGender.female:
        return 'Female';
      case UserGender.other:
        return 'Other';
    }
  }

  static UserGender fromDbValue(dynamic value) {
    if (value is UserGender) return value;
    final str = value?.toString().toLowerCase().trim();
    switch (str) {
      case 'male':
      case 'm':
        return UserGender.male;
      case 'female':
      case 'f':
        return UserGender.female;
      case 'other':
      default:
        return UserGender.other;
    }
  }

  static UserGender? tryFromDbValue(dynamic value) {
    if (value == null) return null;
    return fromDbValue(value);
  }
}
