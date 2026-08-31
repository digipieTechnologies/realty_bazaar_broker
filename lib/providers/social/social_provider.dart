import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/services/clarity_service.dart';
import '../../core/services/supabase_storage_service.dart';
import '../../core/supabase/supabase_config.dart';
import '../../models/models.dart';
import '../../models/social_enums.dart';
import '../../util/app_utils.dart';
import '../../widgets/toast/app_toast.dart';
import '../auth/auth_provider.dart';

class SocialProvider extends ChangeNotifier {
  bool _isFacebookConnected = false;

  bool get isFacebookConnected => _isFacebookConnected;

  bool _isInstagramConnected = false;

  bool get isInstagramConnected => _isInstagramConnected;

  List<SocialPostModel> _posts = [];

  List<SocialPostModel> get posts => _posts;

  SocialAccountModel? _facebookAccount;

  SocialAccountModel? get facebookAccount => _facebookAccount;

  SocialAccountModel? _instagramAccount;

  SocialAccountModel? get instagramAccount => _instagramAccount;

  RealtimeChannel? _socialSubscription;
  String? _currentBrokerId;

  bool _isFetchingConnections = false;

  bool get isFetchingConnections => _isFetchingConnections;

  bool _isDisconnecting = false;

  bool get isDisconnecting => _isDisconnecting;
  String? _disconnectingPlatform;

  String? get disconnectingPlatform => _disconnectingPlatform;

  bool isPlatformDisconnecting(String platform) =>
      _isDisconnecting && _disconnectingPlatform == platform;

  bool _isSyncingPosts = false;

  bool get isSyncingPosts => _isSyncingPosts;

  List<SocialPostModel> _facebookPosts = [];

  List<SocialPostModel> get facebookPosts => _facebookPosts;

  List<SocialPostModel> _instagramPosts = [];

  List<SocialPostModel> get instagramPosts => _instagramPosts;

  bool _isFetchingFacebookPosts = false;

  bool get isFetchingFacebookPosts => _isFetchingFacebookPosts;

  bool _isFetchingInstagramPosts = false;

  bool get isFetchingInstagramPosts => _isFetchingInstagramPosts;

  int _facebookCurrentPage = 1;

  int get facebookCurrentPage => _facebookCurrentPage;
  int _facebookTotalPages = 1;

  int get facebookTotalPages => _facebookTotalPages;
  int _facebookTotalItems = 0;

  int get facebookTotalItems => _facebookTotalItems;

  int _instagramCurrentPage = 1;

  int get instagramCurrentPage => _instagramCurrentPage;
  int _instagramTotalPages = 1;

  int get instagramTotalPages => _instagramTotalPages;
  int _instagramTotalItems = 0;

  int get instagramTotalItems => _instagramTotalItems;

  SocialPlatform _selectedPlatformTab = SocialPlatform.facebook;

  SocialPlatform get selectedPlatformTab => _selectedPlatformTab;

  bool _hasFetchedInitialConnections = false;

  bool get hasFetchedInitialConnections => _hasFetchedInitialConnections;

  // Realtime subscription management
  void subscribeToSocialAccounts(String brokerId) {
    if (_currentBrokerId == brokerId && _socialSubscription != null) {
      debugPrint(
        '[SocialProvider] Already subscribed to social accounts for broker: $brokerId',
      );
      return;
    }

    _currentBrokerId = brokerId;
    _socialSubscription?.unsubscribe();

    debugPrint(
      '[SocialProvider] Subscribing to realtime social_accounts changes for broker: $brokerId',
    );

    // Subscribe to all changes on social_accounts table and filter in Dart for 100% reliability
    _socialSubscription = SupabaseConfig.client
        .channel('public:social_accounts_channel_$brokerId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'social_accounts',
          callback: (payload) {
            debugPrint(
              '[SocialProvider] Realtime Postgres Change Received (${payload.eventType}): new=${payload.newRecord}, old=${payload.oldRecord}',
            );
            final newBrokerId = payload.newRecord['broker_id']?.toString();
            final oldBrokerId = payload.oldRecord['broker_id']?.toString();

            // Match current brokerId or if record is updated
            if (newBrokerId == brokerId ||
                oldBrokerId == brokerId ||
                newBrokerId == null) {
              _handleRealtimePayload(payload);
            }
          },
        );

    _socialSubscription!.subscribe((status, [error]) {
      debugPrint(
        '[SocialProvider] Realtime Subscription Status for social_accounts: $status ${error != null ? ", error: $error" : ""}',
      );
    });
  }

