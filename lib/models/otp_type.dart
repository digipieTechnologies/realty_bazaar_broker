// File: lib/models/otp_type.dart
// Purpose: Type-safe enum representing OTP types (email_verify, forgot_password, change_password) for Supabase database sync.

enum AppOtpType {
  emailVerify('email_verify'),
  forgotPassword('forgot_password'),
  changePassword('change_password');

  final String dbValue;
  const AppOtpType(this.dbValue);

  String get displayName {
    switch (this) {
      case AppOtpType.emailVerify:
        return 'Email Verification';
      case AppOtpType.forgotPassword:
        return 'Forgot Password';
      case AppOtpType.changePassword:
        return 'Change Password';
    }
  }

  static AppOtpType fromDbValue(dynamic value) {
    if (value is AppOtpType) return value;
    final str = value?.toString().toLowerCase().trim();
    switch (str) {
      case 'forgot_password':
      case 'forgotpassword':
        return AppOtpType.forgotPassword;
      case 'change_password':
      case 'changepassword':
        return AppOtpType.changePassword;
      case 'email_verify':
      case 'emailverify':
      default:
        return AppOtpType.emailVerify;
    }
  }

  static AppOtpType? tryFromDbValue(dynamic value) {
    if (value == null) return null;
    return fromDbValue(value);
  }
}
