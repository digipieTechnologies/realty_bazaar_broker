import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../app/app_colors.dart';
import '../../../app/app_text_styles.dart';
import '../../../models/address_model.dart';
import '../../../models/broker_model.dart';
import '../../../models/media_model.dart';
import '../../../models/property_enums.dart';
import '../../../models/property_model.dart';
import '../../../providers/property/property_provider.dart';
import '../../../providers/auth/auth_provider.dart';
import '../../../widgets/common/wizard_footer_widget.dart';
import '../../../widgets/common/common_app_bar.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../widgets/toast/app_toast.dart';
import '../widgets/step_property_details_widget.dart';
import '../widgets/step_property_location_widget.dart';
import '../widgets/step_property_type_widget.dart';
import '../widgets/property_preview_dialog.dart';

class AddEditPropertyScreen extends StatefulWidget {
  final PropertyModel? propertyToEdit;

  const AddEditPropertyScreen({
    super.key,
    this.propertyToEdit,
  });

  @override
  State<AddEditPropertyScreen> createState() => _AddEditPropertyScreenState();
}

class _AddEditPropertyScreenState extends State<AddEditPropertyScreen> {
  int _currentStep = 0; // 0: Type, 1: Details & Specs, 2: Location
  final bool _isSaving = false;

  // Step 1 State
  late PropertyType _propertyType;

  // Step 2 State
  late ListingType _listingType;
  late ConstructionStatus _constructionStatus;
  late AreaUnit _areaUnit;
  late FacingDirection? _facing;
  late FurnishingStatus _furnishingStatus;
  late int _bedrooms;
  late int _bathrooms;
  late int _balconies;
  late int _parking;
  late List<String> _selectedAmenities;
  late List<MediaModel> _medias;

  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _priceController;
  late TextEditingController _areaController;
  late TextEditingController _floorNumberController;
  late TextEditingController _totalFloorsController;

  // Step 3 State
  late TextEditingController _fullAddressController;
  late TextEditingController _cityController;
  late TextEditingController _stateController;
  late TextEditingController _countryController;
  late TextEditingController _pincodeController;
  late TextEditingController _landmarkController;

  @override
  void initState() {
    super.initState();
    final p = widget.propertyToEdit;

    // Step 1 Init
    _propertyType = p?.propertyType ?? PropertyType.apartment;

    // Step 2 Init
    _listingType = p?.listingType ?? ListingType.sale;
    _constructionStatus = p?.constructionStatus ?? ConstructionStatus.readyToMove;
    _areaUnit = p?.areaUnit ?? AreaUnit.sqft;
    _facing = p?.facing ?? FacingDirection.east;
    _furnishingStatus = p?.furnishingStatus ?? FurnishingStatus.unfurnished;
    _bedrooms = p?.bedrooms ?? 2;
    _bathrooms = p?.bathrooms ?? 2;
    _balconies = p?.balconies ?? 1;
    _parking = p?.parking ?? 1;
    _selectedAmenities = List<String>.from(p?.amenities ?? []);
    _medias = List<MediaModel>.from(p?.medias ?? []);

    _titleController = TextEditingController(text: p?.propertyTitle ?? '');
    _descriptionController = TextEditingController(text: p?.propertyDescription ?? '');
    _priceController = TextEditingController(text: p?.price != null && p!.price > 0 ? p.price.toStringAsFixed(0) : '');
    _areaController = TextEditingController(text: p?.area != null && p!.area > 0 ? p.area.toStringAsFixed(0) : '');
    _floorNumberController = TextEditingController(text: p?.floorNumber?.toString() ?? '');
    _totalFloorsController = TextEditingController(text: p?.totalFloors?.toString() ?? '');

    // Step 3 Init
    _fullAddressController = TextEditingController(text: p?.address?.fullAddress ?? '');
    _cityController = TextEditingController(text: p?.address?.city ?? 'Surat');
    _stateController = TextEditingController(text: p?.address?.state ?? 'Gujarat');
    _countryController = TextEditingController(text: p?.address?.country ?? 'India');
    _pincodeController = TextEditingController();
    _landmarkController = TextEditingController();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _areaController.dispose();
    _floorNumberController.dispose();
    _totalFloorsController.dispose();
    _fullAddressController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _countryController.dispose();
    _pincodeController.dispose();
    _landmarkController.dispose();
    super.dispose();
  }

