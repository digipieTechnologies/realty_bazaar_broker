// File: lib/providers/language/language_provider.dart
// Purpose: Dynamic language state management with SharedPreferences persistence.

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageProvider extends ChangeNotifier {
  static const String _prefLanguageKey = 'selected_language_code';
  Locale _locale = const Locale('en');

  Locale get locale => _locale;

  LanguageProvider() {
    _loadLanguage();
  }

  /// Loads the cached language code from SharedPreferences. Defaults to 'en'.
  Future<void> _loadLanguage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? languageCode = prefs.getString(_prefLanguageKey);
      if (languageCode != null) {
        _locale = Locale(languageCode);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Failed to load language: $e');
    }
  }

  /// Updates the active Locale and persists preference in SharedPreferences.
  Future<void> setLanguage(String languageCode) async {
    if (_locale.languageCode == languageCode) return;

    _locale = Locale(languageCode);
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefLanguageKey, languageCode);
    } catch (e) {
      debugPrint('Failed to save language: $e');
    }
  }
}
