// File: lib/models/campaign_enums.dart
// Purpose: Type-safe enums representing target gender selection (all, male, female) for Ad Campaign Settings.

enum CampaignGender {
  all('all'),
  male('male'),
  female('female');

  final String dbValue;

  const CampaignGender(this.dbValue);

  String get labelKey {
    switch (this) {
      case CampaignGender.all:
        return 'gender_all';
      case CampaignGender.male:
        return 'gender_male';
      case CampaignGender.female:
        return 'gender_female';
    }
  }

  static CampaignGender fromDbValue(dynamic value) {
    if (value is CampaignGender) return value;
    final valStr = value?.toString().toLowerCase().trim() ?? '';
    switch (valStr) {
      case 'male':
        return CampaignGender.male;
      case 'female':
        return CampaignGender.female;
      case 'all':
      default:
        return CampaignGender.all;
    }
  }

  static CampaignGender? tryFromDbValue(dynamic value) {
    if (value == null) return null;
    return fromDbValue(value);
  }
}
