// File: lib/app/app_strings.dart
// Purpose: Centralized UI string constants.

class AppStrings {
  AppStrings._();

  // App Level
  static const String appName = 'The Realty Bazaar';
  static const String appVersion = '1.0.0';

  // Splash & Onboarding Placeholder
  static const String welcome = 'Welcome to Broker CRM';
  static const String loadingConfig = 'Initializing configuration and services...';

  // Common UI Button Text
  static const String ok = 'OK';
  static const String cancel = 'Cancel';
  static const String confirm = 'Confirm';
  static const String save = 'Save';
  static const String delete = 'Delete';
  static const String close = 'Close';
  static const String loading = 'Loading...';

  // Validation messages
  static const String emailRequired = 'Email address is required.';
  static const String invalidEmail = 'Please enter a valid email address.';
  static const String phoneRequired = 'Phone number is required.';
  static const String invalidPhone = 'Please enter a valid phone number.';
  static const String fieldRequired = 'This field is required.';

  // Error States
  static const String errorGeneric = 'Something went wrong. Please try again.';
  static const String errorNetwork = 'Network connection issue. Check your internet.';
  static const String errorTimeout = 'Request timed out. Please try again.';

  // Placeholder Screens
  static const String dashboardTitle = 'Broker Flow Dashboard';
  static const String dashboardSubtitle = 'Your reusable CRM architecture components';
}
