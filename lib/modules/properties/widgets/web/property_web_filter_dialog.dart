// File: lib/modules/properties/widgets/web/property_web_filter_dialog.dart
// Purpose: Interactive Web Properties Filter Popup Modal matching the exact design and controls from therealtybazaar.com.

import 'package:flutter/material.dart';

import '../../../../app/app_colors.dart';
import '../../../../app/app_text_styles.dart';
import '../../../../models/property_filter_model.dart';
import '../../../../widgets/buttons/app_button.dart';

class PropertyWebFilterDialog extends StatefulWidget {
  final PropertyFilterModel initialFilter;
  final List<String> availableCities;

  const PropertyWebFilterDialog({super.key, required this.initialFilter, this.availableCities = const []});

  static Future<PropertyFilterModel?> show(
    BuildContext context, {
    required PropertyFilterModel initialFilter,
    List<String> availableCities = const [],
  }) {
    return showDialog<PropertyFilterModel>(
      context: context,
      barrierDismissible: true,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
        child: PropertyWebFilterDialog(initialFilter: initialFilter, availableCities: availableCities),
      ),
    );
  }

  @override
  State<PropertyWebFilterDialog> createState() => _PropertyWebFilterDialogState();
}

class _PropertyWebFilterDialogState extends State<PropertyWebFilterDialog> {
  late TextEditingController _keywordController;
  late String _purpose;
  late String _city;
  late String _propertyType;
  late int? _bedrooms;
  late String _budgetRange;
  late String _furnishing;
  late bool _verifiedOnly;
  late bool _featuredOnly;

  @override
  void initState() {
    super.initState();
    final f = widget.initialFilter;
    _keywordController = TextEditingController(text: f.searchKeyword);
    _purpose = f.purpose;
    _city = f.city;
    _propertyType = f.propertyType;
    _bedrooms = f.bedrooms;
    _budgetRange = f.budgetRange;
    _furnishing = f.furnishing;
    _verifiedOnly = f.verifiedOnly;
    _featuredOnly = f.featuredOnly;
  }

  @override
  void dispose() {
    _keywordController.dispose();
    super.dispose();
  }

  void _resetAll() {
    setState(() {
      _keywordController.clear();
      _purpose = 'all';
      _city = 'all';
      _propertyType = 'all';
      _bedrooms = null;
      _budgetRange = 'any';
      _furnishing = 'all';
      _verifiedOnly = false;
      _featuredOnly = false;
    });
  }

  void _applyFilters() {
    final result = widget.initialFilter.copyWith(
      searchKeyword: _keywordController.text.trim(),
      purpose: _purpose,
      city: _city,
      propertyType: _propertyType,
      bedrooms: () => _bedrooms,
      budgetRange: _budgetRange,
      furnishing: _furnishing,
      verifiedOnly: _verifiedOnly,
      featuredOnly: _featuredOnly,
    );
    Navigator.of(context).pop(result);
  }

