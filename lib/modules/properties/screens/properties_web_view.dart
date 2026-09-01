// File: lib/modules/properties/screens/properties_web_view.dart
// Purpose: High-fidelity Web Properties Directory screen featuring responsive Grid layout,
// live filters popup modal, sort dropdown, and active filter tags matching therealtybazaar.com design.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../app/app_colors.dart';
import '../../../app/app_constants.dart';
import '../../../app/app_text_styles.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../models/property_enums.dart';
import '../../../models/property_filter_model.dart';
import '../../../models/property_model.dart';
import '../../../providers/auth/auth_provider.dart';
import '../../../providers/property/property_provider.dart';
import '../../../widgets/buttons/app_button.dart';
import '../../../widgets/common/app_card_container.dart';
import '../../../widgets/common/app_empty_state_widget.dart';
import '../../../widgets/shimmer/app_shimmer_container.dart';
import '../../../widgets/common/search_filter_header_widget.dart';
import '../widgets/web/property_web_filter_dialog.dart';
import '../widgets/web/property_web_grid_card.dart';
import 'add_edit_property_screen.dart';

class PropertiesWebView extends StatefulWidget {
  const PropertiesWebView({super.key});

  @override
  State<PropertiesWebView> createState() => _PropertiesWebViewState();
}

class _PropertiesWebViewState extends State<PropertiesWebView> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  PropertyFilterModel _filter = const PropertyFilterModel();

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
    setState(() {
      _filter = _filter.copyWith(searchKeyword: query);
    });
  }

  Future<void> _openFilterDialog(List<PropertyModel> allProperties) async {
    // Extract available cities from loaded properties
    final cities = allProperties
        .map((p) => p.address?.city?.trim())
        .where((c) => c != null && c.isNotEmpty)
        .cast<String>()
        .toSet()
        .toList();

    final result = await PropertyWebFilterDialog.show(
      context,
      initialFilter: _filter,
      availableCities: cities,
    );

    if (result != null && mounted) {
      setState(() {
        _filter = result;
        _searchController.text = result.searchKeyword;
      });
    }
  }

  void _openAddEditPropertyScreen([PropertyModel? property]) {
    Navigator.of(context, rootNavigator: true).push(
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
        child: Consumer<PropertyProvider>(
          builder: (context, provider, child) {
            final rawProperties = provider.properties;
            final displayedProperties = _filter.applyTo(rawProperties);
            final int activeFilterCount = _filter.activeFilterCount;

            return SingleChildScrollView(
              controller: _scrollController,
              padding: AppConstants.getTabPadding(context, bottomExtra: 10.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // -----------------------------------------------------------
                  // 1. ORIGINAL TOP SEARCH BAR & ADD BUTTON
                  // -----------------------------------------------------------
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
                  const SizedBox(height: 25.0),

                  // -----------------------------------------------------------
                  // 2. SUBHEADER: Count, Subtitle, FILTER BUTTON & SORT DROPDOWN
                  // -----------------------------------------------------------
                  _buildSubheader(displayedProperties.length, provider.totalItems, activeFilterCount, rawProperties),
                  const SizedBox(height: 12.0),

                  // -----------------------------------------------------------
                  // 3. ACTIVE FILTERS TAGS (if any active)
                  // -----------------------------------------------------------
                  if (_filter.hasActiveFilters) ...[
                    _buildActiveFilterChips(),
                    const SizedBox(height: 16.0),
                  ],

                  // -----------------------------------------------------------
                  // 4. MAIN CONTENT AREA (Loading / Error / Empty / Grid)
                  // -----------------------------------------------------------
                  if (provider.isLoading)
                    _buildShimmerGrid()
                  else if (provider.errorMessage != null && provider.properties.isEmpty)
                    _buildErrorState(provider.errorMessage!, () {
                      final authProvider = Provider.of<AuthProvider>(context, listen: false);
                      final brokerId = authProvider.userProfile?.brokerId?.id ?? '';
                      provider.fetchProperties(
                        brokerId: brokerId,
                        page: 1,
                        searchQuery: _filter.searchKeyword,
                      );
                    })
                  else if (displayedProperties.isEmpty)
                    _buildEmptyState()
                  else ...[
                    // Responsive Grid of Property Cards
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final width = constraints.maxWidth;
                        final int crossAxisCount = width >= 1350 ? 4 : (width >= 900 ? 3 : (width >= 560 ? 2 : 1));

                        return GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          padding: const EdgeInsets.only(right: 50, top: 15),
                          itemCount: displayedProperties.length,
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: crossAxisCount,
                            crossAxisSpacing: 30.0,
                            mainAxisSpacing: 30.0,
                            mainAxisExtent: 382.0,
                          ),
                          itemBuilder: (context, index) {
                            final property = displayedProperties[index];
                            return PropertyWebGridCard(
                              property: property,
                              onEditTap: () => _openAddEditPropertyScreen(property),
                            );
                          },
                        );
                      },
                    ),

                    // ---------------------------------------------------------
                    // 5. INFINITE SCROLL LOADING & FOOTER STATE
                    // ---------------------------------------------------------
                    if (provider.isLoadingMore)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 28.0),
                        child: Center(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const SizedBox(
                                width: 20.0,
                                height: 20.0,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: AppColors.primary,
                                ),
                              ),
                              const SizedBox(width: 12.0),
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
                    else if (!provider.hasMore && displayedProperties.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 28.0),
                        child: Center(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(20.0),
                              border: Border.all(color: AppColors.border, width: 1.0),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.check_circle_outline_rounded, size: 16.0, color: AppColors.primary),
                                const SizedBox(width: 6.0),
                                Text(
                                  'All ${displayedProperties.length} properties loaded',
                                  style: AppTextStyles.caption.copyWith(
                                    color: AppColors.textSecondary,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12.0,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                  ],
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 2. SUBHEADER: Count, Filter Button & Sort Dropdown
  // ---------------------------------------------------------------------------
  Widget _buildSubheader(int count, int total, int activeFilterCount, List<PropertyModel> allProperties) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 580.0;

        final titleColumn = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '$count Properties Loaded',
              style: AppTextStyles.heading2.copyWith(
                fontSize: 18.0,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
                letterSpacing: -0.2,
              ),
            ),
            const SizedBox(height: 2.0),
            Text(
              'Verified Inventory listed directly by local brokers',
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textSecondary,
                fontSize: 12.5,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        );

        final controlsRow = Padding(
          padding: const EdgeInsets.only(right: 50),
          child: Row(
            mainAxisSize: isCompact ? MainAxisSize.max : MainAxisSize.min,
            children: [
              // Filter Button with Badge
              InkWell(
                onTap: () => _openFilterDialog(allProperties),
                borderRadius: BorderRadius.circular(10.0),
                child: Container(
                  height: 38.0,
                  padding: const EdgeInsets.symmetric(horizontal: 14.0),
                  decoration: BoxDecoration(
                    color: activeFilterCount > 0
                        ? AppColors.primary.withValues(alpha: 0.08)
                        : AppColors.surface,
                    borderRadius: BorderRadius.circular(10.0),
                    border: Border.all(
                      color: activeFilterCount > 0 ? AppColors.primary : AppColors.border,
                      width: 1.0,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.02),
                        blurRadius: 6.0,
                        offset: const Offset(0, 2.0),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.tune_rounded,
                        size: 17.0,
                        color: activeFilterCount > 0 ? AppColors.primary : AppColors.textPrimary,
                      ),
                      const SizedBox(width: 6.0),
                      Text(
                        'Filters',
                        style: TextStyle(
                          fontSize: 13.0,
                          fontWeight: FontWeight.w600,
                          color: activeFilterCount > 0 ? AppColors.primary : AppColors.textPrimary,
                        ),
                      ),
                      if (activeFilterCount > 0) ...[
                        const SizedBox(width: 6.0),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 1.5),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(10.0),
                          ),
                          child: Text(
                            '$activeFilterCount',
                            style: const TextStyle(
                              fontSize: 11.0,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10.0),

              // Sort Dropdown
              Container(
                height: 38.0,
                padding: const EdgeInsets.symmetric(horizontal: 12.0),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(10.0),
                  border: Border.all(color: AppColors.border, width: 1.0),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _filter.sortOption,
                    icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 18.0, color: AppColors.textSecondary),
                    style: AppTextStyles.body2.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                      fontSize: 13.0,
                    ),
                    dropdownColor: AppColors.surface,
                    borderRadius: BorderRadius.circular(10.0),
                    items: const [
                      DropdownMenuItem(value: 'price_asc', child: Text('Price: Low to High')),
                      DropdownMenuItem(value: 'price_desc', child: Text('Price: High to Low')),
                      DropdownMenuItem(value: 'newest', child: Text('Newest First')),
                      DropdownMenuItem(value: 'oldest', child: Text('Oldest First')),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        setState(() => _filter = _filter.copyWith(sortOption: val));
                      }
                    },
                  ),
                ),
              ),
            ],
          ),
        );

        if (isCompact) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              titleColumn,
              const SizedBox(height: 12.0),
              controlsRow,
            ],
          );
        }

        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            titleColumn,
            controlsRow,
          ],
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // 3. ACTIVE FILTER CHIPS ROW
  // ---------------------------------------------------------------------------
  Widget _buildActiveFilterChips() {
    final List<Widget> chips = [];

    chips.add(
      Text(
        'Active Filters:',
        style: AppTextStyles.caption.copyWith(
          fontWeight: FontWeight.w700,
          color: AppColors.textSecondary,
          fontSize: 12.5,
        ),
      ),
    );

    if (_filter.purpose != 'all') {
      final label = _filter.purpose == 'sale' ? 'For Sale' : 'For Rent';
      chips.add(_buildChipTag(label, () {
        setState(() => _filter = _filter.copyWith(purpose: 'all'));
      }));
    }

    if (_filter.city != 'all') {
      chips.add(_buildChipTag('City: ${_filter.city.toUpperCase()}', () {
        setState(() => _filter = _filter.copyWith(city: 'all'));
      }));
    }

    if (_filter.propertyType != 'all') {
      final typeEnum = _filter.propertyType.asPropertyType;
      chips.add(_buildChipTag(typeEnum.displayName, () {
        setState(() => _filter = _filter.copyWith(propertyType: 'all'));
      }));
    }

    if (_filter.bedrooms != null) {
      final label = _filter.bedrooms == 4 ? '4+ BHK' : '${_filter.bedrooms} BHK';
      chips.add(_buildChipTag(label, () {
        setState(() => _filter = _filter.copyWith(bedrooms: () => null));
      }));
    }

    if (_filter.budgetRange != 'any') {
      chips.add(_buildChipTag('Budget Filter', () {
        setState(() => _filter = _filter.copyWith(budgetRange: 'any'));
      }));
    }

    if (_filter.furnishing != 'all') {
      final furn = _filter.furnishing.asFurnishingStatus;
      chips.add(_buildChipTag(furn.displayName, () {
        setState(() => _filter = _filter.copyWith(furnishing: 'all'));
      }));
    }

    if (_filter.verifiedOnly) {
      chips.add(_buildChipTag('Verified Only', () {
        setState(() => _filter = _filter.copyWith(verifiedOnly: false));
      }));
    }

    if (_filter.featuredOnly) {
      chips.add(_buildChipTag('Featured Only', () {
        setState(() => _filter = _filter.copyWith(featuredOnly: false));
      }));
    }

    chips.add(
      InkWell(
        onTap: () {
          setState(() {
            _filter = const PropertyFilterModel();
            _searchController.clear();
          });
        },
        borderRadius: BorderRadius.circular(6.0),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 3.0),
          child: Text(
            'Clear All',
            style: AppTextStyles.caption.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w700,
              decoration: TextDecoration.underline,
              fontSize: 12.0,
            ),
          ),
        ),
      ),
    );

    return Wrap(
      spacing: 8.0,
      runSpacing: 6.0,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: chips,
    );
  }

  Widget _buildChipTag(String label, VoidCallback onRemove) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10.0, 4.0, 6.0, 4.0),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2), width: 1.0),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12.0,
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 4.0),
          InkWell(
            onTap: onRemove,
            borderRadius: BorderRadius.circular(10.0),
            child: const Icon(Icons.close_rounded, size: 14.0, color: AppColors.primary),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 4. SHIMMER GRID LOADER
  // ---------------------------------------------------------------------------
  Widget _buildShimmerGrid() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final int crossAxisCount = width >= 1350 ? 4 : (width >= 900 ? 3 : (width >= 560 ? 2 : 1));

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: 8,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 30.0,
            mainAxisSpacing: 30.0,
            mainAxisExtent: 382.0,
          ),
          itemBuilder: (context, index) {
            return Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(18.0),
                border: Border.all(color: AppColors.border, width: 1.0),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppShimmerContainer(
                    width: double.infinity,
                    height: 175.0,
                    borderRadius: 18.0,
                  ),
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.all(14.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              AppShimmerContainer(width: 140.0, height: 18.0),
                              SizedBox(height: 8.0),
                              AppShimmerContainer(width: double.infinity, height: 14.0),
                              SizedBox(height: 6.0),
                              AppShimmerContainer(width: 160.0, height: 12.0),
                              SizedBox(height: 10.0),
                              AppShimmerContainer(width: double.infinity, height: 28.0, borderRadius: 8.0),
                            ],
                          ),
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Divider(height: 1.0, color: AppColors.border),
                              SizedBox(height: 8.0),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  AppShimmerContainer(width: 80.0, height: 12.0),
                                  AppShimmerContainer(width: 70.0, height: 20.0, borderRadius: 10.0),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // 5. ERROR STATE
  // ---------------------------------------------------------------------------
  Widget _buildErrorState(String errorMessage, VoidCallback onRetry) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 48.0),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18.0),
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
          AppButton.solid(
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
  // 6. EMPTY STATE
  // ---------------------------------------------------------------------------
  Widget _buildEmptyState() {
    final hasActive = _filter.hasActiveFilters;

    return AppCardContainer(
      borderRadius: 18.0,
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 48.0),
      child: Column(
        children: [
          AppEmptyStateWidget(
            icon: Icons.apartment_rounded,
            iconSize: 44.0,
            title: hasActive ? 'No Properties Match Your Filters' : context.tr('no_properties_listed_yet'),
            description: hasActive
                ? 'Try adjusting or resetting your filter criteria to see available property listings.'
                : context.tr('no_properties_empty_desc'),
          ),
          if (hasActive) ...[
            const SizedBox(height: 20.0),
            AppButton.outline(
              text: 'Reset Filters',
              iconData: Icons.restart_alt_rounded,
              height: 42.0,
              borderRadius: 10.0,
              onPressed: () {
                setState(() {
                  _filter = const PropertyFilterModel();
                  _searchController.clear();
                });
              },
            ),
          ],
        ],
      ),
    );
  }
}
