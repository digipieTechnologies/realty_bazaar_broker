import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../app/app_colors.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../models/address_model.dart';
import '../../../models/broker_model.dart';
import '../../../models/media_model.dart';
import '../../../models/property_enums.dart';
import '../../../models/property_model.dart';
import '../../../providers/auth/auth_provider.dart';
import '../../../providers/property/property_provider.dart';
import '../../../widgets/common/common_app_bar.dart';
import '../../../widgets/common/wizard_footer_widget.dart';
import '../../../widgets/dialogs/app_dialog.dart';
import '../../../widgets/toast/app_toast.dart';
import '../widgets/property_preview_dialog.dart';
import '../widgets/step_property_details_widget.dart';
import '../widgets/step_property_location_widget.dart';
import '../widgets/step_property_type_widget.dart';

class AddEditPropertyScreen extends StatefulWidget {
  final PropertyModel? propertyToEdit;

  const AddEditPropertyScreen({super.key, this.propertyToEdit});

  @override
  State<AddEditPropertyScreen> createState() => _AddEditPropertyScreenState();
}

class _AddEditPropertyScreenState extends State<AddEditPropertyScreen> {
  final ScrollController _scrollController = ScrollController();
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
    _constructionStatus =
        p?.constructionStatus ?? ConstructionStatus.readyToMove;
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
    _descriptionController = TextEditingController(
      text: p?.propertyDescription ?? '',
    );
    _priceController = TextEditingController(
      text: p?.price != null && p!.price > 0 ? p.price.toStringAsFixed(0) : '',
    );
    _areaController = TextEditingController(
      text: p?.area != null && p!.area > 0 ? p.area.toStringAsFixed(0) : '',
    );
    _floorNumberController = TextEditingController(
      text: p?.floorNumber?.toString() ?? '',
    );
    _totalFloorsController = TextEditingController(
      text: p?.totalFloors?.toString() ?? '',
    );

