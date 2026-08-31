// File: lib/modules/subscription/widgets/platforms_covered_widget.dart
// Purpose: Badge container displaying active ad distribution platforms (Facebook, Instagram, WhatsApp).

// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import '../../../app/app_colors.dart';
import '../../../app/app_text_styles.dart';

class PlatformsCoveredWidget extends StatelessWidget {
  const PlatformsCoveredWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18.0),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Platforms Covered',
            style: AppTextStyles.body1.copyWith(
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
              fontSize: 15.0,
            ),
          ),
          const SizedBox(height: 12.0),
          Wrap(
            spacing: 10.0,
            runSpacing: 10.0,
            children: [
              _buildPlatformChip(
                label: 'Facebook Pages',
                iconData: Icons.facebook_rounded,
                iconColor: const Color(0xFF1877F2),
                bgColor: const Color(0xFFEFF6FF),
              ),
              _buildPlatformChip(
                label: 'Instagram Business',
                iconData: Icons.camera_alt_rounded,
                iconColor: const Color(0xFFE1306C),
                bgColor: const Color(0xFFFDF2F8),
              ),
              _buildPlatformChip(
                label: 'WhatsApp Direct',
                iconData: Icons.chat_rounded,
                iconColor: const Color(0xFF22C55E),
                bgColor: const Color(0xFFF0FDF4),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPlatformChip({
    required String label,
    required IconData iconData,
    required Color iconColor,
    required Color bgColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: iconColor.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(iconData, size: 16.0, color: iconColor),
          const SizedBox(width: 8.0),
          Text(
            label,
            style: AppTextStyles.caption.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
              fontSize: 12.5,
            ),
          ),
        ],
      ),
    );
  }
}