  void unsubscribeSocialAccounts() {
    _socialSubscription?.unsubscribe();
    _socialSubscription = null;
    _currentBrokerId = null;
  }

  void _handleRealtimePayload(PostgresChangePayload payload) {
    debugPrint(
      '[SocialProvider] Realtime Postgres Change Received (${payload.eventType}) for broker: $_currentBrokerId',
    );
    if (_currentBrokerId != null && _currentBrokerId!.isNotEmpty) {
      // Background fetch without showing shimmer
      fetchInitialConnections(_currentBrokerId!, forceShimmer: false);
    }
  }

  // Fetch initial connection states for the current broker via Edge Function
  Future<void> fetchInitialConnections(
    String brokerId, {
    bool forceShimmer = false,
    AuthProvider? authProvider,
  }) async {
    // Only show shimmer if initial connections have NEVER been fetched yet or if forceShimmer is true
    final shouldShowShimmer = !_hasFetchedInitialConnections || forceShimmer;

    if (shouldShowShimmer) {
      _isFetchingConnections = true;
      notifyListeners();
    }

    try {
      final response = await SupabaseConfig.client.functions.invoke(
        'fetch-social-connections',
        body: {'broker_id': brokerId},
      );

      debugPrint(
        'Fetch-social-connections edge function status: ${response.status}',
      );

      _facebookAccount = null;
      _isFacebookConnected = false;
      _instagramAccount = null;
      _isInstagramConnected = false;

      if (response.status == 200) {
        final data = response.data;
        if (data is Map && data['success'] == true) {
          // Process Facebook account object
          if (data['facebook'] != null) {
            final fbAccount = SocialAccountModel.fromJson(data['facebook']);
            final isConnected =
                (fbAccount.isConnected ?? true) && (fbAccount.isActive ?? true);
            _facebookAccount = isConnected ? fbAccount : null;
            _isFacebookConnected = isConnected;
          }

          // Process Instagram account object
          if (data['instagram'] != null) {
            final igAccount = SocialAccountModel.fromJson(data['instagram']);
            final isConnected =
                (igAccount.isConnected ?? true) && (igAccount.isActive ?? true);
            _instagramAccount = isConnected ? igAccount : null;
            _isInstagramConnected = isConnected;
          }

          // If connected is true and broker setupDetails is currently false, update setupDetails locally
          if (authProvider != null) {
            BrokerSetupDetailsModel currentSetup =
                authProvider.userProfile?.brokerId?.setupDetails ??
                const BrokerSetupDetailsModel();

            if (!currentSetup.instagramConnected && _isInstagramConnected) {
              currentSetup = currentSetup.copyWith(
                instagramConnected: _isInstagramConnected,
              );
            }
            if (!currentSetup.facebookConnected && _isFacebookConnected) {
              currentSetup = currentSetup.copyWith(
                facebookConnected: _isFacebookConnected,
              );
            }

            authProvider.updateLocalBrokerSetupDetails(
              setupDetails: currentSetup,
            );
          }
        } else {
          final errorMsg = data is Map
              ? data['message']
              : 'Failed to fetch social connections';
          debugPrint('Error response from fetch-social-connections: $errorMsg');
        }
      } else {
        debugPrint(
          'Fetch-social-connections returned non-200 status: ${response.status}',
        );
      }
    } catch (e) {
      debugPrint('Error fetching social connections via edge function: $e');
    } finally {
      _hasFetchedInitialConnections = true;
      _isFetchingConnections = false;
      notifyListeners();
    }
  }

