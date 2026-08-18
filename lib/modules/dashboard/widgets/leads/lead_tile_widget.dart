// File: lib/modules/dashboard/widgets/leads/lead_tile_widget.dart
// Purpose: Reusable lead tile widget supporting both desktop table row & mobile card layouts with platform badges, quick actions, and View Lead dialog trigger.

import 'package:flutter/material.dart';
import '../../../../app/app_colors.dart';
import '../../../../app/app_text_styles.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../models/social_enums.dart';
import '../../../../models/social_lead_model.dart';
import '../../../../util/app_date_utils.dart';
import '../../../../util/app_utils.dart';
import '../../../../widgets/buttons/app_popup_menu_button.dart';
import '../../../../widgets/common/user_avatar_widget.dart';
import '../../../../widgets/dialogs/view_lead_dialog.dart';
import '../../../../widgets/icons/app_icons.dart';

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

  Widget _buildPlatformBadge(SocialPlatform? platform, {double size = 20.0}) {
    if (platform == SocialPlatform.facebook) {
      return FacebookIconWidget(size: size);
    } else if (platform == SocialPlatform.instagram) {
      return InstagramIconWidget(size: size);
    }
    return Text(
      '--',
      style: AppTextStyles.body2.copyWith(
        color: AppColors.textMuted,
        fontWeight: FontWeight.w600,
        fontSize: size * 0.7,
      ),
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

    if (isMobile) {
      return Card(
        margin: const EdgeInsets.only(bottom: 12.0),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14.0),
          side: const BorderSide(color: AppColors.border, width: 1.0),
        ),
        color: AppColors.surface,
        child: InkWell(
          onTap: onTap ?? () => ViewLeadDialog.show(context, lead),
          borderRadius: BorderRadius.circular(14.0),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Row: Avatar, Name, Platform Badge & Subtitle (Phone on dashboard / Date on leads tab)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    UserAvatarWidget(
                      name: lead.userName,
                      radius: 20.0,
                    ),
                    const SizedBox(width: 12.0),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            lead.userName,
                            style: AppTextStyles.heading3.copyWith(
                              fontSize: 15.0,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 1.5),
                          Row(
                            children: [
                              _buildPlatformBadge(platform, size: 16.0),
                              const SizedBox(width: 6.0),
                              Flexible(
                                child: Text(
                                  isMinimalView ? lead.contactNumber : _formatDate(lead.createdAt),
                                  style: AppTextStyles.caption.copyWith(
                                    color: isMinimalView ? AppColors.textSecondary : AppColors.textMuted,
                                    fontWeight: isMinimalView ? FontWeight.w600 : FontWeight.normal,
                                    fontSize: 12.0,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    _buildPopupMenu(context),
                  ],
                ),

                // Contact Number & Quick Actions Row (Only shown when NOT from dashboard)
                if (!isMinimalView) ...[
                  const SizedBox(height: 12.0),
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: AppColors.background,
                            borderRadius: BorderRadius.circular(8.0),
                            border: Border.all(color: AppColors.border, width: 1.0),
                          ),
                          child: Text(
                            lead.contactNumber,
                            style: AppTextStyles.caption.copyWith(
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8.0),
                      IconButton(
                        onPressed: () => AppUtils.launchAppUrl('tel:${lead.contactNumber}'),
                        icon: const CallIconWidget(size: 22.0),
                        tooltip: 'Call',
                        visualDensity: VisualDensity.compact,
                      ),
                      IconButton(
                        onPressed: () => AppUtils.launchAppUrl('https://wa.me/${lead.whatsappNumber.replaceAll('+', '').replaceAll(' ', '')}'),
                        icon: const WhatsappIconWidget(size: 22.0),
                        tooltip: 'WhatsApp',
                        visualDensity: VisualDensity.compact,
                      ),
                    ],
                  ),
                ],

                // Property Title / Description
                if (propertyText.isNotEmpty) ...[
                  const SizedBox(height: 10.0),
                  if (isMinimalView)
                    Text(
                      propertyText,
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textSecondary,
                        fontSize: 12.0,
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    )
                  else
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(10.0),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceLight,
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      child: Text(
                        propertyText,
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.textSecondary,
                          fontSize: 12.0,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
              ],
            ),
          ),
        ),
      );
    }

    // Desktop Table Row Layout
    return InkWell(
      onTap: onTap ?? () => ViewLeadDialog.show(context, lead),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 14.0),
        decoration: const BoxDecoration(
          border: Border(
            bottom: BorderSide(color: AppColors.border, width: 1.0),
          ),
        ),
        child: Row(
          children: [
            // Lead Details (Avatar & Name & Phone)
            Expanded(
              flex: 3,
              child: Row(
                children: [
                  UserAvatarWidget(
                    name: lead.userName,
                    radius: 20.0,
                  ),
                  const SizedBox(width: 14.0),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          lead.userName,
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
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12.0),

            // Source / Platform
            Expanded(
              flex: 2,
              child: Align(
                alignment: Alignment.center,
                child: _buildPlatformBadge(platform, size: 20.0),
              ),
            ),
            const SizedBox(width: 12.0),

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
            const SizedBox(width: 12.0),

            // Created At
            Expanded(
              flex: 2,
              child: Text(
                _formatDate(lead.createdAt),
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.textSecondary,
                  fontSize: 12.0,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),

            // Actions
            SizedBox(
              width: 40,
              child: _buildPopupMenu(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPopupMenu(BuildContext context) {
    final hasPostPermalink = lead.socialPost?.permalink != null &&
        lead.socialPost!.permalink!.trim().isNotEmpty;

    return AppPopupMenuButton<String>(
      triggerIconColor: AppColors.textSecondary,
      onSelected: (value) {
        if (value == 'view_lead') {
          ViewLeadDialog.show(context, lead);
        } else if (value == 'call') {
          AppUtils.launchAppUrl('tel:${lead.contactNumber}');
        } else if (value == 'whatsapp') {
          AppUtils.launchAppUrl('https://wa.me/${lead.whatsappNumber.replaceAll('+', '').replaceAll(' ', '')}');
        } else if (value == 'view_post') {
          if (hasPostPermalink) {
            AppUtils.launchAppUrl(lead.socialPost!.permalink!);
          }
        }
      },
      items: [
        AppPopupMenuItem<String>(
          value: 'view_lead',
          iconData: Icons.visibility_rounded,
          iconColor: AppColors.primary,
          label: context.tr('view_lead'),
        ),
        AppPopupMenuItem<String>(
          value: 'call',
          icon: const CallIconWidget(size: 18.0),
          label: context.tr('call_lead'),
        ),
        AppPopupMenuItem<String>(
          value: 'whatsapp',
          icon: const WhatsappIconWidget(size: 18.0),
          label: context.tr('send_whatsapp'),
        ),
        if (hasPostPermalink)
          AppPopupMenuItem<String>(
            value: 'view_post',
            iconData: Icons.open_in_new_rounded,
            iconColor: const Color(0xFF1877F2),
            label: context.tr('view_social_post'),
          ),
      ],
    );
  }
}
