// File: lib/modules/visits/widgets/schedule_visit_dialog.dart
// Purpose: Modal dialog for scheduling a site visit, replicating the reference design
//          with dark branded header, property attribution, calendar date picker,
//          hourly time slots dropdown, and validation.

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:the_realty_bazaar/widgets/dialogs/app_base_dialog.dart';

import '../../../../app/app_colors.dart';
import '../../../../app/app_text_styles.dart';
import '../../../../app/app_utils.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../models/country_code.dart';
import '../../../../models/property_model.dart';
import '../../../../models/property_visit_enums.dart';
import '../../../../providers/auth/auth_provider.dart';
import '../../../../providers/property/property_provider.dart';
import '../../../../providers/visit/visit_provider.dart';
import '../../../../widgets/buttons/app_button.dart';
import '../../../../widgets/inputs/app_textfield.dart';
import '../../../../widgets/inputs/property_typeahead_field.dart';
import '../../../../widgets/toast/app_toast.dart';
import '../../auth/widgets/phone_field_widget.dart';

class ScheduleVisitDialog extends StatefulWidget {
  final PropertyModel? preselectedProperty;

  const ScheduleVisitDialog({super.key, this.preselectedProperty});

  @override
  State<ScheduleVisitDialog> createState() => _ScheduleVisitDialogState();
}

