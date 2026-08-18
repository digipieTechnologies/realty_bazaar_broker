// File: lib/models/country_code.dart
// Purpose: Country dial codes and validation requirements for formatting phone inputs.

class CountryCode {
  final String name;
  final String code;
  final String flag;
  final int minLength;
  final int maxLength;
  final RegExp validationPattern;

  const CountryCode({
    required this.name,
    required this.code,
    required this.flag,
    required this.minLength,
    required this.maxLength,
    required this.validationPattern,
  });

  /// Common countries list supported out-of-the-box
  static final List<CountryCode> countries = [
    CountryCode(
      name: 'India',
      code: '+91',
      flag: '🇮🇳',
      minLength: 10,
      maxLength: 10,
      validationPattern: RegExp(r'^[6-9]\d{9}$'),
    ),
    CountryCode(
      name: 'United States',
      code: '+1',
      flag: '🇺🇸',
      minLength: 10,
      maxLength: 10,
      validationPattern: RegExp(r'^\d{10}$'),
    ),
    CountryCode(
      name: 'United Kingdom',
      code: '+44',
      flag: '🇬🇧',
      minLength: 10,
      maxLength: 10,
      validationPattern: RegExp(r'^\d{10}$'),
    ),
    CountryCode(
      name: 'United Arab Emirates',
      code: '+971',
      flag: '🇦🇪',
      minLength: 9,
      maxLength: 9,
      validationPattern: RegExp(r'^\d{9}$'),
    ),
    CountryCode(
      name: 'Canada',
      code: '+1',
      flag: '🇨🇦',
      minLength: 10,
      maxLength: 10,
      validationPattern: RegExp(r'^\d{10}$'),
    ),
    CountryCode(
      name: 'Australia',
      code: '+61',
      flag: '🇦🇺',
      minLength: 9,
      maxLength: 9,
      validationPattern: RegExp(r'^\d{9}$'),
    ),
    CountryCode(
      name: 'Singapore',
      code: '+65',
      flag: '🇸🇬',
      minLength: 8,
      maxLength: 8,
      validationPattern: RegExp(r'^\d{8}$'),
    ),
  ];
}
