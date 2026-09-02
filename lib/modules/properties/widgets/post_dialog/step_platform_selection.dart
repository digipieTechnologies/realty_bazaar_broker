// File: lib/modules/properties/widgets/post_dialog/step_platform_selection.dart
// Purpose: Step 0 UI for platform selection (Instagram & Facebook) with responsive layout, property preview banner, and social publishing tips.

import 'package:flutter/material.dart';
import 'package:the_realty_bazaar/models/property_enums.dart';

import '../../../../app/app_colors.dart';
import '../../../../app/app_text_styles.dart';
import '../../../../core/extensions/currency_extensions.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../models/property_model.dart';
import '../../../../providers/social/social_provider.dart';
import '../../../../widgets/buttons/app_button.dart';
import '../../../../widgets/images/cached_image.dart';

class StepPlatformSelection extends StatelessWidget {
  final bool selectInstagram;
  final bool selectFacebook;
  final ValueChanged<bool> onSelectInstagramChanged;
  final ValueChanged<bool> onSelectFacebookChanged;
  final String? connectionErrorMessage;
  final String brokerId;
  final SocialProvider socialProvider;
  final PropertyModel? property;

  const StepPlatformSelection({
    super.key,
    required this.selectInstagram,
    required this.selectFacebook,
    required this.onSelectInstagramChanged,
    required this.onSelectFacebookChanged,
    this.connectionErrorMessage,
    required this.brokerId,
    required this.socialProvider,
    this.property,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 540;

    return SingleChildScrollView(
      padding: EdgeInsets.all(isMobile ? 12.0 : 18.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.tr('select_social_channels'),
            style: AppTextStyles.heading3.copyWith(fontWeight: FontWeight.bold, fontSize: 16.0),
          ),
          const SizedBox(height: 4.0),
          Text(
            context.tr('select_social_channels_desc'),
            style: AppTextStyles.body2.copyWith(color: AppColors.textSecondary, fontSize: 12.0),
          ),
          const SizedBox(height: 16.0),

          // Responsive Platform Cards (Vertical on Mobile < 540px, Horizontal Row on Desktop/Web)
          if (isMobile)
            Column(
              children: [
                _buildInstagramCard(context),
                const SizedBox(height: 12.0),
                _buildFacebookCard(context),
              ],
            )
          else
            Row(
              children: [
                Expanded(child: _buildInstagramCard(context)),
                const SizedBox(width: 14.0),
                Expanded(child: _buildFacebookCard(context)),
              ],
            ),

          // Connection Error / Warning Banner
          if (connectionErrorMessage != null) ...[
            const SizedBox(height: 16.0),
            _buildConnectionErrorBanner(context),
          ],

          const SizedBox(height: 18.0),

          // Property Details Preview Card
          if (property != null) ...[_buildPropertyPreviewCard(context), const SizedBox(height: 14.0)],

          // Automated Features & Guidelines Card
          _buildPublishingTipsCard(context),
        ],
      ),
    );
  }

  Widget _buildPropertyPreviewCard(BuildContext context) {
    if (property == null) return const SizedBox.shrink();

    final firstMediaUrl = property!.medias.isNotEmpty ? property!.medias.first.url : null;
    final priceStr = property!.price.toCompactCurrency();
    final locationStr = property!.address?.city ?? property!.address?.fullAddress ?? '';

    return Container(
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          // Property Cover Thumbnail
          ClipRRect(
            borderRadius: BorderRadius.circular(8.0),
            child: SizedBox(
              width: 52.0,
              height: 52.0,
              child: firstMediaUrl != null && firstMediaUrl.startsWith('http')
                  ? CachedImage(firstMediaUrl, fit: BoxFit.cover)
                  : Container(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      child: const Icon(Icons.home_rounded, color: AppColors.primary, size: 26.0),
                    ),
            ),
          ),
          const SizedBox(width: 12.0),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        property!.propertyTitle,
                        style: AppTextStyles.body1.copyWith(fontWeight: FontWeight.bold, fontSize: 13.5),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 6.0),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 2.0),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4.0),
                      ),
                      child: Text(
                        property!.listingType.displayName.toUpperCase(),
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 9.0,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2.0),
                Tooltip(
                  message: property!.price.toFullIndianCurrency(),
                  preferBelow: false,
                  child: Text(
                    '$priceStr • $locationStr',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 11.5,
                    ),
                  ),
                ),
                const SizedBox(height: 4.0),
                Row(
                  children: [
                    if (property!.bedrooms > 0) ...[
                      _buildChip('${property!.bedrooms} BHK'),
                      const SizedBox(width: 6.0),
                    ],
                    if (property!.area > 0) ...[
                      _buildChip(
                        '${property!.area.toStringAsFixed(0)} ${property!.areaUnit.displayName.toUpperCase()}',
                      ),
                      const SizedBox(width: 6.0),
                    ],
                    _buildChip(property!.propertyType.displayName.toUpperCase()),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 2.0),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(4.0),
        border: Border.all(color: AppColors.border, width: 0.8),
      ),
      child: Text(
        label,
        style: AppTextStyles.caption.copyWith(
          color: AppColors.textSecondary,
          fontSize: 9.5,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildPublishingTipsCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14.0),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome_rounded, color: AppColors.primary, size: 16.0),
              const SizedBox(width: 6.0),
              Text(
                context.tr('automated_social_features'),
                style: AppTextStyles.body2.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                  fontSize: 12.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10.0),
          _buildTipRow(
            Icons.psychology_rounded,
            context.tr('ai_captions_title'),
            context.tr('ai_captions_desc'),
          ),
          const SizedBox(height: 8.0),
          _buildTipRow(
            Icons.photo_library_rounded,
            context.tr('multimedia_grid_title'),
            context.tr('multimedia_grid_desc'),
          ),
          const SizedBox(height: 8.0),
          _buildTipRow(
            Icons.contact_phone_rounded,
            context.tr('direct_reach_title'),
            context.tr('direct_reach_desc'),
          ),
        ],
      ),
    );
  }

  Widget _buildTipRow(IconData icon, String title, String desc) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 14.0, color: AppColors.primary),
        const SizedBox(width: 8.0),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary, fontSize: 11.0),
              children: [
                TextSpan(
                  text: '$title: ',
                  style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                ),
                TextSpan(text: desc),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInstagramCard(BuildContext context) {
    final isConnected = socialProvider.isInstagramConnected;
    final accountName = socialProvider.instagramAccount?.instagramUsername;

    return _buildPlatformCard(
      context: context,
      title: 'Instagram',
      subtitle: context.tr('ig_feed_desc'),
      logoPath: 'assets/icons/instagram.png',
      fallbackIcon: Icons.camera_alt_rounded,
      brandColor: AppColors.instagram,
      isSelected: selectInstagram,
      isConnected: isConnected,
      accountName: accountName,
      onTap: () {
        onSelectInstagramChanged(!selectInstagram);
      },
    );
  }

  Widget _buildFacebookCard(BuildContext context) {
    final isConnected = socialProvider.isFacebookConnected;
    final accountName = socialProvider.facebookAccount?.pageName;

    return _buildPlatformCard(
      context: context,
      title: 'Facebook Page',
      subtitle: context.tr('fb_page_desc'),
      logoPath: 'assets/icons/facebook.png',
      fallbackIcon: Icons.facebook_rounded,
      brandColor: AppColors.facebook,
      isSelected: selectFacebook,
      isConnected: isConnected,
      accountName: accountName,
      onTap: () {
        onSelectFacebookChanged(!selectFacebook);
      },
    );
  }

  Widget _buildPlatformCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required String logoPath,
    required IconData fallbackIcon,
    required Color brandColor,
    required bool isSelected,
    required bool isConnected,
    String? accountName,
    required VoidCallback onTap,
  }) {
    final badgeBgColor = isConnected ? AppColors.successLight : AppColors.warningLight;
    final badgeBorderColor = isConnected ? AppColors.successBorder : AppColors.warningBorder;
    final badgeTextColor = isConnected ? AppColors.statusSuccessDarkText : AppColors.warningDark;
    final badgeDotColor = isConnected ? AppColors.statusSuccessText : AppColors.warning;
    final statusText = isConnected
        ? (accountName != null ? '@$accountName' : context.tr('connected'))
        : context.tr('not_connected');

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14.0),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(14.0),
        decoration: BoxDecoration(
          color: isSelected ? brandColor.withValues(alpha: 0.05) : AppColors.surface,
          borderRadius: BorderRadius.circular(14.0),
          border: Border.all(
            color: isSelected ? brandColor : AppColors.border,
            width: isSelected ? 2.0 : 1.0,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: brandColor.withValues(alpha: 0.12),
                    blurRadius: 10.0,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                // Brand Logo Asset
                Image.asset(
                  logoPath,
                  width: 32.0,
                  height: 32.0,
                  errorBuilder: (context, error, stackTrace) =>
                      Icon(fallbackIcon, size: 30.0, color: brandColor),
                ),
                const SizedBox(width: 10.0),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: AppTextStyles.body1.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: 14.0,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        subtitle,
                        style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary, fontSize: 10.0),
                      ),
                    ],
                  ),
                ),
                // Checkbox Pill
                Container(
                  width: 22.0,
                  height: 22.0,
                  decoration: BoxDecoration(
                    color: isSelected ? brandColor : Colors.transparent,
                    shape: BoxShape.circle,
                    border: Border.all(color: isSelected ? brandColor : AppColors.textMuted, width: 1.5),
                  ),
                  child: isSelected ? const Icon(Icons.check_rounded, size: 14.0, color: Colors.white) : null,
                ),
              ],
            ),
            const SizedBox(height: 12.0),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 5.0),
              decoration: BoxDecoration(
                color: badgeBgColor,
                borderRadius: BorderRadius.circular(6.0),
                border: Border.all(color: badgeBorderColor, width: 1.0),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 6.0,
                    height: 6.0,
                    decoration: BoxDecoration(color: badgeDotColor, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 6.0),
                  Flexible(
                    child: Text(
                      statusText,
                      style: AppTextStyles.caption.copyWith(
                        color: badgeTextColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 11.0,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConnectionErrorBanner(BuildContext context) {
    final showIgConnect = selectInstagram && !socialProvider.isInstagramConnected;
    final showFbConnect = selectFacebook && !socialProvider.isFacebookConnected;

    if (!showIgConnect && !showFbConnect) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: AppColors.errorLight,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: AppColors.errorBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.warning_amber_rounded, color: AppColors.error, size: 18.0),
              const SizedBox(width: 8.0),
              Expanded(
                child: Text(
                  context.tr('account_conn_required'),
                  style: AppTextStyles.body2.copyWith(
                    color: AppColors.posterBurgundy,
                    fontWeight: FontWeight.bold,
                    fontSize: 12.0,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6.0),
          Text(
            connectionErrorMessage ?? '',
            style: AppTextStyles.caption.copyWith(color: AppColors.error, fontSize: 11.0),
          ),
          const SizedBox(height: 10.0),
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (showIgConnect)
                AppButton.solid(
                  text: context.tr('connect_instagram_business'),
                  iconData: Icons.link_rounded,
                  color: AppColors.instagram,
                  height: 42.0,
                  borderRadius: 10.0,
                  width: double.infinity,
                  onPressed: () {
                    if (brokerId.isNotEmpty) {
                      socialProvider.connectInstagramDirectly(brokerId);
                    }
                  },
                ),
              if (showIgConnect && showFbConnect) const SizedBox(height: 8.0),
              if (showFbConnect)
                AppButton.solid(
                  text: context.tr('connect_facebook_page'),
                  iconData: Icons.link_rounded,
                  color: AppColors.facebook,
                  height: 42.0,
                  borderRadius: 10.0,
                  width: double.infinity,
                  onPressed: () {
                    if (brokerId.isNotEmpty) {
                      socialProvider.connectFacebook(brokerId);
                    }
                  },
                ),
            ],
          ),
        ],
      ),
    );
  }
}