  @override
  Widget build(BuildContext context) {
    // Merge provided cities with default top cities
    final Set<String> citySet = {'all', 'Surat', 'Mumbai', 'Pune', 'Bengaluru', 'Hyderabad', 'Ahmedabad'};
    for (final c in widget.availableCities) {
      if (c.isNotEmpty) citySet.add(c);
    }
    final cityList = citySet.toList();

    return Container(
      width: 580.0,
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.90),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 30.0,
            offset: const Offset(0, 10.0),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // -------------------------------------------------------------------
          // 1. DIALOG HEADER (Filters Title + Reset + Close)
          // -------------------------------------------------------------------
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 18.0),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: AppColors.border, width: 1.0)),
            ),
            child: Row(
              children: [
                const Icon(Icons.tune_rounded, color: AppColors.primary, size: 22.0),
                const SizedBox(width: 10.0),
                Text(
                  'Filters',
                  style: AppTextStyles.heading3.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                const Spacer(),
                // Reset Button
                InkWell(
                  onTap: _resetAll,
                  borderRadius: BorderRadius.circular(6.0),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 6.0),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.restart_alt_rounded, size: 16.0, color: AppColors.primary),
                        const SizedBox(width: 4.0),
                        Text(
                          'Reset',
                          style: AppTextStyles.body2.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8.0),
                // Close Modal 'X'
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 20.0, color: AppColors.textSecondary),
                  onPressed: () => Navigator.of(context).pop(),
                  tooltip: 'Close',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 32.0, minHeight: 32.0),
                ),
              ],
            ),
          ),

          // -------------------------------------------------------------------
          // 2. SCROLLABLE FILTER BODY
          // -------------------------------------------------------------------
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Section A: Location or Keyword
                  _buildSectionLabel('Location or Keyword'),
                  const SizedBox(height: 6.0),
                  Container(
                    height: 44.0,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(10.0),
                      border: Border.all(color: AppColors.border, width: 1.0),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 12.0),
                    child: Row(
                      children: [
                        const Icon(Icons.search_rounded, size: 18.0, color: AppColors.textSecondary),
                        const SizedBox(width: 8.0),
                        Expanded(
                          child: TextField(
                            controller: _keywordController,
                            style: AppTextStyles.body2.copyWith(color: AppColors.textPrimary),
                            decoration: const InputDecoration(
                              hintText: 'e.g. Vesu, Adajan, Villa, 3 BHK...',
                              hintStyle: TextStyle(color: AppColors.textMuted, fontSize: 13.0),
                              border: InputBorder.none,
                              isDense: true,
                            ),
                          ),
                        ),
                        if (_keywordController.text.isNotEmpty)
                          InkWell(
                            onTap: () => setState(() => _keywordController.clear()),
                            child: const Icon(Icons.cancel, size: 16.0, color: AppColors.textMuted),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18.0),

                  // Section B: Purpose (Segmented Tabs: All / Buy / Rent)
                  _buildSectionLabel('Purpose'),
                  const SizedBox(height: 6.0),
                  Container(
                    padding: const EdgeInsets.all(4.0),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                    child: Row(
                      children: [
                        _buildPurposeTab('All', 'all'),
                        _buildPurposeTab('Buy (Sale)', 'sale'),
                        _buildPurposeTab('Rent', 'rent'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18.0),

                  // Section C: City & Property Type in 2 Columns
                  Row(
                    children: [
                      // City Dropdown
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildSectionLabel('City'),
                            const SizedBox(height: 6.0),
                            _buildDropdownContainer(
                              child: DropdownButton<String>(
                                value: cityList.contains(_city) ? _city : 'all',
                                isExpanded: true,
                                underline: const SizedBox(),
                                icon: const Icon(
                                  Icons.keyboard_arrow_down_rounded,
                                  size: 18.0,
                                  color: AppColors.textSecondary,
                                ),
                                style: AppTextStyles.body2.copyWith(
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.w600,
                                ),
                                dropdownColor: AppColors.surface,
                                items: cityList.map((c) {
                                  return DropdownMenuItem<String>(
                                    value: c,
                                    child: Text(c == 'all' ? 'All Cities' : c),
                                  );
                                }).toList(),
                                onChanged: (val) {
                                  if (val != null) setState(() => _city = val);
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 14.0),

                      // Property Type Dropdown
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildSectionLabel('Property Type'),
                            const SizedBox(height: 6.0),
                            _buildDropdownContainer(
                              child: DropdownButton<String>(
                                value: _propertyType,
                                isExpanded: true,
                                underline: const SizedBox(),
                                icon: const Icon(
                                  Icons.keyboard_arrow_down_rounded,
                                  size: 18.0,
                                  color: AppColors.textSecondary,
                                ),
                                style: AppTextStyles.body2.copyWith(
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.w600,
                                ),
                                dropdownColor: AppColors.surface,
                                items: const [
                                  DropdownMenuItem(value: 'all', child: Text('All Types')),
                                  DropdownMenuItem(value: 'apartment', child: Text('Apartment / Flat')),
                                  DropdownMenuItem(value: 'villa', child: Text('Villa / Bungalow')),
                                  DropdownMenuItem(value: 'row_house', child: Text('Row House')),
                                  DropdownMenuItem(value: 'penthouse', child: Text('Penthouse')),
                                  DropdownMenuItem(value: 'commercial', child: Text('Commercial Space')),
                                  DropdownMenuItem(value: 'plot', child: Text('Plot / Land')),
                                ],
                                onChanged: (val) {
                                  if (val != null) setState(() => _propertyType = val);
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18.0),

                  // Section D: Bedrooms (BHK)
                  _buildSectionLabel('Bedrooms (BHK)'),
                  const SizedBox(height: 8.0),
                  Row(
                    children: [
                      _buildBhkPill('Any', null),
                      const SizedBox(width: 8.0),
                      _buildBhkPill('1', 1),
                      const SizedBox(width: 8.0),
                      _buildBhkPill('2', 2),
                      const SizedBox(width: 8.0),
                      _buildBhkPill('3', 3),
                      const SizedBox(width: 8.0),
                      _buildBhkPill('4+', 4),
                    ],
                  ),
                  const SizedBox(height: 18.0),

                  // Section E: Budget Range (2 Columns)
                  _buildSectionLabel('Budget Range'),
                  const SizedBox(height: 8.0),
                  Wrap(
                    spacing: 8.0,
                    runSpacing: 8.0,
                    children: [
                      _buildBudgetPill('Any Budget', 'any'),
                      _buildBudgetPill('Under ₹50 Lac', 'under_50l'),
                      _buildBudgetPill('₹50 Lac – ₹1 Cr', '50l_1cr'),
                      _buildBudgetPill('₹1 Cr – ₹2 Cr', '1cr_2cr'),
                      _buildBudgetPill('₹2 Cr – ₹5 Cr', '2cr_5cr'),
                      _buildBudgetPill('₹5 Cr & Above', '5cr_plus'),
                    ],
                  ),
                  const SizedBox(height: 18.0),

                  // Section F: Furnishing Status
                  _buildSectionLabel('Furnishing'),
                  const SizedBox(height: 6.0),
                  _buildDropdownContainer(
                    child: DropdownButton<String>(
                      value: _furnishing,
                      isExpanded: true,
                      underline: const SizedBox(),
                      icon: const Icon(
                        Icons.keyboard_arrow_down_rounded,
                        size: 18.0,
                        color: AppColors.textSecondary,
                      ),
                      style: AppTextStyles.body2.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                      dropdownColor: AppColors.surface,
                      items: const [
                        DropdownMenuItem(value: 'all', child: Text('Any Furnishing')),
                        DropdownMenuItem(value: 'unfurnished', child: Text('Unfurnished')),
                        DropdownMenuItem(value: 'semi_furnished', child: Text('Semi-Furnished')),
                        DropdownMenuItem(value: 'fully_furnished', child: Text('Fully Furnished')),
                      ],
                      onChanged: (val) {
                        if (val != null) setState(() => _furnishing = val);
                      },
                    ),
                  ),
                  const SizedBox(height: 18.0),

                  // Section G: Checkboxes (Verified Brokers & Featured)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(10.0),
                      border: Border.all(color: AppColors.border, width: 1.0),
                    ),
                    child: Column(
                      children: [
                        _buildCheckboxRow(
                          'Verified Local Brokers Only',
                          'Show only properties from verified local broker network',
                          _verifiedOnly,
                          (val) => setState(() => _verifiedOnly = val ?? false),
                        ),
                        const Divider(height: 1.0, color: AppColors.border),
                        _buildCheckboxRow(
                          'Featured / Promoted Listings',
                          'Highlight top promoted inventory across the platform',
                          _featuredOnly,
                          (val) => setState(() => _featuredOnly = val ?? false),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // -------------------------------------------------------------------
          // 3. DIALOG FOOTER (Apply Filters & Cancel)
          // -------------------------------------------------------------------
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: AppColors.border, width: 1.0)),
            ),
            child: Row(
              children: [
                // Cancel Button (Bottom Left)
                AppButton.outline(
                  text: 'Cancel',
                  height: 44.0,
                  borderRadius: 10.0,
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                const SizedBox(width: 12.0),

                // Apply Filters Solid Button (Bottom Left / Side-by-side)
                AppButton.solid(
                  text: 'Apply Filters',
                  iconData: Icons.done_rounded,
                  height: 44.0,
                  borderRadius: 10.0,
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  color: AppColors.primary,
                  onPressed: _applyFilters,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // HELPER WIDGETS
  // ---------------------------------------------------------------------------

  Widget _buildSectionLabel(String label) {
    return Text(
      label,
      style: AppTextStyles.caption.copyWith(
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
        fontSize: 12.5,
      ),
    );
  }

  Widget _buildDropdownContainer({required Widget child}) {
    return Container(
      height: 42.0,
      padding: const EdgeInsets.symmetric(horizontal: 12.0),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10.0),
        border: Border.all(color: AppColors.border, width: 1.0),
      ),
      alignment: Alignment.center,
      child: child,
    );
  }

  Widget _buildPurposeTab(String title, String value) {
    final isSelected = _purpose == value;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _purpose = value),
        borderRadius: BorderRadius.circular(8.0),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          height: 36.0,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(8.0),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 4.0,
                      offset: const Offset(0, 1.5),
                    ),
                  ]
                : null,
          ),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 13.0,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected ? AppColors.primary : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBhkPill(String title, int? count) {
    final isSelected = _bedrooms == count;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _bedrooms = count),
        borderRadius: BorderRadius.circular(8.0),
        child: Container(
          height: 36.0,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(8.0),
            border: Border.all(color: isSelected ? AppColors.primary : AppColors.border, width: 1.0),
          ),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
              color: isSelected ? Colors.white : AppColors.textPrimary,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBudgetPill(String title, String value) {
    final isSelected = _budgetRange == value;
    return InkWell(
      onTap: () => setState(() => _budgetRange = value),
      borderRadius: BorderRadius.circular(8.0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 8.0),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withValues(alpha: 0.08) : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(8.0),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Text(
          title,
          style: TextStyle(
            fontSize: 12.0,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? AppColors.primary : AppColors.textPrimary,
          ),
        ),
      ),
    );
  }

  Widget _buildCheckboxRow(String title, String subtitle, bool value, ValueChanged<bool?> onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Checkbox(
            value: value,
            activeColor: AppColors.primary,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4.0)),
            onChanged: onChanged,
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.body2.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                    fontSize: 13.0,
                  ),
                ),
                Text(
                  subtitle,
                  style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary, fontSize: 11.0),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
