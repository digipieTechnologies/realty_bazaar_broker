// File: lib/providers/visit/visit_provider.dart
// Purpose: State management and business logic for Property Visits / Site Visits.
//          Handles paginated RPC queries, status & date filtering, real-time database
//          subscriptions, scheduling, rescheduling, and status transitions.

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/supabase/supabase_config.dart';
import '../../models/property_visit_model.dart';

class VisitProvider extends ChangeNotifier {
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  List<PropertyVisitModel> _visits = [];
  List<PropertyVisitModel> get visits => _visits;

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

  List<String> _statusesFilter = []; // Empty = All statuses, or ['pending', 'confirmed', ...]
  List<String> get statusesFilter => _statusesFilter;

  String _dateFilter = 'all'; // 'all', 'today', 'upcoming', 'past'
  String get dateFilter => _dateFilter;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  RealtimeChannel? _visitSubscription;
  String? _currentBrokerId;
  String? _propertyIdFilter;

  void setStatusesFilter(List<String> statuses, {String? brokerId}) {
    _statusesFilter = List<String>.from(statuses);
    notifyListeners();
    fetchVisits(brokerId: brokerId ?? _currentBrokerId, page: 1, searchQuery: _searchQuery);
  }

  void setDateFilter(String newDateFilter, {String? brokerId}) {
    _dateFilter = newDateFilter;
    notifyListeners();
    fetchVisits(brokerId: brokerId ?? _currentBrokerId, page: 1, searchQuery: _searchQuery);
  }

  void setPropertyIdFilter(String? propertyId, {String? brokerId}) {
    _propertyIdFilter = propertyId;
    notifyListeners();
    fetchVisits(brokerId: brokerId ?? _currentBrokerId, page: 1, searchQuery: _searchQuery);
  }

  /// Fetch paginated visits using get_property_visits RPC.
  Future<void> fetchVisits({
    String? brokerId,
    int page = 1,
    String searchQuery = '',
    bool isSilent = false,
  }) async {
    if (!isSilent) {
      _isLoading = true;
      notifyListeners();
    }
    _currentPage = page;
    _searchQuery = searchQuery;
    _errorMessage = null;
    if (brokerId != null && brokerId.isNotEmpty) {
      _currentBrokerId = brokerId;
    }

    try {
      final response = await SupabaseConfig.client.rpc(
        'get_property_visits',
        params: {
          'p_broker_id': brokerId ?? _currentBrokerId,
          'p_page': page,
          'p_limit': _itemsPerPage,
          'p_search_query': searchQuery,
          'p_statuses': _statusesFilter.isEmpty ? null : _statusesFilter,
          'p_date_filter': _dateFilter,
          'p_property_id': _propertyIdFilter,
        },
      );

      if (response != null) {
        final Map<String, dynamic> resMap =
            response is Map<String, dynamic> ? response : {};

        if (resMap['success'] == true && resMap['data'] is List) {
          final rawList = resMap['data'] as List;
          _visits = rawList.map((json) => PropertyVisitModel.fromJson(json)).toList();

          final pagination = resMap['pagination'] as Map<String, dynamic>? ?? {};
          _totalItems = int.tryParse(pagination['total_items']?.toString() ?? '0') ?? _visits.length;
          _totalPages = int.tryParse(pagination['total_pages']?.toString() ?? '1') ?? 1;
          _hasMore = pagination['has_more'] as bool? ?? false;
          _isLoading = false;
          _errorMessage = null;
          notifyListeners();
          return;
        }
      }
      _errorMessage = 'Failed to fetch visits.';
    } catch (e) {
      debugPrint('[VisitProvider] Error calling get_property_visits RPC: $e');
      _errorMessage = e.toString();
    }

    if (!isSilent) {
      _visits = [];
      _totalItems = 0;
      _totalPages = 1;
      _hasMore = false;
    }
    _isLoading = false;
    notifyListeners();
  }

  /// Subscribe to property_visits table real-time changes
  void subscribeToVisits(String brokerId) {
    if (brokerId.isEmpty) return;
    _currentBrokerId = brokerId;

    if (_visitSubscription != null) {
      return;
    }

    _visitSubscription = SupabaseConfig.client
        .channel('property_visits_broker_$brokerId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'property_visits',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'broker_id',
            value: brokerId,
          ),
          callback: (payload) {
            debugPrint(
              '[VisitProvider] Realtime change (${payload.eventType}) for broker: $brokerId',
            );
            fetchVisits(
              brokerId: _currentBrokerId,
              page: _currentPage,
              searchQuery: _searchQuery,
              isSilent: true,
            );
          },
        );

