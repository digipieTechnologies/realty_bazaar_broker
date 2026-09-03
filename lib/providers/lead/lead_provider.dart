// File: lib/providers/lead/lead_provider.dart
// Purpose: Handles paginated social leads fetching via get_social_leads RPC, platform array filtering, search, and smart real-time database subscriptions without UI flickering.

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/supabase/supabase_config.dart';
import '../../models/lead_status_enum.dart';
import '../../models/social_lead_model.dart';

class LeadProvider extends ChangeNotifier {
  bool _isLoading = false;

  bool get isLoading => _isLoading;

  List<SocialLeadModel> _leads = [];

  List<SocialLeadModel> get leads => _leads;

  int _currentPage = 1;

  int get currentPage => _currentPage;

  final int _itemsPerPage = 10;

  int get itemsPerPage => _itemsPerPage;

  int _totalItems = 0;

  int get totalItems => _totalItems;

  int _totalPages = 1;

  int get totalPages => _totalPages;

  bool _hasMore = false;

  bool get hasMore => _hasMore;

  String _searchQuery = '';

  String get searchQuery => _searchQuery;

  List<String> _platformsFilter = []; // Empty = All platforms, or ['facebook'], ['instagram'], ['other']
  List<String> get platformsFilter => _platformsFilter;

  LeadStatus? _statusFilter;
  LeadStatus? get statusFilter => _statusFilter;

  String? _errorMessage;

  String? get errorMessage => _errorMessage;

  RealtimeChannel? _leadSubscription;
  String? _currentBrokerId;

  /// Update platform filters list (e.g., ['facebook'], ['instagram'], ['other'], or [] for all)
  void setPlatformsFilter(List<String> platforms, {String? brokerId}) {
    _platformsFilter = List<String>.from(platforms);
    notifyListeners();
    fetchLeads(brokerId: brokerId ?? _currentBrokerId, page: 1, searchQuery: _searchQuery);
  }

  /// Update status filter (LeadStatus.active, inactive, junk, or null for all)
  void setStatusFilter(LeadStatus? status, {String? brokerId}) {
    _statusFilter = status;
    notifyListeners();
    fetchLeads(brokerId: brokerId ?? _currentBrokerId, page: 1, searchQuery: _searchQuery);
  }

  /// Single platform helper for tab selection ('all', 'facebook', 'instagram', 'other')
  void setFilter(String newFilter, {String? brokerId}) {
    if (newFilter == 'all' || newFilter.isEmpty) {
      _platformsFilter = [];
    } else {
      _platformsFilter = [newFilter];
    }
    notifyListeners();
    fetchLeads(brokerId: brokerId ?? _currentBrokerId, page: 1, searchQuery: _searchQuery);
  }

  /// Get current single filter string for UI tabs
  String get filter {
    if (_platformsFilter.isEmpty) return 'all';
    if (_platformsFilter.length == 1) return _platformsFilter.first;
    return 'all';
  }

  /// Fetch paginated leads from Supabase get_social_leads RPC.
  /// Pass [isSilent: true] for realtime background updates so the screen updates smoothly without showing shimmer loaders.
  Future<void> fetchLeads({
    String? brokerId,
    int page = 1,
    String searchQuery = '',
    LeadStatus? status,
    bool isSilent = false,
  }) async {
    if (!isSilent) {
      _isLoading = true;
      notifyListeners();
    }
    _currentPage = page;
    _searchQuery = searchQuery;
    if (status != null) {
      _statusFilter = status;
    }
    _errorMessage = null;
    if (brokerId != null && brokerId.isNotEmpty) {
      _currentBrokerId = brokerId;
    }

    try {
      final response = await SupabaseConfig.client.rpc(
        'get_social_leads',
        params: {
          'p_broker_id': brokerId ?? _currentBrokerId,
          'p_page': page,
          'p_limit': _itemsPerPage,
          'p_search_query': searchQuery,
          'p_platforms': _platformsFilter.isEmpty ? null : _platformsFilter,
          'p_status': _statusFilter?.apiValue,
        },
      );

      if (response != null) {
        final Map<String, dynamic> resMap = response is Map<String, dynamic> ? response : {};

        if (resMap['success'] == true && resMap['data'] is List) {
          final rawList = resMap['data'] as List;
          _leads = rawList.map((json) => SocialLeadModel.fromJson(json)).toList();

          final pagination = resMap['pagination'] as Map<String, dynamic>? ?? {};
          _totalItems = int.tryParse(pagination['total_items']?.toString() ?? '0') ?? _leads.length;
          _totalPages = int.tryParse(pagination['total_pages']?.toString() ?? '1') ?? 1;
          _hasMore = pagination['has_more'] as bool? ?? false;
          _isLoading = false;
          _errorMessage = null;
          notifyListeners();
          return;
        }
      }
      _errorMessage = 'Failed to fetch leads.';
    } catch (e) {
      debugPrint('[LeadProvider] Error calling get_social_leads RPC: $e');
      _errorMessage = e.toString();
    }

    if (!isSilent) {
      _leads = [];
      _totalItems = 0;
      _totalPages = 1;
      _hasMore = false;
    }
    _isLoading = false;
    notifyListeners();
  }

