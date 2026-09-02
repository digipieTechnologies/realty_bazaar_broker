// File: lib/modules/dashboard/widgets/leads/lead_table_widget.dart
// Purpose: Reusable table and list widget for social lead dashboard using AppFilterButton & LeadFilterPopover for platform filtering.

import 'package:flutter/material.dart';

import '../../../../app/app_colors.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../models/social_lead_model.dart';
import '../../../../util/common_ext.dart';
import '../../../../widgets/buttons/app_button.dart';
import '../../../../widgets/common/app_empty_state_widget.dart';
import '../../../../widgets/common/app_filter_popup.dart';
import '../../../../widgets/common/app_pagination_widget.dart';
import '../../../../widgets/common/app_table_widget.dart';
import '../../../../widgets/shimmer/lead_list_shimmer_widget.dart';
import 'lead_filter_popover.dart';
import 'lead_tile_widget.dart';

class LeadTableWidget extends StatefulWidget {
  final List<SocialLeadModel> leads;
  final bool isLoading;
  final int currentPage;
  final int totalPages;
  final int totalItems;
  final List<String> selectedPlatforms;
  final ValueChanged<List<String>>? onPlatformsFilterChanged;
  final String? activeFilter;
  final ValueChanged<String>? onFilterChanged;
  final ValueChanged<int> onPageChanged;
  final VoidCallback? onAddLeadPressed;
  final ValueChanged<String>? onSearchChanged;

  const LeadTableWidget({
    super.key,
    required this.leads,
    this.isLoading = false,
    required this.currentPage,
    required this.totalPages,
    required this.totalItems,
    this.selectedPlatforms = const [],
    this.onPlatformsFilterChanged,
    this.activeFilter,
    this.onFilterChanged,
    required this.onPageChanged,
    this.onAddLeadPressed,
    this.onSearchChanged,
  });

  @override
  State<LeadTableWidget> createState() => _LeadTableWidgetState();
}

class _LeadTableWidgetState extends State<LeadTableWidget> {
  late List<String> _localPlatformsFilter;

  @override
  void initState() {
    super.initState();
    _localPlatformsFilter = List<String>.from(widget.selectedPlatforms);
    if (_localPlatformsFilter.isEmpty && widget.activeFilter != null && widget.activeFilter != 'all') {
      _localPlatformsFilter = [widget.activeFilter!];
    }
  }

  @override
  void didUpdateWidget(covariant LeadTableWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedPlatforms != oldWidget.selectedPlatforms) {
      _localPlatformsFilter = List<String>.from(widget.selectedPlatforms);
    }
  }

  void _applyFilter() {
    if (widget.onPlatformsFilterChanged != null) {
      widget.onPlatformsFilterChanged!(_localPlatformsFilter);
    } else if (widget.onFilterChanged != null) {
      widget.onFilterChanged!(_localPlatformsFilter.isEmpty ? 'all' : _localPlatformsFilter.first);
    }
  }

  @override
  Widget build(BuildContext context) {
    final useTileView = !context.isDesktop;

    return AppTableContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Toolbar (Search Field, Filter Button & Add Lead Button)
          Padding(
            padding: EdgeInsets.all(useTileView ? 8.0 : 16.0),
            child: Row(
              children: [
                Expanded(
                  child: AppTableSearchField(
                    onSearchChanged: widget.onSearchChanged,
                    hintText: context.tr('search_leads_hint'),
                  ),
                ),
                const SizedBox(width: 12.0),
                AppFilterButton(
                  title: context.tr('filter_leads'),
                  onClear: () {
                    setState(() {
                      _localPlatformsFilter = [];
                    });
                    _applyFilter();
                  },
                  onApply: () {
                    _applyFilter();
                  },
                  child: LeadFilterPopover(
                    selectedPlatforms: _localPlatformsFilter,
                    onPlatformsChanged: (updated) {
                      setState(() {
                        _localPlatformsFilter = updated;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 12.0),
                AppButton(
                  text: context.isMobile ? null : context.tr('add_new_lead'),
                  iconData: Icons.person_add_alt_1_rounded,
                  height: 42.0,
                  width: context.isMobile ? 42.0 : null,
                  padding: context.isMobile ? EdgeInsets.zero : const EdgeInsets.symmetric(horizontal: 16.0),
                  borderRadius: 10.0,
                  color: AppColors.primary,
                  tooltip: context.tr('add_new_lead'),
                  onPressed: widget.onAddLeadPressed,
                ),
              ],
            ),
          ),

          // Desktop Table Header Row (Only shown on full Desktop Web view)
          if (!useTileView)
            AppTableHeaderRow(
              columns: [
                AppTableColumnDef(title: context.tr('col_lead_details'), flex: 3),
                AppTableColumnDef(title: context.tr('col_source'), flex: 2, alignment: Alignment.center),
                AppTableColumnDef(title: context.tr('col_property_details'), flex: 4),
                AppTableColumnDef(title: context.tr('col_created_at'), flex: 2),
              ],
              endSpacing: 40.0,
            ),

          // Lead Items / Shimmer Loading State
          if (widget.isLoading)
            const LeadListShimmerWidget(count: 5)
          else if (widget.leads.isEmpty)
            AppEmptyStateWidget(
              icon: Icons.group_off_rounded,
              title: context.tr('no_leads_found'),
              description: context.tr('no_leads_empty_desc'),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: useTileView ? const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0) : EdgeInsets.zero,
              itemCount: widget.leads.length,
              itemBuilder: (context, index) {
                final lead = widget.leads[index];
                return LeadTileWidget(lead: lead, isMobile: useTileView);
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
