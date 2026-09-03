// File: lib/modules/visits/widgets/visit_table_widget.dart
// Purpose: Main responsive table and tile list container for site visits dashboard,
//          with search field, status filter popover, date chips, and pagination.

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../app/app_colors.dart';
import '../../../../app/app_text_styles.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../models/property_visit_model.dart';
import '../../../../util/app_date_utils.dart';
import '../../../../util/common_ext.dart';
import '../../../../widgets/buttons/app_button.dart';
import '../../../../widgets/common/app_empty_state_widget.dart';
import '../../../../widgets/common/app_filter_popup.dart';
import '../../../../widgets/common/app_pagination_widget.dart';
import '../../../../widgets/common/app_table_widget.dart';
import '../../../../widgets/common/user_avatar_widget.dart';
import '../screens/view_visit_screen.dart';
import 'reschedule_visit_dialog.dart';
import 'visit_filter_popover.dart';
import 'visit_list_shimmer_widget.dart';
import 'visit_status_badge.dart';
import 'visit_tile_widget.dart';

class VisitTableWidget extends StatefulWidget {
  final List<PropertyVisitModel> visits;
  final bool isLoading;
  final int currentPage;
  final int totalPages;
  final int totalItems;
  final List<String> selectedStatuses;
  final ValueChanged<List<String>>? onStatusesFilterChanged;
  final String dateFilter;
  final ValueChanged<String>? onDateFilterChanged;
  final ValueChanged<int> onPageChanged;
  final VoidCallback? onScheduleVisitPressed;
  final ValueChanged<String>? onSearchChanged;

  const VisitTableWidget({
    super.key,
    required this.visits,
    this.isLoading = false,
    required this.currentPage,
    required this.totalPages,
    required this.totalItems,
    this.selectedStatuses = const [],
    this.onStatusesFilterChanged,
    this.dateFilter = 'all',
    this.onDateFilterChanged,
    required this.onPageChanged,
    this.onScheduleVisitPressed,
    this.onSearchChanged,
  });

  @override
  State<VisitTableWidget> createState() => _VisitTableWidgetState();
}

class _VisitTableWidgetState extends State<VisitTableWidget> {
  late List<String> _localStatuses;

  @override
  void initState() {
    super.initState();
    _localStatuses = List<String>.from(widget.selectedStatuses);
  }

