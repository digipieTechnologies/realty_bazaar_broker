// File: lib/widgets/dialogs/view_lead_dialog.dart
// Purpose: Modern app-themed dialog displaying detailed lead information, property specs, images, inquiry notes, and quick action buttons.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../app/app_colors.dart';
import '../../app/app_text_styles.dart';
import '../../core/localization/app_localizations.dart';
import '../../models/social_enums.dart';
import '../../models/social_lead_model.dart';
import '../../util/app_date_utils.dart';
import '../../util/app_utils.dart';
import '../../util/common_ext.dart';
import '../buttons/app_button.dart';
import '../icons/app_icons.dart';
import '../images/cached_image.dart';
import '../toast/app_toast.dart';

import '../common/user_avatar_widget.dart';
import './app_base_dialog.dart';

class ViewLeadDialog extends StatelessWidget {
  final SocialLeadModel lead;

  const ViewLeadDialog({
    super.key,
    required this.lead,
  });

  static Future<void> show(BuildContext context, SocialLeadModel lead) {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (context) => ViewLeadDialog(lead: lead),
    );
  }

  @override
  Widget build(BuildContext context) {
    final socialPost = lead.socialPost;
    final platform = socialPost?.platform;
    final hasPermalink = socialPost?.permalink != null && socialPost!.permalink!.trim().isNotEmpty;
    final property = socialPost?.propertyId;
    final propertyTitle = property?.propertyTitle.isNotEmpty == true
        ? property!.propertyTitle
        : (lead.propertyDetails ?? socialPost?.caption ?? '');
    final notesText = lead.notes;
    final mediaUrls = socialPost?.mediaUrls;

    return AppBaseDialog(
      headerIcon: Icons.contacts_rounded,
      title: context.tr('lead_details'),
      maxWidth: 520.0,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Profile Header & Action Buttons Card
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(16.0),
              border: Border.all(color: AppColors.border, width: 1.0),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    UserAvatarWidget(
                      name: lead.userName,
                      radius: 26.0,
                    ),
                    const SizedBox(width: 14.0),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            lead.userName,
                            style: AppTextStyles.heading3.copyWith(
                              fontSize: 17.0,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 3.0),
                          Text(
                            AppDateUtils.formatDate(lead.createdAt),
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.textMuted,
                              fontSize: 12.0,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16.0),

                // Action Buttons Row (Call & WhatsApp)
                Row(
                  children: [
                    Expanded(
                      child: AppButton(
                        text: context.isMobileUI ? null : context.tr('call_lead'),
                        icon: CallIconWidget(size: context.isMobileUI ? 22.0 : 18.0),
                        variant: AppButtonVariant.secondary,
                        color: AppColors.primary.withValues(alpha: 0.1),
                        textColor: AppColors.primary,
                        borderColor: AppColors.primary.withValues(alpha: 0.2),
                        height: 42.0,
                        borderRadius: 10.0,
                        onPressed: () => AppUtils.launchAppUrl('tel:${lead.contactNumber}'),
                      ),
                    ),
                    const SizedBox(width: 12.0),
                    Expanded(
                      child: AppButton(
                        text: context.isMobileUI ? null : context.tr('send_whatsapp'),
                        icon: WhatsappIconWidget(size: context.isMobileUI ? 22.0 : 18.0),
                        variant: AppButtonVariant.secondary,
                        color: const Color(0xFF25D366).withValues(alpha: 0.1),
                        textColor: const Color(0xFF1EBE5D),
                        borderColor: const Color(0xFF25D366).withValues(alpha: 0.3),
                        height: 42.0,
                        borderRadius: 10.0,
                        onPressed: () => AppUtils.launchAppUrl('https://wa.me/${lead.whatsappNumber.replaceAll('+', '').replaceAll(' ', '')}'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16.0),

          // Section 1: Contact Information
          _buildSectionHeader(context, context.tr('contact_info'), Icons.contacts_rounded),
          const SizedBox(height: 8.0),
          Container(
            padding: const EdgeInsets.all(12.0),
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(12.0),
              border: Border.all(color: AppColors.border, width: 1.0),
            ),
            child: Column(
              children: [
                _buildDetailRow(
                  label: context.tr('phone_number'),
                  value: lead.contactNumber,
                  icon: Icons.phone_android_rounded,
                  trailing: IconButton(
                    icon: const Icon(Icons.copy_rounded, size: 16.0, color: AppColors.textSecondary),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: lead.contactNumber));
                      AppToast.showSuccess(context.tr('copied_title'), context.tr('contact_number_copied'));
                    },
                  ),
                ),
                if (platform != null) ...[
                  const Divider(height: 16.0, thickness: 1.0, color: AppColors.border),
                  _buildDetailRow(
                    label: context.tr('platform_source'),
                    value: platform == SocialPlatform.facebook ? 'Facebook' : (platform == SocialPlatform.instagram ? 'Instagram' : 'Other'),
                    iconWidget: platform == SocialPlatform.facebook
                        ? const FacebookIconWidget(size: 24.0)
                        : (platform == SocialPlatform.instagram ? const InstagramIconWidget(size: 24.0) : null),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16.0),

          // Section 2: Property Details (if available)
          if (propertyTitle.isNotEmpty || property != null) ...[
            _buildSectionHeader(context, context.tr('property_details'), Icons.location_city_rounded),
            const SizedBox(height: 8.0),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14.0),
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(12.0),
                border: Border.all(color: AppColors.border, width: 1.0),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    propertyTitle,
                    style: AppTextStyles.body1.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  if (property != null) ...[
                    const SizedBox(height: 4.0),
                    Text(
                      '${property.propertyType.name.toUpperCase()}${property.price > 0 ? " • ₹${property.price}" : ""}',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (property.address?.fullAddress.isNotEmpty == true) ...[
                      const SizedBox(height: 2.0),
                      Text(
                        property.address!.fullAddress,
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ],

                  // Media preview if available
                  if (mediaUrls != null && mediaUrls.isNotEmpty) ...[
                    const SizedBox(height: 12.0),
                    SizedBox(
                      height: 90.0,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: mediaUrls.length,
                        separatorBuilder: (context, index) => const SizedBox(width: 8.0),
                        itemBuilder: (context, index) {
                          final media = mediaUrls[index];
                          return ClipRRect(
                            borderRadius: BorderRadius.circular(8.0),
                            child: CachedImage(
                              media.url,
                              width: 120.0,
                              height: 90.0,
                              fit: BoxFit.cover,
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16.0),
          ],

          // Section 3: Notes / Inquiry Message (if available)
          if (notesText != null && notesText.trim().isNotEmpty) ...[
            _buildSectionHeader(context, context.tr('inquiry_notes'), Icons.notes_rounded),
            const SizedBox(height: 8.0),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14.0),
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(12.0),
                border: Border.all(color: AppColors.border, width: 1.0),
              ),
              child: Text(
                notesText,
                style: AppTextStyles.body2.copyWith(
                  color: AppColors.textPrimary,
                  height: 1.4,
                ),
              ),
            ),
            const SizedBox(height: 16.0),
          ],

          // Section 4: View Social Post (if permalink available)
          if (hasPermalink) ...[
            AppButton.outline(
              text: context.tr('view_social_post'),
              iconData: Icons.open_in_new_rounded,
              borderColor: AppColors.primary,
              textColor: AppColors.primary,
              width: double.infinity,
              onPressed: () => AppUtils.launchAppUrl(socialPost.permalink!),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20.0, color: AppColors.primary),
        const SizedBox(width: 8.0),
        Text(
          title,
          style: AppTextStyles.caption.copyWith(
            fontWeight: FontWeight.bold,
            fontSize: 13.0,
            color: AppColors.primary,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildDetailRow({
    required String label,
    required String value,
    IconData? icon,
    Widget? iconWidget,
    Widget? trailing,
  }) {
    return Row(
      children: [
        if (iconWidget != null) ...[
          iconWidget,
          const SizedBox(width: 12.0),
        ] else if (icon != null) ...[
          Icon(icon, size: 24.0, color: AppColors.textMuted),
          const SizedBox(width: 12.0),
        ],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.textMuted,
                  fontSize: 11.0,
                ),
              ),
              const SizedBox(height: 2.0),
              Text(
                value,
                style: AppTextStyles.body2.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
        ?trailing,
      ],
    );
  }
}
