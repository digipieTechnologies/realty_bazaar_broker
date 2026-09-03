// File: lib/modules/dashboard/screens/leads_tab_screen.dart
// Purpose: Main Social Leads Dashboard screen supporting RPC-based pagination, platform filtering, search, and real-time database subscriptions.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:the_realty_bazaar/util/common_ext.dart';

import '../../../app/app_colors.dart';
import '../../../app/app_constants.dart';
import '../../../models/social_lead_model.dart';
import '../../../providers/auth/auth_provider.dart';
import '../../../providers/lead/lead_provider.dart';
import '../widgets/leads/add_lead_dialog.dart';
import '../widgets/leads/lead_table_widget.dart';

class LeadsTabScreen extends StatefulWidget {
  const LeadsTabScreen({super.key});

  @override
  State<LeadsTabScreen> createState() => _LeadsTabScreenState();
}

class _LeadsTabScreenState extends State<LeadsTabScreen> {
  String? _brokerId;
  LeadProvider? _leadProvider;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      _brokerId = authProvider.userProfile?.brokerId?.id;

      _leadProvider = context.read<LeadProvider>();
      _leadProvider?.fetchLeads(brokerId: _brokerId, page: 1);

      if (_brokerId != null && _brokerId!.isNotEmpty) {
        _leadProvider?.subscribeToLeads(_brokerId!);
      }
    });
  }

  @override
  void dispose() {
    _leadProvider?.unsubscribeLeads();
    super.dispose();
  }

  Future<void> _handleAddLead() async {
    final newLead = await showDialog<SocialLeadModel>(context: context, builder: (context) => const AddLeadDialog());
    if (newLead != null && mounted) {
      context.read<LeadProvider>().fetchLeads(
        brokerId: _brokerId,
        page: 1,
        searchQuery: context.read<LeadProvider>().searchQuery,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = context.isMobile;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Consumer<LeadProvider>(
          builder: (context, provider, child) {
            return SingleChildScrollView(
              padding: AppConstants.getTabPadding(context, bottomExtra: isMobile ? 80.0 : 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Social Leads Table / Card View Widget with Platform Filters & Pagination
                  LeadTableWidget(
                    leads: provider.leads,
                    isLoading: provider.isLoading,
                    currentPage: provider.currentPage,
                    totalPages: provider.totalPages,
                    totalItems: provider.totalItems,
                    selectedPlatforms: provider.platformsFilter,
                    onPlatformsFilterChanged: (platforms) {
                      provider.setPlatformsFilter(platforms, brokerId: _brokerId);
                    },
                    selectedStatus: provider.statusFilter,
                    onStatusFilterChanged: (status) {
                      provider.setStatusFilter(status, brokerId: _brokerId);
                    },
                    onSearchChanged: (query) {
                      provider.fetchLeads(brokerId: _brokerId, page: 1, searchQuery: query);
                    },
                    onPageChanged: (newPage) {
                      provider.fetchLeads(brokerId: _brokerId, page: newPage, searchQuery: provider.searchQuery);
                    },
                    onAddLeadPressed: _handleAddLead,
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