  @override
  void didUpdateWidget(covariant VisitTableWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedStatuses != oldWidget.selectedStatuses) {
      _localStatuses = List<String>.from(widget.selectedStatuses);
    }
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint('[VisitTableWidget] Error launching url: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final useTileView = !context.isDesktop;

    return AppTableContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Toolbar: Search, Filter, Schedule Button
          Padding(
            padding: EdgeInsets.all(useTileView ? 12.0 : 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: AppTableSearchField(
                        onSearchChanged: widget.onSearchChanged,
                        hintText: context.tr('search_visits_hint'),
                      ),
                    ),
                    const SizedBox(width: 12.0),
                    AppFilterButton(
                      title: 'Filter Visits',
                      onClear: () {
                        setState(() => _localStatuses = []);
                        widget.onStatusesFilterChanged?.call([]);
                      },
                      onApply: () {
                        widget.onStatusesFilterChanged?.call(_localStatuses);
                      },
                      child: VisitFilterPopover(
                        selectedStatuses: _localStatuses,
                        onStatusesChanged: (newStatuses) {
                          setState(() => _localStatuses = newStatuses);
                        },
                      ),
                    ),
                    if (widget.onScheduleVisitPressed != null) ...[
                      const SizedBox(width: 12.0),
                      AppButton(
                        text: useTileView ? null : context.tr('schedule_site_visit'),
                        iconData: Icons.add_rounded,
                        onPressed: widget.onScheduleVisitPressed,
                        height: 42.0,
                        padding: useTileView
                            ? const EdgeInsets.all(10.0)
                            : const EdgeInsets.symmetric(horizontal: 16.0),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 12.0),

                // Date Filter Chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildDateChip('all', context.tr('filter_all')),
                      const SizedBox(width: 8.0),
                      _buildDateChip('today', context.tr('filter_today')),
                      const SizedBox(width: 8.0),
                      _buildDateChip('upcoming', context.tr('filter_upcoming')),
                      const SizedBox(width: 8.0),
                      _buildDateChip('past', context.tr('filter_past')),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1.0, color: AppColors.border),

          // Main Content
          if (widget.isLoading)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: VisitListShimmerWidget(count: useTileView ? 4 : 6),
            )
          else if (widget.visits.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 48.0, horizontal: 16.0),
              child: Center(
                child: AppEmptyStateWidget(
                  title: context.tr('no_visits_found'),
                  description: context.tr('no_visits_found_desc'),
                  icon: Icons.calendar_today_outlined,
                  action: widget.onScheduleVisitPressed != null
                      ? AppButton(
                          text: context.tr('schedule_first_visit'),
                          iconData: Icons.add_rounded,
                          onPressed: widget.onScheduleVisitPressed,
                        )
                      : null,
                ),
              ),
            )
          else if (useTileView)
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: widget.visits.length,
                itemBuilder: (context, index) {
                  final visit = widget.visits[index];
                  return VisitTileWidget(visit: visit, isMobile: true);
                },
              ),
            )
          else
            // Desktop Data Table
            _buildDesktopTable(context),

          // Pagination Footer
          if (widget.totalItems > 0)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: AppPaginationWidget(
                currentPage: widget.currentPage,
                totalPages: widget.totalPages,
                totalItems: widget.totalItems,
                onPageChanged: widget.onPageChanged,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDateChip(String key, String label) {
    final isSelected = widget.dateFilter == key;

    return InkWell(
      onTap: () => widget.onDateFilterChanged?.call(key),
      borderRadius: BorderRadius.circular(20.0),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 6.0),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.circular(20.0),
          border: Border.all(color: isSelected ? AppColors.primary : AppColors.border, width: 1.0),
        ),
        child: Text(
          label,
          style: AppTextStyles.caption.copyWith(
            color: isSelected ? Colors.white : AppColors.textSecondary,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildDesktopTable(BuildContext context) {
    return Column(
      children: [
        // Table Header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
          decoration: const BoxDecoration(
            color: AppColors.background,
            border: Border(bottom: BorderSide(color: AppColors.border, width: 1.0)),
          ),
          child: Row(
            children: [
              Expanded(flex: 3, child: Text('CLIENT', style: _headerStyle)),
              Expanded(flex: 4, child: Text('PROPERTY', style: _headerStyle)),
              Expanded(flex: 3, child: Text('SCHEDULE', style: _headerStyle)),
              Expanded(flex: 2, child: Text('STATUS', style: _headerStyle)),
              const SizedBox(
                width: 120,
                child: Text('ACTIONS', textAlign: TextAlign.right, style: _headerStyle),
              ),
            ],
          ),
        ),

        // Table Rows
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: widget.visits.length,
          separatorBuilder: (context, index) => const Divider(height: 1.0, color: AppColors.border),
          itemBuilder: (context, index) {
            final visit = widget.visits[index];
            final dateStr = AppDateUtils.formatDate(visit.visitDate);

            return InkWell(
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => ViewVisitScreen(visit: visit, visitId: visit.id),
                  ),
                );
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 14.0),
                child: Row(
                  children: [
                    // Client Info
                    Expanded(
                      flex: 3,
                      child: Row(
                        children: [
                          UserAvatarWidget(name: visit.clientName, radius: 18.0),
                          const SizedBox(width: 10.0),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  visit.clientName,
                                  style: AppTextStyles.body2.copyWith(fontWeight: FontWeight.bold),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  visit.contactNumber,
                                  style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Property
                    Expanded(
                      flex: 4,
                      child: Text(
                        visit.property?.propertyTitle ?? 'Property Visit',
                        style: AppTextStyles.body2,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),

                    // Schedule Date & Slot
                    Expanded(
                      flex: 3,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(dateStr, style: AppTextStyles.body2.copyWith(fontWeight: FontWeight.w600)),
                          Text(
                            visit.timeSlot,
                            style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),

                    // Status
                    Expanded(
                      flex: 2,
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: VisitStatusBadge(status: visit.status, isCompact: true),
                      ),
                    ),

                    // Actions
                    SizedBox(
                      width: 120,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          IconButton(
                            icon: SvgPicture.asset(
                              'assets/icons/ic_whatsapp.svg',
                              width: 24.0,
                              height: 24.0,
                              colorFilter: const ColorFilter.mode(Color(0xFF25D366), BlendMode.srcIn),
                            ),
                            onPressed: () => _launchUrl(visit.buildWhatsappUrl()),
                            visualDensity: VisualDensity.compact,
                            padding: const EdgeInsets.all(4.0),
                            tooltip: 'WhatsApp',
                          ),
                          IconButton(
                            icon: SvgPicture.asset(
                              'assets/icons/ic_call.svg',
                              width: 22.0,
                              height: 22.0,
                              colorFilter: const ColorFilter.mode(Color(0xFF7E22CE), BlendMode.srcIn),
                            ),
                            padding: const EdgeInsets.all(4.0),
                            visualDensity: VisualDensity.compact,
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (context) => RescheduleVisitDialog(visit: visit),
                              );
                            },
                            tooltip: 'Reschedule',
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.arrow_forward_ios_rounded,
                              size: 14.0,
                              color: AppColors.textSecondary,
                            ),
                            padding: const EdgeInsets.all(4.0),
                            visualDensity: VisualDensity.compact,
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) => ViewVisitScreen(visit: visit, visitId: visit.id),
                                ),
                              );
                            },
                            tooltip: 'View Details',
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  static const TextStyle _headerStyle = TextStyle(
    fontSize: 11.0,
    fontWeight: FontWeight.bold,
    color: AppColors.textSecondary,
    letterSpacing: 0.8,
  );
}
