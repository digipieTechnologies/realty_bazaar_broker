// File: lib/modules/properties/widgets/field_info_dialog.dart
// Purpose: Premium theme info dialog using AppBaseDialog for field help, good examples, and pro tips.

import 'package:flutter/material.dart';

import '../../../app/app_colors.dart';
import '../../../app/app_text_styles.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../widgets/buttons/app_button.dart';
import '../../../widgets/dialogs/app_base_dialog.dart';

class FieldInfoDialog extends StatelessWidget {
  final String title;
  final String description;
  final List<String> examples;
  final String? tip;

  const FieldInfoDialog({
    super.key,
    required this.title,
    required this.description,
    this.examples = const [],
    this.tip,
  });

  static void show(
    BuildContext context, {
    required String title,
    required String description,
    List<String> examples = const [],
    String? tip,
  }) {
    showDialog(
      context: context,
      builder: (context) =>
          FieldInfoDialog(title: title, description: description, examples: examples, tip: tip),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppBaseDialog(
      headerIcon: Icons.info_rounded,
      title: title,
      maxWidth: 520.0,
      footer: Align(
        alignment: Alignment.centerRight,
        child: AppButton(
          text: context.tr('got_it'),
          height: 38.0,
          borderRadius: 8.0,
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Description Body
          Text(description, style: AppTextStyles.body1.copyWith(color: AppColors.textSecondary, height: 1.5)),

          // Examples Section
          if (examples.isNotEmpty) ...[
            const SizedBox(height: 16.0),
            Text(
              'Good Examples:',
              style: AppTextStyles.caption.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8.0),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12.0),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(10.0),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: examples
                    .map(
                      (ex) => Padding(
                        padding: const EdgeInsets.only(bottom: 6.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              '• ',
                              style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
                            ),
                            Expanded(
                              child: Text(
                                ex,
                                style: AppTextStyles.body2.copyWith(color: AppColors.textPrimary),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
          ],

          // Pro Tip Section
          if (tip != null && tip!.isNotEmpty) ...[
            const SizedBox(height: 16.0),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12.0),
              decoration: BoxDecoration(
                color: AppColors.secondary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10.0),
                border: Border.all(color: AppColors.secondary.withValues(alpha: 0.3)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.lightbulb_rounded, color: AppColors.secondary, size: 18.0),
                  const SizedBox(width: 8.0),
                  Expanded(
                    child: Text(
                      tip!,
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
