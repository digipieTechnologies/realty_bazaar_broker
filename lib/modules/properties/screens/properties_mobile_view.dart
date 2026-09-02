// File: lib/modules/properties/screens/properties_mobile_view.dart
// Purpose: Dedicated Mobile Properties View with infinite scroll pagination and untouched mobile card design.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../app/app_colors.dart';
import '../../../app/app_constants.dart';
import '../../../app/app_text_styles.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../models/property_model.dart';
import '../../../providers/auth/auth_provider.dart';
import '../../../providers/property/property_provider.dart';
import '../../../util/common_ext.dart';
import '../../../widgets/buttons/app_button.dart';
import '../../../widgets/common/app_card_container.dart';
import '../../../widgets/common/app_empty_state_widget.dart';
import '../../../widgets/common/search_filter_header_widget.dart';
import '../../../widgets/shimmer/property_list_shimmer_widget.dart';
import '../widgets/property_card_widget.dart';
import 'add_edit_property_screen.dart';

class PropertiesMobileView extends StatefulWidget {
  const PropertiesMobileView({super.key});

  @override
  State<PropertiesMobileView> createState() => _PropertiesMobileViewState();
}

class _PropertiesMobileViewState extends State<PropertiesMobileView> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final brokerId = authProvider.userProfile?.brokerId?.id ?? '';
      context.read<PropertyProvider>().fetchProperties(brokerId: brokerId, page: 1, searchQuery: '');
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.hasClients) {
      final maxScroll = _scrollController.position.maxScrollExtent;
      final currentScroll = _scrollController.position.pixels;
      if (maxScroll - currentScroll <= 300) {
        _loadMore();
      }
    }
  }

  void _loadMore() {
    final provider = context.read<PropertyProvider>();
    if (!provider.isLoading && !provider.isLoadingMore && provider.hasMore) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final brokerId = authProvider.userProfile?.brokerId?.id ?? '';
      provider.loadMoreProperties(brokerId: brokerId);
    }
  }

  void _onSearchQueryChanged(String query) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final brokerId = authProvider.userProfile?.brokerId?.id ?? '';
    context.read<PropertyProvider>().fetchProperties(brokerId: brokerId, page: 1, searchQuery: query);
  }

  void _openAddEditPropertyScreen([PropertyModel? property]) {
    Navigator.of(
      context,
      rootNavigator: true,
    ).push(MaterialPageRoute(builder: (context) => AddEditPropertyScreen(propertyToEdit: property)));
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = context.isMobile;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          controller: _scrollController,
          padding: AppConstants.getTabPadding(context, bottomExtra: isMobile ? 80.0 : 24.0),
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
                trailingAction: AppButton.solid(
                  iconData: Icons.add_rounded,
                  width: 46.0,
                  height: 46.0,
                  borderRadius: 12.0,
                  padding: EdgeInsets.zero,
                  color: AppColors.primary,
                  onPressed: () => _openAddEditPropertyScreen(),
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
                    return _buildErrorState(provider.errorMessage!, () {
                      final authProvider = Provider.of<AuthProvider>(context, listen: false);
                      final brokerId = authProvider.userProfile?.brokerId?.id ?? '';
                      provider.fetchProperties(brokerId: brokerId, page: 1, searchQuery: _searchController.text);
                    });
                  }

                  if (provider.properties.isEmpty) {
                    return _buildEmptyState(provider.searchQuery);
                  }

                  return Column(
                    children: [
                      // List of Property Cards
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

                      // Infinite Scroll Loading State
                      if (provider.isLoadingMore)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 24.0),
                          child: Center(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const SizedBox(
                                  width: 18.0,
                                  height: 18.0,
                                  child: CircularProgressIndicator(strokeWidth: 2.5, color: AppColors.primary),
                                ),
                                const SizedBox(width: 10.0),
                                Text(
                                  'Loading more properties...',
                                  style: AppTextStyles.body2.copyWith(
                                    color: AppColors.textSecondary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      else if (!provider.hasMore && provider.properties.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 20.0),
                          child: Center(
                            child: Text(
                              'All ${provider.properties.length} properties loaded',
                              style: AppTextStyles.caption.copyWith(
                                color: AppColors.textMuted,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
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
            decoration: BoxDecoration(color: AppColors.error.withValues(alpha: 0.1), shape: BoxShape.circle),
            child: const Icon(Icons.cloud_off_rounded, size: 44.0, color: AppColors.error),
          ),
          const SizedBox(height: 20.0),
          Text(
            context.tr('unable_to_load_properties'),
            style: AppTextStyles.heading3.copyWith(fontWeight: FontWeight.bold, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 8.0),
          Text(
            context.tr('properties_load_error_desc'),
            style: AppTextStyles.body2.copyWith(color: AppColors.textSecondary),
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
        title: isSearching ? context.tr('no_properties_found') : context.tr('no_properties_listed_yet'),
        description: isSearching
            ? context.tr('no_properties_matched_desc', arguments: {'query': searchQuery})
            : context.tr('no_properties_empty_desc'),
      ),
    );
  }
}