  bool _validateCurrentStep() {
    if (_currentStep == 0) {
      if (_propertyType == PropertyType.unknown) {
        AppToast.showError(context.tr('validation_error'), context.tr('err_select_property_type'));
        return false;
      }
    } else if (_currentStep == 1) {
      if (_titleController.text.trim().isEmpty) {
        AppToast.showError(context.tr('validation_error'), context.tr('err_enter_property_title'));
        return false;
      }
      final price = double.tryParse(_priceController.text.trim());
      if (price == null || price <= 0) {
        AppToast.showError(context.tr('validation_error'), context.tr('err_enter_valid_price'));
        return false;
      }
      final area = double.tryParse(_areaController.text.trim());
      if (area == null || area <= 0) {
        AppToast.showError(context.tr('validation_error'), context.tr('err_enter_valid_area'));
        return false;
      }
    } else if (_currentStep == 2) {
      if (_fullAddressController.text.trim().isEmpty) {
        AppToast.showError(context.tr('validation_error'), context.tr('err_enter_street_address'));
        return false;
      }
      if (_cityController.text.trim().isEmpty) {
        AppToast.showError(context.tr('validation_error'), context.tr('err_enter_city'));
        return false;
      }
    }
    return true;
  }

  void _nextStep() {
    if (!_validateCurrentStep()) return;

    if (_currentStep < 2) {
      setState(() => _currentStep++);
    } else {
      _showPreviewDialog();
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
    } else {
      Navigator.of(context).pop();
    }
  }

  void _showPreviewDialog() {
    final isEdit = widget.propertyToEdit != null;
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final activeBrokerId = authProvider.userProfile?.brokerId?.id ?? '';
    final property = PropertyModel(
      id: widget.propertyToEdit?.id,
      brokerId: widget.propertyToEdit?.brokerId ?? (activeBrokerId.isNotEmpty ? BrokerModel(id: activeBrokerId) : null),
      propertyTitle: _titleController.text.trim(),
      propertyDescription: _descriptionController.text.trim(),
      propertyType: _propertyType,
      listingType: _listingType,
      price: double.tryParse(_priceController.text.trim()) ?? 0.0,
      area: double.tryParse(_areaController.text.trim()) ?? 0.0,
      areaUnit: _areaUnit,
      bedrooms: _bedrooms,
      bathrooms: _bathrooms,
      balconies: _balconies,
      parking: _parking,
      floorNumber: int.tryParse(_floorNumberController.text.trim()),
      totalFloors: int.tryParse(_totalFloorsController.text.trim()),
      furnishingStatus: _furnishingStatus,
      propertyStatus: widget.propertyToEdit?.propertyStatus ?? PropertyStatus.available,
      constructionStatus: _constructionStatus,
      facing: _facing,
      amenities: _selectedAmenities,
      medias: _medias,
      addressId: AddressModel(
        fullAddress: _fullAddressController.text.trim(),
        city: _cityController.text.trim(),
        state: _stateController.text.trim(),
        country: _countryController.text.trim(),
        pincode: _pincodeController.text.trim(),
        landmark: _landmarkController.text.trim(),
        entityType: 'property',
        entityId: widget.propertyToEdit?.id,
      ),
    );

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return PropertyPreviewDialog(
          property: property,
          isEdit: isEdit,
          propertyProvider: Provider.of<PropertyProvider>(context, listen: false),
          onSuccess: (savedProperty) {
            if (mounted) {
              Navigator.of(context).pop(savedProperty);
            }
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.propertyToEdit != null;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: CommonAppBar(
        title: isEdit ? context.tr('edit_property_listing') : context.tr('add_new_property'),
        onBackPressed: _previousStep,
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, outerConstraints) {
            final isMobile = outerConstraints.maxWidth < 600;

            return SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: isMobile ? 12.0 : 24.0,
                vertical: isMobile ? 12.0 : 24.0,
              ),
              child: Center(
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 900.0),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16.0),
                    border: Border.all(color: AppColors.border, width: 1.0),
                  ),
                  padding: EdgeInsets.all(isMobile ? 14.0 : 24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  // 1. STEP PROGRESS WIZARD HEADER
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final isMobile = constraints.maxWidth < 600;
                      return _buildStepWizardHeader(isMobile);
                    },
                  ),
                  const SizedBox(height: 32.0),

                  // 2. ACTIVE STEP CONTENT
                  if (_currentStep == 0)
                    StepPropertyTypeWidget(
                      selectedType: _propertyType,
                      onTypeSelected: (type) => setState(() => _propertyType = type),
                    )
                  else if (_currentStep == 1)
                    StepPropertyDetailsWidget(
                      listingType: _listingType,
                      onListingTypeChanged: (val) => setState(() => _listingType = val),
                      constructionStatus: _constructionStatus,
                      onConstructionStatusChanged: (val) => setState(() => _constructionStatus = val),
                      titleController: _titleController,
                      descriptionController: _descriptionController,
                      priceController: _priceController,
                      areaController: _areaController,
                      areaUnit: _areaUnit,
                      onAreaUnitChanged: (val) => setState(() => _areaUnit = val),
                      bedrooms: _bedrooms,
                      onBedroomsChanged: (val) => setState(() => _bedrooms = val),
                      bathrooms: _bathrooms,
                      onBathroomsChanged: (val) => setState(() => _bathrooms = val),
                      balconies: _balconies,
                      onBalconiesChanged: (val) => setState(() => _balconies = val),
                      parking: _parking,
                      onParkingChanged: (val) => setState(() => _parking = val),
                      floorNumberController: _floorNumberController,
                      totalFloorsController: _totalFloorsController,
                      facing: _facing,
                      onFacingChanged: (val) => setState(() => _facing = val),
                      furnishingStatus: _furnishingStatus,
                      onFurnishingStatusChanged: (val) => setState(() => _furnishingStatus = val),
                      selectedAmenities: _selectedAmenities,
                      onAmenitiesChanged: (val) => setState(() => _selectedAmenities = val),
                      medias: _medias,
                      onMediasChanged: (val) => setState(() => _medias = val),
                    )
                  else
                    StepPropertyLocationWidget(
                      fullAddressController: _fullAddressController,
                      cityController: _cityController,
                      stateController: _stateController,
                      countryController: _countryController,
                      pincodeController: _pincodeController,
                      landmarkController: _landmarkController,
                    ),