  // Disconnect social connection via Edge Function
  Future<bool> disconnectSocialAccount(String brokerId, String platform) async {
    _isDisconnecting = true;
    _disconnectingPlatform = platform;
    notifyListeners();

    try {
      final response = await SupabaseConfig.client.functions.invoke(
        'disconnect-social-account',
        body: {'broker_id': brokerId, 'platform': platform},
      );

      debugPrint(
        'Disconnect $platform edge function status: ${response.status}',
      );

      if (response.status == 200) {
        final data = response.data;
        if (data is Map && data['success'] == true) {
          if (platform == 'facebook') {
            _facebookAccount = null;
            _isFacebookConnected = false;
          } else if (platform == 'instagram') {
            _instagramAccount = null;
            _isInstagramConnected = false;
          }
          notifyListeners();

          final platformName = platform == 'facebook'
              ? 'Facebook Page'
              : 'Instagram Business';
          AppToast.showSuccess(
            'Account Disconnected',
            'Successfully disconnected $platformName, unsubscribed webhooks, and revoked Meta access permissions.',
          );
          return true;
        } else {
          final errorMsg = data is Map
              ? (data['message'] ?? data['error'])?.toString()
              : 'Failed to disconnect $platform.';
          AppToast.showError(
            'Disconnect Failed',
            errorMsg ?? 'An unexpected server response was received.',
          );
          return false;
        }
      } else {
        AppToast.showError(
          'Disconnect Failed',
          'Server returned status code: ${response.status}',
        );
        return false;
      }
    } catch (e) {
      debugPrint('Error calling disconnect-social-account edge function: $e');
      AppToast.showError(
        'Disconnect Error',
        'Could not contact server: ${e.toString()}',
      );
      return false;
    } finally {
      _isDisconnecting = false;
      _disconnectingPlatform = null;
      notifyListeners();
    }
  }

  // Trigger Direct Instagram connection OAuth dialog URL flow
  Future<void> connectInstagramDirectly(String brokerId) async {
    try {
      final response = await SupabaseConfig.client.functions.invoke(
        'instagram-connect',
        body: {'broker_id': brokerId},
      );

      debugPrint('Instagram-connect edge function status: ${response.status}');

      if (response.status == 200) {
        final data = response.data;
        if (data is Map && data['success'] == true) {
          final url = data['url']?.toString() ?? '';
          debugPrint('Generated Instagram Auth URL: $url');
          if (url.isNotEmpty) {
            await AppUtils.launchAppUrl(url);
          } else {
            AppToast.showError(
              'Connection Error',
              'No connection link was returned by the server.',
            );
          }
        } else {
          final errorMsg = data is Map
              ? (data['error'] ?? data['message'])?.toString()
              : 'Failed to retrieve connection link.';
          AppToast.showError(
            'Connection Failed',
            errorMsg ?? 'An unexpected response was received.',
          );
        }
      } else {
        AppToast.showError(
          'Connection Failed',
          'Server returned status code: ${response.status}',
        );
      }
    } catch (e) {
      debugPrint('Error calling instagram-connect edge function: $e');
      AppToast.showError(
        'Connection Failed',
        'Could not contact connection server: ${e.toString()}',
      );
    }
  }

  // Trigger Facebook connection OAuth dialog URL flow
  Future<void> connectFacebook(String brokerId) async {
    await _invokeFacebookConnect(brokerId);
  }

  Future<void> _invokeFacebookConnect(String brokerId) async {
    try {
      final response = await SupabaseConfig.client.functions.invoke(
        'facebook-connect',
        body: {'broker_id': brokerId},
      );

      debugPrint('Facebook-connect edge function status: ${response.status}');

      if (response.status == 200) {
        final data = response.data;
        if (data is Map && data['success'] == true) {
          final url = data['url']?.toString() ?? '';
          if (url.isNotEmpty) {
            await AppUtils.launchAppUrl(url);
          } else {
            AppToast.showError(
              'Connection Error',
              'No connection link was returned by the server.',
            );
          }
        } else {
          final errorMsg = data is Map
              ? (data['error'] ?? data['message'])?.toString()
              : 'Failed to retrieve connection link.';
          AppToast.showError(
            'Connection Failed',
            errorMsg ?? 'An unexpected response was received.',
          );
        }
      } else {
        AppToast.showError(
          'Connection Failed',
          'Server returned status code: ${response.status}',
        );
      }
    } catch (e) {
      debugPrint('Error calling meta-connect edge function: $e');
      AppToast.showError(
        'Connection Failed',
        'Could not contact connection server: ${e.toString()}',
      );
    }
  }

