// File: lib/modules/dashboard/screens/ad_campaign_settings_screen.dart
// Purpose: Responsive Ad Campaign Settings screen with Gender selection, Target Areas search,
// Targeting Suggestions, Map Banner illustration, Age Range slider, Time Schedule slider, and Supabase integration.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../app/app_assets.dart';
import '../../../app/app_colors.dart';
import '../../../app/app_constants.dart';
import '../../../app/app_text_styles.dart';
import '../../../app/app_utils.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../models/models.dart';
import '../../../providers/auth/auth_provider.dart';
import '../../../providers/campaign/ad_campaign_provider.dart';
import '../../../util/common_ext.dart';
import '../../../widgets/buttons/app_button.dart';
import '../../../widgets/common/app_section_header.dart';
import '../../../widgets/common/common_app_bar.dart';
import '../../../widgets/dialogs/app_dialog.dart';
import '../../../widgets/inputs/age_range_slider_widget.dart';
import '../../../widgets/inputs/app_radio_tile.dart';
import '../../../widgets/inputs/time_schedule_slider_widget.dart';
import '../../../widgets/shimmer/ad_campaign_settings_shimmer_widget.dart';
import '../../../widgets/toast/app_toast.dart';
import '../../campaigns/widgets/target_area_search_widget.dart';
import '../../campaigns/widgets/targeting_suggestions_widget.dart';

class AdCampaignSettingsScreen extends StatefulWidget {
  const AdCampaignSettingsScreen({super.key});

  @override
  State<AdCampaignSettingsScreen> createState() => _AdCampaignSettingsScreenState();
}

class _AdCampaignSettingsScreenState extends State<AdCampaignSettingsScreen> {
  String? _brokerId;

  // Form State
  CampaignGender _gender = CampaignGender.all;
  List<TargetAreaModel> _targetAreas = [];
  List<String> _suggestions = [];
  RangeValues _ageRange = const RangeValues(18, 65);
  RangeValues _timeRange = const RangeValues(6, 24);
  bool _isWholeDay = false;
  bool _isInitialized = false;

  // Initial Snapshot State (for tracking unsaved changes)
  CampaignGender _initialGender = CampaignGender.all;
  List<TargetAreaModel> _initialTargetAreas = [];
  List<String> _initialSuggestions = [];
  RangeValues _initialAgeRange = const RangeValues(18, 65);
  RangeValues _initialTimeRange = const RangeValues(6, 24);
  bool _initialIsWholeDay = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      _brokerId = authProvider.userProfile?.brokerId?.id;

