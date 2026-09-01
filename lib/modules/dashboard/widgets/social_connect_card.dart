// ignore_for_file: deprecated_member_use

// File: lib/modules/dashboard/widgets/social_connect_card.dart
// Purpose: Modern, colorful social channel connection card widget featuring brand background tints, animated expandable details, live status badges, and gradient action buttons.

import 'package:flutter/material.dart';

import '../../../../app/app_colors.dart';
import '../../../../app/app_text_styles.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../util/common_ext.dart';
import '../../../../widgets/badges/app_status_badge.dart';
import '../../../../widgets/buttons/app_circular_chevron.dart';
import '../../../../widgets/common/user_avatar_widget.dart';

class SocialConnectCard extends StatefulWidget {
  final String platformName;
  final String description;
  final List<String> features;
  final bool isConnected;
  final bool isLoading;
  final VoidCallback onConnectPressed;
  final Widget logo;
  final Color? buttonColor;
  final List<Color>? buttonGradient;

  final String? userName;
  final String? userImageUrl;

  const SocialConnectCard({
    super.key,
    required this.platformName,
    required this.description,
    required this.features,
    required this.isConnected,
    this.isLoading = false,
    required this.onConnectPressed,
    required this.logo,
    this.buttonColor,
    this.buttonGradient,
    this.userName,
    this.userImageUrl,
  });

  @override
  State<SocialConnectCard> createState() => _SocialConnectCardState();
}