  /// Subscribe to social_leads table real-time changes for current broker smartly
  void subscribeToLeads(String brokerId) {
    if (brokerId.isEmpty) return;
    _currentBrokerId = brokerId;

    // Avoid duplicating channels if already subscribed to the same broker
    if (_leadSubscription != null) {
      return;
    }

    _leadSubscription = SupabaseConfig.client
        .channel('social_leads_broker_$brokerId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'social_leads',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'broker_id',
            value: brokerId,
          ),
          callback: (payload) {
            debugPrint(
              '[LeadProvider] Smart Realtime change event (${payload.eventType}) for broker: $brokerId',
            );
            fetchLeads(
              brokerId: _currentBrokerId,
              page: _currentPage,
              searchQuery: _searchQuery,
              isSilent: true,
            );
          },
        );

    _leadSubscription!.subscribe();
  }

  /// Fetches a single lead by its ID
  Future<SocialLeadModel?> fetchLeadById(String leadId, {bool forceRefresh = false}) async {
    // 1. Check cached list if not forcing refresh
    if (!forceRefresh) {
      for (final l in _leads) {
        if (l.id == leadId) return l;
      }
    }

    // 2. Fetch from DB
    try {
      final response = await SupabaseConfig.client
          .from('social_leads')
          .select('*, social_post:social_posts(*, property:properties(*, address:addresses(*)))')
          .eq('id', leadId.trim())
          .maybeSingle();

      if (response != null) {
        final fetched = SocialLeadModel.fromJson(response);
        updateCachedLead(fetched);
        return fetched;
      }
    } catch (e) {
      debugPrint('[LeadProvider] Error fetching lead by ID ($leadId): $e');
    }
    return null;
  }

  /// Updates lead status with optimistic UI update and Supabase persistence
  Future<bool> updateLeadStatus(String leadId, LeadStatus newStatus) async {
    final oldIndex = _leads.indexWhere((l) => l.id == leadId);
    final oldLead = oldIndex != -1 ? _leads[oldIndex] : null;

    if (oldLead != null) {
      _leads[oldIndex] = oldLead.copyWith(status: newStatus);
      notifyListeners();
    }

    try {
      await SupabaseConfig.client
          .from('social_leads')
          .update({'status': newStatus.apiValue})
          .eq('id', leadId);
      return true;
    } catch (e) {
      debugPrint('[LeadProvider] Error updating lead status: $e');
      if (oldLead != null && oldIndex != -1) {
        _leads[oldIndex] = oldLead;
        notifyListeners();
      }
      return false;
    }
  }

  /// Synchronizes or inserts a lead in the in-memory cache
  void updateCachedLead(SocialLeadModel updatedLead) {
    final index = _leads.indexWhere((l) => l.id == updatedLead.id);
    if (index != -1) {
      _leads[index] = updatedLead;
    } else {
      _leads.insert(0, updatedLead);
    }
    notifyListeners();
  }

  /// Unsubscribe from social_leads real-time changes
  void unsubscribeLeads() {
    _leadSubscription?.unsubscribe();
    _leadSubscription = null;
  }

  /// Reset state and unsubscribe on user sign out
  void clear() {
    unsubscribeLeads();
    _leads = [];
    _currentPage = 1;
    _totalItems = 0;
    _totalPages = 1;
    _hasMore = false;
    _searchQuery = '';
    _platformsFilter = [];
    _statusFilter = null;
    _errorMessage = null;
    _currentBrokerId = null;
    _isLoading = false;
    notifyListeners();
  }
}
