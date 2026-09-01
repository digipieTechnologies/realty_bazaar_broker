// ignore_for_file: deprecated_member_use

import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../../app/app_colors.dart';
import '../../../../app/app_text_styles.dart';
import '../../../../core/localization/app_localizations.dart';

class LivePerformanceCard extends StatelessWidget {
  final bool isLocked;

  const LivePerformanceCard({super.key, required this.isLocked});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.0),
        side: const BorderSide(color: AppColors.border, width: 1.0),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16.0),
        child: Stack(
          children: [
            // Underlying Stats Content
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Card Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          context.tr('live_performance'),
                          style: AppTextStyles.heading3.copyWith(
                            fontWeight: FontWeight.bold,
                            color: isLocked ? AppColors.textPrimary.withOpacity(0.3) : AppColors.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                        decoration: BoxDecoration(
                          color: AppColors.border.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(6.0),
                        ),
                        child: Text(
                          context.tr('preview_mode'),
                          style: AppTextStyles.caption.copyWith(
                            fontSize: 9.0,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 36.0),

                  // Metrics Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildMetricColumn(
                        context.tr("todays_leads"),
                        isLocked ? '--' : '24',
                        AppColors.primary,
                      ),
                      _buildMetricColumn(
                        context.tr("engagement"),
                        isLocked ? '--' : '84.6%',
                        AppColors.success,
                      ),
                      _buildMetricColumn(context.tr("reach_caps"), isLocked ? '--' : '12.8K', Colors.orange),
                    ],
                  ),
                  const SizedBox(height: 12.0),
                ],
              ),
            ),

            // Locked Overlay (Blur + Padlock Message)
            if (isLocked)
              Positioned.fill(
                child: ClipRect(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 4.0, sigmaY: 4.0),
                    child: Container(
                      color: Colors.white.withOpacity(0.85),
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Padlock Icon Circle
                          Container(
                            padding: const EdgeInsets.all(12.0),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.08),
                              shape: BoxShape.circle,
                              border: Border.all(color: AppColors.primary.withOpacity(0.15), width: 1.5),
                            ),
                            child: const Icon(
                              Icons.lock_outline_rounded,
                              size: 24.0,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(height: 14.0),

                          // Header Locked Text
                          Text(
                            context.tr('connect_to_unlock_analytics'),
                            style: AppTextStyles.body1.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 6.0),

                          // Subtitle Locked Text
                          Text(
                            context.tr('track_growth_realtime'),
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.textSecondary,
                              fontSize: 12.0,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricColumn(String label, String value, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          label,
          style: AppTextStyles.caption.copyWith(
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
            color: AppColors.textMuted,
          ),
        ),
        const SizedBox(height: 8.0),
        Text(
          value,
          style: TextStyle(
            fontSize: 28.0,
            fontWeight: FontWeight.w800,
            color: isLocked ? AppColors.textPrimary.withOpacity(0.2) : color,
          ),
        ),
      ],
    );
  }
}
