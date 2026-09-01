// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../app/app_colors.dart';
import '../../../app/app_constants.dart';
import '../../../app/app_routes.dart';
import '../../../app/app_text_styles.dart';
import '../../../app/app_utils.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../models/models.dart';
import '../../../providers/auth/auth_provider.dart';
import '../../../util/common_ext.dart';
import '../../../widgets/buttons/app_button.dart';
import '../../../widgets/buttons/language_selector_button.dart';
import '../../../widgets/dialogs/app_dialog.dart';
import '../../../widgets/dividers/app_divider.dart';
import '../../../widgets/inputs/app_textfield.dart';
import '../../../widgets/loaders/app_loader.dart';
import '../../../widgets/toast/app_toast.dart';
import '../../auth/widgets/phone_field_widget.dart';

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
  late TextEditingController _brokerCodeController;
  late TextEditingController _fullAddressController;
  late TextEditingController _cityController;
  late TextEditingController _stateController;
  late TextEditingController _pincodeController;
  late TextEditingController _countryController;
  late TextEditingController _landmarkController;
  late CountryCode _selectedCountry;

  // Focus nodes
  final _nameFocusNode = FocusNode();
  final _phoneFocusNode = FocusNode();
  final _businessNameFocusNode = FocusNode();
  final _fullAddressFocusNode = FocusNode();
  final _landmarkFocusNode = FocusNode();
  final _cityFocusNode = FocusNode();
  final _stateFocusNode = FocusNode();
  final _pincodeFocusNode = FocusNode();
  final _countryFocusNode = FocusNode();
  final _saveFocusNode = FocusNode();

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
    _businessNameController = TextEditingController(text: broker?.businessName ?? '');
    _brokerCodeController = TextEditingController(text: broker?.brokerCode ?? '');

    _fullAddressController = TextEditingController(text: address?.fullAddress ?? '');
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
    _brokerCodeController.dispose();
    _fullAddressController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _pincodeController.dispose();
    _countryController.dispose();
    _landmarkController.dispose();

    _nameFocusNode.dispose();
    _phoneFocusNode.dispose();
    _businessNameFocusNode.dispose();
    _fullAddressFocusNode.dispose();
    _landmarkFocusNode.dispose();
    _cityFocusNode.dispose();
    _stateFocusNode.dispose();
    _pincodeFocusNode.dispose();
    _countryFocusNode.dispose();
    _saveFocusNode.dispose();

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
          TextInput.finishAutofillContext(shouldSave: true);
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
            description: authProvider.errorMessage ?? context.tr('error_generic'),
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
    final isDesktop = context.isDesktop;
    final isMobile = context.isMobileUI;

    if (profile == null) {
      return Scaffold(
        body: Center(child: AppLoader(isFullScreen: false, loadingText: context.tr('error_generic'))),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: AppConstants.getTabPadding(context, bottomExtra: isMobile ? 80.0 : 24.0),
          child: Form(
            key: _formKey,
            child: AutofillGroup(
              child: FocusTraversalGroup(
                policy: OrderedTraversalPolicy(),
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
                          Expanded(flex: 3, child: _buildPersonalDetailsCard(isDesktop)),
                          const SizedBox(width: 24.0),
                          Expanded(flex: 4, child: _buildBusinessDetailsCard(isDesktop)),
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
                      alignment: isDesktop ? Alignment.centerRight : Alignment.center,
                      child: FocusTraversalOrder(
                        order: const NumericFocusOrder(10),
                        child: AppButton(
                          text: context.tr('save_changes'),
                          variant: AppButtonVariant.gradient,
                          width: isDesktop ? 200.0 : double.infinity,
                          focusNode: _saveFocusNode,
                          isLoading: _isSaving,
                          onPressed: _isSaving ? null : _saveChanges,
                        ),
                      ),
                    ),

                    SizedBox(height: isDesktop ? 20.0 : 14.0),
                    const AppDivider(),
                    SizedBox(height: isDesktop ? 20.0 : 14.0),

                    // Change Language Option (Mobile & Tablet view only)
                    if (!isDesktop) ...[
                      const LanguageSelectorButton(),
                      SizedBox(height: isMobile ? 14.0 : 16.0),
                      const AppDivider(),
                      SizedBox(height: isMobile ? 14.0 : 16.0),
                    ],

                    // Account Actions Section (Downside)
                    _buildAccountActionsCard(isDesktop),
                  ],
                ),
              ),
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
                style: AppTextStyles.heading1.copyWith(fontSize: isDesktop ? 26.0 : 20.0),
              ),
              const SizedBox(height: 4.0),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
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
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
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

            FocusTraversalOrder(
              order: const NumericFocusOrder(1),
              child: AppTextField(
                controller: _nameController,
                focusNode: _nameFocusNode,
                label: context.tr('full_name'),
                hint: context.tr('full_name'),
                keyboardType: TextInputType.name,
                autofillHints: const [AutofillHints.name],
                textInputAction: TextInputAction.next,
                onFieldSubmitted: (_) => _phoneFocusNode.requestFocus(),
                prefixIcon: const Icon(Icons.person_outline, color: AppColors.iconDefault),
                validator: AppUtils.validateName,
              ),
            ),
            SizedBox(height: isDesktop ? 20.0 : 12.0),

            FocusTraversalOrder(
              order: const NumericFocusOrder(2),
              child: PhoneFieldWidget(
                controller: _phoneController,
                focusNode: _phoneFocusNode,
                initialCountry: _selectedCountry,
                textInputAction: TextInputAction.next,
                onFieldSubmitted: (_) => _businessNameFocusNode.requestFocus(),
                onCountryChanged: (country) {
                  setState(() {
                    _selectedCountry = country;
                  });
                },
              ),
            ),
            SizedBox(height: isDesktop ? 20.0 : 12.0),

            ExcludeFocusTraversal(
              child: AppTextField(
                controller: _emailController,
                label: context.tr('email_address'),
                hint: context.tr('email_address'),
                readOnly: true,
                prefixIcon: const Icon(Icons.email_outlined, color: AppColors.iconDefault),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.copy_rounded, size: 18.0, color: AppColors.iconDefault),
                  tooltip: context.tr('copy'),
                  onPressed: () {
                    final text = _emailController.text.trim();
                    if (text.isNotEmpty) {
                      Clipboard.setData(ClipboardData(text: text));
                      AppToast.showSuccess(context.tr('copied_title'), context.tr('email_copied'));
                    }
                  },
                ),
              ),
            ),
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

            FocusTraversalOrder(
              order: const NumericFocusOrder(3),
              child: AppTextField(
                controller: _businessNameController,
                focusNode: _businessNameFocusNode,
                label: context.tr('business_name'),
                hint: context.tr('business_name'),
                keyboardType: TextInputType.text,
                autofillHints: const [AutofillHints.organizationName],
                textInputAction: TextInputAction.next,
                onFieldSubmitted: (_) => _fullAddressFocusNode.requestFocus(),
                prefixIcon: const Icon(Icons.business_outlined, color: AppColors.iconDefault),
                validator: (val) => AppUtils.validateRequired(val, fieldName: context.tr('business_name')),
              ),
            ),
            SizedBox(height: isDesktop ? 20.0 : 12.0),

            ExcludeFocusTraversal(
              child: AppTextField(
                controller: _brokerCodeController,
                label: context.tr('broker_code'),
                hint: context.tr('broker_code'),
                readOnly: true,
                prefixIcon: const Icon(Icons.badge_outlined, color: AppColors.iconDefault),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.copy_rounded, size: 18.0, color: AppColors.iconDefault),
                  tooltip: context.tr('copy'),
                  onPressed: () {
                    final text = _brokerCodeController.text.trim();
                    if (text.isNotEmpty) {
                      Clipboard.setData(ClipboardData(text: text));
                      AppToast.showSuccess(context.tr('copied_title'), context.tr('broker_code_copied'));
                    }
                  },
                ),
              ),
            ),
            SizedBox(height: isDesktop ? 20.0 : 12.0),

            FocusTraversalOrder(
              order: const NumericFocusOrder(4),
              child: AppTextField(
                controller: _fullAddressController,
                focusNode: _fullAddressFocusNode,
                label: context.tr('full_address'),
                hint: context.tr('full_address'),
                keyboardType: TextInputType.streetAddress,
                autofillHints: const [AutofillHints.fullStreetAddress],
                textInputAction: TextInputAction.next,
                onFieldSubmitted: (_) => _landmarkFocusNode.requestFocus(),
                maxLines: 1,
                prefixIcon: const Icon(Icons.location_on_outlined, color: AppColors.iconDefault),
                validator: (val) => AppUtils.validateRequired(val, fieldName: context.tr('full_address')),
              ),
            ),
            SizedBox(height: isDesktop ? 20.0 : 12.0),

            FocusTraversalOrder(
              order: const NumericFocusOrder(5),
              child: AppTextField(
                controller: _landmarkController,
                focusNode: _landmarkFocusNode,
                label: context.tr('landmark'),
                hint: context.tr('landmark'),
                keyboardType: TextInputType.text,
                autofillHints: const [AutofillHints.sublocality],
                textInputAction: TextInputAction.next,
                onFieldSubmitted: (_) => _pincodeFocusNode.requestFocus(),
                prefixIcon: const Icon(Icons.pin_drop_outlined, color: AppColors.iconDefault),
                validator: (val) => AppUtils.validateRequired(val, fieldName: context.tr('landmark')),
              ),
            ),
            SizedBox(height: isDesktop ? 20.0 : 12.0),

            if (isDesktop) ...[
              Row(
                children: [
                  Expanded(
                    child: FocusTraversalOrder(
                      order: const NumericFocusOrder(6),
                      child: AppTextField(
                        controller: _pincodeController,
                        focusNode: _pincodeFocusNode,
                        label: context.tr('pincode'),
                        hint: context.tr('pincode'),
                        keyboardType: TextInputType.number,
                        autofillHints: const [AutofillHints.postalCode],
                        textInputAction: TextInputAction.next,
                        onFieldSubmitted: (_) => _cityFocusNode.requestFocus(),
                        prefixIcon: const Icon(Icons.numbers_outlined, color: AppColors.iconDefault),
                        validator: (val) => AppUtils.validateRequired(val, fieldName: context.tr('pincode')),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16.0),
                  Expanded(
                    child: FocusTraversalOrder(
                      order: const NumericFocusOrder(7),
                      child: AppTextField(
                        controller: _cityController,
                        focusNode: _cityFocusNode,
                        label: context.tr('city'),
                        hint: context.tr('city'),
                        keyboardType: TextInputType.text,
                        autofillHints: const [AutofillHints.addressCity],
                        textInputAction: TextInputAction.next,
                        onFieldSubmitted: (_) => _stateFocusNode.requestFocus(),
                        prefixIcon: const Icon(Icons.location_city_outlined, color: AppColors.iconDefault),
                        validator: (val) => AppUtils.validateRequired(val, fieldName: context.tr('city')),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20.0),
              Row(
                children: [
                  Expanded(
                    child: FocusTraversalOrder(
                      order: const NumericFocusOrder(8),
                      child: AppTextField(
                        controller: _stateController,
                        focusNode: _stateFocusNode,
                        label: context.tr('state'),
                        hint: context.tr('state'),
                        keyboardType: TextInputType.text,
                        autofillHints: const [AutofillHints.addressState],
                        textInputAction: TextInputAction.next,
                        onFieldSubmitted: (_) => _countryFocusNode.requestFocus(),
                        prefixIcon: const Icon(Icons.map_outlined, color: AppColors.iconDefault),
                        validator: (val) => AppUtils.validateRequired(val, fieldName: context.tr('state')),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16.0),
                  Expanded(
                    child: FocusTraversalOrder(
                      order: const NumericFocusOrder(9),
                      child: AppTextField(
                        controller: _countryController,
                        focusNode: _countryFocusNode,
                        label: context.tr('country'),
                        hint: context.tr('country'),
                        keyboardType: TextInputType.text,
                        autofillHints: const [AutofillHints.countryName],
                        textInputAction: TextInputAction.done,
                        onFieldSubmitted: (_) => _saveChanges(),
                        prefixIcon: const Icon(Icons.public_outlined, color: AppColors.iconDefault),
                        validator: (val) => AppUtils.validateRequired(val, fieldName: context.tr('country')),
                      ),
                    ),
                  ),
                ],
              ),
            ] else ...[
              FocusTraversalOrder(
                order: const NumericFocusOrder(6),
                child: AppTextField(
                  controller: _pincodeController,
                  focusNode: _pincodeFocusNode,
                  label: context.tr('pincode'),
                  hint: context.tr('pincode'),
                  keyboardType: TextInputType.number,
                  autofillHints: const [AutofillHints.postalCode],
                  textInputAction: TextInputAction.next,
                  onFieldSubmitted: (_) => _cityFocusNode.requestFocus(),
                  prefixIcon: const Icon(Icons.numbers_outlined, color: AppColors.iconDefault),
                  validator: (val) => AppUtils.validateRequired(val, fieldName: context.tr('pincode')),
                ),
              ),
              const SizedBox(height: 12.0),
              FocusTraversalOrder(
                order: const NumericFocusOrder(7),
                child: AppTextField(
                  controller: _cityController,
                  focusNode: _cityFocusNode,
                  label: context.tr('city'),
                  hint: context.tr('city'),
                  keyboardType: TextInputType.text,
                  autofillHints: const [AutofillHints.addressCity],
                  textInputAction: TextInputAction.next,
                  onFieldSubmitted: (_) => _stateFocusNode.requestFocus(),
                  prefixIcon: const Icon(Icons.location_city_outlined, color: AppColors.iconDefault),
                  validator: (val) => AppUtils.validateRequired(val, fieldName: context.tr('city')),
                ),
              ),
              const SizedBox(height: 12.0),
              FocusTraversalOrder(
                order: const NumericFocusOrder(8),
                child: AppTextField(
                  controller: _stateController,
                  focusNode: _stateFocusNode,
                  label: context.tr('state'),
                  hint: context.tr('state'),
                  keyboardType: TextInputType.text,
                  autofillHints: const [AutofillHints.addressState],
                  textInputAction: TextInputAction.next,
                  onFieldSubmitted: (_) => _countryFocusNode.requestFocus(),
                  prefixIcon: const Icon(Icons.map_outlined, color: AppColors.iconDefault),
                  validator: (val) => AppUtils.validateRequired(val, fieldName: context.tr('state')),
                ),
              ),
              const SizedBox(height: 12.0),
              FocusTraversalOrder(
                order: const NumericFocusOrder(9),
                child: AppTextField(
                  controller: _countryController,
                  focusNode: _countryFocusNode,
                  label: context.tr('country'),
                  hint: context.tr('country'),
                  keyboardType: TextInputType.text,
                  autofillHints: const [AutofillHints.countryName],
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _saveChanges(),
                  prefixIcon: const Icon(Icons.public_outlined, color: AppColors.iconDefault),
                  validator: (val) => AppUtils.validateRequired(val, fieldName: context.tr('country')),
                ),
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
      type: DialogType.info,
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Card(
          elevation: 0.0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.0),
            side: const BorderSide(color: AppColors.border, width: 1.0),
          ),
          child: Theme(
            data: Theme.of(context).copyWith(
              dividerColor: Colors.transparent,
              splashColor: Colors.transparent,
              highlightColor: Colors.transparent,
            ),
            child: ExpansionTile(
              initiallyExpanded: false,
              tilePadding: EdgeInsets.all(16).copyWith(bottom: 8, top: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
              childrenPadding: EdgeInsets.fromLTRB(
                isDesktop ? 20.0 : 16.0,
                0.0,
                isDesktop ? 20.0 : 16.0,
                isDesktop ? 20.0 : 16.0,
              ),
              leading: Container(
                padding: const EdgeInsets.all(8.0),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: const Icon(Icons.manage_accounts_outlined, size: 22.0, color: AppColors.primary),
              ),
              title: Text(
                context.tr('account_actions'),
                style: AppTextStyles.heading3.copyWith(fontSize: 16.0),
              ),
              subtitle: Text(
                context.tr('sign_out_subtitle'),
                style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
              ),
              children: [
                const Divider(height: 24, color: AppColors.border),
                const SizedBox(height: 8.0),

                // Danger Zone (Delete Account)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14.0),
                  decoration: BoxDecoration(
                    color: AppColors.error.withOpacity(0.04),
                    borderRadius: BorderRadius.circular(12.0),
                    border: Border.all(color: AppColors.error.withOpacity(0.2), width: 1.0),
                  ),
                  child: isDesktop
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    context.tr('delete_account'),
                                    style: const TextStyle(
                                      fontSize: 14.0,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.error,
                                    ),
                                  ),
                                  const SizedBox(height: 2.0),
                                  Text(
                                    context.tr('delete_account_subtitle'),
                                    style: const TextStyle(fontSize: 12.0, color: AppColors.textSecondary),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 16.0),
                            AppButton(
                              text: context.tr('delete_account'),
                              variant: AppButtonVariant.outline,
                              borderColor: AppColors.error.withOpacity(0.5),
                              textColor: AppColors.error,
                              height: 38.0,
                              iconData: Icons.delete_outline_rounded,
                              onPressed: () => context.push(AppRoutes.deleteAccount),
                            ),
                          ],
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.warning_amber_rounded, size: 18.0, color: AppColors.error),
                                const SizedBox(width: 6.0),
                                Text(
                                  context.tr('delete_account'),
                                  style: const TextStyle(
                                    fontSize: 14.0,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.error,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4.0),
                            Text(
                              context.tr('delete_account_subtitle'),
                              style: const TextStyle(fontSize: 12.0, color: AppColors.textSecondary),
                            ),
                            const SizedBox(height: 12.0),
                            AppButton(
                              text: context.tr('delete_account'),
                              variant: AppButtonVariant.outline,
                              borderColor: AppColors.error.withOpacity(0.5),
                              textColor: AppColors.error,
                              height: 40.0,
                              width: double.infinity,
                              iconData: Icons.delete_outline_rounded,
                              onPressed: () => context.push(AppRoutes.deleteAccount),
                            ),
                          ],
                        ),
                ),

                const SizedBox(height: 16.0),
                const Divider(color: AppColors.border),
                const SizedBox(height: 8.0),

                // Legal links footer
                Row(
                  children: [
                    TextButton(
                      onPressed: () => context.push(AppRoutes.privacyPolicy),
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: const Size(50, 30),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(
                        context.tr('privacy_policy'),
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8.0),
                      child: Text('•', style: TextStyle(color: AppColors.textSecondary)),
                    ),
                    TextButton(
                      onPressed: () => context.push(AppRoutes.termsOfService),
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: const Size(50, 30),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(
                        context.tr('terms_of_service'),
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 20.0),

        // Sign Out Button below Account Actions card
        Align(
          alignment: isDesktop ? Alignment.centerLeft : Alignment.center,
          child: Padding(
            padding: const EdgeInsets.only(left: 4, right: 4),
            child: AppButton.outline(
              text: context.tr('sign_out_button'),
              iconData: Icons.logout_rounded,
              width: isDesktop ? 180.0 : double.infinity,
              height: 44.0,
              textColor: AppColors.textPrimary,
              isLoading: _isSigningOut,
              onPressed: _isSigningOut || _isSaving ? null : _showSignOutConfirmation,
            ),
          ),
        ),
      ],
    );
  }
}