  void setSelectedPlatformTab(SocialPlatform tab, {String? brokerId}) {
    if (_selectedPlatformTab == tab) return;
    _selectedPlatformTab = tab;
    notifyListeners();

    if (brokerId != null && brokerId.isNotEmpty) {
      if (tab == SocialPlatform.facebook &&
          _facebookPosts.isEmpty &&
          !_isFetchingFacebookPosts) {
        fetchFacebookPosts(brokerId, page: 1);
      } else if (tab == SocialPlatform.instagram &&
          _instagramPosts.isEmpty &&
          !_isFetchingInstagramPosts) {
        fetchInstagramPosts(brokerId, page: 1);
      }
    }
  }

  Future<void> fetchFacebookPosts(String brokerId, {int page = 1}) async {
    _isFetchingFacebookPosts = true;
    _facebookCurrentPage = page;
    notifyListeners();

    try {
      final response = await SupabaseConfig.client.functions.invoke(
        'fetch-facebook-posts',
        body: {'broker_id': brokerId, 'page': page, 'limit': 10},
      );

      if (response.status == 200) {
        final data = response.data;
        if (data is Map && data['success'] == true) {
          _isFacebookConnected = data['is_connected'] ?? false;
          _facebookTotalItems = data['total_items'] ?? 0;
          _facebookTotalPages = data['total_pages'] ?? 1;
          final List rawList = data['posts'] ?? [];
          _facebookPosts = rawList
              .map((item) => SocialPostModel.fromJson(item))
              .toList();
        }
      }
    } catch (e) {
      debugPrint('[SocialProvider] Error fetching Facebook posts: $e');
    } finally {
      _isFetchingFacebookPosts = false;
      notifyListeners();
    }
  }

  Future<void> fetchInstagramPosts(String brokerId, {int page = 1}) async {
    _isFetchingInstagramPosts = true;
    _instagramCurrentPage = page;
    notifyListeners();

    try {
      final response = await SupabaseConfig.client.functions.invoke(
        'fetch-instagram-posts',
        body: {'broker_id': brokerId, 'page': page, 'limit': 10},
      );

      if (response.status == 200) {
        final data = response.data;
        if (data is Map && data['success'] == true) {
          _isInstagramConnected = data['is_connected'] ?? false;
          _instagramTotalItems = data['total_items'] ?? 0;
          _instagramTotalPages = data['total_pages'] ?? 1;
          final List rawList = data['posts'] ?? [];
          _instagramPosts = rawList
              .map((item) => SocialPostModel.fromJson(item))
              .toList();
        }
      }
    } catch (e) {
      debugPrint('[SocialProvider] Error fetching Instagram posts: $e');
    } finally {
      _isFetchingInstagramPosts = false;
      notifyListeners();
    }
  }

  // Refresh and fetch posts from Edge Functions
  Future<void> syncAndFetchPosts(String brokerId) async {
    _isSyncingPosts = true;
    notifyListeners();

    try {
      if (_selectedPlatformTab == SocialPlatform.instagram) {
        await fetchInstagramPosts(brokerId, page: _instagramCurrentPage);
      } else {
        await fetchFacebookPosts(brokerId, page: _facebookCurrentPage);
      }

      AppToast.showSuccess(
        'Refresh Complete',
        'Successfully loaded your social media posts.',
      );
    } catch (e) {
      debugPrint('Error loading social posts: $e');
      AppToast.showError(
        'Refresh Failed',
        'Could not load social posts: ${e.toString()}',
      );
    } finally {
      _isSyncingPosts = false;
      notifyListeners();
    }
  }

  // Fetch posts from supabase local DB table
  Future<void> fetchPosts(String brokerId) async {
    try {
      final response = await SupabaseConfig.client
          .from('social_posts')
          .select()
          .eq('broker_id', brokerId)
          .order('published_at', ascending: false);

      _posts = response.map((item) => SocialPostModel.fromJson(item)).toList();
      notifyListeners();
    } catch (e) {
      debugPrint('Error fetching social posts from DB: $e');
    }
  }