    // Step 3 Init
    _fullAddressController = TextEditingController(
      text: p?.address?.fullAddress ?? '',
    );
    _cityController = TextEditingController(text: p?.address?.city ?? 'Surat');
    _stateController = TextEditingController(
      text: p?.address?.state ?? 'Gujarat',
    );
    _countryController = TextEditingController(
      text: p?.address?.country ?? 'India',
    );
    _pincodeController = TextEditingController();
    _landmarkController = TextEditingController();
  }

  @override
  void dispose() {
    _scrollController.dispose();
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
        AppToast.showError(
          context.tr('validation_error'),
          context.tr('err_select_property_type'),
        );
        return false;
      }
    } else if (_currentStep == 1) {
      if (_titleController.text.trim().isEmpty) {
        AppToast.showError(
          context.tr('validation_error'),
          context.tr('err_enter_property_title'),
        );
        return false;
      }
      final price = double.tryParse(_priceController.text.trim());
      if (price == null || price <= 0) {
        AppToast.showError(
          context.tr('validation_error'),
          context.tr('err_enter_valid_price'),
        );
        return false;
      }
      final area = double.tryParse(_areaController.text.trim());
      if (area == null || area <= 0) {
        AppToast.showError(
          context.tr('validation_error'),
          context.tr('err_enter_valid_area'),
        );
        return false;
      }
    } else if (_currentStep == 2) {
      if (_fullAddressController.text.trim().isEmpty) {
        AppToast.showError(
          context.tr('validation_error'),
          context.tr('err_enter_street_address'),
        );
        return false;
      }
      if (_cityController.text.trim().isEmpty) {
        AppToast.showError(
          context.tr('validation_error'),
          context.tr('err_enter_city'),
        );
        return false;
      }
    }
    return true;
  }

  void _scrollToTop() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0.0,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    }
  }

  void _nextStep() {
    if (!_validateCurrentStep()) return;

    if (_currentStep < 2) {
      setState(() => _currentStep++);
      _scrollToTop();
    } else {
      _showPreviewDialog();
    }
  }

  Future<void> _previousStep() async {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
      _scrollToTop();
    } else {
      await _confirmAndPop();
    }
  }

  Future<bool> _confirmAndPop() async {
    final confirmed = await AppDialog.showConfirmationDialog(
      context,
      title: context.tr('discard_changes'),
      description: context.tr('discard_changes_desc'),
      type: DialogType.warning,
      confirmText: context.tr('discard'),
      cancelText: context.tr('cancel'),
    );

    if (confirmed == true && mounted) {
      Navigator.of(context).pop();
      return true;
    }
    return false;
  }

  void _showPreviewDialog() {
    final isEdit = widget.propertyToEdit != null;
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final activeBrokerId = authProvider.userProfile?.brokerId?.id ?? '';
    final property = PropertyModel(
      id: widget.propertyToEdit?.id,
      brokerId:
          widget.propertyToEdit?.brokerId ??
          (activeBrokerId.isNotEmpty ? BrokerModel(id: activeBrokerId) : null),
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
      propertyStatus:
          widget.propertyToEdit?.propertyStatus ?? PropertyStatus.available,
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
          propertyProvider: Provider.of<PropertyProvider>(
            context,
            listen: false,
          ),
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
    final mediaQueryWidth = MediaQuery.of(context).size.width;
    final isMobileScreen = mediaQueryWidth < 600;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        await _previousStep();
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: CommonAppBar(
          title: isEdit
              ? context.tr('edit_property_listing')
              : context.tr('add_new_property'),
          onBackPressed: _previousStep,
        ),
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, outerConstraints) {
              final isMobile = outerConstraints.maxWidth < 600;

              return SingleChildScrollView(
                controller: _scrollController,
                padding: EdgeInsets.symmetric(
                  horizontal: isMobile ? 12.0 : 24.0,
                  vertical: 12,
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
                        // ACTIVE STEP CONTENT
                        if (_currentStep == 0)
                          StepPropertyTypeWidget(
                            selectedType: _propertyType,
                            onTypeSelected: (type) =>
                                setState(() => _propertyType = type),
                          )
                        else if (_currentStep == 1)
                          StepPropertyDetailsWidget(
                            listingType: _listingType,
                            onListingTypeChanged: (val) =>
                                setState(() => _listingType = val),
                            constructionStatus: _constructionStatus,
                            onConstructionStatusChanged: (val) =>
                                setState(() => _constructionStatus = val),
                            titleController: _titleController,
                            descriptionController: _descriptionController,
                            priceController: _priceController,
                            areaController: _areaController,
                            areaUnit: _areaUnit,
                            onAreaUnitChanged: (val) =>
                                setState(() => _areaUnit = val),
                            bedrooms: _bedrooms,
                            onBedroomsChanged: (val) =>
                                setState(() => _bedrooms = val),
                            bathrooms: _bathrooms,
                            onBathroomsChanged: (val) =>
                                setState(() => _bathrooms = val),
                            balconies: _balconies,
                            onBalconiesChanged: (val) =>
                                setState(() => _balconies = val),
                            parking: _parking,
                            onParkingChanged: (val) =>
                                setState(() => _parking = val),
                            floorNumberController: _floorNumberController,
                            totalFloorsController: _totalFloorsController,
                            facing: _facing,
                            onFacingChanged: (val) =>
                                setState(() => _facing = val),
                            furnishingStatus: _furnishingStatus,
                            onFurnishingStatusChanged: (val) =>
                                setState(() => _furnishingStatus = val),
                            selectedAmenities: _selectedAmenities,
                            onAmenitiesChanged: (val) =>
                                setState(() => _selectedAmenities = val),
                            medias: _medias,
                            onMediasChanged: (val) =>
                                setState(() => _medias = val),
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
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        bottomNavigationBar: Container(
          decoration: const BoxDecoration(
            color: AppColors.surface,
            border: Border(top: BorderSide(color: AppColors.border, width: 1.0)),
          ),
          padding: EdgeInsets.symmetric(
            horizontal: isMobileScreen ? 12 : 24,
            vertical: 10,
          ),
          child: SafeArea(
            top: false,
            child: Center(
              heightFactor: 1.0,
              child: Container(
                constraints: const BoxConstraints(maxWidth: 900.0),
                child: WizardFooterWidget(
                  currentStep: _currentStep,
                  totalSteps: 3,
                  onBackPressed: _previousStep,
                  onNextPressed: _nextStep,
                  isSaving: _isSaving,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
