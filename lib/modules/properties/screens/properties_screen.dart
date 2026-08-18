import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../app/app_colors.dart';
import '../../../app/app_constants.dart';
import '../../../app/app_text_styles.dart';
import '../../../models/property_model.dart';
import '../../../providers/property/property_provider.dart';
import '../../../providers/auth/auth_provider.dart';
import '../../../widgets/common/search_filter_header_widget.dart';
import '../../../widgets/shimmer/property_list_shimmer_widget.dart';
import '../../../widgets/common/app_card_container.dart';
import '../../../widgets/common/app_empty_state_widget.dart';
import '../../../widgets/common/app_pagination_widget.dart';
import '../widgets/property_card_widget.dart';
import '../../../widgets/buttons/app_button.dart';
import 'add_edit_property_screen.dart';

import '../../../core/localization/app_localizations.dart';

class PropertiesScreen extends StatefulWidget {
  const PropertiesScreen({super.key});

  @override
  State<PropertiesScreen> createState() => _PropertiesScreenState();
}

class _PropertiesScreenState extends State<PropertiesScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Initial fetch via PropertyProvider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final brokerId = authProvider.userProfile?.brokerId?.id ?? '';
      context.read<PropertyProvider>().fetchProperties(
            brokerId: brokerId,
            page: 1,
            searchQuery: '',
          );
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchQueryChanged(String query) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final brokerId = authProvider.userProfile?.brokerId?.id ?? '';
    context.read<PropertyProvider>().fetchProperties(
          brokerId: brokerId,
          page: 1,
          searchQuery: query,
        );
  }

  void _onPageChanged(int page) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final brokerId = authProvider.userProfile?.brokerId?.id ?? '';
    context.read<PropertyProvider>().fetchProperties(
          brokerId: brokerId,
          page: page,
          searchQuery: _searchController.text,
        );
  }

  void _openAddEditPropertyScreen([PropertyModel? property]) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => AddEditPropertyScreen(propertyToEdit: property),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: AppConstants.getTabPadding(context),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Search Input Header with "+ Add Property" Button
              SearchFilterHeaderWidget(
                controller: _searchController,
                hintText: context.tr('search_property_hint'),
                onSearchChanged: _onSearchQueryChanged,
                onClearPressed: () {
                  _searchController.clear();
                  _onSearchQueryChanged('');
                },
                trailingAction: MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: SizedBox(
                    height: 46.0,
                    width: 46.0,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.zero,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                        elevation: 0,
                      ),
                      onPressed: () => _openAddEditPropertyScreen(),
                      child: const Icon(Icons.add_rounded, size: 24.0),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20.0),

              // Property Consumer (Shimmer / Error State / Empty State / Card List)
              Consumer<PropertyProvider>(
                builder: (context, provider, child) {
                  if (provider.isLoading) {
                    return const PropertyListShimmerWidget(count: 3);
                  }

                  if (provider.errorMessage != null && provider.properties.isEmpty) {
                    return _buildErrorState(
                      provider.errorMessage!,
                      () {
                        final authProvider = Provider.of<AuthProvider>(context, listen: false);
                        final brokerId = authProvider.userProfile?.brokerId?.id ?? '';
                        provider.fetchProperties(
                          brokerId: brokerId,
                          page: provider.currentPage,
                          searchQuery: _searchController.text,
                        );
                      },
                    );
                  }

                  if (provider.properties.isEmpty) {
                    return _buildEmptyState(provider.searchQuery);
                  }

                  return Column(
                    children: [
                      // List of Property Cards for current page
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: provider.properties.length,
                        itemBuilder: (context, index) {
                          final property = provider.properties[index];
                          return PropertyCardWidget(
                            property: property,
                            onEditTap: () {
                              _openAddEditPropertyScreen(property);
                            },
                          );
                        },
                      ),
                      const SizedBox(height: 20.0),

                      // Bottom Pagination Widget
                      AppPaginationWidget(
                        currentPage: provider.currentPage,
                        totalPages: provider.totalPages,
                        totalItems: provider.totalItems,
                        itemsPerPage: provider.itemsPerPage,
                        itemLabel: context.tr('properties').toLowerCase(),
                        onPageChanged: _onPageChanged,
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 40.0),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // ERROR STATE WIDGET
  // ---------------------------------------------------------------------------
  Widget _buildErrorState(String errorMessage, VoidCallback onRetry) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40.0),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: AppColors.border, width: 1.0),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: AppColors.error.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.cloud_off_rounded,
              size: 44.0,
              color: AppColors.error,
            ),
          ),
          const SizedBox(height: 20.0),
          Text(
            context.tr('unable_to_load_properties'),
            style: AppTextStyles.heading3.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8.0),
          Text(
            context.tr('properties_load_error_desc'),
            style: AppTextStyles.body2.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24.0),
          AppButton(
            text: context.tr('try_again'),
            iconData: Icons.refresh_rounded,
            height: 44.0,
            borderRadius: 10.0,
            onPressed: onRetry,
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // EMPTY STATE WIDGET
  // ---------------------------------------------------------------------------
  Widget _buildEmptyState(String searchQuery) {
    final isSearching = searchQuery.trim().isNotEmpty;

    return AppCardContainer(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40.0),
      child: AppEmptyStateWidget(
        icon: Icons.apartment_rounded,
        iconSize: 40.0,
        title: isSearching
            ? context.tr('no_properties_found')
            : context.tr('no_properties_listed_yet'),
        description: isSearching
            ? context.tr('no_properties_matched_desc', arguments: {'query': searchQuery})
            : context.tr('no_properties_empty_desc'),
      ),
    );
  }
}
