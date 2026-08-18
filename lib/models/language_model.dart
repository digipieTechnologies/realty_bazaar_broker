// File: lib/models/language_model.dart
// Purpose: Model representation of a supported application language.

class LanguageModel {
  final String code;
  final String name;

  const LanguageModel({
    required this.code,
    required this.name,
  });

  /// Static list of languages supported by the application.
  static const List<LanguageModel> languages = [
    LanguageModel(code: 'en', name: 'English'),
    LanguageModel(code: 'hi', name: 'हिन्दी'),
    LanguageModel(code: 'gu', name: 'ગુજરાતી'),
  ];
}