class _SocialConnectCardState extends State<SocialConnectCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final isDesktop = context.isDesktop;
    final isInstagram =
        widget.buttonGradient != null || widget.platformName.toLowerCase().contains('instagram');

    // Brand Palette Tokens
    final Color cardBgColor = isInstagram
        ? AppColors
              .instagramLightBg // Soft Instagram Pink Tint
        : AppColors.facebookLightBg; // Soft Facebook Blue Tint

    final Color borderColor = isInstagram ? AppColors.instagramLightBorder : AppColors.facebookLightBorder;

    final Color accentColor = isInstagram ? AppColors.instagram : AppColors.facebook;

    return Container(
      decoration: BoxDecoration(
        color: cardBgColor,
        borderRadius: BorderRadius.circular(18.0),
        border: Border.all(color: borderColor, width: 1.2),
        boxShadow: [
          BoxShadow(color: accentColor.withValues(alpha: 0.06), blurRadius: 12.0, offset: const Offset(0, 4)),
        ],
      ),
      padding: EdgeInsets.all(isDesktop ? 16.0 : 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header Row: Logo, Title, User Profile, Status Badge & Chevron
          InkWell(
            onTap: () {
              setState(() {
                _isExpanded = !_isExpanded;
              });
            },
            borderRadius: BorderRadius.circular(12.0),
            child: Row(
              children: [
                // Platform Logo Badge
                Container(
                  padding: const EdgeInsets.all(2.0),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.06),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: SizedBox(
                    width: isDesktop ? 38.0 : 32.0,
                    height: isDesktop ? 38.0 : 32.0,
                    child: widget.logo,
                  ),
                ),
                const SizedBox(width: 12.0),

                // Platform Title & Connected Username
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        widget.platformName,
                        style: AppTextStyles.heading3.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: isDesktop ? 15.5 : 13.5,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      if (widget.isConnected && widget.userName != null) ...[
                        const SizedBox(height: 3.0),
                        Row(
                          children: [
                            _buildBorderedAvatar(radius: 8.0),
                            const SizedBox(width: 6.0),
                            Expanded(
                              child: Text(
                                widget.userName!,
                                style: AppTextStyles.caption.copyWith(
                                  fontSize: 12.0,
                                  color: accentColor,
                                  fontWeight: FontWeight.w700,
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
                const SizedBox(width: 8.0),

                // Live Status Badge Widget
                AppStatusBadge.socialStatus(
                  text: widget.isConnected ? context.tr('connected') : context.tr('not_connected'),
                  isConnected: widget.isConnected,
                ),
                const SizedBox(width: 6.0),

                // Expand/Collapse Chevron Icon Widget
                AppCircularChevron(isExpanded: _isExpanded),
              ],
            ),
          ),

          // Expandable Body Details
          AnimatedCrossFade(
            firstChild: const SizedBox(width: double.infinity, height: 0),
            secondChild: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: isDesktop ? 12.0 : 8.0),
                Divider(height: 1.0, color: borderColor),
                SizedBox(height: isDesktop ? 12.0 : 8.0),

                // Description
                Text(
                  widget.description,
                  style: AppTextStyles.body2.copyWith(
                    color: AppColors.textSecondary,
                    fontSize: 12.5,
                    height: 1.4,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: isDesktop ? 12.0 : 8.0),

                // Bullet Features
                ...widget.features.map((feature) => _buildFeatureRow(feature, accentColor)),
                SizedBox(height: isDesktop ? 16.0 : 10.0),

                // Action Button
                _buildActionButton(context, accentColor),
              ],
            ),
            crossFadeState: _isExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 250),
          ),
        ],
      ),
    );
  }

  Widget _buildBorderedAvatar({required double radius}) {
    return UserAvatarWidget(
      name: widget.userName ?? widget.platformName,
      imageUrl: widget.userImageUrl,
      radius: radius,
      borderColor: Colors.white,
      borderWidth: 1.5,
    );
  }

  Widget _buildFeatureRow(String feature, Color accentColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(3.0),
            decoration: BoxDecoration(color: accentColor.withValues(alpha: 0.12), shape: BoxShape.circle),
            child: Icon(Icons.bolt_rounded, color: accentColor, size: 13.0),
          ),
          const SizedBox(width: 8.0),
          Expanded(
            child: Text(
              feature,
              style: AppTextStyles.caption.copyWith(
                fontSize: 12.5,
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(BuildContext context, Color accentColor) {
    if (widget.isLoading) {
      return Container(
        width: double.infinity,
        height: 40.0,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: widget.isConnected
              ? AppColors.error.withValues(alpha: 0.08)
              : accentColor.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(20.0),
          border: Border.all(
            color: widget.isConnected
                ? AppColors.error.withValues(alpha: 0.3)
                : accentColor.withValues(alpha: 0.3),
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 16.0,
              height: 16.0,
              child: CircularProgressIndicator(
                strokeWidth: 2.0,
                valueColor: AlwaysStoppedAnimation<Color>(widget.isConnected ? AppColors.error : accentColor),
              ),
            ),
            const SizedBox(width: 8.0),
            Text(
              widget.isConnected ? 'Disconnecting...' : 'Connecting...',
              style: AppTextStyles.button.copyWith(
                color: widget.isConnected ? AppColors.error : accentColor,
                fontSize: 13.0,
              ),
            ),
          ],
        ),
      );
    }

    final String buttonText = widget.isConnected
        ? '${context.tr('disconnect')} ${widget.platformName}'
        : '${context.tr('connect')} ${widget.platformName}';

    // Disconnect button styling (clean red outline style)
    if (widget.isConnected) {
      return InkWell(
        onTap: widget.onConnectPressed,
        borderRadius: BorderRadius.circular(20.0),
        child: Container(
          width: double.infinity,
          height: 40.0,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20.0),
            border: Border.all(color: AppColors.error, width: 1.5),
            boxShadow: [
              BoxShadow(
                color: AppColors.error.withValues(alpha: 0.08),
                blurRadius: 6.0,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Text(
            buttonText,
            style: AppTextStyles.button.copyWith(
              color: AppColors.error,
              fontSize: 13.5,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      );
    }

    // Connect button styling (vibrant brand gradient or solid color)
    return InkWell(
      onTap: widget.onConnectPressed,
      borderRadius: BorderRadius.circular(20.0),
      child: Container(
        width: double.infinity,
        height: 40.0,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: widget.buttonGradient == null ? (widget.buttonColor ?? accentColor) : null,
          gradient: widget.buttonGradient != null
              ? LinearGradient(
                  colors: widget.buttonGradient!,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          borderRadius: BorderRadius.circular(20.0),
          boxShadow: [
            BoxShadow(
              color: accentColor.withValues(alpha: 0.3),
              blurRadius: 10.0,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Text(
          buttonText,
          style: AppTextStyles.button.copyWith(
            fontSize: 13.5,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
