// File: lib/modules/visits/widgets/reschedule_visit_dialog.dart
// Purpose: Dialog allowing brokers to reschedule an existing site visit with a new date,
//          hourly time slot, and mandatory reason.

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../../app/app_colors.dart';
import '../../../../app/app_text_styles.dart';
import '../../../../app/app_utils.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../models/property_visit_enums.dart';
import '../../../../models/property_visit_model.dart';
import '../../../../providers/visit/visit_provider.dart';
import '../../../../widgets/buttons/app_button.dart';
import '../../../../widgets/dialogs/app_base_dialog.dart';
import '../../../../widgets/inputs/app_textfield.dart';
import '../../../../widgets/toast/app_toast.dart';

class RescheduleVisitDialog extends StatefulWidget {
  final PropertyVisitModel visit;

  const RescheduleVisitDialog({super.key, required this.visit});

  @override
  State<RescheduleVisitDialog> createState() => _RescheduleVisitDialogState();
}

class _RescheduleVisitDialogState extends State<RescheduleVisitDialog> {
  final _formKey = GlobalKey<FormState>();
  final _reasonController = TextEditingController();

  DateTime? _newDate;
  String? _newTimeSlot;
  bool _isSaving = false;
  late final List<String> _availableSlots;

  static List<String> get _hourlySlots => VisitTimeSlot.labels;

  @override
  void initState() {
    super.initState();
    _newDate = widget.visit.visitDate ?? DateTime.now();
    final currentSlot = widget.visit.timeSlot.trim();
    if (currentSlot.isNotEmpty && !_hourlySlots.contains(currentSlot)) {
      _availableSlots = [currentSlot, ..._hourlySlots];
    } else {
      _availableSlots = List.from(_hourlySlots);
    }
    _newTimeSlot = _availableSlots.contains(currentSlot) ? currentSlot : _availableSlots.first;
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _newDate ?? now,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: now.add(const Duration(days: 365)),
    );

    if (picked != null) {
      setState(() {
        _newDate = picked;
      });
    }
  }

  String? _validateReason(String? value) {
    if (value == null || value.trim().isEmpty) {
      return context.tr('reschedule_reason_required');
    }
    if (value.trim().length < 3) {
      return 'Please enter a valid reason';
    }
    return null;
  }

  Future<void> _handleSave() async {
    AppUtils.hideKeyboard(context);

    if (_newDate == null) {
      AppToast.showError('Required', context.tr('visit_date_required'));
      return;
    }

    if (_newTimeSlot == null || _newTimeSlot!.isEmpty) {
      AppToast.showError('Required', context.tr('time_slot_required'));
      return;
    }

    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isSaving = true);

    try {
      final updated = await context.read<VisitProvider>().rescheduleVisit(
        visitId: widget.visit.id!,
        newDate: _newDate!,
        newTimeSlot: _newTimeSlot!,
        reason: _reasonController.text.trim(),
      );

      if (mounted) {
        AppToast.showSuccess(context.tr('site_visits'), context.tr('visit_rescheduled_success'));
        Navigator.of(context).pop(updated);
      }
    } catch (e) {
      debugPrint('[RescheduleVisitDialog] Error: $e');
      if (mounted) {
        AppToast.showError('Error', e.toString());
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final curDate = widget.visit.visitDate;
    final curDateStr = curDate != null ? DateFormat('dd-MMM-yyyy').format(curDate) : 'N/A';

    return AppBaseDialog(
      headerIcon: Icons.update_rounded,
      title: context.tr('reschedule_site_visit'),
      maxWidth: 480.0,
      isCloseDisabled: _isSaving,
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Current Schedule Banner
            Container(
              padding: const EdgeInsets.all(12.0),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(10.0),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline_rounded, size: 18.0, color: AppColors.textSecondary),
                  const SizedBox(width: 8.0),
                  Expanded(
                    child: Text(
                      'Current Schedule: $curDateStr (${widget.visit.timeSlot})',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16.0),

            // New Date Picker
            Text(
              '${context.tr('preferred_date')} *',
              style: AppTextStyles.label,
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
                      _newDate != null ? DateFormat('dd-MMM-yyyy').format(_newDate!) : 'dd-MMM-yyyy',
                      style: AppTextStyles.body2,
                    ),
                    const Icon(Icons.calendar_today_outlined, size: 18.0, color: AppColors.textSecondary),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16.0),

            // New Time Slot
            Text(
              '${context.tr('preferred_time_slot')} *',
              style: AppTextStyles.label,
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
                  value: _newTimeSlot,
                  items: _availableSlots.map((slot) {
                    return DropdownMenuItem<String>(
                      value: slot,
                      child: Text(slot, style: AppTextStyles.body2),
                    );
                  }).toList(),
                  onChanged: _isSaving
                      ? null
                      : (val) {
                          setState(() => _newTimeSlot = val);
                        },
                ),
              ),
            ),
            const SizedBox(height: 16.0),

            // Reason for Rescheduling (Mandatory)
            Text(
              '${context.tr('reschedule_reason_label')} *',
              style: AppTextStyles.label,
            ),
            const SizedBox(height: 6.0),
            AppTextField(
              controller: _reasonController,
              hint: context.tr('reschedule_reason_hint'),
              maxLines: 3,
              minLines: 2,
              validator: _validateReason,
            ),
            const SizedBox(height: 20.0),

            // Save Button
            AppButton(
              text: context.tr('reschedule_site_visit'),
              onPressed: _handleSave,
              isLoading: _isSaving,
              width: double.infinity,
            ),
          ],
        ),
      ),
    );
  }
}
