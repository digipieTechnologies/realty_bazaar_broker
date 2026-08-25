import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/services/clarity_service.dart';
import '../../core/supabase/supabase_config.dart';
import '../../models/models.dart';

class VideoRequestProvider extends ChangeNotifier {
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  List<VideoRequestModel> _requests = [];
  List<VideoRequestModel> get requests => _requests;

  int _totalRequests = 0;
  int get totalRequests => _totalRequests;

  int _pendingRequests = 0;
  int get pendingRequests => _pendingRequests;

  int _inProgressRequests = 0;
  int get inProgressRequests => _inProgressRequests;

  int _completedRequests = 0;
  int get completedRequests => _completedRequests;

  int _cancelledRequests = 0;
  int get cancelledRequests => _cancelledRequests;

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

  VideoRequestStatus? _statusFilter;
  VideoRequestStatus? get statusFilter => _statusFilter;

  List<VideoRequestStatus> _statusesFilter = [];
  List<VideoRequestStatus> get statusesFilter => _statusesFilter;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  void setStatusFilter(VideoRequestStatus? status) {
    _statusFilter = status;
    if (status != null) {
      _statusesFilter = [status];
    } else {
      _statusesFilter = [];
    }
    notifyListeners();
  }

  void setStatusesFilter(List<VideoRequestStatus> statuses) {
    _statusesFilter = List<VideoRequestStatus>.from(statuses);
    if (_statusesFilter.length == 1) {
      _statusFilter = _statusesFilter.first;
    } else {
      _statusFilter = null;
    }
    notifyListeners();
  }

  /// Fetch summarized request counts from Supabase RPC with optional broker_id
  Future<void> fetchVideoRequestCounts({String? brokerId}) async {
    try {
      final response = await SupabaseConfig.client.rpc(
        'fetch_video_request_counts',
        params: {
          'p_broker_id': brokerId,
        },
      );
      if (response != null) {
        final resMap = response is Map<String, dynamic> ? response : {};
        _totalRequests = int.tryParse(resMap['total']?.toString() ?? '0') ?? 0;
        _pendingRequests = int.tryParse(resMap['pending']?.toString() ?? '0') ?? 0;
        _inProgressRequests = int.tryParse(resMap['in_progress']?.toString() ?? '0') ?? 0;
        _completedRequests = int.tryParse(resMap['completed']?.toString() ?? '0') ?? 0;
        _cancelledRequests = int.tryParse(resMap['cancelled']?.toString() ?? '0') ?? 0;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('[VideoRequestProvider] Error calling fetch_video_request_counts RPC: $e');
    }
  }

  /// Fetch paginated video request list for a specific broker or all brokers
  Future<void> fetchVideoRequests({
    String? brokerId,
    int page = 1,
    String searchQuery = '',
  }) async {
    _isLoading = true;
    _currentPage = page;
    _searchQuery = searchQuery;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await SupabaseConfig.client.rpc(
        'fetch_video_requests',
        params: {
          'p_broker_id': brokerId,
          'p_page': page,
          'p_limit': _itemsPerPage,
          'p_search_query': searchQuery,
          'p_status': _statusFilter?.dbValue,
          'p_statuses': _statusesFilter.isEmpty ? null : _statusesFilter.map((s) => s.dbValue).toList(),
        },
      );

      if (response != null) {
        final Map<String, dynamic> resMap = response is Map<String, dynamic>
            ? response
            : {};
        
        if (resMap['success'] == true && resMap['data'] is List) {
          final rawList = resMap['data'] as List;
          _requests = rawList
              .map((json) => VideoRequestModel.fromJson(json))
              .toList();

          final pagination = resMap['pagination'] is Map ? resMap['pagination'] as Map : {};
          _totalItems = int.tryParse(pagination['total_items']?.toString() ?? '0') ?? _requests.length;
          _totalPages = int.tryParse(pagination['total_pages']?.toString() ?? '1') ?? 1;
          _hasMore = pagination['has_more'] as bool? ?? false;
          _isLoading = false;
          _errorMessage = null;
          notifyListeners();
          return;
        }
      }
      _errorMessage = 'Failed to fetch video requests.';
    } catch (e) {
      debugPrint('[VideoRequestProvider] Error calling fetch_video_requests RPC: $e');
      _errorMessage = e.toString();
    }

    _requests = [];
    _totalItems = 0;
    _totalPages = 1;
    _hasMore = false;
    _isLoading = false;
    notifyListeners();
  }

  RealtimeChannel? _videoRequestSubscription;
  String? _currentBrokerId;

  /// Subscribe to video requests real-time changes filtered by current broker ID
  void subscribeToVideoRequests(String brokerId) {
    _currentBrokerId = brokerId;
    _videoRequestSubscription?.unsubscribe();

    _videoRequestSubscription = SupabaseConfig.client
        .channel('video_requests_broker_$brokerId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'video_requests',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'broker_id',
            value: brokerId,
          ),
          callback: (payload) {
            debugPrint('[VideoRequestProvider] Realtime Postgres Change Received (${payload.eventType}) for broker: $brokerId');
            _handleRealtimePayload(payload);
          },
        );