    _visitSubscription!.subscribe();
  }

  /// Fetch a single visit by ID with property, address, and audit history
  Future<PropertyVisitModel?> fetchVisitById(String visitId) async {
    try {
      final response = await SupabaseConfig.client
          .from('property_visits')
          .select(
            '*, property:properties(*, address:addresses(*)), broker:brokers(*), history:property_visit_history(*)',
          )
          .eq('id', visitId.trim())
          .maybeSingle();

      if (response != null) {
        return PropertyVisitModel.fromJson(response);
      }
    } catch (e) {
      debugPrint('[VisitProvider] Error fetching visit by ID ($visitId): $e');
    }
    return null;
  }

  /// Schedule a new site visit
  Future<PropertyVisitModel> scheduleVisit({
    required String brokerId,
    required String propertyId,
    required String clientName,
    required String clientPhone,
    required DateTime visitDate,
    required String timeSlot,
    String? notes,
  }) async {
    final dateFormatted = visitDate.toIso8601String().split('T').first;

    final response = await SupabaseConfig.client
        .from('property_visits')
        .insert({
          'broker_id': brokerId,
          'property_id': propertyId,
          'client_name': clientName.trim(),
          'client_phone': clientPhone.replaceAll(RegExp(r'\D'), '').trim(),
          'phone_country_code': '91',
          'phone_country_iso': 'IN',
          'visit_date': dateFormatted,
          'time_slot': timeSlot.trim(),
          'status': 'pending',
          'notes': notes?.trim().isNotEmpty == true ? notes!.trim() : null,
        })
        .select(
          '*, property:properties(*, address:addresses(*)), broker:brokers(*)',
        )
        .single();

    final newVisit = PropertyVisitModel.fromJson(response);
    // Refresh active list silently
    fetchVisits(brokerId: brokerId, page: 1, searchQuery: _searchQuery, isSilent: true);
    return newVisit;
  }

  /// Reschedule an existing visit with new date, hourly time slot, and mandatory reason
  Future<PropertyVisitModel> rescheduleVisit({
    required String visitId,
    required DateTime newDate,
    required String newTimeSlot,
    required String reason,
  }) async {
    final dateFormatted = newDate.toIso8601String().split('T').first;

    // Fetch current count to increment
    final existing = await fetchVisitById(visitId);
    final nextCount = (existing?.rescheduleCount ?? 0) + 1;

    final response = await SupabaseConfig.client
        .from('property_visits')
        .update({
          'visit_date': dateFormatted,
          'time_slot': newTimeSlot.trim(),
          'status': 'rescheduled',
          'reschedule_count': nextCount,
          'reschedule_reason': reason.trim(),
        })
        .eq('id', visitId)
        .select(
          '*, property:properties(*, address:addresses(*)), broker:brokers(*), history:property_visit_history(*)',
        )
        .single();

    final updated = PropertyVisitModel.fromJson(response);
    _updateCachedVisit(updated);
    return updated;
  }

  /// Update visit status ('confirmed', 'completed', 'cancelled', 'no_show')
  Future<PropertyVisitModel> updateVisitStatus({
    required String visitId,
    required String newStatus,
    String? reason,
    String? notes,
  }) async {
    final Map<String, dynamic> updatePayload = {
      'status': newStatus,
    };

    if (newStatus == 'cancelled' && reason != null) {
      updatePayload['cancelled_reason'] = reason.trim();
    }
    if (notes != null && notes.trim().isNotEmpty) {
      updatePayload['notes'] = notes.trim();
    }

    final response = await SupabaseConfig.client
        .from('property_visits')
        .update(updatePayload)
        .eq('id', visitId)
        .select(
          '*, property:properties(*, address:addresses(*)), broker:brokers(*), history:property_visit_history(*)',
        )
        .single();

    final updated = PropertyVisitModel.fromJson(response);
    _updateCachedVisit(updated);
    return updated;
  }

  void _updateCachedVisit(PropertyVisitModel updated) {
    final index = _visits.indexWhere((v) => v.id == updated.id);
    if (index != -1) {
      _visits[index] = updated;
      notifyListeners();
    }
  }

  void unsubscribeVisits() {
    _visitSubscription?.unsubscribe();
    _visitSubscription = null;
  }

  void clear() {
    unsubscribeVisits();
    _visits = [];
    _currentPage = 1;
    _totalItems = 0;
    _totalPages = 1;
    _hasMore = false;
    _searchQuery = '';
    _statusesFilter = [];
    _dateFilter = 'all';
    _errorMessage = null;
    _currentBrokerId = null;
    _propertyIdFilter = null;
    _isLoading = false;
    notifyListeners();
  }
}
