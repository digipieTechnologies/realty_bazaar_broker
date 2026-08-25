// File: lib/providers/campaign/ad_campaign_provider.dart
// Purpose: State management provider for loading, editing, saving Ad Campaign Settings,
// and invoking the search-target-areas Supabase Edge Function for location autocomplete.

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/services/clarity_service.dart';

import '../../models/models.dart';

class AdCampaignProvider extends ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;

  AdCampaignSettingsModel? _settings;
  bool _isLoading = false;
  bool _isSaving = false;
  bool _isSearchingAreas = false;
  List<TargetAreaModel> _areaSearchResults = [];
  String? _errorMessage;

  AdCampaignSettingsModel? get settings => _settings;
  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  bool get isSearchingAreas => _isSearchingAreas;
  List<TargetAreaModel> get areaSearchResults => _areaSearchResults;
  String? get errorMessage => _errorMessage;

  /// Fetches existing campaign settings for a given broker ID from Supabase
  Future<void> fetchCampaignSettings(String brokerId) async {
    if (brokerId.isEmpty) return;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _supabase
          .from('ad_campaign_settings')
          .select('*')
          .eq('broker_id', brokerId)
          .maybeSingle();

      if (response != null) {
        _settings = AdCampaignSettingsModel.fromJson(response);
      } else {
        // Initialize default campaign settings for the broker
        _settings = AdCampaignSettingsModel(
          brokerId: BrokerModel(id: brokerId),
          gender: CampaignGender.all,
          areaDetails: const [],
          targetingSuggestions: const [],
          startAgeRange: 18,
          endAgeRange: 65,
          campaignStartTime: null,
          campaignEndTime: null,
          campaignIsAllDay: false,
        );
      }
    } catch (e) {
      debugPrint('[AdCampaignProvider] fetchCampaignSettings error: $e');
      _errorMessage = 'Failed to load campaign settings: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Saves or updates campaign settings in Supabase
  Future<bool> saveCampaignSettings(AdCampaignSettingsModel updatedSettings) async {
    _isSaving = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final payload = updatedSettings.toJson();

      final response = await _supabase
          .from('ad_campaign_settings')
          .upsert(payload, onConflict: 'broker_id')
          .select('*')
          .single();

      _settings = AdCampaignSettingsModel.fromJson(response);
      ClarityService.instance.sendCustomEvent('feature_save_ad_campaign_settings');
      _isSaving = false;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('[AdCampaignProvider] saveCampaignSettings error: $e');
      _errorMessage = e.toString();
      _isSaving = false;
      notifyListeners();
      return false;
    }
  }

  /// Searches target locations using the search-target-areas Edge Function
  Future<List<TargetAreaModel>> searchTargetAreas(String query) async {
    if (query.trim().isEmpty) {
      _areaSearchResults = [];
      notifyListeners();
      return [];
    }

    _isSearchingAreas = true;
    notifyListeners();

    try {
      final response = await _supabase.functions.invoke(
        'search-target-areas',
        body: {'query': query.trim()},
      );

      if (response.status == 200 && response.data != null) {
        final Map<String, dynamic> body = response.data is Map
            ? Map<String, dynamic>.from(response.data as Map)
            : {};
        final List list = body['data'] as List? ?? [];

        _areaSearchResults = list
            .map((e) => TargetAreaModel.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList();
      } else {
        _areaSearchResults = [];
      }
    } catch (e) {
      debugPrint('[AdCampaignProvider] searchTargetAreas Edge function error: $e');
      _areaSearchResults = [];
    } finally {
      _isSearchingAreas = false;
      notifyListeners();
    }

    return _areaSearchResults;
  }

  void clearSearchResults() {
    _areaSearchResults = [];
    notifyListeners();
  }
}
