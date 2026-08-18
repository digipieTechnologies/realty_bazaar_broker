// File: lib/widgets/dialogs/app_dialog.dart
// Purpose: Dialog overlays built on ContainerCorner supporting confirmation, success, and error themes.

// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import '../../app/app_colors.dart';
import '../../app/app_text_styles.dart';
import '../buttons/rounded_button.dart';
import '../containers/container_corner.dart';

enum DialogType { info, success, error, warning }

class AppDialog extends StatelessWidget {
  final String title;
  final String description;
  final DialogType type;
  final String confirmText;
  final String? cancelText;
  final VoidCallback onConfirm;
  final VoidCallback? onCancel;

  const AppDialog({
    super.key,
    required this.title,
    required this.description,
    this.type = DialogType.info,
    this.confirmText = 'Confirm',
    this.cancelText,
    required this.onConfirm,
    this.onCancel,
  });

  // --- STATIC HELPERS FOR QUICK SHOW ---

  static Future<T?> show<T>(
    BuildContext context, {
    required String title,
    required String description,
    DialogType type = DialogType.info,
    String confirmText = 'Confirm',
    String? cancelText,
    required VoidCallback onConfirm,
    VoidCallback? onCancel,
  }) {
    return showDialog<T>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AppDialog(
        title: title,
        description: description,
        type: type,
        confirmText: confirmText,
        cancelText: cancelText,
        onConfirm: onConfirm,
        onCancel: onCancel,
      ),
    );
  }

  static Future<T?> showSuccess<T>(
    BuildContext context, {
    required String title,
    required String description,
    String confirmText = 'OK',
    required VoidCallback onConfirm,
  }) {
    return show<T>(
      context,
      title: title,
      description: description,
      type: DialogType.success,
      confirmText: confirmText,
      onConfirm: onConfirm,
    );
  }

  static Future<T?> showError<T>(
    BuildContext context, {
    required String title,
    required String description,
    String confirmText = 'Close',
    required VoidCallback onConfirm,
  }) {
    return show<T>(
      context,
      title: title,
      description: description,
      type: DialogType.error,
      confirmText: confirmText,
      onConfirm: onConfirm,
    );
  }

  /// Shows a themed confirmation dialog and returns [bool?]:
  /// - `true`  → user pressed confirm
  /// - `false` → user pressed cancel
  /// - `null`  → user dismissed via back button or barrier tap
  static Future<bool?> showConfirmationDialog(
    BuildContext context, {
    required String title,
    required String description,
    DialogType type = DialogType.info,
    required String confirmText,
    String? cancelText,
  }) {
    Color themeColor;
    IconData themeIcon;

    switch (type) {
      case DialogType.success:
        themeColor = AppColors.success;
        themeIcon = Icons.check_circle_outline_rounded;
      case DialogType.error:
        themeColor = AppColors.error;
        themeIcon = Icons.error_outline_rounded;
      case DialogType.warning:
        themeColor = AppColors.warning;
        themeIcon = Icons.warning_amber_rounded;
      case DialogType.info:
        themeColor = AppColors.primary;
        themeIcon = Icons.info_outline_rounded;
    }

    return showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: ContainerCorner(
          width: 320.0,
          color: AppColors.surface,
          borderRadius: 16.0,
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon
              ContainerCorner(
                width: 56.0,
                height: 56.0,
                borderRadius: 28.0,
                color: themeColor.withValues(alpha: 0.1),
                alignment: Alignment.center,
                child: Icon(themeIcon, color: themeColor, size: 32.0),
              ),
              const SizedBox(height: 20.0),
              // Title
              Text(title, style: AppTextStyles.heading3, textAlign: TextAlign.center),
              const SizedBox(height: 10.0),
              // Description
              Text(description, style: AppTextStyles.body2, textAlign: TextAlign.center),
              const SizedBox(height: 24.0),
              // Buttons
              Row(
                children: [
                  if (cancelText != null) ...[
                    Expanded(
                      child: RoundedButton(
                        text: cancelText,
                        variant: ButtonVariant.outline,
                        borderColor: AppColors.border,
                        textStyle: AppTextStyles.button.copyWith(
                          color: AppColors.textSecondary,
                        ),
                        onPressed: () => Navigator.of(ctx).pop(false),
                      ),
                    ),
                    const SizedBox(width: 12.0),
                  ],
                  Expanded(
                    child: RoundedButton(
                      text: confirmText,
                      variant: ButtonVariant.solid,
                      color: themeColor,
                      onPressed: () => Navigator.of(ctx).pop(true),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- HELPER TO GET DIALOG ICON & COLOR ---

  IconData _getIcon() {
    switch (type) {
      case DialogType.success:
        return Icons.check_circle_outline_rounded;
      case DialogType.error:
        return Icons.error_outline_rounded;
      case DialogType.warning:
        return Icons.warning_amber_rounded;
      case DialogType.info:
        return Icons.info_outline_rounded;
    }
  }

  Color _getColor() {
    switch (type) {
      case DialogType.success:
        return AppColors.success;
      case DialogType.error:
        return AppColors.error;
      case DialogType.warning:
        return AppColors.warning;
      case DialogType.info:
        return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeColor = _getColor();

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: ContainerCorner(
        width: 320.0,
        color: AppColors.surface,
        borderRadius: 16.0,
        padding: const EdgeInsets.all(24.0),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Styled header icon
              ContainerCorner(
                width: 56.0,
                height: 56.0,
                borderRadius: 28.0,
                color: themeColor.withOpacity(0.1),
                alignment: Alignment.center,
                child: Icon(_getIcon(), color: themeColor, size: 32.0),
              ),
              const SizedBox(height: 20.0),

              // Title
              Text(
                title,
                style: AppTextStyles.heading3,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10.0),

              // Description
              Text(
                description,
                style: AppTextStyles.body2,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24.0),

              // Buttons Row
              Row(
                children: [
                  if (cancelText != null) ...[
                    Expanded(
                      child: RoundedButton(
                        text: cancelText!,
                        variant: ButtonVariant.outline,
                        borderColor: AppColors.border,
                        textStyle: AppTextStyles.button.copyWith(
                          color: AppColors.textSecondary,
                        ),
                        onPressed: () {
                          Navigator.of(context).pop();
                          if (onCancel != null) onCancel!();
                        },
                      ),
                    ),
                    const SizedBox(width: 12.0),
                  ],
                  Expanded(
                    child: RoundedButton(
                      text: confirmText,
                      variant: ButtonVariant.solid,
                      color: themeColor,
                      onPressed: () {
                        Navigator.of(context).pop();
                        onConfirm();
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
