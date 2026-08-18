import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../../app/app_colors.dart';
import '../../../../app/app_text_styles.dart';
import '../../../../providers/dashboard/dashboard_provider.dart';
import '../../../../providers/social/social_provider.dart';
import '../../../../widgets/toast/app_toast.dart';
import '../../../../core/localization/app_localizations.dart';

class QuickActionsCard extends StatelessWidget {
  const QuickActionsCard({super.key});

  @override
  Widget build(BuildContext context) {
    final dashboardProvider = context.watch<DashboardProvider>();
    final socialProvider = context.watch<SocialProvider>();
    final actions = dashboardProvider.getQuickActions(
      socialProvider.isFacebookConnected,
      socialProvider.isInstagramConnected,
    );

    return Card(
      elevation: 0,
      color: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.0),
        side: const BorderSide(color: AppColors.border, width: 1.0),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.tr('quick_actions'),
              style: AppTextStyles.caption.copyWith(
                fontWeight: FontWeight.bold,
                letterSpacing: 0.8,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 24.0),
            
            // Grid layout (2 columns, 3 rows)
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: actions.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16.0,
                mainAxisSpacing: 24.0,
                childAspectRatio: 1.8,
              ),
              itemBuilder: (context, index) {
                final action = actions[index];
                return _buildActionItem(context, action);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionItem(BuildContext context, QuickActionItem action) {
    final iconColor = action.isLocked 
        ? AppColors.textMuted 
        : AppColors.primary;
    final textColor = action.isLocked 
        ? AppColors.textMuted 
        : AppColors.textPrimary;

    return InkWell(
      onTap: () {
        if (action.isLocked) {
          AppToast.showSuccess(
            context.tr('action_locked_title'),
            context.tr('action_locked_desc', arguments: {'action': context.tr('action_${action.id}')}),
          );
        } else {
          context.go(action.routePath);
        }
      },
      borderRadius: BorderRadius.circular(8.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            action.icon,
            size: 26.0,
            color: iconColor,
          ),
          const SizedBox(height: 8.0),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  context.tr('action_${action.id}'),
                  style: TextStyle(
                    fontSize: 12.0,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (action.isLocked) ...[
                const SizedBox(width: 4.0),
                const Icon(
                  Icons.lock_outline_rounded,
                  size: 11.0,
                  color: AppColors.textMuted,
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
