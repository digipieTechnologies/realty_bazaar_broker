// File: lib/widgets/dialogs/permission_dialog.dart
// Purpose: Reusable, modern explanation dialog shown when requesting permissions or guiding users to Settings when permanently denied.

import 'package:flutter/material.dart';

import '../../app/app_colors.dart';
import '../../app/app_text_styles.dart';
import '../buttons/app_button.dart';

class PermissionDialog extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final String primaryButtonText;
  final String cancelButtonText;
  final VoidCallback onPrimaryPressed;
  final VoidCallback? onCancelPressed;

  const PermissionDialog({
    super.key,
    required this.title,
    required this.description,
    this.icon = Icons.photo_library_rounded,
    this.primaryButtonText = 'Open Settings',
    this.cancelButtonText = 'Cancel',
    required this.onPrimaryPressed,
    this.onCancelPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.0)),
      elevation: 8,
      backgroundColor: AppColors.surface,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon Header
            Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: AppColors.primary, size: 36.0),
            ),
            const SizedBox(height: 18.0),

            // Title
            Text(
              title,
              textAlign: TextAlign.center,
              style: AppTextStyles.heading3.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
                fontSize: 18.0,
              ),
            ),
            const SizedBox(height: 10.0),

            // Description
            Text(
              description,
              textAlign: TextAlign.center,
              style: AppTextStyles.body2.copyWith(
                color: AppColors.textSecondary,
                height: 1.4,
                fontSize: 13.5,
              ),
            ),
            const SizedBox(height: 24.0),

            // Action Buttons Row
            Row(
              children: [
                // Cancel Button
                Expanded(
                  child: AppButton.outline(
                    text: cancelButtonText,
                    height: 44.0,
                    borderRadius: 12.0,
                    borderColor: AppColors.border,
                    textColor: AppColors.textSecondary,
                    onPressed: () {
                      Navigator.of(context).pop(false);
                      onCancelPressed?.call();
                    },
                  ),
                ),
                const SizedBox(width: 12.0),

                // Primary Action Button (Open Settings / Allow)
                Expanded(
                  child: AppButton.solid(
                    text: primaryButtonText,
                    height: 44.0,
                    borderRadius: 12.0,
                    color: AppColors.primary,
                    onPressed: () {
                      Navigator.of(context).pop(true);
                      onPrimaryPressed();
                    },
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
