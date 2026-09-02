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

  /// Plans with one_time billing type, sorted by price ascending
  List<SubscriptionPlanModel> get oneTimePlans {
    final list = _plans
        .where((p) => p.billingType == PlanBillingType.oneTime)
        .toList();
    list.sort((a, b) => a.amount.compareTo(b.amount));
    return list;
  }

  /// Plans with recurring billing type, sorted by price ascending
  List<SubscriptionPlanModel> get recurringPlans {
    final list = _plans
        .where((p) => p.billingType == PlanBillingType.recurring)
        .toList();
    list.sort((a, b) => a.amount.compareTo(b.amount));
    return list;
  }

  /// Backward compatibility getter for monthlyPlans
  List<SubscriptionPlanModel> get monthlyPlans => recurringPlans;

  /// Plans with custom billing type
  List<SubscriptionPlanModel> get customPlans {
    return _plans
        .where((p) => p.billingType == PlanBillingType.custom)
        .toList();
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
  /// and dynamically sorts them according to billing type and price.
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
      // Primary Sort: Billing type order -> oneTime (0), recurring (1), custom (2)
      // Secondary Sort: Amount ascending
      loadedPlans.sort((a, b) {
        final orderA = _getBillingTypeSortWeight(a.billingType);
        final orderB = _getBillingTypeSortWeight(b.billingType);

        if (orderA != orderB) {
          return orderA.compareTo(orderB);
        }

        return a.amount.compareTo(b.amount);
      });

      _plans = loadedPlans;

      // Default selected plan to Most Popular if available, or first plan
      if (_plans.isNotEmpty && _selectedPlan == null) {
        _selectedPlan = popularPlan ?? _plans.first;
      }

      debugPrint(
        '[SubscriptionProvider] Fetched ${_plans.length} active subscription plans successfully.',
      );
    } catch (e) {
      _errorMessage = 'Failed to load subscription plans: ${e.toString()}';
      debugPrint('[SubscriptionProvider] Error fetching subscription plans: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  int _getBillingTypeSortWeight(PlanBillingType billingType) {
    switch (billingType) {
      case PlanBillingType.oneTime:
        return 0;
      case PlanBillingType.recurring:
        return 1;
      case PlanBillingType.custom:
        return 2;
    }
  }

  Future<bool> processSubscriptionPayment({
    required String brokerId,
    required String subscriptionPlanId,
    required double amount,
    required String paymentId,
    required String paymentProvider,
    required int totalDays,
    required String planCode,
  }) async {
    try {
      final res = await SupabaseConfig.client.rpc(
        'process_subscription_payment',
        params: {
          'p_broker_id': brokerId,
          'p_subscription_plan_id': subscriptionPlanId,
          'p_amount': amount,
          'p_payment_id': paymentId,
          'p_payment_provider': paymentProvider,
          'p_total_days': totalDays,
          'p_plan_code': planCode,
        },
      );

      return res['success'] == true;
    } catch (e) {
      debugPrint('Error processing subscription payment: $e');
      return false;
    }
  }

  /// Fetches the currently running active subscription for a broker using RPC
  Future<UserSubscriptionModel?> fetchActiveBrokerSubscription(
    String brokerId,
  ) async {
    try {
      final res = await SupabaseConfig.client.rpc(
        'get_broker_active_subscription',
        params: {'p_broker_id': brokerId},
      );

      if (res != null) {
        return UserSubscriptionModel.fromJson(res);
      }
      return null;
    } catch (e) {
      debugPrint('Error fetching active broker subscription: $e');
      return null;
    }
  }

  /// Resets state on logout
  void clear() {
    _plans = [];
    _selectedPlan = null;
    _errorMessage = null;
    _isLoading = false;
    notifyListeners();
  }
}
