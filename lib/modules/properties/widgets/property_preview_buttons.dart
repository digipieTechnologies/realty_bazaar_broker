// File: lib/modules/properties/widgets/property_preview_buttons.dart
// Purpose: A clean action button footer using the common AppButton system for publishing flows.

import 'package:flutter/material.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../widgets/buttons/app_button.dart';

class PropertyPreviewButtons extends StatelessWidget {
  final bool isPublishing;
  final String uploadStatusText;
  final bool isEdit;
  final VoidCallback onCancel;
  final VoidCallback onConfirm;

  const PropertyPreviewButtons({
    super.key,
    required this.isPublishing,
    required this.uploadStatusText,
    required this.isEdit,
    required this.onCancel,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (!isPublishing) ...[
          Expanded(
            child: AppButton.outline(
              text: context.tr('edit_details'),
              height: 48.0,
              borderRadius: 12.0,
              onPressed: onCancel,
            ),
          ),
          const SizedBox(width: 12.0),
        ],
        Expanded(
          child: AppButton(
            text: isPublishing ? uploadStatusText : (isEdit ? context.tr('save_changes') : context.tr('save_publish')),
            isLoading: isPublishing,
            height: 48.0,
            borderRadius: 12.0,
            onPressed: isPublishing ? null : onConfirm,
          ),
        ),
      ],
    );
  }
}
