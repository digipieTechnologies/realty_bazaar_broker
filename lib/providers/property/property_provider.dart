import 'package:flutter/material.dart';
import '../../core/services/clarity_service.dart';
import '../../core/supabase/supabase_config.dart';
import '../../models/address_model.dart';
import '../../models/broker_setup_details_model.dart';
import '../../models/property_model.dart';
import '../auth/auth_provider.dart';

class PropertyProvider extends ChangeNotifier {
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  List<PropertyModel> _properties = [];
  List<PropertyModel> get properties => _properties;

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

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  Future<void> fetchProperties({
    required String brokerId,
    int page = 1,
    String searchQuery = '',
    bool forVideoRequest = false,
  }) async {
    _isLoading = true;
    _currentPage = page;
    _searchQuery = searchQuery;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await SupabaseConfig.client.rpc(
        'fetch_properties',
        params: {
          'p_broker_id': brokerId,
          'p_page': page,
          'p_limit': _itemsPerPage,
          'p_search_query': searchQuery,
          'p_for_video_request': forVideoRequest,
        },
      );

      if (response != null) {
        final Map<String, dynamic> resMap = response is Map<String, dynamic>
            ? response
            : {};
        
        if (resMap['success'] == true && resMap['data'] is List) {
          final rawList = resMap['data'] as List;
          _properties = rawList.map((json) => PropertyModel.fromJson(json)).toList();

          final pagination = resMap['pagination'] as Map<String, dynamic>? ?? {};
          _totalItems = int.tryParse(pagination['total_items']?.toString() ?? '0') ?? _properties.length;
          _totalPages = int.tryParse(pagination['total_pages']?.toString() ?? '1') ?? 1;
          _hasMore = pagination['has_more'] as bool? ?? false;
          _isLoading = false;
          _errorMessage = null;
          notifyListeners();
          return;
        }
      }
      _errorMessage = 'Failed to fetch properties.';
    } catch (e) {
      debugPrint('[PropertyProvider] Error calling fetch-properties RPC: $e');
      _errorMessage = e.toString();
    }

    _properties = [];
    _totalItems = 0;
    _totalPages = 1;
    _hasMore = false;
    _isLoading = false;
    notifyListeners();
  }

  Future<Map<String, dynamic>> fetchPropertiesPage({
    required String brokerId,
    int page = 1,
    int limit = 10,
    String searchQuery = '',
    bool forVideoRequest = false,
  }) async {
    try {
      final response = await SupabaseConfig.client.rpc(
        'fetch_properties',
        params: {
          'p_broker_id': brokerId,
          'p_page': page,
          'p_limit': limit,
          'p_search_query': searchQuery,
          'p_for_video_request': forVideoRequest,
        },
      );

      if (response != null && response is Map<String, dynamic>) {
        if (response['success'] == true && response['data'] is List) {
          final rawList = response['data'] as List;
          final properties = rawList.map((json) => PropertyModel.fromJson(json)).toList();
          final pagination = response['pagination'] as Map<String, dynamic>? ?? {};
          final hasMore = pagination['has_more'] as bool? ?? false;
          final totalItems = int.tryParse(pagination['total_items']?.toString() ?? '0') ?? properties.length;

          return {
            'properties': properties,
            'hasMore': hasMore,
            'totalItems': totalItems,
          };
        }
      }
    } catch (e) {
      debugPrint('[PropertyProvider] Error fetching properties page: $e');
    }

    return {
      'properties': <PropertyModel>[],
      'hasMore': false,
      'totalItems': 0,
    };
  }

  Future<PropertyModel?> saveProperty(
    PropertyModel property, {
    bool isEdit = false,
    AuthProvider? authProvider,
  }) async {
    try {
      final payload = property.toJson();
      debugPrint('[PropertyProvider] saveProperty payload: $payload');
      final response = await SupabaseConfig.client.rpc(
        'publish_property',
        params: {
          'p_property': payload,
          'p_is_edit': isEdit,
        },
      );

      if (response != null) {
        final Map<String, dynamic> data = response is Map<String, dynamic>
            ? response
            : {};
        if (data['success'] == true) {
          ClarityService.instance.sendCustomEvent(
            isEdit ? 'feature_property_updated' : 'feature_property_created',
          );

          if (authProvider != null) {
            final currentSetup = authProvider.userProfile?.brokerId?.setupDetails ??
                const BrokerSetupDetailsModel();
            if (!currentSetup.propertiesImported) {
              final updatedSetup = currentSetup.copyWith(propertiesImported: true);
              authProvider.updateLocalBrokerSetupDetails(setupDetails: updatedSetup);
            }
          }

          final brokerIdStr = property.brokerId?.id;
          if (brokerIdStr != null && brokerIdStr.isNotEmpty) {
            await fetchProperties(brokerId: brokerIdStr, page: 1, searchQuery: _searchQuery);
          }
          if (data['property'] != null) {
            final returnedJson = data['property'] as Map<String, dynamic>;
            final mergedProperty = property.copyWith(
              id: returnedJson['id']?.toString(),
              addressId: returnedJson['address_id'] != null
                  ? AddressModel.fromJson(returnedJson['address_id'])
                  : null,
            );
            return mergedProperty;
          }
          return property;
        }
      }

      final errorMsg = response is Map ? (response['error'] ?? 'Unknown error') : 'Server error';
      throw Exception(errorMsg);
    } catch (e) {
      debugPrint('[PropertyProvider] Error saving property: $e');
      _errorMessage = 'Failed to save property: $e';
      notifyListeners();
      return null;
    }
  }

  Future<String?> generateCaption(String propertyId) async {
    try {
      final response = await SupabaseConfig.client.functions.invoke(
        'generate-caption',
        body: {
          'propertyId': propertyId,
        },
      );

      if (response.status == 200 && response.data != null) {
        if (response.data is Map) {
          return response.data['caption'];
        }
      }
      final errorMsg = response.data is Map ? (response.data['error'] ?? 'Unknown error') : 'Server error';
      throw Exception(errorMsg);
    } catch (e) {
      debugPrint('[PropertyProvider] Error generating caption: $e');
      rethrow;
    }
  }

  Future<PropertyModel?> fetchPropertyById(String id) async {
    try {
      final response = await SupabaseConfig.client
          .from('properties')
          .select('*, address:addresses(*)')
          .eq('id', id)
          .maybeSingle();

      if (response != null) {
        return PropertyModel.fromJson(response);
      }
    } catch (e) {
      debugPrint('[PropertyProvider] Error fetching property by ID: $e');
    }
    return null;
  }

  Future<bool> deleteProperty(String propertyId, {required String brokerId}) async {
    try {
      await SupabaseConfig.client.rpc(
        'soft_delete_property',
        params: {'p_property_id': propertyId},
      );

      await fetchProperties(brokerId: brokerId, page: _currentPage, searchQuery: _searchQuery);
      return true;
    } catch (e) {
      debugPrint('[PropertyProvider] Error deleting property: $e');
      _errorMessage = 'Failed to delete property: $e';
      notifyListeners();
      return false;
    }
  }

  /// Reset state on user sign out
  void clear() {
    _properties = [];
    _currentPage = 1;
    _totalItems = 0;
    _totalPages = 1;
    _hasMore = false;
    _searchQuery = '';
    _errorMessage = null;
    _isLoading = false;
    notifyListeners();
  }
}
