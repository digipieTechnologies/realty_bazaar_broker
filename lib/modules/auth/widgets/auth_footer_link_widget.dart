// File: lib/modules/auth/widgets/auth_footer_link_widget.dart
// Purpose: Footer action link wrapper for screen transitions (e.g. sign in <=> sign up).

import 'package:flutter/material.dart';

import '../../../app/app_colors.dart';
import '../../../app/app_text_styles.dart';

class AuthFooterLinkWidget extends StatelessWidget {
  final String mainText;
  final String actionText;
  final VoidCallback onTap;
  final FocusNode? focusNode;

  const AuthFooterLinkWidget({
    super.key,
    required this.mainText,
    required this.actionText,
    required this.onTap,
    this.focusNode,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Wrap(
        alignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text('$mainText ', style: AppTextStyles.body2.copyWith(color: AppColors.textSecondary)),
          InkWell(
            focusNode: focusNode,
            borderRadius: BorderRadius.circular(4.0),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 2.0),
              child: Text(
                actionText,
                style: AppTextStyles.body2.copyWith(color: AppColors.primary, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
