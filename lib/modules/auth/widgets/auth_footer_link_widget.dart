// File: lib/modules/auth/widgets/auth_footer_link_widget.dart
// Purpose: Footer action link wrapper for screen transitions (e.g. sign in <=> sign up).

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import '../../../app/app_colors.dart';
import '../../../app/app_text_styles.dart';

class AuthFooterLinkWidget extends StatelessWidget {
  final String mainText;
  final String actionText;
  final VoidCallback onTap;

  const AuthFooterLinkWidget({
    super.key,
    required this.mainText,
    required this.actionText,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: RichText(
        textAlign: TextAlign.center,
        text: TextSpan(
          text: '$mainText ',
          style: AppTextStyles.body2.copyWith(color: AppColors.textSecondary),
          children: [
            TextSpan(
              text: actionText,
              style: AppTextStyles.body2.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
                decoration: TextDecoration.underline,
              ),
              recognizer: TapGestureRecognizer()..onTap = onTap,
            ),
          ],
        ),
      ),
    );
  }
}
