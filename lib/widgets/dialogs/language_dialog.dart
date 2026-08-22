// File: lib/widgets/dialogs/language_dialog.dart
// Purpose: A themed dialog showing supported languages dynamically and saving selection to LanguageProvider.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../app/app_colors.dart';
import '../../app/app_text_styles.dart';
import '../../models/language_model.dart';
import '../../providers/language/language_provider.dart';
import '../../core/localization/app_localizations.dart';
import '../buttons/app_button.dart';
import '../containers/container_corner.dart';

class LanguageDialog extends StatefulWidget {
  const LanguageDialog({super.key});

  /// Static helper to trigger the dialog overlay
  static Future<void> show(BuildContext context) {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (context) => const LanguageDialog(),
    );
  }

  @override
  State<LanguageDialog> createState() => _LanguageDialogState();
}

class _LanguageDialogState extends State<LanguageDialog> {
  late String _selectedLanguageCode;

  @override
  void initState() {
    super.initState();
    // Pre-select active language code
    _selectedLanguageCode =
        context.read<LanguageProvider>().locale.languageCode;
  }

  @override
  Widget build(BuildContext context) {
    final languageProvider = context.watch<LanguageProvider>();

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: ContainerCorner(
        width: 340.0,
        color: AppColors.surface,
        borderRadius: 16.0,
        padding: const EdgeInsets.all(24.0),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
            // Styled header icon
            Center(
              child: ContainerCorner(
                width: 56.0,
                height: 56.0,
                borderRadius: 28.0,
                color: AppColors.primary.withValues(alpha: 0.1),
                alignment: Alignment.center,
                child: const Icon(
                  Icons.translate_rounded,
                  color: AppColors.primary,
                  size: 26.0,
                ),
              ),
            ),
            const SizedBox(height: 16.0),

            // Dialog Title
            Text(
              context.tr('select_language'),
              style: AppTextStyles.heading3,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20.0),

            // Language Selection List
            Column(
              children: LanguageModel.languages.map((language) {
                final isSelected = _selectedLanguageCode == language.code;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        _selectedLanguageCode = language.code;
                      });
                    },
                    borderRadius: BorderRadius.circular(10.0),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16.0,
                        vertical: 12.0,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.primary.withValues(alpha: 0.06)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(10.0),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.border,
                          width: 1.0,
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              language.name,
                              style: TextStyle(
                                fontSize: 14.0,
                                fontWeight: isSelected
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                                color: isSelected
                                    ? AppColors.primary
                                    : AppColors.textPrimary,
                              ),
                            ),
                          ),
                          if (isSelected)
                            const Icon(
                              Icons.check_circle_rounded,
                              color: AppColors.primary,
                              size: 20.0,
                            )
                          else
                            Container(
                              width: 20.0,
                              height: 20.0,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: AppColors.iconDefault,
                                  width: 1.5,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24.0),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: AppButton(
                    text: context.tr('cancel'),
                    variant: AppButtonVariant.outline,
                    borderColor: AppColors.border,
                    textStyle: AppTextStyles.button.copyWith(
                      color: AppColors.textPrimary,
                    ),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                  ),
                ),
                const SizedBox(width: 12.0),
                Expanded(
                  child: AppButton(
                    text: context.tr('save'),
                    variant: AppButtonVariant.solid,
                    color: AppColors.primary,
                    onPressed: () {
                      languageProvider.setLanguage(_selectedLanguageCode);
                      Navigator.of(context).pop();
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
