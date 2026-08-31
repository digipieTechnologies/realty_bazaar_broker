// File: lib/widgets/buttons/language_selector_button.dart
// Purpose: Standalone change language button displaying current active language badge and opening LanguageDialog on tap.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/app_colors.dart';
import '../../core/localization/app_localizations.dart';
import '../../models/language_model.dart';
import '../../providers/language/language_provider.dart';
import '../dialogs/language_dialog.dart';

class LanguageSelectorButton extends StatelessWidget {
  const LanguageSelectorButton({super.key});

  @override
  Widget build(BuildContext context) {
    final languageProvider = context.watch<LanguageProvider>();
    final currentCode = languageProvider.locale.languageCode;
    final currentLanguage = LanguageModel.languages.firstWhere(
      (l) => l.code == currentCode,
      orElse: () => LanguageModel.languages.first,
    );

    return InkWell(
      onTap: () => LanguageDialog.show(context),
      borderRadius: BorderRadius.circular(10.0),
      child: Container(
        constraints: const BoxConstraints(minHeight: 48.0),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(10.0),
          border: Border.all(color: AppColors.border, width: 1.0),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.translate_rounded,
              size: 20.0,
              color: AppColors.textSecondary,
            ),
            const SizedBox(width: 12.0),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.tr('change_language'),
                    style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    currentLanguage.name,
                    style: const TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w500,
                      color: AppColors.primary,
                      height: 0,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              size: 18.0,
              color: AppColors.textMuted,
            ),
          ],
        ),
      ),
    );
  }
}
