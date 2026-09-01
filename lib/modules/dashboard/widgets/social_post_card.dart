// File: lib/modules/dashboard/widgets/social_post_card.dart
// Purpose: Display live social post cards with unified _PostMetricsRow widget for both minimal dashboard and full card views.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../app/app_colors.dart';
import '../../../app/app_routes.dart';
import '../../../app/app_text_styles.dart';
import '../../../app/app_utils.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../models/social_enums.dart';
import '../../../models/social_post_model.dart';
import '../../../providers/auth/auth_provider.dart';
import '../../../providers/social/social_provider.dart';
import '../../../util/common_ext.dart';
import '../../../widgets/buttons/app_button.dart';
import '../../../widgets/common/app_card_container.dart';
import '../../../widgets/icons/app_icons.dart';
import '../../../widgets/images/cached_image.dart';
import '../../../widgets/toast/app_toast.dart';
import 'automation_confirmation_dialog.dart';
import 'package:the_realty_bazaar/app/app_navigator.dart';

class SocialPostCard extends StatelessWidget {
  final SocialPostModel post;
  final bool isMinimalView;

  const SocialPostCard({super.key, required this.post, this.isMinimalView = false});

  @override
  Widget build(BuildContext context) {
    if (isMinimalView) {
      return _buildDashboardMinimalCard(context);
    }
    final isMobile = context.isMobileUI;
    final isFB = post.platform == SocialPlatform.facebook;

    final mediaUrl =
        post.mediaUrl ??
        (post.mediaUrls != null && post.mediaUrls!.isNotEmpty ? post.mediaUrls!.first.url : null);
    final thumbnailUrl = post.thumbnailUrl ?? mediaUrl;
    final hasMedia = thumbnailUrl != null && thumbnailUrl.isNotEmpty;
    final isVideo =
        post.mediaType?.toLowerCase().contains('video') == true ||
        post.mediaType?.toLowerCase().contains('reel') == true;

    final timeStr = _formatDate(post.publishedAt ?? post.createdAt);
    final hasPermalink = post.permalink != null && post.permalink!.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: AppCardContainer(
        borderRadius: 16.0,
        onTap: () => AppNavigator.navigateToPostDetails(context, post),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // 1. Post Media Image with Floating Overlays (~230px height)
            SizedBox(
              height: 230.0,
              width: double.infinity,
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16.0)),
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: hasMedia
                          ? CachedImage(
                              thumbnailUrl,
                              width: double.infinity,
                              height: 230.0,
                              fit: BoxFit.cover,
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(16.0)),
                            )
                          : Container(
                              color: AppColors.background,
                              child: Center(
                                child: Icon(
                                  isFB ? Icons.article_rounded : Icons.photo_library_rounded,
                                  size: 32.0,
                                  color: AppColors.textMuted.withValues(alpha: 0.4),
                                ),
                              ),
                            ),
                    ),

                    // Video Play Badge
                    if (hasMedia && isVideo)
                      Positioned.fill(
                        child: Container(
                          color: Colors.black.withValues(alpha: 0.15),
                          child: Center(
                            child: Container(
                              padding: const EdgeInsets.all(8.0),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.6),
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 1.5),
                              ),
                              child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 22.0),
                            ),
                          ),
                        ),
                      ),

                    // Top-Right Floating Date Pill Overlay
                    if (timeStr.isNotEmpty)
                      Positioned(
                        top: 10.0,
                        right: 10.0,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 5.0),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.55),
                            borderRadius: BorderRadius.circular(20.0),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.25), width: 0.8),
                          ),
                          child: Text(
                            timeStr,
                            style: AppTextStyles.caption.copyWith(
                              fontSize: 11.0,
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),

                    // Bottom-Right Floating Open Icon Button Overlay
                    if (hasPermalink)
                      Positioned(
                        bottom: 10.0,
                        right: 10.0,
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () => AppUtils.launchAppUrl(post.permalink!),
                            borderRadius: BorderRadius.circular(20.0),
                            child: Container(
                              padding: const EdgeInsets.all(7.0),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.55),
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white.withValues(alpha: 0.25), width: 0.8),
                              ),
                              child: const Icon(Icons.open_in_new_rounded, size: 14.0, color: Colors.white),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),

            // 2. Caption & Bottom Metrics / Action Bar
            _buildBottomSection(isMobile: isMobile),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomSection({required bool isMobile}) {
    Widget content = Padding(
      padding: const EdgeInsets.all(12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Caption (Expanded, max 2 lines)
          if (post.caption != null && post.caption!.trim().isNotEmpty)
            SizedBox(
              width: double.infinity,
              child: Text(
                post.caption!.trim(),
                style: AppTextStyles.body2.copyWith(
                  color: AppColors.textPrimary,
                  fontSize: 12.5,
                  height: 1.35,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            )
          else
            const SizedBox.shrink(),

          const SizedBox(height: 8.0),

          // Shared Metrics Row Widget with Automation Button
          _PostMetricsRow(post: post, showAutomationButton: true),
        ],
      ),
    );

    if (!isMobile) {
      return Expanded(child: content);
    }
    return content;
  }

  Widget _buildDashboardMinimalCard(BuildContext context) {
    final isFB = post.platform == SocialPlatform.facebook;
    final mediaUrl =
        post.mediaUrl ??
        (post.mediaUrls != null && post.mediaUrls!.isNotEmpty ? post.mediaUrls!.first.url : null);
    final thumbnailUrl = post.thumbnailUrl ?? mediaUrl;
    final hasMedia = thumbnailUrl != null && thumbnailUrl.isNotEmpty;
    final isVideo =
        post.mediaType?.toLowerCase().contains('video') == true ||
        post.mediaType?.toLowerCase().contains('reel') == true;

    return AppCardContainer(
      borderRadius: 14.0,
      onTap: () {
        if (post.permalink != null && post.permalink!.isNotEmpty) {
          AppUtils.launchAppUrl(post.permalink!);
        }
      },
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Minimal Image/Media Section (Height: 120.0px)
          Stack(
            children: [
              SizedBox(
                height: 120.0,
                width: double.infinity,
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(14.0)),
                  child: hasMedia
                      ? CachedImage(thumbnailUrl, width: double.infinity, height: 120.0, fit: BoxFit.cover)
                      : Container(
                          color: isFB
                              ? AppColors.facebook.withValues(alpha: 0.1)
                              : AppColors.instagram.withValues(alpha: 0.1),
                          child: Center(
                            child: isFB
                                ? const FacebookIconWidget(size: 40.0)
                                : const InstagramIconWidget(size: 40.0),
                          ),
                        ),
                ),
              ),
              // Top Left Platform Badge
              Positioned(
                top: 8,
                left: 8,
                child: Container(
                  padding: const EdgeInsets.all(4.0),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8.0),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.15),
                        blurRadius: 6.0,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: isFB ? const FacebookIconWidget(size: 18.0) : const InstagramIconWidget(size: 18.0),
                ),
              ),
              // Video / Reel Badge at Top Right
              if (isVideo)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4.0),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.65),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 14.0),
                  ),
                ),
            ],
          ),

          // Details Section (Caption & Shared Metrics Row with Date)
          Padding(
            padding: const EdgeInsets.all(10.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Caption
                Text(
                  (post.caption != null && post.caption!.trim().isNotEmpty)
                      ? post.caption!.trim()
                      : 'No caption provided',
                  style: AppTextStyles.heading3.copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: 12.5,
                    color: AppColors.textPrimary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8.0),

                // Shared Metrics Row Widget with Date
                _PostMetricsRow(post: post, showDate: true),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime? dateTime) {
    if (dateTime == null) return '';
    final difference = DateTime.now().difference(dateTime);

    if (difference.inDays >= 7) {
      return AppUtils.formatDate(dateTime, format: 'MMM d, yyyy');
    } else if (difference.inDays >= 1) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours >= 1) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes >= 1) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}

