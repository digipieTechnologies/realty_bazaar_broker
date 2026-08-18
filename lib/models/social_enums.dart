// File: lib/models/social_enums.dart
// Purpose: Type-safe enum representing social platforms (facebook, instagram, other).

enum SocialPlatform {
  facebook,
  instagram,
  other;

  String get dbValue {
    switch (this) {
      case SocialPlatform.facebook:
        return 'facebook';
      case SocialPlatform.instagram:
        return 'instagram';
      case SocialPlatform.other:
        return 'other';
    }
  }

  String get displayName {
    switch (this) {
      case SocialPlatform.facebook:
        return 'Facebook';
      case SocialPlatform.instagram:
        return 'Instagram';
      case SocialPlatform.other:
        return 'Other';
    }
  }

  static SocialPlatform fromDbValue(dynamic value) {
    if (value == null) return SocialPlatform.other;
    if (value is SocialPlatform) return value;
    final str = value.toString().toLowerCase().trim();
    if (str.isEmpty) return SocialPlatform.other;
    if (str.contains('facebook') || str.contains('fb')) {
      return SocialPlatform.facebook;
    }
    if (str.contains('instagram') || str.contains('insta')) {
      return SocialPlatform.instagram;
    }
    return SocialPlatform.other;
  }
}