    _videoRequestSubscription!.subscribe();
  }

  /// Unsubscribe from video requests real-time changes
  void unsubscribeVideoRequests() {
    _videoRequestSubscription?.unsubscribe();
    _videoRequestSubscription = null;
    _currentBrokerId = null;
  }

  void _handleRealtimePayload(PostgresChangePayload payload) {
    if (_currentBrokerId == null) return;

    final newRecord = payload.newRecord;
    final oldRecord = payload.oldRecord;
    final recordId = (newRecord['id'] ?? oldRecord['id'])?.toString();

    final bool isDeleted = (newRecord['is_deleted'] == true) ||
        (newRecord['is_deleted']?.toString().toLowerCase() == 'true') ||
        (payload.eventType == PostgresChangeEvent.delete);

    final bool isPresentOnCurrentPage = recordId != null &&
        _requests.any((r) => r.id == recordId);

    // Re-fetch current page directly if record was deleted, updated while on current page, or inserted
    if (isDeleted || isPresentOnCurrentPage || payload.eventType == PostgresChangeEvent.insert) {
      fetchVideoRequestCounts(brokerId: _currentBrokerId);
      fetchVideoRequests(
        brokerId: _currentBrokerId,
        page: _currentPage,
        searchQuery: _searchQuery,
      );
    }
  }

  /// Fetch video request and property details for a given property ID using fetch_video_request_details RPC
  Future<({VideoRequestModel? videoRequest, PropertyModel? property})> fetchVideoRequestDetails({
    required String propertyId,
  }) async {
    try {
      final response = await SupabaseConfig.client.rpc(
        'fetch_video_request_details',
        params: {'p_property_id': propertyId},
      );

      VideoRequestModel? videoRequest;
      PropertyModel? property;

      if (response != null && response is Map && response['success'] == true) {
        if (response['video_request'] != null) {
          videoRequest = VideoRequestModel.fromJson(response['video_request']);
        }
        if (response['property'] != null) {
          property = PropertyModel.fromJson(response['property']);
        }
      }
      return (videoRequest: videoRequest, property: property);
    } catch (e) {
      debugPrint('[VideoRequestProvider] Error fetching video request details RPC: $e');
      return (videoRequest: null, property: null);
    }
  }

  /// Submit a new video request record
  Future<VideoRequestModel?> submitRequest({
    required String brokerId,
    required String propertyId,
    String? notes,
  }) async {
    try {
      final response = await SupabaseConfig.client.from('video_requests').insert({
        'broker_id': brokerId,
        'property_id': propertyId,
        'status': VideoRequestStatus.pending.dbValue,
        'notes': notes != null && notes.isNotEmpty ? notes : null,
      }).select('*, property:properties(*, address:addresses(*))').single();

      final newModel = VideoRequestModel.fromJson(response);

      ClarityService.instance.sendCustomEvent('feature_video_request_submitted');

      await fetchVideoRequestCounts(brokerId: brokerId);
      await fetchVideoRequests(
        brokerId: brokerId,
        page: _currentPage,
        searchQuery: _searchQuery,
      );

      return newModel;
    } catch (e) {
      debugPrint('[VideoRequestProvider] Error submitting video request: $e');
      return null;
    }
  }

  /// Cancel a video request (updates status to cancelled with optional reason and canceller user ID)
  Future<VideoRequestModel?> cancelRequestWithModel(String requestId, {String? brokerId, String? cancelReason, String? cancelledByUserId}) async {
    try {
      final currentUserId = cancelledByUserId ?? SupabaseConfig.client.auth.currentUser?.id;
      final updates = <String, dynamic>{
        'status': VideoRequestStatus.cancelled.dbValue,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      };
      if (currentUserId != null && currentUserId.isNotEmpty) {
        updates['cancelled_by_user_id'] = currentUserId;
      }
      if (cancelReason != null && cancelReason.isNotEmpty) {
        updates['cancel_reason'] = cancelReason;
      }

      final response = await SupabaseConfig.client
          .from('video_requests')
          .update(updates)
          .eq('id', requestId)
          .select('*, property:properties(*, address:addresses(*))')
          .single();

      final updatedModel = VideoRequestModel.fromJson(response);

      // Refresh list and counts
      await fetchVideoRequestCounts(brokerId: brokerId);
      await fetchVideoRequests(
        brokerId: brokerId,
        page: _currentPage,
        searchQuery: _searchQuery,
      );
      return updatedModel;
    } catch (e) {
      debugPrint('[VideoRequestProvider] Error cancelling video request: $e');
      return null;
    }
  }

  /// Cancel a video request (returns bool for backwards compatibility)
  Future<bool> cancelRequest(String requestId, {String? brokerId, String? cancelReason, String? cancelledByUserId}) async {
    final result = await cancelRequestWithModel(requestId, brokerId: brokerId, cancelReason: cancelReason, cancelledByUserId: cancelledByUserId);
    return result != null;
  }

  /// Reset state and unsubscribe on user sign out
  void clear() {
    unsubscribeVideoRequests();
    _requests = [];
    _totalRequests = 0;
    _pendingRequests = 0;
    _inProgressRequests = 0;
    _completedRequests = 0;
    _cancelledRequests = 0;
    _currentPage = 1;
    _totalItems = 0;
    _totalPages = 1;
    _hasMore = false;
    _searchQuery = '';
    _statusFilter = null;
    _statusesFilter = [];
    _errorMessage = null;
    _isLoading = false;
    notifyListeners();
  }
}