// Private reusable Sub-Widget for Post Metrics Row across minimal and full views
class _PostMetricsRow extends StatelessWidget {
  final SocialPostModel post;
  final bool showDate;
  final bool showAutomationButton;

  const _PostMetricsRow({required this.post, this.showDate = false, this.showAutomationButton = false});

  @override
  Widget build(BuildContext context) {
    final isFB = post.platform == SocialPlatform.facebook;
    final likes = post.likesCount ?? 0;
    final comments = post.commentCount ?? 0;
    final sharesOrSaved = isFB ? (post.shareCount ?? 0) : (post.insights?.savedCount ?? 0);

    return Row(
      children: [
        _buildMetricItem(icon: Icons.favorite_border_rounded, value: likes, color: AppColors.error),
        const SizedBox(width: 10.0),
        _buildMetricItem(
          icon: Icons.chat_bubble_outline_rounded,
          value: comments,
          color: AppColors.primary800,
        ),
        const SizedBox(width: 10.0),
        _buildMetricItem(
          icon: isFB ? Icons.share_outlined : Icons.bookmark_border_rounded,
          value: sharesOrSaved,
          color: AppColors.primary,
        ),
        if (showDate) ...[
          const Spacer(),
          Text(
            _formatDate(post.publishedAt ?? post.createdAt),
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textMuted,
              fontSize: 10.5,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
        if (showAutomationButton) ...[
          const SizedBox(width: 4.0),
          Expanded(
            child: Align(
              alignment: Alignment.centerRight,
              child: _AutomationButton(post: post),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildMetricItem({required IconData icon, required int value, required Color color}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14.0, color: color),
        const SizedBox(width: 3.5),
        Text(
          _formatNumber(value),
          style: AppTextStyles.caption.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
            fontSize: 11.5,
          ),
        ),
      ],
    );
  }

  String _formatNumber(int number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    }
    return number.toString();
  }

  String _formatDate(DateTime? dateTime) {
    if (dateTime == null) return '';
    final difference = DateTime.now().difference(dateTime);

    if (difference.inDays >= 7) {
      return AppUtils.formatDate(dateTime, format: 'MMM d, yyyy');
    } else if (difference.inDays >= 1) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours >= 1) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes >= 1) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}

class _AutomationButton extends StatefulWidget {
  final SocialPostModel post;

  const _AutomationButton({required this.post});

  @override
  State<_AutomationButton> createState() => _AutomationButtonState();
}

class _AutomationButtonState extends State<_AutomationButton> {
  bool _isLoading = false;

  Future<void> _toggleAutomation(BuildContext context) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final socialProvider = Provider.of<SocialProvider>(context, listen: false);
    final isCurrentlyEnabled = widget.post.isStoredInDb;

    final confirmed = await AutomationConfirmationDialog.show(context, isEnabling: !isCurrentlyEnabled);

    if (!confirmed || !mounted) return;

    final brokerId = authProvider.userProfile?.brokerId?.id;

    if (brokerId == null || brokerId.isEmpty) {
      AppToast.showError('Error', 'Broker profile not found.');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    if (isCurrentlyEnabled) {
      await socialProvider.disablePostAutomation(widget.post, brokerId);
    } else {
      await socialProvider.enablePostAutomation(widget.post, brokerId);
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEnabled = widget.post.isStoredInDb;
    final text = isEnabled ? context.tr('pause_leads') : context.tr('get_leads');

    return FittedBox(
      fit: BoxFit.scaleDown,
      child: isEnabled
          ? AppButton.outline(
              text: text,
              isLoading: _isLoading,
              onPressed: () => _toggleAutomation(context),
              height: 32.0,
              borderRadius: 8.0,
              borderColor: AppColors.error,
              textColor: AppColors.error,
              padding: const EdgeInsets.symmetric(horizontal: 10.0),
              textStyle: AppTextStyles.caption.copyWith(fontWeight: FontWeight.bold, fontSize: 11.0),
            )
          : AppButton.solid(
              text: text,
              iconData: Icons.auto_awesome_rounded,
              isLoading: _isLoading,
              onPressed: () => _toggleAutomation(context),
              height: 32.0,
              borderRadius: 8.0,
              color: AppColors.primary,
              textColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 10.0),
              textStyle: AppTextStyles.caption.copyWith(fontWeight: FontWeight.bold, fontSize: 11.0),
            ),
    );
  }
}
