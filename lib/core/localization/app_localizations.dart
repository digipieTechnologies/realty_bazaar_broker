// File: lib/core/localization/app_localizations.dart
// Purpose: Custom JSON-based localization system with key-value translate lookup and BuildContext extension.

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppLocalizations {
  final Locale locale;
  AppLocalizations(this.locale);

  /// Helper method to keep code clean
  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  /// Static delegate instance
  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  late Map<String, String> _localizedStrings;

  /// Loads the localized JSON assets matching the active language code
  Future<bool> load() async {
    try {
      String jsonString = await rootBundle.loadString(
        'assets/lang/${locale.languageCode}.json',
      );
      Map<String, dynamic> jsonMap = json.decode(jsonString);

      _localizedStrings = jsonMap.map((key, value) {
        return MapEntry(key, value.toString());
      });
      return true;
    } catch (e) {
      debugPrint('Error loading language file: $e');
      _localizedStrings = {};
      return false;
    }
  }

  /// Looks up translation for [key] with support for argument replacements
  String translate(String key, {Map<String, String>? arguments}) {
    String value = _localizedStrings[key] ?? key;
    if (arguments != null) {
      arguments.forEach((argKey, argVal) {
        value = value.replaceAll('{$argKey}', argVal);
      });
    }
    return value;
  }
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return ['en', 'hi', 'gu'].contains(locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) async {
    AppLocalizations localizations = AppLocalizations(locale);
    await localizations.load();
    return localizations;
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

/// Helper extension on BuildContext to translate keys easily
extension LocalizationExtension on BuildContext {
  String tr(String key, {Map<String, String>? arguments}) {
    return AppLocalizations.of(this)?.translate(key, arguments: arguments) ??
        key;
  }
}
