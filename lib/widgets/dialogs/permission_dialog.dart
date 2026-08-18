// File: lib/widgets/dialogs/permission_dialog.dart
// Purpose: Reusable, modern explanation dialog shown when requesting permissions or guiding users to Settings when permanently denied.

import 'package:flutter/material.dart';
import '../../app/app_colors.dart';
import '../../app/app_text_styles.dart';

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
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20.0),
      ),
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
              child: Icon(
                icon,
                color: AppColors.primary,
                size: 36.0,
              ),
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
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.of(context).pop(false);
                      onCancelPressed?.call();
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12.0),
                      side: const BorderSide(color: AppColors.border),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                    ),
                    child: Text(
                      cancelButtonText,
                      style: AppTextStyles.button.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12.0),

                // Primary Action Button (Open Settings / Allow)
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop(true);
                      onPrimaryPressed();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 12.0),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                    ),
                    child: Text(
                      primaryButtonText,
                      style: AppTextStyles.button.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
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
