// File: lib/widgets/loaders/app_loader.dart
// Purpose: Inline and full-screen premium loader indicators.

// ignore_for_file: deprecated_member_use

import 'dart:ui';
import 'package:flutter/material.dart';
import '../../app/app_colors.dart';
import '../../app/app_text_styles.dart';

class AppLoader extends StatelessWidget {
  final bool isFullScreen;
  final double size;
  final Color? color;
  final bool isDark;
  final String? loadingText;

  const AppLoader({
    super.key,
    this.isFullScreen = false,
    this.size = 32.0,
    this.color,
    this.isDark = true,
    this.loadingText,
  });

  @override
  Widget build(BuildContext context) {
    final indicatorColor =
        color ?? (isDark ? AppColors.primary : AppColors.surface);

    final Widget spinner = SizedBox(
      width: size,
      height: size,
      child: CircularProgressIndicator(
        strokeWidth: 3.0,
        valueColor: AlwaysStoppedAnimation<Color>(indicatorColor),
      ),
    );

    if (!isFullScreen) {
      if (loadingText != null) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            spinner,
            const SizedBox(height: 12.0),
            Text(
              loadingText!,
              style: AppTextStyles.body2.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        );
      }
      return spinner;
    }

    // Full screen glassmorphic loading screen
    return Stack(
      children: [
        Positioned.fill(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 4.0, sigmaY: 4.0),
            child: Container(color: Colors.black.withOpacity(0.3)),
          ),
        ),
        Center(
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 32.0,
              vertical: 24.0,
            ),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16.0),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 15.0,
                  spreadRadius: 2.0,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                spinner,
                if (loadingText != null) ...[
                  const SizedBox(height: 16.0),
                  Text(
                    loadingText!,
                    style: AppTextStyles.body1.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ] else ...[
                  const SizedBox(height: 12.0),
                  Text(
                    'Loading...',
                    style: AppTextStyles.body2.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}
