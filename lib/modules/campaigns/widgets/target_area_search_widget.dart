// File: lib/modules/campaigns/widgets/target_area_search_widget.dart
// Purpose: Interactive location search input with autocomplete suggestions and removable target area chips.

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../app/app_colors.dart';
import '../../../app/app_text_styles.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../models/models.dart';
import '../../../providers/campaign/ad_campaign_provider.dart';
import '../../../widgets/common/app_tag_chip.dart';

class TargetAreaSearchWidget extends StatefulWidget {
  final List<TargetAreaModel> selectedAreas;
  final ValueChanged<List<TargetAreaModel>> onAreasChanged;

  const TargetAreaSearchWidget({
    super.key,
    required this.selectedAreas,
    required this.onAreasChanged,
  });

  @override
  State<TargetAreaSearchWidget> createState() => _TargetAreaSearchWidgetState();
}

class _TargetAreaSearchWidgetState extends State<TargetAreaSearchWidget> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  Timer? _debounce;
  bool _showDropdown = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      if (!_focusNode.hasFocus) {
        Future.delayed(const Duration(milliseconds: 200), () {
          if (mounted) setState(() => _showDropdown = false);
        });
      }
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onSearchQueryChanged(String query) {
    _debounce?.cancel();
    if (query.trim().isEmpty) {
      context.read<AdCampaignProvider>().clearSearchResults();
      setState(() => _showDropdown = false);
      return;
    }

    _debounce = Timer(const Duration(milliseconds: 350), () async {
      final provider = context.read<AdCampaignProvider>();
      await provider.searchTargetAreas(query);
      if (mounted) {
        setState(() => _showDropdown = true);
      }
    });
  }

  void _addArea(TargetAreaModel area) {
    if (!widget.selectedAreas.any((a) => a.fullArea == area.fullArea)) {
      final updated = List<TargetAreaModel>.from(widget.selectedAreas)..add(area);
      widget.onAreasChanged(updated);
    }
    _controller.clear();
    context.read<AdCampaignProvider>().clearSearchResults();
    setState(() => _showDropdown = false);
  }

  void _removeArea(TargetAreaModel area) {
    final updated = List<TargetAreaModel>.from(widget.selectedAreas)
      ..removeWhere((a) => a.fullArea == area.fullArea);
    widget.onAreasChanged(updated);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AdCampaignProvider>();
    final searchResults = provider.areaSearchResults;
    final isSearching = provider.isSearchingAreas;

    final buildingKeywords = const [
      'society', 'socity', 'soc', 'shoc', 'soc.',
      'bunglows', 'bungalow', 'bungalows', 'bnglow',
      'chsl', 'chs', 'apt', 'apts', 'appartment', 'apartment', 'apartments',
      'residency', 'realty', 'rowhouse', 'row house', 'villas', 'villa',
      'homes', 'nivas', 'niwas', 'heights', 'arcade', 'square',
      'palace', 'chambers', 'flats', 'flat', 'plaza', 'estate',
      'township', 'nest', 'haven', 'bliss', 'paradise', 'valley',
      'greens', 'residence', 'coop', 'co-op', 'building', 'house',
      'plots', 'plot', 'complex', 'shopping', 'hub', 'infra',
      'enclave', 'shoppes', 'sanctuary', 'cottage', 'manor', 'court',
      'terrace', 'gardens', 'resort', 'commercial'
    ];

    final filteredResults = searchResults.where((item) {
      final itemFullClean = item.fullArea.toLowerCase().trim();
      final itemAreaClean = item.area.toLowerCase().trim();

      final isAlreadySelected = widget.selectedAreas.any((selected) =>
          selected.fullArea.toLowerCase().trim() == itemFullClean ||
          selected.area.toLowerCase().trim() == itemAreaClean);
      if (isAlreadySelected) return false;

      final isBuildingOrSociety = buildingKeywords.any((kw) =>
          itemFullClean.contains(kw) || itemAreaClean.contains(kw));
      if (isBuildingOrSociety) return false;

      return true;
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header Title
        Row(
          children: [
            Text(
              context.tr('target_areas'),
              style: AppTextStyles.heading3.copyWith(
                fontSize: 15.0,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(width: 6.0),
            Text(
              '(${context.tr('required')})',
              style: AppTextStyles.caption.copyWith(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: AppColors.error,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4.0),
        Text(
          context.tr('target_areas_desc'),
          style: AppTextStyles.caption.copyWith(
            fontSize: 12.0,
            color: AppColors.textMuted,
          ),
        ),
        const SizedBox(height: 12.0),

        // Display Added Chips (using AppTagChip)
        if (widget.selectedAreas.isNotEmpty) ...[
          Wrap(
            spacing: 6.0,
            runSpacing: 6.0,
            children: widget.selectedAreas.map((area) {
              return AppTagChip(
                label: area.fullArea,
                onDelete: () => _removeArea(area),
              );
            }).toList(),
          ),
          const SizedBox(height: 12.0),
        ],

        // Input Field Container (without "Add" text button)
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12.0),
            border: Border.all(color: AppColors.border, width: 1.0),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              TextField(
                controller: _controller,
                focusNode: _focusNode,
                onChanged: _onSearchQueryChanged,
                style: AppTextStyles.body2.copyWith(fontSize: 13.5),
                decoration: InputDecoration(
                  hintText: context.tr('add_target_area'),
                  hintStyle: AppTextStyles.body2.copyWith(
                    color: AppColors.textMuted,
                    fontSize: 13.5,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 14.0,
                  ),
                  suffixIcon: isSearching
                      ? const Padding(
                          padding: EdgeInsets.all(12.0),
                          child: SizedBox(
                            width: 16.0,
                            height: 16.0,
                            child: CircularProgressIndicator(strokeWidth: 2.0),
                          ),
                        )
                      : null,
                ),
              ),

              // Dropdown Suggestions List (No map icon, text starts at left, trailing + rounded shadow button)
              if (_showDropdown && filteredResults.isNotEmpty) ...[
                const Divider(height: 1.0, color: AppColors.border),
                Container(
                  constraints: const BoxConstraints(maxHeight: 220.0),
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: filteredResults.length,
                    separatorBuilder: (context, index) =>
                        const Divider(height: 1.0, color: AppColors.border),
                    itemBuilder: (context, index) {
                      final item = filteredResults[index];
                      return ListTile(
                        dense: true,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16.0,
                          vertical: 4.0,
                        ),
                        title: Text(
                          item.fullArea,
                          style: AppTextStyles.body2.copyWith(
                            fontSize: 13.0,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        trailing: Container(
                          width: 28.0,
                          height: 28.0,
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withValues(alpha: 0.3),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.add_rounded,
                            size: 18.0,
                            color: Colors.white,
                          ),
                        ),
                        onTap: () => _addArea(item),
                      );
                    },
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
