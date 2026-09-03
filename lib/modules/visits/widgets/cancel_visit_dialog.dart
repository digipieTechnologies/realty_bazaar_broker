// File: lib/modules/visits/widgets/cancel_visit_dialog.dart
// Purpose: Confirmation modal to cancel a site visit with mandatory cancellation reason.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../app/app_text_styles.dart';
import '../../../../app/app_utils.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../models/property_visit_model.dart';
import '../../../../providers/visit/visit_provider.dart';
import '../../../../widgets/buttons/app_button.dart';
import '../../../../widgets/dialogs/app_base_dialog.dart';
import '../../../../widgets/inputs/app_textfield.dart';
import '../../../../widgets/toast/app_toast.dart';

class CancelVisitDialog extends StatefulWidget {
  final PropertyVisitModel visit;

  const CancelVisitDialog({super.key, required this.visit});

  @override
  State<CancelVisitDialog> createState() => _CancelVisitDialogState();
}

class _CancelVisitDialogState extends State<CancelVisitDialog> {
  final _formKey = GlobalKey<FormState>();
  final _reasonController = TextEditingController();
  bool _isSaving = false;

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  String? _validateReason(String? value) {
    if (value == null || value.trim().isEmpty) {
      return context.tr('cancel_visit_reason_required');
    }
    if (value.trim().length < 3) {
      return 'Please enter a valid cancellation reason';
    }
    return null;
  }

  Future<void> _handleCancelVisit() async {
    AppUtils.hideKeyboard(context);

    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isSaving = true);

    try {
      final updated = await context.read<VisitProvider>().updateVisitStatus(
        visitId: widget.visit.id!,
        newStatus: 'cancelled',
        reason: _reasonController.text.trim(),
      );

      if (mounted) {
        AppToast.showSuccess(
          context.tr('site_visits'),
          'Site visit cancelled.',
        );
        Navigator.of(context).pop(updated);
      }
    } catch (e) {
      debugPrint('[CancelVisitDialog] Error: $e');
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
    return AppBaseDialog(
      headerIcon: Icons.cancel_outlined,
      title: context.tr('cancel_visit_title'),
      maxWidth: 440.0,
      isCloseDisabled: _isSaving,
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.tr('confirm_cancel_visit'),
              style: AppTextStyles.body1,
            ),
            const SizedBox(height: 16.0),

            Text(
              '${context.tr('cancel_visit_reason_label')} *',
              style: AppTextStyles.body1.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6.0),
            AppTextField(
              controller: _reasonController,
              hint: context.tr('cancel_visit_reason_hint'),
              maxLines: 3,
              minLines: 2,
              validator: _validateReason,
            ),
            const SizedBox(height: 20.0),

            Row(
              children: [
                Expanded(
                  child: AppButton(
                    text: 'Keep Visit',
                    variant: AppButtonVariant.outline,
                    onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
                  ),
                ),
                const SizedBox(width: 12.0),
                Expanded(
                  child: AppButton(
                    text: context.tr('cancel_visit'),
                    variant: AppButtonVariant.danger,
                    onPressed: _handleCancelVisit,
                    isLoading: _isSaving,
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