      if (_brokerId != null && _brokerId!.isNotEmpty) {
        final provider = context.read<AdCampaignProvider>();
        provider.fetchCampaignSettings(_brokerId!).then((_) {
          if (mounted) _syncStateFromProvider();
        });
      }
    });
  }

  void _syncStateFromProvider() {
    final provider = context.read<AdCampaignProvider>();
    final settings = provider.settings;
    if (settings != null) {
      setState(() {
        _gender = settings.gender;
        _targetAreas = List<TargetAreaModel>.from(settings.areaDetails);
        _suggestions = List<String>.from(settings.targetingSuggestions);
        _ageRange = RangeValues(
          settings.startAgeRange.toDouble(),
          settings.endAgeRange.toDouble(),
        );

        _isWholeDay = settings.campaignIsAllDay;

        double startH = 6.0;
        double endH = 24.0;
        if (settings.campaignStartTime != null) {
          startH = _parseHourStringToDouble(settings.campaignStartTime!);
        }
        if (settings.campaignEndTime != null) {
          endH = _parseHourStringToDouble(settings.campaignEndTime!);
        }
        _timeRange = RangeValues(startH, endH);

        // Store initial snapshot
        _initialGender = _gender;
        _initialTargetAreas = List<TargetAreaModel>.from(_targetAreas);
        _initialSuggestions = List<String>.from(_suggestions);
        _initialAgeRange = _ageRange;
        _initialTimeRange = _timeRange;
        _initialIsWholeDay = _isWholeDay;

        _isInitialized = true;
      });
    }
  }

  /// Checks if form state matches initial state (returns true if user can back without confirmation)
  bool userCanBack() {
    if (_gender != _initialGender) return false;
    if (_isWholeDay != _initialIsWholeDay) return false;
    if (_ageRange != _initialAgeRange) return false;
    if (!_isWholeDay && _timeRange != _initialTimeRange) return false;

    if (_suggestions.length != _initialSuggestions.length) return false;
    for (int i = 0; i < _suggestions.length; i++) {
      if (_suggestions[i] != _initialSuggestions[i]) return false;
    }

    if (_targetAreas.length != _initialTargetAreas.length) return false;
    for (int i = 0; i < _targetAreas.length; i++) {
      if (_targetAreas[i].fullArea != _initialTargetAreas[i].fullArea) return false;
    }

    return true;
  }

  double _parseHourStringToDouble(String timeStr) {
    try {
      final parts = timeStr.split(':');
      if (parts.isNotEmpty) {
        return double.parse(parts[0]);
      }
    } catch (_) {}
    return 6.0;
  }

  String _formatDoubleToHourString(double hourVal) {
    final int h = hourVal.round();
    return '${h.toString().padLeft(2, '0')}:00';
  }

  Future<void> _handleSaveSettings() async {
    AppUtils.hideKeyboard(context);

    if (_brokerId == null || _brokerId!.isEmpty) {
      AppToast.showError(
        context.tr('toast_action_failed_title'),
        context.tr('error_broker_not_found'),
      );
      return;
    }

    if (_targetAreas.isEmpty) {
      AppToast.showError(
        context.tr('toast_action_failed_title'),
        context.tr('select_target_area_error'),
      );
      return;
    }

    final provider = context.read<AdCampaignProvider>();
    final currentSettings = provider.settings;

    final updatedModel = AdCampaignSettingsModel(
      id: currentSettings?.id,
      brokerId: BrokerModel(id: _brokerId!),
      gender: _gender,
      areaDetails: _targetAreas,
      targetingSuggestions: _suggestions,
      startAgeRange: _ageRange.start.round(),
      endAgeRange: _ageRange.end.round(),
      campaignStartTime: _isWholeDay ? null : _formatDoubleToHourString(_timeRange.start),
      campaignEndTime: _isWholeDay ? null : _formatDoubleToHourString(_timeRange.end),
      campaignIsAllDay: _isWholeDay,
    );

    final success = await provider.saveCampaignSettings(updatedModel);

    if (!mounted) return;

    if (success) {
      _initialGender = _gender;
      _initialTargetAreas = List<TargetAreaModel>.from(_targetAreas);
      _initialSuggestions = List<String>.from(_suggestions);
      _initialAgeRange = _ageRange;
      _initialTimeRange = _timeRange;
      _initialIsWholeDay = _isWholeDay;

      AppToast.showSuccess(
        context.tr('toast_saved_title'),
        context.tr('toast_saved_desc'),
      );
    } else {
      AppToast.showError(
        context.tr('toast_action_failed_title'),
        provider.errorMessage ?? context.tr('save_campaign_failed'),
      );
    }
  }

  Future<bool> _confirmAndPop() async {
    if (userCanBack()) {
      if (mounted) Navigator.of(context).pop();
      return true;
    }

    final confirmed = await AppDialog.showConfirmationDialog(
      context,
      title: context.tr('discard_changes'),
      description: context.tr('discard_changes_desc'),
      type: DialogType.warning,
      confirmText: context.tr('discard'),
      cancelText: context.tr('cancel'),
    );

    if (confirmed == true && mounted) {
      Navigator.of(context).pop();
      return true;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AdCampaignProvider>();
    final isMobile = context.isMobileUI;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        await _confirmAndPop();
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: CommonAppBar(
          title: context.tr('ad_campaign_settings'),
          onBackPressed: _confirmAndPop,
        ),
      body: SafeArea(
        child: provider.isLoading && !_isInitialized
            ? const AdCampaignSettingsShimmerWidget()
            : SingleChildScrollView(
                padding: AppConstants.getTabPadding(context),
                child: Center(
                  child: Container(
                    constraints: BoxConstraints(maxWidth: isMobile ? 600.0 : 900.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Section 1: Gender Selection Radios
                        _buildGenderSection(context),
                        const SizedBox(height: 20.0),

                        // Section 2: Target Areas Autocomplete & Chips
                        TargetAreaSearchWidget(
                          selectedAreas: _targetAreas,
                          onAreasChanged: (newAreas) {
                            setState(() => _targetAreas = newAreas);
                          },
                        ),
                        const SizedBox(height: 20.0),

                        // Section 3: Map Banner Illustration Image
                        _buildMapBannerIllustration(context),
                        const SizedBox(height: 24.0),

                        // Section 4: Targeting Suggestions Text & Tags
                        TargetingSuggestionsWidget(
                          suggestions: _suggestions,
                          onSuggestionsChanged: (newSuggestions) {
                            setState(() => _suggestions = newSuggestions);
                          },
                        ),
                        const SizedBox(height: 24.0),

                        const Divider(height: 1.0, color: AppColors.border),
                        const SizedBox(height: 20.0),

                        // Section 5: Advanced Settings (Age & Time Schedule Sliders)
                        _buildAdvancedSettingsSection(context),
                        const SizedBox(height: 32.0),

                        // Section 6: Primary Save Settings Button
                        AppButton(
                          text: context.tr('save_settings'),
                          height: 50.0,
                          width: double.infinity,
                          borderRadius: 14.0,
                          isLoading: provider.isSaving,
                          onPressed: _handleSaveSettings,
                        ),
                        const SizedBox(height: 24.0),
                      ],
                    ),
                  ),
                ),
              ),
        ),
      ),
    );
  }

  // --- Gender Selection Radios Widget ---
  Widget _buildGenderSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.tr('select_gender'),
          style: AppTextStyles.heading3.copyWith(
            fontSize: 15.0,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 10.0),
        Row(
          children: [
            AppRadioTile(
              isSelected: _gender == CampaignGender.all,
              label: context.tr('gender_all'),
              onTap: () => setState(() => _gender = CampaignGender.all),
            ),
            const SizedBox(width: 24.0),
            AppRadioTile(
              isSelected: _gender == CampaignGender.male,
              label: context.tr('gender_male'),
              onTap: () => setState(() => _gender = CampaignGender.male),
            ),
            const SizedBox(width: 24.0),
            AppRadioTile(
              isSelected: _gender == CampaignGender.female,
              label: context.tr('gender_female'),
              onTap: () => setState(() => _gender = CampaignGender.female),
            ),
          ],
        ),
      ],
    );
  }

  // --- Map Banner Illustration Card ---
  Widget _buildMapBannerIllustration(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 160.0,
      decoration: BoxDecoration(
        color: AppColors.accentTealLight,
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: AppColors.border, width: 1.0),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15.0),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Image.asset(
              AppAssets.mapBanner,
              width: double.infinity,
              height: 160.0,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                // Custom fallback 3D map illustration vector
                return Stack(
                  alignment: Alignment.center,
                  children: [
                    Icon(
                      Icons.map_rounded,
                      size: 80.0,
                      color: AppColors.primary.withValues(alpha: 0.3),
                    ),
                    const Icon(
                      Icons.location_on_rounded,
                      size: 48.0,
                      color: AppColors.accentCoral,
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // --- Advanced Settings Section (Sliders) ---
  Widget _buildAdvancedSettingsSection(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: AppColors.border, width: 1.0),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppSectionHeader(
            title: context.tr('advanced_settings'),
            icon: Icons.tune_rounded,
            padding: EdgeInsets.zero,
          ),
          const SizedBox(height: 20.0),

          // Age Range Slider
          AgeRangeSliderWidget(
            values: _ageRange,
            min: 13.0,
            max: 80.0,
            onChanged: (newValues) {
              setState(() => _ageRange = newValues);
            },
          ),
          const SizedBox(height: 24.0),

          // Time Schedule Slider
          TimeScheduleSliderWidget(
            values: _timeRange,
            isWholeDay: _isWholeDay,
            onChanged: (newValues) {
              setState(() => _timeRange = newValues);
            },
            onWholeDayChanged: (val) {
              setState(() => _isWholeDay = val ?? true);
            },
          ),
        ],
      ),
    );
  }
}