class _ScheduleVisitDialogState extends State<ScheduleVisitDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _notesController = TextEditingController();

  PropertyModel? _selectedProperty;
  DateTime? _selectedDate;
  String? _selectedTimeSlot;
  bool _isSaving = false;
  CountryCode _selectedCountry = CountryCode.countries.first;

  static List<String> get _hourlySlots => VisitTimeSlot.labels;

  @override
  void initState() {
    super.initState();
    _selectedProperty = widget.preselectedProperty;
    if (_selectedProperty == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final auth = context.read<AuthProvider>();
        final bId = auth.userProfile?.brokerId?.id;
        final propProvider = context.read<PropertyProvider>();
        if (propProvider.properties.isEmpty && bId != null && bId.isNotEmpty) {
          propProvider.fetchProperties(brokerId: bId);
        }
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? now,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: now.add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  String? _validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return context.tr('client_name_required');
    }
    if (value.trim().length < 2) {
      return context.tr('client_name_min');
    }
    return null;
  }


  Future<void> _handleConfirm() async {
    AppUtils.hideKeyboard(context);

    if (_selectedProperty == null) {
      AppToast.showError('Required', context.tr('property_required'));
      return;
    }

    if (_selectedDate == null) {
      AppToast.showError('Required', context.tr('visit_date_required'));
      return;
    }

    if (_selectedTimeSlot == null || _selectedTimeSlot!.isEmpty) {
      AppToast.showError('Required', context.tr('time_slot_required'));
      return;
    }

    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    final authProvider = context.read<AuthProvider>();
    final brokerId = authProvider.userProfile?.brokerId?.id ?? _selectedProperty!.brokerId?.id;

    if (brokerId == null || brokerId.isEmpty) {
      setState(() => _isSaving = false);
      AppToast.showError('Error', 'Broker profile not found.');
      return;
    }

    try {
      final visitProvider = context.read<VisitProvider>();
      final newVisit = await visitProvider.scheduleVisit(
        brokerId: brokerId,
        propertyId: _selectedProperty!.id!,
        clientName: _nameController.text.trim(),
        clientPhone: '${_selectedCountry.code} ${_phoneController.text.trim()}',
        visitDate: _selectedDate!,
        timeSlot: _selectedTimeSlot!,
        notes: _notesController.text.trim(),
      );

      if (mounted) {
        AppToast.showSuccess(context.tr('site_visits'), context.tr('visit_scheduled_success'));
        Navigator.of(context).pop(newVisit);
      }
    } catch (e) {
      debugPrint('[ScheduleVisitDialog] Error saving visit: $e');
      if (mounted) {
        AppToast.showError('Error', e.toString());
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
    final authProvider = context.read<AuthProvider>();
    final brokerId = authProvider.userProfile?.brokerId?.id ?? _selectedProperty?.brokerId?.id;

    return AppBaseDialog(
      title: context.tr('schedule_site_visit'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // --- FORM FIELDS ---
            Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Property Picker using TypeAhead (if not preselected)
                  if (widget.preselectedProperty == null) ...[
                    PropertyTypeAheadField(
                      brokerId: brokerId,
                      selectedPropertyId: _selectedProperty?.id,
                      isRequired: true,
                      label: context.tr('select_property'),
                      hintText: context.tr('select_property'),
                      onPropertyChanged: (property) {
                        setState(() {
                          _selectedProperty = property;
                        });
                      },
                      validator: (val) {
                        if (_selectedProperty == null) {
                          return context.tr('property_required');
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16.0),
                  ],

                  // Date & Time Slot in Responsive Row
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final isTwoColumn = constraints.maxWidth > 360;

                      final dateField = Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          RichText(
                            text: TextSpan(
                              text: context.tr('preferred_date'),
                              style: AppTextStyles.label,
                              children: const [
                                TextSpan(
                                  text: ' *',
                                  style: TextStyle(color: AppColors.primary),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 6.0),
                          InkWell(
                            onTap: _isSaving ? null : _pickDate,
                            borderRadius: BorderRadius.circular(10.0),
                            child: Container(
                              height: 48.0,
                              padding: const EdgeInsets.symmetric(horizontal: 14.0),
                              decoration: BoxDecoration(
                                border: Border.all(color: AppColors.border),
                                borderRadius: BorderRadius.circular(10.0),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    _selectedDate != null
                                        ? DateFormat('dd-MMM-yyyy').format(_selectedDate!)
                                        : 'dd-MMM-yyyy',
                                    style: AppTextStyles.body2.copyWith(
                                      color: _selectedDate != null
                                          ? AppColors.textPrimary
                                          : AppColors.textSecondary,
                                    ),
                                  ),
                                  const Icon(
                                    Icons.calendar_today_outlined,
                                    size: 18.0,
                                    color: AppColors.textSecondary,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      );

                      final timeSlotField = Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          RichText(
                            text: TextSpan(
                              text: context.tr('preferred_time_slot'),
                              style: AppTextStyles.label,
                              children: const [
                                TextSpan(
                                  text: ' *',
                                  style: TextStyle(color: AppColors.primary),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 6.0),
                          Container(
                            height: 48.0,
                            padding: const EdgeInsets.symmetric(horizontal: 14.0),
                            decoration: BoxDecoration(
                              border: Border.all(color: AppColors.border),
                              borderRadius: BorderRadius.circular(10.0),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                isExpanded: true,
                                value: _selectedTimeSlot,
                                hint: Text(
                                  context.tr('select_time_slot'),
                                  style: AppTextStyles.body2.copyWith(color: AppColors.textSecondary),
                                ),
                                icon: const Icon(
                                  Icons.keyboard_arrow_down_rounded,
                                  color: AppColors.textSecondary,
                                ),
                                items: _hourlySlots.map((slot) {
                                  return DropdownMenuItem<String>(
                                    value: slot,
                                    child: Text(
                                      slot,
                                      style: AppTextStyles.body2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  );
                                }).toList(),
                                onChanged: _isSaving
                                    ? null
                                    : (val) {
                                        setState(() {
                                          _selectedTimeSlot = val;
                                        });
                                      },
                              ),
                            ),
                          ),
                        ],
                      );

                      if (isTwoColumn) {
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: dateField),
                            const SizedBox(width: 12.0),
                            Expanded(child: timeSlotField),
                          ],
                        );
                      } else {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [dateField, const SizedBox(height: 14.0), timeSlotField],
                        );
                      }
                    },
                  ),
                  const SizedBox(height: 16.0),
                  AppTextField(
                    controller: _nameController,
                    label: "${context.tr('your_full_name')} *",
                    hint: context.tr('full_name_hint'),
                    validator: _validateName,
                    prefixIcon: const Icon(
                      Icons.person_outline_rounded,
                      size: 20.0,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 16.0),

                  // Phone Number (WhatsApp)
                  PhoneFieldWidget(
                    controller: _phoneController,
                    initialCountry: _selectedCountry,
                    onCountryChanged: (country) {
                      setState(() {
                        _selectedCountry = country;
                      });
                    },
                  ),
                  const SizedBox(height: 24.0),

                  // Confirm Button
                  AppButton(
                    text: context.tr('confirm_site_visit_request'),
                    onPressed: _handleConfirm,
                    isLoading: _isSaving,
                    width: double.infinity,
                    height: 48.0,
                    borderRadius: 12.0,
                    color: const Color(0xFF2563EB), // Rich primary blue
                  ),
                  const SizedBox(height: 16.0),

                  // Privacy Lock Notice
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.lock_outline_rounded, size: 14.0, color: AppColors.textSecondary),
                      const SizedBox(width: 6.0),
                      Flexible(
                        child: Text(
                          context.tr('visit_privacy_notice'),
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.textSecondary,
                            fontSize: 11.5,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