  // Enable automation by saving post into local DB schema (social_posts)
  Future<SocialPostModel?> enablePostAutomation(
    SocialPostModel post,
    String brokerId,
  ) async {
    try {
      // Prepare media_urls list matching schema jsonb format
      final List<Map<String, dynamic>> mediaUrlsList = [];
      if (post.mediaUrls != null && post.mediaUrls!.isNotEmpty) {
        for (final m in post.mediaUrls!) {
          mediaUrlsList.add(m.toJson());
        }
      } else if (post.mediaUrl != null && post.mediaUrl!.isNotEmpty) {
        mediaUrlsList.add({
          'url': post.mediaUrl,
          'type': post.mediaType ?? 'image',
          'thumbnail': post.thumbnailUrl ?? post.mediaUrl,
        });
      }

      final targetPostId = (post.postId != null && post.postId!.isNotEmpty)
          ? post.postId!
          : (post.platformPostId ?? post.id ?? '');

      final pageId = (post.pageId != null && post.pageId!.isNotEmpty)
          ? post.pageId!
          : (targetPostId.contains('_')
                ? targetPostId.split('_').first
                : 'main_page');

      final payload = <String, dynamic>{
        'broker_id': brokerId,
        'platform': post.platform?.dbValue ?? 'facebook',
        'page_id': pageId,
        'post_id': targetPostId,
        'caption': post.caption,
        'media_urls': mediaUrlsList,
        'permalink': post.permalink,
        'views_count': post.viewsCount ?? 0,
        'comment_count': post.commentCount ?? 0,
        'likes_count': post.likesCount ?? 0,
        if (post.publishedAt != null)
          'published_at': post.publishedAt?.toUtc().toIso8601String(),
        if (post.propertyId?.id != null) 'property_id': post.propertyId!.id,
      };

      final response = await SupabaseConfig.client
          .from('social_posts')
          .insert(payload)
          .select()
          .single();

      final insertedPost = SocialPostModel.fromJson(response);
      final updatedPost = post.copyWith(
        id: insertedPost.id,
        dbSocialPost: insertedPost,
      );

      _updatePostInLists(updatedPost);

      ClarityService.instance.sendCustomEvent('feature_enable_post_automation');

      AppToast.showSuccess(
        'Leads Activated',
        'Lead capture is now active for this post.',
      );
      return updatedPost;
    } catch (e) {
      debugPrint('[SocialProvider] Error enabling post automation: $e');
      final errStr = e.toString().toLowerCase();

      if (errStr.contains('duplicate key') ||
          errStr.contains('unique_broker_platform_post') ||
          errStr.contains('23505')) {
        try {
          final targetPostId = (post.postId != null && post.postId!.isNotEmpty)
              ? post.postId!
              : (post.platformPostId ?? post.id ?? '');

          final existing = await SupabaseConfig.client
              .from('social_posts')
              .select()
              .eq('broker_id', brokerId)
              .eq('platform', post.platform?.dbValue ?? 'facebook')
              .eq('post_id', targetPostId)
              .maybeSingle();

          if (existing != null) {
            final dbPost = SocialPostModel.fromJson(existing);
            final updatedPost = post.copyWith(
              id: dbPost.id,
              dbSocialPost: dbPost,
            );
            _updatePostInLists(updatedPost);
            AppToast.showSuccess(
              'Leads Active',
              'Lead capture is already active for this post.',
            );
            return updatedPost;
          }
        } catch (fetchErr) {
          debugPrint('[SocialProvider] Error handling conflict: $fetchErr');
        }
      }

      AppToast.showError(
        'Error',
        'Could not activate leads. Please try again.',
      );
      return null;
    }
  }