                  const SizedBox(height: 40.0),

                  // 3. BOTTOM ACTION BUTTONS ROW (MODERN REUSABLE WIZARD FOOTER)
                  WizardFooterWidget(
                    currentStep: _currentStep,
                    totalSteps: 3,
                    onBackPressed: _previousStep,
                    onNextPressed: _nextStep,
                    isSaving: _isSaving,
                    nextLabel: context.tr('next_step'),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    ),
  ),
);
}

  Widget _buildStepWizardHeader(bool isMobile) {
    final steps = [
      {'title': context.tr('wizard_step_1_title'), 'subtitle': context.tr('wizard_step_1_subtitle')},
      {'title': context.tr('wizard_step_2_title'), 'subtitle': context.tr('wizard_step_2_subtitle')},
      {'title': context.tr('wizard_step_3_title'), 'subtitle': context.tr('wizard_step_3_subtitle')},
    ];

    if (isMobile) {
      final progress = (_currentStep + 1) / steps.length;

      return Container(
        padding: const EdgeInsets.all(14.0),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12.0),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.15)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 4.0),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(20.0),
                      ),
                      child: Text(
                        context.tr('step_progress_format', arguments: {
                          'current': '${_currentStep + 1}',
                          'total': '${steps.length}',
                          'title': steps[_currentStep]['title']!,
                        }),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                Text(
                  '${(progress * 100).toInt()}%',
                  style: AppTextStyles.caption.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10.0),
            ClipRRect(
              borderRadius: BorderRadius.circular(4.0),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 6.0,
                backgroundColor: AppColors.border,
                valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
              ),
            ),
          ],
        ),
      );
    }

    return Row(
      children: List.generate(steps.length, (index) {
        final isActive = index == _currentStep;
        final isCompleted = index < _currentStep;

        return Expanded(
          child: Row(
            children: [
              Expanded(
                child: MouseRegion(
                  cursor: isCompleted ? SystemMouseCursors.click : SystemMouseCursors.basic,
                  child: GestureDetector(
                    onTap: isCompleted ? () => setState(() => _currentStep = index) : null,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 12.0),
                      decoration: BoxDecoration(
                        color: isActive
                            ? AppColors.primary.withValues(alpha: 0.06)
                            : (isCompleted ? AppColors.surface : AppColors.background),
                        borderRadius: BorderRadius.circular(12.0),
                        border: Border.all(
                          color: isActive
                              ? AppColors.primary
                              : (isCompleted ? AppColors.primary.withValues(alpha: 0.3) : AppColors.border),
                          width: isActive ? 2.0 : 1.0,
                        ),
                        boxShadow: isActive
                            ? [
                                BoxShadow(
                                  color: AppColors.primary.withValues(alpha: 0.1),
                                  blurRadius: 10,
                                  offset: const Offset(0, 3),
                                ),
                              ]
                            : [],
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isActive || isCompleted ? AppColors.primary : AppColors.border,
                            ),
                            child: Center(
                              child: isCompleted
                                  ? const Icon(Icons.check, size: 16, color: Colors.white)
                                  : Text(
                                      '${index + 1}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: isActive ? Colors.white : AppColors.textMuted,
                                      ),
                                    ),
                            ),
                          ),
                          const SizedBox(width: 10.0),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  steps[index]['title']!,
                                  style: TextStyle(
                                    fontSize: 13.0,
                                    fontWeight: isActive || isCompleted ? FontWeight.bold : FontWeight.w500,
                                    color: isActive ? AppColors.primary : AppColors.textPrimary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2.0),
                                Text(
                                  steps[index]['subtitle']!,
                                  style: AppTextStyles.caption.copyWith(
                                    color: AppColors.textMuted,
                                    fontSize: 11.0,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              if (index < steps.length - 1)
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8.0),
                  child: Icon(Icons.arrow_forward_ios_rounded, color: AppColors.textMuted, size: 14.0),
                ),
            ],
          ),
        );
      }),
    );
  }
}
