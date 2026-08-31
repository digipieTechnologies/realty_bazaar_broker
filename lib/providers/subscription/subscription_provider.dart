// File: lib/providers/subscription/subscription_provider.dart
// Purpose: Provider managing subscription plans fetched dynamically from Supabase database with smart sorting.

import 'package:flutter/material.dart';

import '../../core/supabase/supabase_config.dart';
import '../../models/models.dart';

class SubscriptionProvider extends ChangeNotifier {
  List<SubscriptionPlanModel> _plans = [];
  List<SubscriptionPlanModel> get plans => _plans;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  SubscriptionPlanModel? _selectedPlan;
  SubscriptionPlanModel? get selectedPlan => _selectedPlan;

  void setSelectedPlan(SubscriptionPlanModel? plan) {
    _selectedPlan = plan;
    notifyListeners();
  }

  /// Plans with one_time duration, sorted by price ascending
  List<SubscriptionPlanModel> get oneTimePlans {
    final list = _plans.where((p) => p.duration == SubscriptionDuration.oneTime).toList();
    list.sort((a, b) => a.amount.compareTo(b.amount));
    return list;
  }

  /// Plans with monthly duration, sorted by price ascending
  List<SubscriptionPlanModel> get monthlyPlans {
    final list = _plans.where((p) => p.duration == SubscriptionDuration.month).toList();
    list.sort((a, b) => a.amount.compareTo(b.amount));
    return list;
  }

  /// Plans with yearly duration, sorted by price ascending
  List<SubscriptionPlanModel> get yearlyPlans {
    final list = _plans.where((p) => p.duration == SubscriptionDuration.year).toList();
    list.sort((a, b) => a.amount.compareTo(b.amount));
    return list;
  }

  /// Plans with custom duration
  List<SubscriptionPlanModel> get customPlans {
    return _plans.where((p) => p.duration == SubscriptionDuration.custom).toList();
  }

  /// Returns the designated Most Popular plan if available
  SubscriptionPlanModel? get popularPlan {
    try {
      return _plans.firstWhere((p) => p.isPopular);
    } catch (_) {
      return null;
    }
  }

  /// Fetches all active subscription plans from Supabase subscription_plans table
  /// and dynamically sorts them according to duration type and price.
  Future<void> fetchActiveSubscriptionPlans() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await SupabaseConfig.client
          .from(SubscriptionPlanModel.tableName)
          .select()
          .eq('is_active', true);

      final List<SubscriptionPlanModel> loadedPlans = (response as List)
          .map((item) => SubscriptionPlanModel.fromJson(item))
          .toList();

      // Dynamic sorting logic:
      // Primary Sort: Duration order -> oneTime (0), month (1), year (2), custom (3)
      // Secondary Sort: Amount ascending
      loadedPlans.sort((a, b) {
        final durationOrderA = _getDurationSortWeight(a.duration);
        final durationOrderB = _getDurationSortWeight(b.duration);

        if (durationOrderA != durationOrderB) {
          return durationOrderA.compareTo(durationOrderB);
        }

        return a.amount.compareTo(b.amount);
      });

      _plans = loadedPlans;

      // Default selected plan to Most Popular if available, or first plan
      if (_plans.isNotEmpty && _selectedPlan == null) {
        _selectedPlan = popularPlan ?? _plans.first;
      }

      debugPrint('[SubscriptionProvider] Fetched ${_plans.length} active subscription plans successfully.');
    } catch (e) {
      _errorMessage = 'Failed to load subscription plans: ${e.toString()}';
      debugPrint('[SubscriptionProvider] Error fetching subscription plans: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  int _getDurationSortWeight(SubscriptionDuration duration) {
    switch (duration) {
      case SubscriptionDuration.oneTime:
        return 0;
      case SubscriptionDuration.month:
        return 1;
      case SubscriptionDuration.year:
        return 2;
      case SubscriptionDuration.custom:
        return 3;
    }
  }
}
