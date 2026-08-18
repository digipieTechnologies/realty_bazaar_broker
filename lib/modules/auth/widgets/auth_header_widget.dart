// File: lib/modules/auth/widgets/auth_header_widget.dart
// Purpose: Header widget displaying branding logo, title, and subtitle across auth screens.

import 'package:flutter/material.dart';

import '../../../app/app_colors.dart';
import '../../../app/app_text_styles.dart';
import '../../../widgets/brand/app_logo.dart';

class AuthHeaderWidget extends StatelessWidget {
  final String title;
  final String? subtitle;
  final double logoHeight;
  final double logoWidth;

  const AuthHeaderWidget({
    super.key,
    required this.title,
    this.subtitle,
    this.logoHeight = 64.0, // Reduced default height to fit AppLogo nicely
    this.logoWidth = 64.0,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // App branding logo header
        AppLogo(size: logoHeight),
        const SizedBox(height: 24.0),

        // Form Title
        Text(
          title,
          style: AppTextStyles.heading2.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),

        // Form Subtitle
        if (subtitle != null) ...[
          const SizedBox(height: 8.0),
          Text(
            subtitle!,
            style: AppTextStyles.body2.copyWith(color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }
}
