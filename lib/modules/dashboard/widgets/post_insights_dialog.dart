// File: lib/modules/dashboard/widgets/post_insights_dialog.dart
// Purpose: Modal dialog displaying native-styled Meta post insights, engagement metrics, and reach performance.

import 'package:flutter/material.dart';
import '../../../app/app_colors.dart';
import '../../../app/app_text_styles.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../models/social_post_model.dart';
import '../../../models/social_enums.dart';
import '../../../widgets/dialogs/app_base_dialog.dart';

class PostInsightsDialog extends StatelessWidget {
  final SocialPostModel post;

  const PostInsightsDialog({
    super.key,
    required this.post,
  });

  static Future<void> show(BuildContext context, SocialPostModel post) {
    return showDialog(
      context: context,
      builder: (context) => PostInsightsDialog(post: post),
    );
  }

  @override
  Widget build(BuildContext context) {
    final insights = post.insights ?? const PostInsightsModel();
    final isFacebook = post.platform == SocialPlatform.facebook;
    final platformName = isFacebook ? 'Facebook' : 'Instagram';
    final platformColor = isFacebook ? const Color(0xFF1877F2) : const Color(0xFFE4405F);
    final assetIcon = isFacebook ? 'assets/icons/facebook.png' : 'assets/icons/instagram.png';

    final impressions = insights.impressions > 0 ? insights.impressions : (post.viewsCount ?? 0);
    final reach = insights.reach > 0 ? insights.reach : (impressions > 0 ? (impressions * 0.8).round() : 0);
    final engagement = insights.engagement > 0 ? insights.engagement : ((post.likesCount ?? 0) + (post.commentCount ?? 0) + (post.shareCount ?? 0));

    return AppBaseDialog(
      headerIconWidget: Image.asset(
        assetIcon,
        width: 28.0,
        height: 28.0,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) => Icon(
          Icons.insights_rounded,
          color: platformColor,
          size: 28.0,
        ),
      ),
      title: '$platformName ${context.tr('post_insights')}',
      subtitle: context.tr('live_meta_insights'),
      maxWidth: 480.0,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

            // Overview Metric Grid (2x2)
            GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 12.0,
              mainAxisSpacing: 12.0,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: 2.2,
              children: [
                _buildMetricCard(
                  title: context.tr('impressions_caps'),
                  value: '$impressions',
                  icon: Icons.remove_red_eye_rounded,
                  color: AppColors.primary,
                ),
                _buildMetricCard(
                  title: context.tr('reach_caps'),
                  value: '$reach',
                  icon: Icons.people_outline_rounded,
                  color: AppColors.secondary,
                ),
                _buildMetricCard(
                  title: context.tr('engagement_caps'),
                  value: '$engagement',
                  icon: Icons.auto_awesome_rounded,
                  color: AppColors.warning,
                ),
                _buildMetricCard(
                  title: isFacebook ? context.tr('shares_caps') : context.tr('saved_caps'),
                  value: isFacebook ? '${insights.shareCount}' : '${insights.savedCount}',
                  icon: isFacebook ? Icons.share_rounded : Icons.bookmark_border_rounded,
                  color: AppColors.info,
                ),
              ],
            ),
            const SizedBox(height: 20.0),

            // Detailed Breakdown
            const Divider(color: AppColors.border, height: 1.0),
            const SizedBox(height: 16.0),

            Text(
              context.tr('interactions_breakdown'),
              style: AppTextStyles.caption.copyWith(
                fontWeight: FontWeight.bold,
                letterSpacing: 0.8,
                color: AppColors.textMuted,
                fontSize: 11.0,
              ),
            ),
            const SizedBox(height: 12.0),

            _buildDetailRow(
              icon: Icons.favorite_rounded,
              iconColor: const Color(0xFFE4405F),
              label: context.tr('likes'),
              value: '${post.likesCount ?? 0}',
            ),
            const SizedBox(height: 8.0),

            _buildDetailRow(
              icon: Icons.chat_bubble_outline_rounded,
              iconColor: const Color(0xFF1877F2),
              label: context.tr('comments'),
              value: '${post.commentCount ?? 0}',
            ),
            const SizedBox(height: 8.0),

            if (isFacebook)
              _buildDetailRow(
                icon: Icons.share_outlined,
                iconColor: AppColors.info,
                label: context.tr('shares'),
                value: '${post.shareCount ?? 0}',
              )
            else
              _buildDetailRow(
                icon: Icons.bookmark_border_rounded,
                iconColor: AppColors.warning,
                label: context.tr('saves'),
                value: '${insights.savedCount}',
              ),

            if (post.mediaType?.toLowerCase().contains('video') == true) ...[
              const SizedBox(height: 8.0),
              _buildDetailRow(
                icon: Icons.play_circle_outline_rounded,
                iconColor: AppColors.secondary,
                label: context.tr('video_views'),
                value: '${insights.videoViews}',
              ),
            ],

            const SizedBox(height: 16.0),
            const Divider(color: AppColors.border, height: 1.0),
            const SizedBox(height: 16.0),

            // Automation Status
            Row(
              children: [
                Icon(
                  post.isStoredInDb ? Icons.check_circle_rounded : Icons.info_outline_rounded,
                  size: 16.0,
                  color: post.isStoredInDb ? AppColors.success : AppColors.textMuted,
                ),
                const SizedBox(width: 6.0),
                Text(
                  post.isStoredInDb
                      ? context.tr('automation_active')
                      : context.tr('live_meta_post'),
                  style: AppTextStyles.caption.copyWith(
                    color: post.isStoredInDb ? AppColors.success : AppColors.textMuted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20.0),

            // Close Button
            SizedBox(
              width: double.infinity,
              height: 44.0,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                ),
                child: Text(context.tr('close_insights'), style: AppTextStyles.button),
              ),
            ),
          ],
        ),
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10.0),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: AppColors.border, width: 1.0),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8.0),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8.0),
            ),
            child: Icon(icon, size: 18.0, color: color),
          ),
          const SizedBox(width: 10.0),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: AppTextStyles.caption.copyWith(
                    fontSize: 9.5,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                    color: AppColors.textMuted,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2.0),
                Text(
                  value,
                  style: AppTextStyles.heading3.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 15.0,
                    color: AppColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, size: 18.0, color: iconColor),
        const SizedBox(width: 10.0),
        Text(
          label,
          style: AppTextStyles.body2.copyWith(
            color: AppColors.textSecondary,
            fontSize: 13.0,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: AppTextStyles.body2.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
            fontSize: 13.5,
          ),
        ),
      ],
    );
  }
}
