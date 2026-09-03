import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:the_realty_bazaar/app/app_navigator.dart';

import '../../../../app/app_colors.dart';
import '../../../../app/app_text_styles.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../models/social_enums.dart';
import '../../../../models/social_lead_model.dart';
import '../../../../providers/lead/lead_provider.dart';
import '../../../../util/app_date_utils.dart';
import '../../../../widgets/badges/app_lead_status_badge.dart';
import '../../../../widgets/badges/app_platform_badge.dart';
import '../../../../widgets/buttons/app_circular_chevron.dart';
import '../../../../widgets/common/user_avatar_widget.dart';
import '../../../../widgets/icons/app_icons.dart';
import '../../../../widgets/toast/app_toast.dart';

class LeadTileWidget extends StatelessWidget {
  final SocialLeadModel lead;
  final bool isMobile;
  final bool isMinimalView;
  final VoidCallback? onTap;

  const LeadTileWidget({
    super.key,
    required this.lead,
    this.isMobile = false,
    this.isMinimalView = false,
    this.onTap,
  });

  String _formatDate(DateTime? dateTime) {
    return AppDateUtils.formatDate(dateTime);
  }

  Widget _buildAvatarWithPlatformBadge(SocialPlatform? platform, {double radius = 24.0}) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        UserAvatarWidget(name: lead.userName, radius: radius),
        if (platform == SocialPlatform.facebook)
          Positioned(
            right: -2,
            bottom: -2,
            child: Container(
              padding: const EdgeInsets.all(2.0),
              decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
              child: const FacebookIconWidget(size: 14.0),
            ),
          )
        else if (platform == SocialPlatform.instagram)
          Positioned(
            right: -2,
            bottom: -2,
            child: Container(
              padding: const EdgeInsets.all(2.0),
              decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
              child: const InstagramIconWidget(size: 14.0),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final platform = lead.socialPost?.platform;
    final rawPropertyTitle = lead.socialPost?.propertyId?.propertyTitle;
    final String propertyText = (rawPropertyTitle != null && rawPropertyTitle.trim().isNotEmpty)
        ? rawPropertyTitle.trim()
        : (lead.propertyDetails != null && lead.propertyDetails!.trim().isNotEmpty
              ? lead.propertyDetails!.trim()
              : (lead.socialPost?.caption ?? 'General Inquiry'));

    // --- MOBILE CARD LAYOUT (Modern Food & Product Card Aesthetic) ---
    if (isMobile) {
      return Container(
        margin: const EdgeInsets.only(bottom: 12.0),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20.0),
          border: Border.all(color: AppColors.border, width: 1.0),
          boxShadow: [
            BoxShadow(
              color: AppColors.shadow.withValues(alpha: 0.06),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(20.0),
          child: InkWell(
            onTap: onTap ?? () => AppNavigator.navigateToLeadDetails(context, lead),
            borderRadius: BorderRadius.circular(20.0),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top Row: Avatar on Left, Name & Subtitle in Center, Platform Badge & Chevron on Right
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Prominent Avatar
                      _buildAvatarWithPlatformBadge(platform, radius: 24.0),
                      const SizedBox(width: 14.0),

                      // Name & Contact Info Column
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              lead.userName.isNotEmpty ? lead.userName : 'Lead Prospect',
                              style: AppTextStyles.heading3.copyWith(
                                fontSize: 15.5,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 3.0),
                            Text(
                              isMinimalView
                                  ? lead.contactNumber
                                  : '${lead.contactNumber} • ${_formatDate(lead.createdAt)}',
                              style: AppTextStyles.caption.copyWith(
                                color: AppColors.textMuted,
                                fontSize: 12.0,
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8.0),

                      // Status Badge & Action Arrow
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          AppLeadStatusBadge(
                            status: lead.status,
                            onStatusChanged: (newStatus) async {
                              final success = await context.read<LeadProvider>().updateLeadStatus(
                                lead.id!,
                                newStatus,
                              );
                              if (success && context.mounted) {
                                AppToast.showSuccess('Lead Status', context.tr('leads_toast_status_updated'));
                              }
                            },
                          ),
                          const SizedBox(width: 8.0),
                          AppCircularChevron(
                            collapsedIcon: Icons.chevron_right_rounded,
                            iconColor: AppColors.primary,
                            backgroundColor: AppColors.primary.withValues(alpha: 0.08),
                            iconSize: 18.0,
                            padding: 6.0,
                          ),
                        ],
                      ),
                    ],
                  ),

                  // Bottom Section: Inquired Property Title Box
                  if (propertyText.isNotEmpty) ...[
                    const SizedBox(height: 14.0),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 10.0),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(12.0),
                        border: Border.all(color: AppColors.primary.withValues(alpha: 0.1), width: 1.0),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              propertyText,
                              style: AppTextStyles.caption.copyWith(
                                color: AppColors.textPrimary,
                                fontSize: 13.0,
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      );
    }

    // --- DESKTOP TABLE ROW LAYOUT ---
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap ?? () => AppNavigator.navigateToLeadDetails(context, lead),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 14.0),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: AppColors.border, width: 1.0)),
          ),
          child: Row(
            children: [
              // Lead Details (Avatar with Badge Overlay, Name & Phone)
              Expanded(
                flex: 3,
                child: Row(
                  children: [
                    UserAvatarWidget(name: lead.userName, radius: 20.0),
                    const SizedBox(width: 14.0),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            lead.userName.isNotEmpty ? lead.userName : 'Lead Prospect',
                            style: AppTextStyles.heading3.copyWith(
                              fontSize: 14.0,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 3.0),
                          Text(
                            lead.contactNumber,
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w600,
                              fontSize: 12.0,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Status Badge (Interactive)
              Expanded(
                flex: 1,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: AppLeadStatusBadge(
                    status: lead.status,
                    onStatusChanged: (newStatus) async {
                      final success = await context.read<LeadProvider>().updateLeadStatus(
                        lead.id!,
                        newStatus,
                      );
                      if (success && context.mounted) {
                        AppToast.showSuccess('Lead Status', context.tr('leads_toast_status_updated'));
                      }
                    },
                  ),
                ),
              ),

              // Source / Platform Badge
              Expanded(
                flex: 1,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: AppPlatformBadge(platform: platform),
                ),
              ),

              // Property Details
              Expanded(
                flex: 4,
                child: Text(
                  propertyText,
                  style: AppTextStyles.body2.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                    fontSize: 13.0,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),

              // Created At
              Expanded(
                flex: 1,
                child: Text(
                  _formatDate(lead.createdAt),
                  style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary, fontSize: 12.0),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),

              // Action Chevron Button
              AppCircularChevron(
                collapsedIcon: Icons.chevron_right_rounded,
                iconColor: AppColors.textMuted,
                backgroundColor: Colors.transparent,
                iconSize: 20.0,
                padding: 4.0,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
