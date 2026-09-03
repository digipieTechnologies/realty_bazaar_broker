// File: lib/modules/visits/screens/visits_tab_screen.dart
// Purpose: Main Site Visits Dashboard screen supporting RPC pagination, status filtering,
//          date chips ('all', 'today', 'upcoming', 'past'), search, and real-time database subscriptions.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../app/app_colors.dart';
import '../../../app/app_constants.dart';
import '../../../models/property_visit_model.dart';
import '../../../providers/auth/auth_provider.dart';
import '../../../providers/visit/visit_provider.dart';
import '../../../util/common_ext.dart';
import '../widgets/schedule_visit_dialog.dart';
import '../widgets/visit_table_widget.dart';

class VisitsTabScreen extends StatefulWidget {
  const VisitsTabScreen({super.key});

  @override
  State<VisitsTabScreen> createState() => _VisitsTabScreenState();
}

class _VisitsTabScreenState extends State<VisitsTabScreen> {
  String? _brokerId;
  VisitProvider? _visitProvider;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      _brokerId = authProvider.userProfile?.brokerId?.id;

      _visitProvider = context.read<VisitProvider>();
      _visitProvider?.fetchVisits(brokerId: _brokerId, page: 1);

      if (_brokerId != null && _brokerId!.isNotEmpty) {
        _visitProvider?.subscribeToVisits(_brokerId!);
      }
    });
  }

  @override
  void dispose() {
    _visitProvider?.unsubscribeVisits();
    super.dispose();
  }

  Future<void> _handleScheduleVisit() async {
    final newVisit = await showDialog<PropertyVisitModel>(
      context: context,
      builder: (context) => const ScheduleVisitDialog(),
    );

    if (newVisit != null && mounted) {
      context.read<VisitProvider>().fetchVisits(
            brokerId: _brokerId,
            page: 1,
            searchQuery: context.read<VisitProvider>().searchQuery,
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = context.isMobile;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Consumer<VisitProvider>(
          builder: (context, provider, child) {
            return SingleChildScrollView(
              padding: AppConstants.getTabPadding(context, bottomExtra: isMobile ? 80.0 : 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  VisitTableWidget(
                    visits: provider.visits,
                    isLoading: provider.isLoading,
                    currentPage: provider.currentPage,
                    totalPages: provider.totalPages,
                    totalItems: provider.totalItems,
                    selectedStatuses: provider.statusesFilter,
                    onStatusesFilterChanged: (statuses) {
                      provider.setStatusesFilter(statuses, brokerId: _brokerId);
                    },
                    dateFilter: provider.dateFilter,
                    onDateFilterChanged: (dateFilter) {
                      provider.setDateFilter(dateFilter, brokerId: _brokerId);
                    },
                    onSearchChanged: (query) {
                      provider.fetchVisits(brokerId: _brokerId, page: 1, searchQuery: query);
                    },
                    onPageChanged: (newPage) {
                      provider.fetchVisits(
                        brokerId: _brokerId,
                        page: newPage,
                        searchQuery: provider.searchQuery,
                      );
                    },
                    onScheduleVisitPressed: _handleScheduleVisit,
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
