// File: lib/modules/dashboard/widgets/video_requests/video_request_table_widget.dart
// Purpose: Reusable table and list widget for video request dashboard.

// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';

import '../../../../app/app_colors.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../models/models.dart';
import '../../../../util/common_ext.dart';
import '../../../../widgets/buttons/app_button.dart';
import '../../../../widgets/common/app_empty_state_widget.dart';
import '../../../../widgets/common/app_filter_popup.dart';
import '../../../../widgets/common/app_pagination_widget.dart';
import '../../../../widgets/common/app_table_widget.dart';
import '../../../../widgets/shimmer/video_request_list_shimmer_widget.dart';
import 'video_request_filter_popover.dart';
import 'video_request_tile_widget.dart';

class VideoRequestTableWidget extends StatefulWidget {
  final List<VideoRequestModel> requests;
  final bool isLoading;
  final int currentPage;
  final int totalPages;
  final int totalItems;
  final int itemsPerPage;
  final ValueChanged<int> onPageChanged;
  final ValueChanged<String>? onSearchChanged;
  final Function(VideoRequestModel)? onCancelRequest;
  final VideoRequestStatus? statusFilter;
  final ValueChanged<VideoRequestStatus?>? onStatusFilterChanged;
  final List<VideoRequestStatus>? statusesFilter;
  final ValueChanged<List<VideoRequestStatus>>? onStatusesFilterChanged;
  final VoidCallback? onRequestVideoPressed;

  const VideoRequestTableWidget({
    super.key,
    required this.requests,
    required this.isLoading,
    required this.currentPage,
    required this.totalPages,
    required this.totalItems,
    required this.itemsPerPage,
    required this.onPageChanged,
    this.onSearchChanged,
    this.onCancelRequest,
    this.statusFilter,
    this.onStatusFilterChanged,
    this.statusesFilter,
    this.onStatusesFilterChanged,
    this.onRequestVideoPressed,
  });

  @override
  State<VideoRequestTableWidget> createState() => _VideoRequestTableWidgetState();
}

class _VideoRequestTableWidgetState extends State<VideoRequestTableWidget> {
  List<VideoRequestStatus> _localStatusesFilter = [];

  @override
  void initState() {
    super.initState();
    _localStatusesFilter =
        widget.statusesFilter ?? (widget.statusFilter != null ? [widget.statusFilter!] : []);
  }

  @override
  void didUpdateWidget(covariant VideoRequestTableWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.statusesFilter != oldWidget.statusesFilter) {
      setState(() {
        _localStatusesFilter = widget.statusesFilter ?? [];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final useTileView = !context.isDesktop;

    return AppTableContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Toolbar (Search Field & Filter Button)
          Padding(
            padding: EdgeInsets.all(useTileView ? 8.0 : 16.0),
            child: Row(
              children: [
                Expanded(
                  child: AppTableSearchField(
                    onSearchChanged: widget.onSearchChanged,
                    hintText: context.tr('search_requests_hint'),
                  ),
                ),
                const SizedBox(width: 12.0),
                AppFilterButton(
                  title: 'Filter Requests',
                  onClear: () {
                    setState(() {
                      _localStatusesFilter = [];
                    });
                    if (widget.onStatusesFilterChanged != null) {
                      widget.onStatusesFilterChanged!([]);
                    } else if (widget.onStatusFilterChanged != null) {
                      widget.onStatusFilterChanged!(null);
                    }
                  },
                  onApply: () {
                    if (widget.onStatusesFilterChanged != null) {
                      widget.onStatusesFilterChanged!(_localStatusesFilter);
                    } else if (widget.onStatusFilterChanged != null) {
                      widget.onStatusFilterChanged!(
                        _localStatusesFilter.length == 1 ? _localStatusesFilter.first : null,
                      );
                    }
                  },
                  child: VideoRequestFilterPopover(
                    selectedStatuses: _localStatusesFilter,
                    onStatusesChanged: (updated) {
                      setState(() {
                        _localStatusesFilter = updated;
                      });
                    },
                  ),
                ),
                if (widget.onRequestVideoPressed != null) ...[
                  const SizedBox(width: 12.0),
                  AppButton(
                    text: context.isMobileUI ? null : context.tr('generate_video_request'),
                    iconData: Icons.add_rounded,
                    height: 42.0,
                    width: context.isMobileUI ? 42.0 : null,
                    padding: context.isMobileUI
                        ? EdgeInsets.zero
                        : const EdgeInsets.symmetric(horizontal: 16.0),
                    borderRadius: 10.0,
                    color: AppColors.primary,
                    tooltip: context.tr('generate_video_request'),
                    onPressed: widget.onRequestVideoPressed,
                  ),
                ],
              ],
            ),
          ),

          // Desktop Table Header Row
          if (!useTileView)
            const AppTableHeaderRow(
              columns: [
                AppTableColumnDef(title: 'PROPERTY DETAILS', flex: 3),
                AppTableColumnDef(title: 'STATUS', flex: 2),
                AppTableColumnDef(title: 'BROKER NOTES', flex: 4),
                AppTableColumnDef(title: 'CREATED AT', flex: 2),
              ],
              endSpacing: 40.0,
            ),

          // Table Body / List
          if (widget.isLoading)
            const VideoRequestListShimmerWidget(count: 3)
          else if (widget.requests.isEmpty)
            AppEmptyStateWidget(
              icon: Icons.video_library_outlined,
              title: context.tr('no_requests_found'),
              description: 'No video shoot requests found matching your current filter selection.',
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: useTileView
                  ? const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0)
                  : EdgeInsets.zero,
              itemCount: widget.requests.length,
              itemBuilder: (context, index) {
                final req = widget.requests[index];
                return VideoRequestTileWidget(
                  req: req,
                  isMobile: useTileView,
                  onCancelPressed: widget.onCancelRequest != null ? () => widget.onCancelRequest!(req) : null,
                );
              },
            ),

          // Pagination Footer Widget
          AppPaginationWidget(
            currentPage: widget.currentPage,
            totalPages: widget.totalPages,
            totalItems: widget.totalItems,
            onPageChanged: widget.onPageChanged,
          ),
        ],
      ),
    );
  }
}