  // Disable automation by deleting post record
  Future<SocialPostModel?> disablePostAutomation(
    SocialPostModel post,
    String brokerId,
  ) async {
    try {
      final dbId =
          post.dbSocialPost?.id ??
          (post.id != null && post.id != post.platformPostId ? post.id : null);
      final targetPostId = post.postId ?? post.platformPostId ?? post.id;
      final platformVal = post.platform?.dbValue;

      if (dbId != null && dbId.isNotEmpty) {
        await SupabaseConfig.client
            .from('social_posts')
            .delete()
            .eq('id', dbId);
      } else if (targetPostId != null && targetPostId.isNotEmpty) {
        var query = SupabaseConfig.client
            .from('social_posts')
            .delete()
            .eq('broker_id', brokerId)
            .eq('post_id', targetPostId);
        if (platformVal != null) {
          query = query.eq('platform', platformVal);
        }
        await query;
      }

      final updatedPost = post.copyWith(dbSocialPost: null);

      _updatePostInLists(updatedPost);

      AppToast.showSuccess(
        'Leads Paused',
        'Lead capture has been paused for this post.',
      );
      return updatedPost;
    } catch (e) {
      debugPrint('[SocialProvider] Error disabling post automation: $e');
      AppToast.showError(
        'Error',
        'Could not pause leads. Please try again.',
      );
      return null;
    }
  }

  void _updatePostInLists(SocialPostModel updatedPost) {
    final targetId =
        updatedPost.platformPostId ?? updatedPost.postId ?? updatedPost.id;

    final fbIdx = _facebookPosts.indexWhere(
      (p) => (p.platformPostId ?? p.postId ?? p.id) == targetId,
    );
    if (fbIdx != -1) {
      _facebookPosts[fbIdx] = updatedPost;
    }

    final igIdx = _instagramPosts.indexWhere(
      (p) => (p.platformPostId ?? p.postId ?? p.id) == targetId,
    );
    if (igIdx != -1) {
      _instagramPosts[igIdx] = updatedPost;
    }

    notifyListeners();
  }

  // --- PUBLISHING STATE & METHODS ---
  bool _isPublishing = false;

  bool get isPublishing => _isPublishing;

  String _publishingStep = '';

  String get publishingStep => _publishingStep;

  double _publishingProgress = 0.0;

  double get publishingProgress => _publishingProgress;

  void _updatePublishingState(bool isPublishing, String step, double progress) {
    _isPublishing = isPublishing;
    _publishingStep = step;
    _publishingProgress = progress;
    notifyListeners();
  }

  // Upload an asset file to Supabase Storage using centralized SupabaseStorageService
  Future<String> uploadAsset(
    String fileName,
    Uint8List bytes, {
    String mimeType = 'image/jpeg',
  }) async {
    final publicUrl = await SupabaseStorageService.uploadFile(
      filePath: fileName,
      bucketName: 'social_assets',
      folderName: 'posts',
      customFileName: fileName,
      fileBytes: bytes,
    );
    return publicUrl ?? '';
  }

  // Helper method to resolve a valid public URL for a media item
  Future<String> _resolvePublicMediaUrl(
    PickedMedia media,
    String mimeType,
  ) async {
    // Case 1: Bytes are present (e.g. newly exported sticker overlay or picked file with bytes)
    if (media.bytes.isNotEmpty) {
      final sanitizedMediaName = media.name.replaceAll(
        RegExp(r'[^a-zA-Z0-9._-]'),
        '_',
      );
      final uniqueName =
          '${DateTime.now().millisecondsSinceEpoch}_$sanitizedMediaName';

      return await uploadAsset(
        uniqueName,
        media.bytes,
        mimeType: mimeType,
      );
    }

    // Case 2: Path is ALREADY a valid HTTP / HTTPS public URL (e.g. property image from Supabase storage)
    if (media.path.startsWith('http://') || media.path.startsWith('https://')) {
      return media.path;
    }

    // Case 3: Fetch file bytes via Dio (works on all platforms: Web, Android, iOS, Desktop)
    if (media.path.isNotEmpty) {
      try {
        final response = await Dio().get<List<int>>(
          media.path,
          options: Options(responseType: ResponseType.bytes),
        );
        if (response.data != null && response.data!.isNotEmpty) {
          final fileBytes = Uint8List.fromList(response.data!);
          final sanitizedMediaName = media.name.replaceAll(
            RegExp(r'[^a-zA-Z0-9._-]'),
            '_',
          );
          final uniqueName =
              '${DateTime.now().millisecondsSinceEpoch}_$sanitizedMediaName';

          return await uploadAsset(
            uniqueName,
            fileBytes,
            mimeType: mimeType,
          );
        }
      } catch (e) {
        debugPrint('[SocialProvider] Error reading media path for upload: $e');
      }
    }

    return '';
  }

