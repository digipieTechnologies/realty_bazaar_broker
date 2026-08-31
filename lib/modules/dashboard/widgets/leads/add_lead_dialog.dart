// File: lib/modules/dashboard/widgets/leads/add_lead_dialog.dart
// Purpose: Flexible and responsive modal dialog for brokers to manually add leads with required single-line property details.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../../app/app_colors.dart';
import '../../../../app/app_text_styles.dart';
import '../../../../app/app_utils.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/supabase/supabase_config.dart';
import '../../../../models/social_lead_model.dart';
import '../../../../providers/auth/auth_provider.dart';
import '../../../../widgets/buttons/app_button.dart';
import '../../../../widgets/dialogs/app_base_dialog.dart';
import '../../../../widgets/inputs/app_textfield.dart';
import '../../../../widgets/toast/app_toast.dart';

class AddLeadDialog extends StatefulWidget {
  const AddLeadDialog({super.key});

  @override
  State<AddLeadDialog> createState() => _AddLeadDialogState();
}

class _AddLeadDialogState extends State<AddLeadDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _propertyDetailsController = TextEditingController();
  final _notesController = TextEditingController();

  bool _isSaving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _propertyDetailsController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  String? _validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter client name';
    }
    if (value.trim().length < 2) {
      return 'Name must be at least 2 characters';
    }
    return null;
  }

  String? _validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter phone number';
    }
    final clean = value.replaceAll(RegExp(r'\D'), '');
    if (clean.length != 10) {
      return 'Please enter valid 10-digit mobile number';
    }
    if (!RegExp(r'^[6-9]\d{9}$').hasMatch(clean)) {
      return 'Please enter valid 10-digit mobile number';
    }
    return null;
  }

  String? _validatePropertyDetails(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Property details are required';
    }
    if (value.trim().length < 3) {
      return 'Please enter descriptive property details';
    }
    return null;
  }

  Future<void> _handleSaveLead() async {
    AppUtils.hideKeyboard(context);
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    final name = _nameController.text.trim();
    final rawPhone = _phoneController.text.replaceAll(RegExp(r'\D'), '').trim();
    final propertyDetails = _propertyDetailsController.text.trim();
    final notes = _notesController.text.trim();

    final authProvider = context.read<AuthProvider>();
    final brokerId = authProvider.userProfile?.brokerId?.id;

    try {
      final response = await SupabaseConfig.client
          .from('social_leads')
          .insert({
            'user_name': name,
            'phone': rawPhone,
            'phone_country_code': '91',
            'phone_country_iso': 'IN',
            'property_details': propertyDetails,
            'notes': notes.isNotEmpty ? notes : null,
            'broker_id': brokerId,
          })
          .select()
          .single();

      final newLead = SocialLeadModel.fromJson(response);

      if (mounted) {
        AppToast.showSuccess('Lead Saved', 'Lead for "$name" recorded successfully.');
        Navigator.of(context).pop(newLead);
      }
    } catch (e) {
      debugPrint('Failed to save lead: $e');
      if (mounted) {
        AppToast.showError('Save Failed', e.toString());
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppBaseDialog(
      headerIcon: Icons.person_add_alt_1_rounded,
      title: context.tr('add_new_lead'),
      maxWidth: 500.0,
      isCloseDisabled: _isSaving,
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Lead Name Input
            AppTextField(
              controller: _nameController,
              label: context.tr('client_lead_name_label'),
              hint: context.tr('client_lead_name_hint'),
              prefixIcon: const Icon(Icons.person_outline_rounded, size: 20.0, color: AppColors.primary),
              validator: _validateName,
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 16.0),

            // Phone Number Input
            AppTextField(
              controller: _phoneController,
              label: context.tr('phone_number_required_label'),
              hint: context.tr('phone_number_hint'),
              keyboardType: TextInputType.phone,
              validator: _validatePhone,
              textInputAction: TextInputAction.next,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(10)],
              prefixIcon: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(width: 12.0),
                  const Icon(Icons.phone_outlined, size: 20.0, color: AppColors.primary),
                  const SizedBox(width: 8.0),
                  Text('+91 ', style: AppTextStyles.textField.copyWith(fontWeight: FontWeight.bold)),
                  Container(width: 1.0, height: 16.0, color: AppColors.border),
                  const SizedBox(width: 12.0),
                ],
              ),
            ),
            const SizedBox(height: 16.0),

            // Property Details Input (Required & Single-Line maxLines: 1)
            AppTextField(
              controller: _propertyDetailsController,
              label: context.tr('property_details_required_label'),
              hint: context.tr('property_details_hint'),
              maxLines: 1, // Single line requirement
              prefixIcon: const Icon(Icons.location_city_outlined, size: 20.0, color: AppColors.primary),
              validator: _validatePropertyDetails,
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 16.0),

            // Additional Notes (Optional)
            AppTextField(
              controller: _notesController,
              label: context.tr('additional_notes_label'),
              hint: context.tr('additional_notes_hint'),
              maxLines: 2,
              prefixIcon: const Icon(Icons.edit_note_rounded, size: 20.0, color: AppColors.primary),
              textInputAction: TextInputAction.done,
            ),
            const SizedBox(height: 28.0),

            // Actions Row using Unified AppButton
            Row(
              children: [
                Expanded(
                  child: AppButton.outline(
                    text: context.tr('cancel'),
                    height: 46.0,
                    onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
                  ),
                ),
                const SizedBox(width: 12.0),
                Expanded(
                  child: AppButton.solid(
                    text: context.tr('save_lead'),
                    height: 46.0,
                    isLoading: _isSaving,
                    onPressed: _handleSaveLead,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
