// File: lib/modules/dashboard/widgets/base_tab_screen.dart
// Purpose: Base placeholder screens for the shell navigation tabs.

// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';

import '../../../app/app_colors.dart';
import '../../../app/app_constants.dart';
import '../../../app/app_text_styles.dart';

class BaseTabScreen extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;

  const BaseTabScreen({super.key, required this.title, required this.description, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.background,
      child: Center(
        child: SingleChildScrollView(
          padding: AppConstants.getTabPadding(context),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Styled icon container
              Container(
                padding: const EdgeInsets.all(20.0),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.08),
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.primary.withOpacity(0.12), width: 1.5),
                ),
                child: Icon(icon, size: 48.0, color: AppColors.primary),
              ),
              const SizedBox(height: 20.0),

              // Description
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400.0),
                child: Text(
                  description,
                  style: AppTextStyles.subtitle.copyWith(fontSize: 14.0, color: AppColors.textSecondary),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 32.0),

              // Glassmorphic status/action card
              Card(
                margin: EdgeInsets.zero,
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16.0),
                  side: const BorderSide(color: AppColors.border, width: 1.0),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8.0,
                        height: 8.0,
                        decoration: const BoxDecoration(color: AppColors.success, shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 8.0),
                      Text(
                        'Ready for Dynamic Integration',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