  // Helper method to resolve cover URL for videos
  Future<String?> _resolvePublicCoverUrl(PickedMedia media) async {
    if (media.thumbnailBytes != null && media.thumbnailBytes!.isNotEmpty) {
      final sanitizedCoverName = (media.thumbnailName ?? "cover.jpg")
          .replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
      final coverName =
          '${DateTime.now().millisecondsSinceEpoch}_cover_$sanitizedCoverName';

      return await uploadAsset(
        coverName,
        media.thumbnailBytes!,
        mimeType: 'image/jpeg',
      );
    } else if (media.thumbnailName != null &&
        (media.thumbnailName!.startsWith('http://') ||
            media.thumbnailName!.startsWith('https://'))) {
      return media.thumbnailName;
    }
    return null;
  }

  // Orchestrate publishing post to Instagram
  Future<bool> publishInstagramPost({
    required String brokerId,
    String? propertyId,
    required String caption,
    required List<PickedMedia> medias,
  }) async {
    try {
      // 1. Uploading / Resolving media files
      _updatePublishingState(true, 'Uploading media files to Storage...', 0.1);
      final List<Map<String, dynamic>> mediaUrlsPayload = [];

      for (int i = 0; i < medias.length; i++) {
        final media = medias[i];
        final isVideo =
            media.type == 'video' || media.name.toLowerCase().endsWith('.mp4');
        final mimeType = isVideo ? 'video/mp4' : 'image/jpeg';

        final mediaUrl = await _resolvePublicMediaUrl(media, mimeType);

        if (mediaUrl.isEmpty) {
          throw Exception(
            'Could not resolve a valid public image URL for ${media.name}',
          );
        }

        // Test public accessibility of the uploaded URL
        try {
          final testRes = await Dio().head(mediaUrl);
          debugPrint(
            '[SocialProvider] Public URL accessibility check for $mediaUrl: Status ${testRes.statusCode}',
          );
        } catch (testErr) {
          debugPrint(
            '[SocialProvider] CRITICAL: The asset URL ($mediaUrl) is NOT publicly accessible! Error: $testErr',
          );
        }

        String? coverUrl;
        if (isVideo) {
          _updatePublishingState(
            true,
            'Uploading video covers (${i + 1}/${medias.length})...',
            0.1 + (i / medias.length) * 0.3,
          );
          coverUrl = await _resolvePublicCoverUrl(media);
        }

        mediaUrlsPayload.add({
          'media_url': mediaUrl,
          'thumbnail_url': coverUrl,
          'type': media.type,
        });
      }

      // 2. Invoking publish edge function
      _updatePublishingState(true, 'Publishing to Instagram...', 0.6);

      final response = await SupabaseConfig.client.functions.invoke(
        'publish-instagram-post',
        body: {
          'broker_id': brokerId,
          'property_id': propertyId,
          'caption': caption,
          'medias': mediaUrlsPayload,
        },
      );

      if (response.status != 200) {
        final data = response.data;
        final errorMsg = data is Map
            ? (data['message'] ?? 'Failed to publish.')
            : 'Server error.';
        throw Exception(errorMsg.toString());
      }

      final data = response.data;
      if (data is Map && data['success'] == true) {
        _updatePublishingState(true, 'Syncing database...', 0.9);

        // Refresh local feed
        await fetchPosts(brokerId);

        _updatePublishingState(false, '', 1.0);
        AppToast.showSuccess(
          'Publish Complete',
          'Your post is now live on Instagram!',
        );
        return true;
      } else {
        final msg = data is Map
            ? (data['message'] ?? 'Unknown error')
            : 'Publishing failed.';
        throw Exception(msg.toString());
      }
    } catch (e) {
      debugPrint('Error publishing instagram post: $e');
      _updatePublishingState(false, '', 0.0);
      AppToast.showError('Publish Failed', e.toString());
      return false;
    }
  }

