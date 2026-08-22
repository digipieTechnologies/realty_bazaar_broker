// File: lib/modules/leads/screens/view_lead_screen.dart
// Purpose: Premium Lead Details screen with standard AppSectionHeader components, hero cover banner, callout action buttons, interactive property card, and responsive desktop/mobile layouts.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../app/app_colors.dart';
import '../../../app/app_text_styles.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/localization/property_localizer.dart';
import '../../../models/models.dart';
import '../../../models/social_enums.dart';
import '../../../util/app_date_utils.dart';
import '../../../util/app_utils.dart';
import '../../../widgets/badges/app_platform_badge.dart';
import '../../../widgets/buttons/app_button.dart';
import '../../../widgets/common/app_section_header.dart';
import '../../../widgets/common/common_app_bar.dart';
import '../../../widgets/common/user_avatar_widget.dart';
import '../../../widgets/icons/app_icons.dart';
import '../../../widgets/images/cached_image.dart';
import '../../../widgets/toast/app_toast.dart';

class ViewLeadScreen extends StatelessWidget {
  final SocialLeadModel lead;

  const ViewLeadScreen({
    super.key,
    required this.lead,
  });

  @override
  Widget build(BuildContext context) {
    final socialPost = lead.socialPost;
    final platform = socialPost?.platform;
    final hasPermalink =
        socialPost?.permalink != null &&
        socialPost!.permalink!.trim().isNotEmpty;
    final PropertyModel? property = socialPost?.propertyId;
    final propertyTitle = property?.propertyTitle.isNotEmpty == true
        ? property!.propertyTitle
        : (lead.propertyDetails ?? socialPost?.caption ?? '');
    final notesText = lead.notes;
    final mediaUrls = socialPost?.mediaUrls ?? property?.medias;

    final isInstagram = platform == SocialPlatform.instagram;
    final isFacebook = platform == SocialPlatform.facebook;

    // Platform cover gradient
    final Gradient coverGradient = isInstagram
        ? const LinearGradient(
            colors: [Color(0xFF833AB4), Color(0xFFFD1D1D), Color(0xFFFCB045)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          )
        : (isFacebook
            ? const LinearGradient(
                colors: [Color(0xFF1877F2), Color(0xFF0056C6)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : LinearGradient(
                colors: [AppColors.primary, AppColors.primary700],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: CommonAppBar(
        title: context.tr('lead_details'),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isDesktop = constraints.maxWidth > 900;

            final profileHeroCard = _buildHeroProfileCard(context, coverGradient, platform);
            final contactInfoCard = _buildContactInfoCard(context, platform);
            final propertyCard = (propertyTitle.isNotEmpty || property != null)
                ? _buildPropertyCard(context, propertyTitle, property, mediaUrls)
                : null;
            final notesCard = (notesText != null && notesText.trim().isNotEmpty)
                ? _buildInquiryNotesCard(context, notesText.trim())
                : null;
            final permalinkButton = hasPermalink
                ? _buildSocialPostButton(context, socialPost.permalink!)
                : null;

            final hasRightContent = propertyCard != null || notesCard != null;

            if (isDesktop) {
              if (!hasRightContent) {
                // Centered single column for leads without property details or notes
                return Center(
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 720.0),
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        profileHeroCard,
                        const SizedBox(height: 14.0),
                        contactInfoCard,
                        if (permalinkButton != null) ...[
                          const SizedBox(height: 14.0),
                          permalinkButton,
                        ],
                      ],
                    ),
                  ),
                );
              }

              // Two-column layout for leads with property details or notes
              return Center(
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 1200.0),
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Left Column: Profile Hero, Actions & Contact (Flex 3)
                      Expanded(
                        flex: 3,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            profileHeroCard,
                            const SizedBox(height: 14.0),
                            contactInfoCard,
                            if (permalinkButton != null) ...[
                              const SizedBox(height: 14.0),
                              permalinkButton,
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(width: 16.0),

                      // Right Column: Property & Inquiry Notes (Flex 2)
                      Expanded(
                        flex: 2,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (propertyCard != null) ...[
                              propertyCard,
                              const SizedBox(height: 14.0),
                            ],
                            if (notesCard != null) ...[
                              notesCard,
                              const SizedBox(height: 14.0),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            // Mobile Layout
            return Padding(
              padding: const EdgeInsets.all(14.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  profileHeroCard,
                  const SizedBox(height: 14.0),
                  contactInfoCard,
                  if (propertyCard != null) ...[
                    const SizedBox(height: 14.0),
                    propertyCard,
                  ],
                  if (notesCard != null) ...[
                    const SizedBox(height: 14.0),
                    notesCard,
                  ],
                  if (permalinkButton != null) ...[
                    const SizedBox(height: 14.0),
                    permalinkButton,
                  ],
                  const SizedBox(height: 16.0),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  // --- 1. HERO PROFILE CARD WITH COVER & ACTION BUTTONS ---
  Widget _buildHeroProfileCard(
    BuildContext context,
    Gradient coverGradient,
    SocialPlatform? platform,
  ) {
    final dateStr = AppDateUtils.formatDate(lead.createdAt);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20.0),
        border: Border.all(color: AppColors.border, width: 1.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Cover Header Banner
          Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.bottomCenter,
            children: [
              Container(
                height: 100.0,
                decoration: BoxDecoration(
                  gradient: coverGradient,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(19.0),
                    topRight: Radius.circular(19.0),
                  ),
                ),
                child: Stack(
                  children: [
                    // Decorative background circles
                    Positioned(
                      right: -20,
                      top: -20,
                      child: Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.12),
                        ),
                      ),
                    ),
                    Positioned(
                      left: -30,
                      bottom: -30,
                      child: Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.08),
                        ),
                      ),
                    ),
                    // Platform Badge in Header
                    if (platform != null)
                      Positioned(
                        top: 14,
                        right: 14,
                        child: AppPlatformBadge(
                          platform: platform,
                          isHeaderStyle: true,
                          iconSize: 16.0,
                        ),
                      ),
                  ],
                ),
              ),

              // Overlapping Avatar with White Border & Active Status Dot
              Positioned(
                bottom: -36.0,
                child: Stack(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(4.0),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Color(0x1F000000),
                            blurRadius: 12,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: UserAvatarWidget(
                        name: lead.userName,
                        radius: 36.0,
                      ),
                    ),
                    // Active Status Dot
                    Positioned(
                      right: 4,
                      bottom: 4,
                      child: Container(
                        width: 16.0,
                        height: 16.0,
                        decoration: BoxDecoration(
                          color: const Color(0xFF22C55E),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2.5),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 44.0),

          // User Name & Meta Info
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              children: [
                Text(
                  lead.userName.isNotEmpty ? lead.userName : 'Lead Prospect',
                  style: AppTextStyles.heading1.copyWith(
                    fontSize: 20.0,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4.0),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.access_time_rounded,
                      size: 14.0,
                      color: AppColors.textMuted,
                    ),
                    const SizedBox(width: 4.0),
                    Text(
                      'Received $dateStr',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textMuted,
                        fontSize: 13.0,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 24.0),
          const Divider(height: 1.0, color: AppColors.border),
          const SizedBox(height: 20.0),

          // 3 Large Action Option Callout Buttons (Call, Message, WhatsApp)
          Padding(
            padding: const EdgeInsets.only(left: 16.0, right: 16.0, bottom: 20.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildActionCalloutButton(
                  context,
                  label: 'Call',
                  icon: const CallIconWidget(size: 24.0, color: Colors.white),
                  gradient: const LinearGradient(
                    colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
                  ),
                  shadowColor: const Color(0xFF2563EB),
                  onTap: () => AppUtils.launchAppUrl('tel:${lead.contactNumber}'),
                ),
                _buildActionCalloutButton(
                  context,
                  label: 'Message',
                  icon: const MessageIconWidget(size: 24.0, color: Colors.white),
                  gradient: const LinearGradient(
                    colors: [Color(0xFF0EA5E9), Color(0xFF0284C7)],
                  ),
                  shadowColor: const Color(0xFF0EA5E9),
                  onTap: () => AppUtils.launchAppUrl('sms:${lead.contactNumber}'),
                ),
                _buildActionCalloutButton(
                  context,
                  label: 'WhatsApp',
                  icon: const WhatsappIconWidget(size: 24.0, color: Colors.white),
                  gradient: const LinearGradient(
                    colors: [Color(0xFF25D366), Color(0xFF128C7E)],
                  ),
                  shadowColor: const Color(0xFF25D366),
                  onTap: () => AppUtils.launchAppUrl(lead.buildWhatsappUrl()),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionCalloutButton(
    BuildContext context, {
    required String label,
    required Widget icon,
    required Gradient gradient,
    required Color shadowColor,
    required VoidCallback onTap,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 56.0,
          height: 56.0,
          decoration: BoxDecoration(
            gradient: gradient,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: shadowColor.withValues(alpha: 0.35),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              customBorder: const CircleBorder(),
              child: Center(child: icon),
            ),
          ),
        ),
        const SizedBox(height: 8.0),
        Text(
          label,
          style: AppTextStyles.caption.copyWith(
            fontSize: 12.0,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  // --- 2. CONTACT INFORMATION CARD ---
  Widget _buildContactInfoCard(BuildContext context, SocialPlatform? platform) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: AppColors.border, width: 1.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Common Standard AppSectionHeader
          AppSectionHeader(
            title: context.tr('contact_info'),
            icon: Icons.person_pin_rounded,
            iconColor: AppColors.primary,
            iconBgColor: AppColors.primary.withValues(alpha: 0.1),
            padding: const EdgeInsets.only(bottom: 16.0),
          ),

          // Phone Row
          _buildInfoRowTile(
            icon: Icons.phone_in_talk_rounded,
            iconColor: AppColors.primary,
            label: context.tr('phone_number'),
            value: lead.contactNumber,
            trailing: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  Clipboard.setData(ClipboardData(text: lead.contactNumber));
                  AppToast.showSuccess(
                    context.tr('copied_title'),
                    context.tr('contact_number_copied'),
                  );
                },
                borderRadius: BorderRadius.circular(8.0),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 6.0),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.copy_rounded,
                        size: 14.0,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 4.0),
                      Text(
                        'Copy',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 11.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          if (platform != null) ...[
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12.0),
              child: Divider(height: 1.0, color: AppColors.border),
            ),

            // Platform Row
            _buildInfoRowTile(
              customIcon: platform == SocialPlatform.facebook
                  ? const FacebookIconWidget(size: 24.0)
                  : const InstagramIconWidget(size: 24.0),
              label: context.tr('platform_source'),
              value: platform == SocialPlatform.facebook
                  ? 'Facebook Lead Ads'
                  : 'Instagram Lead Form',
            ),
          ],
        ],
      ),
    );
  }

  // --- 3. INQUIRED PROPERTY CARD ---
  Widget _buildPropertyCard(
    BuildContext context,
    String propertyTitle,
    PropertyModel? property,
    List<dynamic>? mediaUrls,
  ) {
    final typeText = property != null
        ? PropertyLocalizer.getLocalizedPropertyType(context, property.propertyType).toUpperCase()
        : '';
    final priceStr = property != null && property.price > 0
        ? _formatPrice(property.price)
        : '';
    final addressStr = property?.address?.fullAddress.isNotEmpty == true
        ? property!.address!.fullAddress
        : '';

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: AppColors.border, width: 1.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Common Standard AppSectionHeader
                AppSectionHeader(
                  title: context.tr('property_details'),
                  icon: Icons.real_estate_agent_rounded,
                  iconColor: AppColors.success,
                  iconBgColor: AppColors.success.withValues(alpha: 0.1),
                  padding: const EdgeInsets.only(bottom: 16.0),
                ),

                // Property Title
                Text(
                  propertyTitle,
                  style: AppTextStyles.heading2.copyWith(
                    fontSize: 16.0,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8.0),

                // Badges Row (Type & Price)
                Wrap(
                  spacing: 8.0,
                  runSpacing: 6.0,
                  children: [
                    if (typeText.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 4.0),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        child: Text(
                          typeText,
                          style: AppTextStyles.caption.copyWith(
                            fontSize: 11.5,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    if (priceStr.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 4.0),
                        decoration: BoxDecoration(
                          color: AppColors.success.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        child: Text(
                          priceStr,
                          style: AppTextStyles.caption.copyWith(
                            fontSize: 11.5,
                            fontWeight: FontWeight.bold,
                            color: AppColors.success,
                          ),
                        ),
                      ),
                  ],
                ),

                if (addressStr.isNotEmpty) ...[
                  const SizedBox(height: 10.0),
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on_outlined,
                        size: 15.0,
                        color: AppColors.textMuted,
                      ),
                      const SizedBox(width: 4.0),
                      Expanded(
                        child: Text(
                          addressStr,
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.textMuted,
                            fontSize: 12.5,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),

          // Media Thumbnails Carousel
          if (mediaUrls != null && mediaUrls.isNotEmpty) ...[
            const Divider(height: 1.0, color: AppColors.border),
            Container(
              padding: const EdgeInsets.all(16.0),
              height: 120.0,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                itemCount: mediaUrls.length,
                separatorBuilder: (context, index) => const SizedBox(width: 10.0),
                itemBuilder: (context, index) {
                  final media = mediaUrls[index];
                  final url = media is MediaModel ? media.url : media.toString();
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(12.0),
                    child: CachedImage(
                      url,
                      width: 130.0,
                      height: 88.0,
                      fit: BoxFit.cover,
                    ),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }

  // --- 4. INQUIRY NOTES CARD ---
  Widget _buildInquiryNotesCard(BuildContext context, String notesText) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: AppColors.border, width: 1.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Common Standard AppSectionHeader
          AppSectionHeader(
            title: context.tr('inquiry_notes'),
            icon: Icons.chat_bubble_outline_rounded,
            iconColor: AppColors.warning,
            iconBgColor: AppColors.warning.withValues(alpha: 0.1),
            padding: const EdgeInsets.only(bottom: 14.0),
          ),

          // Styled Quote Box Container
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14.0),
            decoration: BoxDecoration(
              color: AppColors.warning.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(14.0),
              border: Border.all(color: AppColors.warning.withValues(alpha: 0.3), width: 1.0),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.format_quote_rounded,
                  size: 22.0,
                  color: AppColors.warning,
                ),
                const SizedBox(width: 10.0),
                Expanded(
                  child: Text(
                    notesText,
                    style: AppTextStyles.body2.copyWith(
                      color: AppColors.textPrimary,
                      fontSize: 13.5,
                      height: 1.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- 5. SOCIAL POST ACTION BUTTON ---
  Widget _buildSocialPostButton(BuildContext context, String permalink) {
    return AppButton.solid(
      text: context.tr('view_social_post'),
      iconData: Icons.open_in_new_rounded,
      color: AppColors.primary,
      width: double.infinity,
      height: 48.0,
      borderRadius: 14.0,
      onPressed: () => AppUtils.launchAppUrl(permalink),
    );
  }

  // Helper Info Row Tile with Muted Grey Field Label and Bold Dark Field Content
  Widget _buildInfoRowTile({
    IconData? icon,
    Widget? customIcon,
    Color? iconColor,
    required String label,
    required String value,
    Widget? trailing,
  }) {
    return Row(
      children: [
        if (customIcon != null)
          customIcon
        else if (icon != null)
          Container(
            padding: const EdgeInsets.all(8.0),
            decoration: BoxDecoration(
              color: (iconColor ?? AppColors.primary).withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10.0),
            ),
            child: Icon(icon, size: 18.0, color: iconColor ?? AppColors.primary),
          ),
        const SizedBox(width: 12.0),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Muted grey field label
              Text(
                label,
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.textMuted,
                  fontSize: 12.0,
                  letterSpacing: 0.2,
                ),
              ),
              const SizedBox(height: 3.0),
              // Dark bold field content
              Text(
                value,
                style: AppTextStyles.body2.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                  fontSize: 14.0,
                ),
              ),
            ],
          ),
        ),
        ?trailing,
      ],
    );
  }

  String _formatPrice(double amount) {
    if (amount >= 10000000) {
      return '₹${(amount / 10000000).toStringAsFixed(2)} Cr';
    } else if (amount >= 100000) {
      return '₹${(amount / 100000).toStringAsFixed(2)} Lakh';
    } else if (amount > 0) {
      return '₹${amount.toStringAsFixed(0)}';
    }
    return '';
  }
}
