import 'package:flutter/material.dart';

import '../../../app/app_colors.dart';
import '../../../app/app_text_styles.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../widgets/buttons/app_button.dart';
import '../../../widgets/containers/container_corner.dart';

class AutomationConfirmationDialog extends StatelessWidget {
  final bool isEnabling;

  const AutomationConfirmationDialog({super.key, required this.isEnabling});

  static Future<bool> show(BuildContext context, {required bool isEnabling}) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (context) => AutomationConfirmationDialog(isEnabling: isEnabling),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final themeColor = isEnabling ? AppColors.primary : AppColors.error;
    final title = isEnabling ? context.tr('get_leads_title') : context.tr('pause_leads_title');

    final points = isEnabling
        ? [
            _AutomationPoint(
              icon: Icons.chat_bubble_outline_rounded,
              iconColor: AppColors.primary,
              title: context.tr('automation_instant_replies_title'),
              description: context.tr('automation_instant_replies_desc'),
            ),
            _AutomationPoint(
              icon: Icons.person_add_alt_1_rounded,
              iconColor: AppColors.primary800,
              title: context.tr('automation_lead_capture_title'),
              description: context.tr('automation_lead_capture_desc'),
            ),
            _AutomationPoint(
              icon: Icons.insights_rounded,
              iconColor: AppColors.success,
              title: context.tr('automation_real_time_insights_title'),
              description: context.tr('automation_real_time_insights_desc'),
            ),
          ]
        : [
            _AutomationPoint(
              icon: Icons.pause_circle_outline_rounded,
              iconColor: AppColors.warning,
              title: context.tr('automation_pause_replies_title'),
              description: context.tr('automation_pause_replies_desc'),
            ),
            _AutomationPoint(
              icon: Icons.person_off_rounded,
              iconColor: AppColors.error,
              title: context.tr('automation_pause_leads_title'),
              description: context.tr('automation_pause_leads_desc'),
            ),
            _AutomationPoint(
              icon: Icons.verified_user_outlined,
              iconColor: AppColors.success,
              title: context.tr('automation_data_preserved_title'),
              description: context.tr('automation_data_preserved_desc'),
            ),
          ];

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
      child: ContainerCorner(
        width: 440.0,
        color: AppColors.surface,
        borderRadius: 20.0,
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row with Badge & Close
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                ContainerCorner(
                  width: 48.0,
                  height: 48.0,
                  borderRadius: 14.0,
                  color: themeColor.withValues(alpha: 0.1),
                  alignment: Alignment.center,
                  child: Icon(
                    isEnabling ? Icons.auto_awesome_rounded : Icons.do_not_disturb_on_rounded,
                    color: themeColor,
                    size: 26.0,
                  ),
                ),
                const SizedBox(width: 14.0),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: AppTextStyles.heading3.copyWith(fontSize: 18.0, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 2.0),
                      Text(
                        isEnabling ? context.tr('get_leads_subtitle') : context.tr('pause_leads_subtitle'),
                        style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  icon: const Icon(Icons.close_rounded, size: 20.0, color: AppColors.textMuted),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  splashRadius: 20.0,
                ),
              ],
            ),

            const SizedBox(height: 20.0),
            const Divider(color: AppColors.border, height: 1.0),
            const SizedBox(height: 20.0),

            // Smart Point-Wise List
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  children: points.map((point) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 14.0),
                      child: ContainerCorner(
                        padding: const EdgeInsets.all(14.0),
                        borderRadius: 12.0,
                        color: AppColors.background,
                        borderWidth: 1.0,
                        borderColor: AppColors.border.withValues(alpha: 0.6),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ContainerCorner(
                              width: 34.0,
                              height: 34.0,
                              borderRadius: 10.0,
                              color: point.iconColor.withValues(alpha: 0.12),
                              alignment: Alignment.center,
                              child: Icon(point.icon, size: 18.0, color: point.iconColor),
                            ),
                            const SizedBox(width: 12.0),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    point.title,
                                    style: AppTextStyles.body2.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 3.0),
                                  Text(
                                    point.description,
                                    style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary, height: 1.35),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),

            const SizedBox(height: 8.0),

            // Actions Row
            Row(
              children: [
                Expanded(
                  child: AppButton.outline(
                    text: context.tr('cancel'),
                    onPressed: () => Navigator.of(context).pop(false),
                    height: 42.0,
                    borderRadius: 10.0,
                    borderColor: AppColors.border,
                    textColor: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(width: 12.0),
                Expanded(
                  child: AppButton.solid(
                    text: isEnabling ? context.tr('get_leads') : context.tr('pause_leads'),
                    iconData: isEnabling ? Icons.auto_awesome_rounded : null,
                    onPressed: () => Navigator.of(context).pop(true),
                    height: 42.0,
                    borderRadius: 10.0,
                    color: themeColor,
                    textColor: Colors.white,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _AutomationPoint {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String description;

  const _AutomationPoint({required this.icon, required this.iconColor, required this.title, required this.description});
}