  // Orchestrate publishing post to Facebook Page
  Future<bool> publishFacebookPost({
    required String brokerId,
    String? propertyId,
    required String caption,
    required List<PickedMedia> medias,
  }) async {
    try {
      // 1. Uploading / Resolving media files
      _updatePublishingState(true, 'Uploading media files to Storage...', 0.1);
      final List<Map<String, dynamic>> mediaUrlsPayload = [];

      for (int i = 0; i < medias.length; i++) {
        final media = medias[i];
        final isVideo =
            media.type == 'video' || media.name.toLowerCase().endsWith('.mp4');
        final mimeType = isVideo ? 'video/mp4' : 'image/jpeg';

        final mediaUrl = await _resolvePublicMediaUrl(media, mimeType);

        if (mediaUrl.isEmpty) {
          throw Exception(
            'Could not resolve a valid public image URL for ${media.name}',
          );
        }

        // Test public accessibility of the uploaded URL
        try {
          final testRes = await Dio().head(mediaUrl);
          debugPrint(
            '[SocialProvider] Public URL accessibility check for $mediaUrl: Status ${testRes.statusCode}',
          );
        } catch (testErr) {
          debugPrint(
            '[SocialProvider] CRITICAL: The asset URL ($mediaUrl) is NOT publicly accessible! Error: $testErr',
          );
        }

        String? coverUrl;
        if (isVideo) {
          _updatePublishingState(
            true,
            'Uploading video covers (${i + 1}/${medias.length})...',
            0.1 + (i / medias.length) * 0.3,
          );
          coverUrl = await _resolvePublicCoverUrl(media);
        }

        mediaUrlsPayload.add({
          'media_url': mediaUrl,
          'thumbnail_url': coverUrl,
          'type': media.type,
        });
      }

      // 2. Invoking publish edge function
      _updatePublishingState(true, 'Publishing to Facebook Page...', 0.6);

      final response = await SupabaseConfig.client.functions.invoke(
        'publish-facebook-post',
        body: {
          'broker_id': brokerId,
          'property_id': propertyId,
          'caption': caption,
          'medias': mediaUrlsPayload,
        },
      );

      if (response.status != 200) {
        final data = response.data;
        final errorMsg = data is Map
            ? (data['message'] ?? 'Failed to publish.')
            : 'Server error.';
        throw Exception(errorMsg.toString());
      }

      final data = response.data;
      if (data is Map && data['success'] == true) {
        _updatePublishingState(true, 'Syncing database...', 0.9);

        // Refresh local feed
        await fetchPosts(brokerId);

        _updatePublishingState(false, '', 1.0);
        AppToast.showSuccess(
          'Publish Complete',
          'Your post is now live on Facebook!',
        );
        return true;
      } else {
        final msg = data is Map
            ? (data['message'] ?? 'Unknown error')
            : 'Publishing failed.';
        throw Exception(msg.toString());
      }
    } catch (e) {
      debugPrint('Error publishing facebook post: $e');
      _updatePublishingState(false, '', 0.0);
      AppToast.showError('Publish Failed', e.toString());
      return false;
    }
  }

  /// Reset state and unsubscribe on user sign out
  void clear() {
    unsubscribeSocialAccounts();
    _isFacebookConnected = false;
    _isInstagramConnected = false;
    _facebookAccount = null;
    _instagramAccount = null;
    _posts = [];
    _facebookPosts = [];
    _instagramPosts = [];
    _hasFetchedInitialConnections = false;
    _isFetchingConnections = false;
    _isSyncingPosts = false;
    _isFetchingFacebookPosts = false;
    _isFetchingInstagramPosts = false;
    _facebookCurrentPage = 1;
    _facebookTotalPages = 1;
    _facebookTotalItems = 0;
    _instagramCurrentPage = 1;
    _instagramTotalPages = 1;
    _instagramTotalItems = 0;
    notifyListeners();
  }
}

class PickedMedia {
  final String path;
  final String name;
  final Uint8List bytes;
  final String type; // 'image' or 'video'

  Uint8List? thumbnailBytes;
  String? thumbnailName;

  PickedMedia({
    required this.path,
    required this.name,
    required this.bytes,
    required this.type,
    this.thumbnailBytes,
    this.thumbnailName,
  });
}
