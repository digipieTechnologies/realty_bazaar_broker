// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import '../../../../app/app_colors.dart';
import '../../../../app/app_text_styles.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../util/common_ext.dart';
import '../../../../widgets/common/app_card_container.dart';
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
    final isDesktop = context.isDesktopUI;
    final bool effectiveExpanded = _isExpanded;

    return AppCardContainer(
      padding: const EdgeInsets.all(14.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header Row: Toggle view on all platforms & screen sizes
          InkWell(
            onTap: () {
              setState(() {
                _isExpanded = !_isExpanded;
              });
            },
            borderRadius: BorderRadius.circular(10.0),
            child: Row(
              children: [
                widget.logo,
                const SizedBox(width: 10.0),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        widget.platformName,
                        style: AppTextStyles.heading3.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: isDesktop ? 15.0 : 13.5,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      // Subtitle with profile avatar when connected (all viewports)
                      if (widget.isConnected && widget.userName != null) ...[
                        const SizedBox(height: 2.0),
                        Row(
                          children: [
                            _buildBorderedAvatar(radius: 7.5, iconSize: 9.0),
                            const SizedBox(width: 5.0),
                            Expanded(
                              child: Text(
                                widget.userName!,
                                style: AppTextStyles.caption.copyWith(
                                  fontSize: 11.5,
                                  color: AppColors.secondary,
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
                const SizedBox(width: 6.0),
                _buildStatusBadge(context),
                const SizedBox(width: 4.0),
                Icon(
                  _isExpanded
                      ? Icons.keyboard_arrow_up_rounded
                      : Icons.keyboard_arrow_down_rounded,
                  color: AppColors.textSecondary,
                  size: 22.0,
                ),
              ],
            ),
          ),

          // Expandable Body Details
          AnimatedCrossFade(
            firstChild: const SizedBox(width: double.infinity, height: 0),
            secondChild: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 10.0),
                const Divider(height: 1.0, color: AppColors.border),
                const SizedBox(height: 10.0),

                // Description
                Text(
                  widget.description,
                  style: AppTextStyles.body2.copyWith(
                    color: AppColors.textSecondary,
                    fontSize: 12.0,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 10.0),

                // Bullet features
                ...widget.features.map((feature) => _buildFeatureRow(feature)),
                const SizedBox(height: 14.0),

                // Action Button
                _buildActionButton(context),
              ],
            ),
            crossFadeState: effectiveExpanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 250),
          ),
        ],
      ),
    );
  }

  Widget _buildBorderedAvatar({required double radius, required double iconSize}) {
    return UserAvatarWidget(
      name: widget.userName ?? widget.platformName,
      imageUrl: widget.userImageUrl,
      radius: radius,
      borderColor: AppColors.border,
      borderWidth: 1.0,
    );
  }

  Widget _buildStatusBadge(BuildContext context) {
    final bgColor = widget.isConnected
        ? AppColors.success.withValues(alpha: 0.1)
        : AppColors.border.withValues(alpha: 0.5);
    final textColor = widget.isConnected
        ? AppColors.success
        : AppColors.textSecondary;
    final text = widget.isConnected
        ? context.tr('connected').toUpperCase()
        : context.tr('not_connected').toUpperCase();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6.0),
        border: Border.all(
          color: widget.isConnected ? AppColors.success.withValues(alpha: 0.2) : AppColors.border,
          width: 1.0,
        ),
      ),
      child: Text(
        text,
        style: AppTextStyles.caption.copyWith(
          fontSize: 9.0,
          fontWeight: FontWeight.w700,
          color: textColor,
          letterSpacing: 0.3,
        ),
      ),
    );
  }

  Widget _buildFeatureRow(String feature) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0),
      child: Row(
        children: [
          const Icon(
            Icons.bolt_rounded,
            color: Color(0xFF6366F1),
            size: 15.0,
          ),
          const SizedBox(width: 6.0),
          Expanded(
            child: Text(
              feature,
              style: AppTextStyles.caption.copyWith(
                fontSize: 12.0,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(BuildContext context) {
    if (widget.isLoading) {
      return Container(
        width: double.infinity,
        height: 36.0,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: widget.isConnected
              ? AppColors.error.withValues(alpha: 0.08)
              : AppColors.primary.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(18.0),
          border: Border.all(
            color: widget.isConnected ? AppColors.error.withValues(alpha: 0.3) : AppColors.primary.withValues(alpha: 0.3),
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 14.0,
              height: 14.0,
              child: CircularProgressIndicator(
                strokeWidth: 2.0,
                valueColor: AlwaysStoppedAnimation<Color>(
                  widget.isConnected ? AppColors.error : AppColors.primary,
                ),
              ),
            ),
            const SizedBox(width: 8.0),
            Text(
              widget.isConnected ? 'Disconnecting...' : 'Connecting...',
              style: AppTextStyles.button.copyWith(
                color: widget.isConnected ? AppColors.error : AppColors.primary,
                fontSize: 12.0,
              ),
            ),
          ],
        ),
      );
    }

    final String buttonText = widget.isConnected
        ? '${context.tr('disconnect')} ${widget.platformName}'
        : '${context.tr('connect')} ${widget.platformName}';

    // Disconnect button styling (outline style)
    if (widget.isConnected) {
      return InkWell(
        onTap: widget.onConnectPressed,
        borderRadius: BorderRadius.circular(18.0),
        child: Container(
          width: double.infinity,
          height: 36.0,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(18.0),
            border: Border.all(color: AppColors.error, width: 1.5),
          ),
          child: Text(
            buttonText,
            style: AppTextStyles.button.copyWith(
              color: AppColors.error,
              fontSize: 13.0,
            ),
          ),
        ),
      );
    }

    // Connect button styling (gradient or solid)
    return InkWell(
      onTap: widget.onConnectPressed,
      borderRadius: BorderRadius.circular(18.0),
      child: Container(
        width: double.infinity,
        height: 36.0,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: widget.buttonGradient == null ? (widget.buttonColor ?? AppColors.primary) : null,
          gradient: widget.buttonGradient != null
              ? LinearGradient(
                  colors: widget.buttonGradient!,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          borderRadius: BorderRadius.circular(18.0),
          boxShadow: [
            BoxShadow(
              color: (widget.buttonColor ?? AppColors.primary).withValues(alpha: 0.2),
              blurRadius: 6.0,
              offset: const Offset(0, 3),
            )
          ],
        ),
        child: Text(
          buttonText,
          style: AppTextStyles.button.copyWith(
            fontSize: 13.0,
          ),
        ),
      ),
    );
  }
}
