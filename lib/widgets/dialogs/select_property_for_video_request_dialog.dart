// File: lib/widgets/dialogs/select_property_for_video_request_dialog.dart
// Purpose: Modal dialog for selecting a property without media to request a video shoot.

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/app_colors.dart';
import '../../app/app_text_styles.dart';
import '../../core/localization/app_localizations.dart';
import '../../models/models.dart';
import '../../modules/properties/widgets/select_property_tile_widget.dart';
import '../../providers/property/property_provider.dart';
import '../buttons/rounded_button.dart';
import '../inputs/app_textfield.dart';
import '../shimmer/select_property_list_shimmer_widget.dart';
import 'video_request_dialog.dart';
import 'app_base_dialog.dart';

class SelectPropertyForVideoRequestDialog extends StatefulWidget {
  final String brokerId;

  const SelectPropertyForVideoRequestDialog({
    super.key,
    required this.brokerId,
  });

  @override
  State<SelectPropertyForVideoRequestDialog> createState() =>
      _SelectPropertyForVideoRequestDialogState();
}

class _SelectPropertyForVideoRequestDialogState
    extends State<SelectPropertyForVideoRequestDialog> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;

  bool _isInitialLoading = true;
  bool _isLoadingMore = false;
  bool _hasMore = false;
  int _currentPage = 1;
  String _searchQuery = '';

  List<PropertyModel> _properties = [];
  PropertyModel? _selectedProperty;

  @override
  void initState() {
    super.initState();
    _loadInitialProperties();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 150 &&
        _hasMore &&
        !_isLoadingMore &&
        !_isInitialLoading) {
      _loadNextPage();
    }
  }

  Future<void> _loadInitialProperties() async {
    setState(() {
      _isInitialLoading = true;
      _currentPage = 1;
      _properties = [];
      _selectedProperty = null;
    });

    final provider = Provider.of<PropertyProvider>(context, listen: false);
    final result = await provider.fetchPropertiesPage(
      brokerId: widget.brokerId,
      page: 1,
      limit: 10,
      searchQuery: _searchQuery,
      forVideoRequest: true,
    );

    if (mounted) {
      setState(() {
        _properties = List<PropertyModel>.from(result['properties'] as List);
        _hasMore = result['hasMore'] as bool? ?? false;
        _isInitialLoading = false;
      });
    }
  }

  Future<void> _loadNextPage() async {
    setState(() {
      _isLoadingMore = true;
    });

    final nextPage = _currentPage + 1;
    final provider = Provider.of<PropertyProvider>(context, listen: false);
    final result = await provider.fetchPropertiesPage(
      brokerId: widget.brokerId,
      page: nextPage,
      limit: 10,
      searchQuery: _searchQuery,
      forVideoRequest: true,
    );

    if (mounted) {
      final newItems = result['properties'] as List<PropertyModel>;
      setState(() {
        _currentPage = nextPage;
        _properties.addAll(newItems);
        _hasMore = result['hasMore'] as bool? ?? false;
        _isLoadingMore = false;
      });
    }
  }

  void _onSearchChanged(String query) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      if (mounted && _searchQuery != query.trim()) {
        _searchQuery = query.trim();
        _loadInitialProperties();
      }
    });
  }

  void _handleContinue() {
    if (_selectedProperty == null || _selectedProperty!.id == null) return;

    final selectedId = _selectedProperty!.id!;
    final brokerId = widget.brokerId;
    final parentContext = context;

    Navigator.of(parentContext).pop();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      showDialog(
        context: parentContext,
        builder: (context) => VideoRequestDialog(
          propertyId: selectedId,
          brokerId: brokerId,
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return AppBaseDialog(
      headerIcon: Icons.video_collection_rounded,
      title: context.tr('select_property_for_video_request'),
      maxWidth: 540.0,
      isScrollable: false,
      footer: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          RoundedButton(
            text: context.tr('continue_button'),
            onPressed: _selectedProperty == null ? null : _handleContinue,
            isDisabled: _selectedProperty == null,
            variant: ButtonVariant.solid,
            color: AppColors.primary,
            height: 44.0,
            borderRadius: 10.0,
            padding: const EdgeInsets.symmetric(horizontal: 28.0),
          ),
        ],
      ),
      content: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.only(bottom: 12.0),
            child: AppTextField(
              controller: _searchController,
              hint: context.tr('search_properties_hint'),
              prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textSecondary, size: 20.0),
              onChanged: _onSearchChanged,
            ),
          ),

          // Property List Content
          Expanded(
            child: _isInitialLoading
                ? const SingleChildScrollView(
                    child: SelectPropertyListShimmerWidget(itemCount: 5),
                  )
                : _properties.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.location_city_outlined,
                                size: 48.0,
                                color: AppColors.textSecondary,
                              ),
                              const SizedBox(height: 12.0),
                              Text(
                                context.tr('no_properties_without_media'),
                                style: AppTextStyles.body1.copyWith(
                                  color: AppColors.textSecondary,
                                  fontWeight: FontWeight.w500,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        itemCount: _properties.length + (_hasMore ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (index == _properties.length) {
                            return const Padding(
                              padding: EdgeInsets.symmetric(vertical: 16.0),
                              child: Center(
                                child: SizedBox(
                                  width: 24.0,
                                  height: 24.0,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                                  ),
                                ),
                              ),
                            );
                          }

                          final property = _properties[index];
                          final isSelected = _selectedProperty?.id == property.id;

                          return SelectPropertyTileWidget(
                            property: property,
                            isSelected: isSelected,
                            onTap: () {
                              setState(() {
                                _selectedProperty = isSelected ? null : property;
                              });
                            },
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
