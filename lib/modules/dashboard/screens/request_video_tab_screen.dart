import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'package:provider/provider.dart';

import '../../../app/app_colors.dart';
import '../../../app/app_constants.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../providers/auth/auth_provider.dart';
import '../../../providers/video_request/video_request_provider.dart';
import '../../../util/common_ext.dart';
import '../../../widgets/common/common_app_bar.dart';
import '../../../widgets/dialogs/select_property_for_video_request_dialog.dart';
import '../../../widgets/shimmer/video_request_list_shimmer_widget.dart';
import '../../../widgets/toast/app_toast.dart';
import '../widgets/video_requests/video_request_summary_section.dart';
import '../widgets/video_requests/video_request_table_widget.dart';

class RequestVideoTabScreen extends StatefulWidget {
  const RequestVideoTabScreen({super.key});

  @override
  State<RequestVideoTabScreen> createState() => _RequestVideoTabScreenState();
}

class _RequestVideoTabScreenState extends State<RequestVideoTabScreen> {
  String? _brokerId;
  final _storage = GetStorage();
  bool _isStatsExpanded = true;
  VideoRequestProvider? _videoRequestProvider;

  @override
  void initState() {
    super.initState();
    _isStatsExpanded = _storage.read<bool>('video_requests_stats_expanded') ?? true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      _brokerId = authProvider.userProfile?.brokerId?.id;

      _videoRequestProvider = context.read<VideoRequestProvider>();
      _videoRequestProvider?.fetchVideoRequestCounts(brokerId: _brokerId);
      _videoRequestProvider?.fetchVideoRequests(brokerId: _brokerId, page: 1);

      if (_brokerId != null) {
        _videoRequestProvider?.subscribeToVideoRequests(_brokerId!);
      }
    });
  }

  @override
  void dispose() {
    _videoRequestProvider?.unsubscribeVideoRequests();
    super.dispose();
  }

  Future<void> _handleCancelRequest(dynamic req) async {
    final provider = context.read<VideoRequestProvider>();
    final success = await provider.cancelRequest(req.id, brokerId: _brokerId);
    if (!mounted) return;
    if (success) {
      AppToast.showSuccess(
        context.tr('toast_request_cancelled_title'),
        context.tr('toast_request_cancelled_desc'),
      );
    } else {
      AppToast.showError(context.tr('toast_action_failed_title'), context.tr('toast_action_failed_desc'));
    }
  }

  void _handleRequestVideo() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final brokerId = authProvider.userProfile?.brokerId?.id ?? _brokerId ?? '';
    if (brokerId.isEmpty) {
      AppToast.showError('Error', 'Broker profile information not available.');
      return;
    }
    showDialog(
      context: context,
      builder: (context) => SelectPropertyForVideoRequestDialog(brokerId: brokerId),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = context.isMobileUI;
    final canPop = Navigator.of(context).canPop();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: canPop ? CommonAppBar(title: context.tr('video_requests')) : null,
      body: SafeArea(
        child: Consumer<VideoRequestProvider>(
          builder: (context, provider, child) {
            return SingleChildScrollView(
              padding: AppConstants.getTabPadding(context, bottomExtra: isMobile ? 80.0 : 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Top Metric Summary Cards
                  provider.isLoading && provider.requests.isEmpty
                      ? const VideoRequestStatsShimmerWidget()
                      : VideoRequestSummarySection(
                          totalRequests: provider.totalRequests,
                          pendingRequests: provider.pendingRequests,
                          inProgressRequests: provider.inProgressRequests,
                          completedRequests: provider.completedRequests,
                          isExpanded: _isStatsExpanded,
                          onToggle: () {
                            setState(() {
                              _isStatsExpanded = !_isStatsExpanded;
                              _storage.write('video_requests_stats_expanded', _isStatsExpanded);
                            });
                          },
                        ),
                  SizedBox(height: isMobile ? 14.0 : 24.0),

                  // 2. Video Requests Table / List View
                  VideoRequestTableWidget(
                    requests: provider.requests,
                    isLoading: provider.isLoading,
                    currentPage: provider.currentPage,
                    totalPages: provider.totalPages,
                    totalItems: provider.totalItems,
                    itemsPerPage: provider.itemsPerPage,
                    onSearchChanged: (value) {
                      provider.fetchVideoRequests(brokerId: _brokerId, page: 1, searchQuery: value);
                    },
                    onPageChanged: (newPage) {
                      provider.fetchVideoRequests(
                        brokerId: _brokerId,
                        page: newPage,
                        searchQuery: provider.searchQuery,
                      );
                    },
                    onCancelRequest: _handleCancelRequest,
                    statusesFilter: provider.statusesFilter,
                    onStatusesFilterChanged: (newStatuses) {
                      provider.setStatusesFilter(newStatuses);
                      provider.fetchVideoRequests(
                        brokerId: _brokerId,
                        page: 1,
                        searchQuery: provider.searchQuery,
                      );
                    },
                    onRequestVideoPressed: _handleRequestVideo,
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
