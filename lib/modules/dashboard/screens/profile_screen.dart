// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../app/app_routes.dart';
import '../../../app/app_colors.dart';
import '../../../app/app_constants.dart';
import '../../../app/app_text_styles.dart';
import '../../../app/app_utils.dart';
import '../../../providers/auth/auth_provider.dart';
import '../../../widgets/inputs/app_textfield.dart';
import '../../../widgets/buttons/app_button.dart';
import '../../../widgets/loaders/app_loader.dart';
import '../../../widgets/dialogs/app_dialog.dart';
import '../../../widgets/dividers/app_divider.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../util/common_ext.dart';
import '../../auth/widgets/phone_field_widget.dart';
import '../../../models/models.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;
  late TextEditingController _businessNameController;
  late TextEditingController _fullAddressController;
  late TextEditingController _cityController;
  late TextEditingController _stateController;
  late TextEditingController _pincodeController;
  late TextEditingController _countryController;
  late TextEditingController _landmarkController;
  late CountryCode _selectedCountry;
  bool _isSaving = false;
  bool _isSigningOut = false;

  @override
  void initState() {
    super.initState();
    _initFormControllers();
  }

  void _initFormControllers() {
    final profile = context.read<AuthProvider>().userProfile;
    final broker = profile?.brokerId;
    final address = broker?.addressId;

    _nameController = TextEditingController(text: profile?.name ?? '');
    _emailController = TextEditingController(text: profile?.email ?? '');
    _businessNameController = TextEditingController(
      text: broker?.businessName ?? '',
    );

    _fullAddressController = TextEditingController(
      text: address?.fullAddress ?? '',
    );
    _cityController = TextEditingController(text: address?.city ?? '');
    _stateController = TextEditingController(text: address?.state ?? '');
    _pincodeController = TextEditingController(text: address?.pincode ?? '');
    _countryController = TextEditingController(text: address?.country ?? '');
    _landmarkController = TextEditingController(text: address?.landmark ?? '');

    // Parse phone number into country and national number components
    final fullPhone = profile?.phone ?? '';
    CountryCode matchedCountry = CountryCode.countries.first;
    String nationalNumber = '';

    for (final c in CountryCode.countries) {
      if (fullPhone.startsWith(c.code)) {
        matchedCountry = c;
        nationalNumber = fullPhone.substring(c.code.length).trim();
        break;
      }
    }

    if (nationalNumber.isEmpty && fullPhone.isNotEmpty) {
      if (fullPhone.startsWith('+')) {
        final parts = fullPhone.split(' ');
        if (parts.length > 1) {
          nationalNumber = parts.sublist(1).join(' ').trim();
        } else {
          nationalNumber = fullPhone;
        }
      } else {
        nationalNumber = fullPhone;
      }
    }

    _selectedCountry = matchedCountry;
    _phoneController = TextEditingController(text: nationalNumber);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _businessNameController.dispose();
    _fullAddressController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _pincodeController.dispose();
    _countryController.dispose();
    _landmarkController.dispose();
    super.dispose();
  }

  Future<void> _saveChanges() async {
    AppUtils.hideKeyboard(context);
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    try {
      final authProvider = context.read<AuthProvider>();

      // Format number as: +91 9988776655
      final cleanNumber = _phoneController.text.replaceAll(RegExp(r'\D'), '');
      final formattedPhone = '${_selectedCountry.code} $cleanNumber';

      final success = await authProvider.updateProfileAndBroker(
        name: _nameController.text.trim(),
        phone: formattedPhone,
        businessName: _businessNameController.text.trim(),
        fullAddress: _fullAddressController.text.trim(),
        city: _cityController.text.trim(),
        state: _stateController.text.trim(),
        pincode: _pincodeController.text.trim(),
        country: _countryController.text.trim(),
        landmark: _landmarkController.text.trim(),
      );

      if (mounted) {
        if (success) {
          AppDialog.showSuccess(
            context,
            title: context.tr('profile_updated_title'),
            description: context.tr('profile_updated_desc'),
            onConfirm: () {},
          );
        } else {
          AppDialog.showError(
            context,
            title: context.tr('update_failed_title'),
            description:
                authProvider.errorMessage ?? context.tr('error_generic'),
            onConfirm: () {},
          );
        }
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final profile = authProvider.userProfile;
    final isDesktop = context.isDesktopUI;
    final isMobile = context.isMobileUI;

    if (profile == null) {
      return Scaffold(
        body: Center(
          child: AppLoader(
            isFullScreen: false,
            loadingText: context.tr('error_generic'),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: AppConstants.getTabPadding(
            context,
            bottomExtra: isMobile ? 80.0 : 24.0,
          ),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Heading Section
                _buildHeader(profile, isDesktop),
                SizedBox(height: isDesktop ? 24.0 : 14.0),

                // Forms Layout
                if (isDesktop)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 3,
                        child: _buildPersonalDetailsCard(isDesktop),
                      ),
                      const SizedBox(width: 24.0),
                      Expanded(
                        flex: 4,
                        child: _buildBusinessDetailsCard(isDesktop),
                      ),
                    ],
                  )
                else
                  Column(
                    children: [
                      _buildPersonalDetailsCard(isDesktop),
                      SizedBox(height: isMobile ? 12.0 : 24.0),
                      _buildBusinessDetailsCard(isDesktop),
                    ],
                  ),

                SizedBox(height: isDesktop ? 24.0 : 16.0),

                // Save Button (Upside)
                Align(
                  alignment: isDesktop
                      ? Alignment.centerRight
                      : Alignment.center,
                  child: AppButton(
                    text: context.tr('save_changes'),
                    variant: AppButtonVariant.gradient,
                    width: isDesktop ? 200.0 : double.infinity,
                    isLoading: _isSaving,
                    onPressed: _isSaving || _isSigningOut ? null : _saveChanges,
                  ),
                ),

                SizedBox(height: isDesktop ? 20.0 : 14.0),
                const AppDivider(),
                SizedBox(height: isDesktop ? 20.0 : 14.0),

                // Account Actions Section (Downside)
                _buildAccountActionsCard(isDesktop),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(dynamic profile, bool isDesktop) {
    final plan = profile.brokerId?.plan ?? 'Free';

    return Row(
      children: [
        CircleAvatar(
          radius: isDesktop ? 36 : 28,
          backgroundColor: AppColors.primary.withOpacity(0.1),
          child: Text(
            (profile.name as String? ?? 'B').substring(0, 1).toUpperCase(),
            style: TextStyle(
              fontSize: isDesktop ? 28 : 20,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
        ),
        SizedBox(width: isDesktop ? 20.0 : 12.0),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                profile.name ?? 'Broker Profile',
                style: AppTextStyles.heading1.copyWith(
                  fontSize: isDesktop ? 26.0 : 20.0,
                ),
              ),
              const SizedBox(height: 4.0),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      (profile.role?.displayName ?? 'Broker').toUpperCase(),
                      style: const TextStyle(
                        fontSize: 10.0,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8.0),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.success.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      plan.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 10.0,
                        fontWeight: FontWeight.bold,
                        color: AppColors.success,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPersonalDetailsCard(bool isDesktop) {
    return Card(
      elevation: 0.0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.0),
        side: const BorderSide(color: AppColors.border, width: 1.0),
      ),
      child: Padding(
        padding: EdgeInsets.all(isDesktop ? 24.0 : 14.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(context.tr('personal_details'), style: AppTextStyles.heading3),
            const SizedBox(height: 4.0),
            Text(
              context.tr('personal_details_subtitle'),
              style: const TextStyle(fontSize: 13.0, color: AppColors.textSecondary),
            ),
            Divider(height: isDesktop ? 32 : 20, color: AppColors.border),

            AppTextField(
              controller: _nameController,
              label: context.tr('full_name'),
              hint: context.tr('full_name'),
              prefixIcon: const Icon(
                Icons.person_outline,
                color: AppColors.iconDefault,
              ),
              validator: AppUtils.validateName,
            ),
            SizedBox(height: isDesktop ? 20.0 : 12.0),

            PhoneFieldWidget(
              controller: _phoneController,
              initialCountry: _selectedCountry,
              onCountryChanged: (country) {
                setState(() {
                  _selectedCountry = country;
                });
              },
            ),
            SizedBox(height: isDesktop ? 20.0 : 12.0),

            AppTextField(
              controller: _emailController,
              label: context.tr('email_address'),
              hint: context.tr('email_address'),
              readOnly: true,
              prefixIcon: const Icon(
                Icons.email_outlined,
                color: AppColors.iconDefault,
              ),
            ).disable(isDisable: true),
          ],
        ),
      ),
    );
  }

  Widget _buildBusinessDetailsCard(bool isDesktop) {
    return Card(
      elevation: 0.0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.0),
        side: const BorderSide(color: AppColors.border, width: 1.0),
      ),
      child: Padding(
        padding: EdgeInsets.all(isDesktop ? 24.0 : 14.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(context.tr('business_details'), style: AppTextStyles.heading3),
            const SizedBox(height: 4.0),
            Text(
              context.tr('business_details_subtitle'),
              style: const TextStyle(fontSize: 13.0, color: AppColors.textSecondary),
            ),
            Divider(height: isDesktop ? 32 : 20, color: AppColors.border),

            AppTextField(
              controller: _businessNameController,
              label: context.tr('business_name'),
              hint: context.tr('business_name'),
              prefixIcon: const Icon(
                Icons.business_outlined,
                color: AppColors.iconDefault,
              ),
              validator: (val) =>
                  AppUtils.validateRequired(val, fieldName: context.tr('business_name')),
            ),
            SizedBox(height: isDesktop ? 20.0 : 12.0),

            AppTextField(
              controller: _fullAddressController,
              label: context.tr('full_address'),
              hint: context.tr('full_address'),
              maxLines: 1,
              prefixIcon: const Icon(
                Icons.location_on_outlined,
                color: AppColors.iconDefault,
              ),
              validator: (val) =>
                  AppUtils.validateRequired(val, fieldName: context.tr('full_address')),
            ),
            SizedBox(height: isDesktop ? 20.0 : 12.0),

            AppTextField(
              controller: _landmarkController,
              label: context.tr('landmark'),
              hint: context.tr('landmark'),
              prefixIcon: const Icon(
                Icons.pin_drop_outlined,
                color: AppColors.iconDefault,
              ),
              validator: (val) =>
                  AppUtils.validateRequired(val, fieldName: context.tr('landmark')),
            ),
            SizedBox(height: isDesktop ? 20.0 : 12.0),

            if (isDesktop) ...[
              Row(
                children: [
                  Expanded(
                    child: AppTextField(
                      controller: _cityController,
                      label: context.tr('city'),
                      hint: context.tr('city'),
                      prefixIcon: const Icon(
                        Icons.location_city_outlined,
                        color: AppColors.iconDefault,
                      ),
                      validator: (val) =>
                          AppUtils.validateRequired(val, fieldName: context.tr('city')),
                    ),
                  ),
                  const SizedBox(width: 16.0),
                  Expanded(
                    child: AppTextField(
                      controller: _stateController,
                      label: context.tr('state'),
                      hint: context.tr('state'),
                      prefixIcon: const Icon(
                        Icons.map_outlined,
                        color: AppColors.iconDefault,
                      ),
                      validator: (val) =>
                          AppUtils.validateRequired(val, fieldName: context.tr('state')),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20.0),
              Row(
                children: [
                  Expanded(
                    child: AppTextField(
                      controller: _pincodeController,
                      label: context.tr('pincode'),
                      hint: context.tr('pincode'),
                      prefixIcon: const Icon(
                        Icons.numbers_outlined,
                        color: AppColors.iconDefault,
                      ),
                      validator: (val) =>
                          AppUtils.validateRequired(val, fieldName: context.tr('pincode')),
                    ),
                  ),
                  const SizedBox(width: 16.0),
                  Expanded(
                    child: AppTextField(
                      controller: _countryController,
                      label: context.tr('country'),
                      hint: context.tr('country'),
                      prefixIcon: const Icon(
                        Icons.public_outlined,
                        color: AppColors.iconDefault,
                      ),
                      validator: (val) =>
                          AppUtils.validateRequired(val, fieldName: context.tr('country')),
                    ),
                  ),
                ],
              ),
            ] else ...[
              AppTextField(
                controller: _cityController,
                label: context.tr('city'),
                hint: context.tr('city'),
                prefixIcon: const Icon(
                  Icons.location_city_outlined,
                  color: AppColors.iconDefault,
                ),
                validator: (val) =>
                    AppUtils.validateRequired(val, fieldName: context.tr('city')),
              ),
              const SizedBox(height: 12.0),
              AppTextField(
                controller: _stateController,
                label: context.tr('state'),
                hint: context.tr('state'),
                prefixIcon: const Icon(
                  Icons.map_outlined,
                  color: AppColors.iconDefault,
                ),
                validator: (val) =>
                    AppUtils.validateRequired(val, fieldName: context.tr('state')),
              ),
              const SizedBox(height: 12.0),
              AppTextField(
                controller: _pincodeController,
                label: context.tr('pincode'),
                hint: context.tr('pincode'),
                prefixIcon: const Icon(
                  Icons.numbers_outlined,
                  color: AppColors.iconDefault,
                ),
                validator: (val) =>
                    AppUtils.validateRequired(val, fieldName: context.tr('pincode')),
              ),
              const SizedBox(height: 12.0),
              AppTextField(
                controller: _countryController,
                label: context.tr('country'),
                hint: context.tr('country'),
                prefixIcon: const Icon(
                  Icons.public_outlined,
                  color: AppColors.iconDefault,
                ),
                validator: (val) =>
                    AppUtils.validateRequired(val, fieldName: context.tr('country')),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _showSignOutConfirmation() async {
    final confirmed = await AppDialog.showConfirmationDialog(
      context,
      title: context.tr('confirm_sign_out'),
      description: context.tr('sign_out_warning'),
      confirmText: context.tr('sign_out_button'),
      cancelText: context.tr('cancel'),
      type: DialogType.warning,
    );

    if (confirmed == true && mounted) {
      setState(() => _isSigningOut = true);
      try {
        final router = GoRouter.of(context);
        await context.read<AuthProvider>().signOut(context);
        if (mounted) {
          router.go(AppRoutes.login);
        }
      } finally {
        if (mounted) {
          setState(() => _isSigningOut = false);
        }
      }
    }
  }

  Widget _buildAccountActionsCard(bool isDesktop) {
    return Card(
      elevation: 0.0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.0),
        side: const BorderSide(color: AppColors.border, width: 1.0),
      ),
      child: Padding(
        padding: EdgeInsets.all(isDesktop ? 24.0 : 14.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(context.tr('account_actions'), style: AppTextStyles.heading3),
            const SizedBox(height: 4.0),
            Text(
              context.tr('sign_out_subtitle'),
              style: const TextStyle(fontSize: 13.0, color: AppColors.textSecondary),
            ),
            Divider(height: isDesktop ? 32 : 20, color: AppColors.border),
            Align(
              alignment: isDesktop ? Alignment.centerLeft : Alignment.center,
              child: AppButton(
                text: context.tr('sign_out_button'),
                variant: AppButtonVariant.solid,
                color: AppColors.error,
                width: isDesktop ? 200.0 : double.infinity,
                isLoading: _isSigningOut,
                onPressed: _isSigningOut || _isSaving ? null : _showSignOutConfirmation,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
