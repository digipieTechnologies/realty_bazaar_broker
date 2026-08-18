import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../models/property_enums.dart';

import '../../../app/app_colors.dart';
import '../../../app/app_routes.dart';
import '../../../app/app_text_styles.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/localization/property_localizer.dart';
import '../../../models/property_model.dart';
import '../../../providers/auth/auth_provider.dart';
import '../../../providers/property/property_provider.dart';
import '../../../widgets/buttons/app_button.dart';
import '../../../widgets/buttons/app_popup_menu_button.dart';
import '../../../widgets/common/app_card_container.dart';
import '../../../widgets/dialogs/app_dialog.dart';
import '../../../widgets/images/cached_image.dart';
import '../../../widgets/toast/app_toast.dart';

class PropertyCardWidget extends StatelessWidget {
  final PropertyModel property;
  final VoidCallback? onEditTap;
  final VoidCallback? onTileTap;
  final bool isMinimalView;

  const PropertyCardWidget({
    super.key,
    required this.property,
    this.onEditTap,
    this.onTileTap,
    this.isMinimalView = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isMinimalView) {
      return _buildDashboardMinimalCard(context);
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWeb = constraints.maxWidth >= 768;
        return isWeb ? _buildWebLayout(context) : _buildMobileLayout(context);
      },
    );
  }

  // -----------------------------------------------------------------------------
  // 1. MINIMAL DASHBOARD CARD VIEW
  // -----------------------------------------------------------------------------
  void _handleCardTap(BuildContext context) {
    if (onTileTap != null) {
      onTileTap!();
    } else {
      AppRoutes.navigateToPropertyDetails(context, property);
    }
  }

  Widget _buildDashboardMinimalCard(BuildContext context) {
    final imageUrl = property.medias.isNotEmpty ? property.medias.first.url : null;
    final addressText = property.address?.fullAddress ??
        '${property.address?.city ?? "Surat"}, ${property.address?.state ?? "Gujarat"}';
    final formattedPrice = _formatCurrency(property.price);

    return AppCardContainer(
      borderRadius: 14.0,
      onTap: () => _handleCardTap(context),
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Minimal Image Section (Height: 120.0px)
          Stack(
            children: [
              CachedImage(
                imageUrl,
                height: 120.0,
                width: double.infinity,
                fit: BoxFit.cover,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(14.0),
                ),
              ),
              // Top Status Badge
              Positioned(
                top: 8,
                left: 8,
                child: _buildStatusBadge(context, property.propertyStatus),
              ),
              // Photo Counter Badge
              Positioned(
                bottom: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 3.0),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.65),
                    borderRadius: BorderRadius.circular(5.0),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.photo_camera_outlined,
                        color: Colors.white,
                        size: 11.0,
                      ),
                      const SizedBox(width: 3.0),
                      Text(
                        '${property.medias.isNotEmpty ? property.medias.length : 1}',
                        style: AppTextStyles.caption.copyWith(
                          color: Colors.white,
                          fontSize: 10.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // Minimal Details (Title, Price, Location)
          Padding(
            padding: const EdgeInsets.all(10.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Title
                Text(
                  property.propertyTitle,
                  style: AppTextStyles.heading3.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 13.5,
                    color: AppColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2.0),

                // Price
                Text(
                  formattedPrice,
                  style: AppTextStyles.heading3.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                    fontSize: 14.0,
                  ),
                ),
                const SizedBox(height: 3.0),

                // Location
                _buildAddressRow(addressText, iconSize: 13.0, fontSize: 11.0),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // -----------------------------------------------------------------------------
  // 2. DESKTOP / WEB HORIZONTAL CARD LAYOUT
  // -----------------------------------------------------------------------------
  Widget _buildWebLayout(BuildContext context) {
    final imageUrl = property.medias.isNotEmpty ? property.medias.first.url : null;
    final addressText = property.address?.fullAddress ??
        '${property.address?.city ?? "Surat"}, ${property.address?.state ?? "Gujarat"}';
    final formattedPrice = _formatCurrency(property.price);

    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: AppCardContainer(
        borderRadius: 16.0,
        onTap: () => _handleCardTap(context),
        padding: const EdgeInsets.all(16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left Image Section
            _buildImageSection(context, imageUrl, 260.0, 180.0),
            const SizedBox(width: 20.0),

            // Middle Content Section
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              property.propertyTitle,
                              style: AppTextStyles.heading3.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6.0),
                      _buildAddressRow(addressText, iconSize: 16.0, fontSize: 13.0),
                      const SizedBox(height: 14.0),
                      Wrap(
                        spacing: 8.0,
                        runSpacing: 6.0,
                        children: [
                          _buildChip(
                            label: PropertyLocalizer.getLocalizedListingType(
                              context,
                              property.listingType,
                            ).toUpperCase(),
                            color: AppColors.primary,
                            isOutline: true,
                          ),
                          _buildChip(
                            label: PropertyLocalizer.getLocalizedPropertyType(
                              context,
                              property.propertyType,
                            ),
                            color: AppColors.textSecondary,
                            isOutline: true,
                          ),
                          if (property.area > 0)
                            _buildChip(
                              label:
                                  '${property.area.toStringAsFixed(0)} ${PropertyLocalizer.getLocalizedAreaUnit(context, property.areaUnit)}',
                              color: AppColors.textSecondary,
                              isOutline: true,
                            ),
                          if (property.bedrooms > 0)
                            _buildChip(
                              label: '${property.bedrooms} BHK',
                              color: AppColors.textSecondary,
                              isOutline: true,
                            ),
                          if (property.furnishingStatus != FurnishingStatus.unfurnished)
                            _buildChip(
                              label: PropertyLocalizer.getLocalizedFurnishingStatus(
                                context,
                                property.furnishingStatus,
                              ),
                              color: AppColors.textSecondary,
                              isOutline: true,
                            ),
                          if (property.constructionStatus != ConstructionStatus.underConstruction)
                            _buildChip(
                              label: PropertyLocalizer.getLocalizedConstructionStatus(
                                context,
                                property.constructionStatus,
                              ),
                              color: AppColors.textSecondary,
                              isOutline: true,
                            ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16.0),

            // Right Price & Action Column
            Container(
              width: 180.0,
              padding: const EdgeInsets.only(left: 16.0),
              decoration: const BoxDecoration(
                border: Border(
                  left: BorderSide(color: AppColors.border, width: 1.0),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      _buildStatusBadge(context, property.propertyStatus),
                      const SizedBox(height: 16.0),
                      Text(
                        formattedPrice,
                        style: AppTextStyles.heading2.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                          fontSize: 22.0,
                        ),
                      ),
                      const SizedBox(height: 2.0),
                      Text(
                        property.listingType == ListingType.rent
                            ? context.tr('per_month')
                            : context.tr('total_price'),
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.textSecondary,
                          fontSize: 12.0,
                        ),
                      ),
                      const SizedBox(height: 6.0),
                      Text(
                        '₹ ${(property.price / (property.area > 0 ? property.area : 1)).toStringAsFixed(0)} / ${PropertyLocalizer.getLocalizedAreaUnit(context, property.areaUnit)}',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.textMuted,
                          fontSize: 11.0,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20.0),
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 38.0,
                          child: AppButton(
                            text: context.tr('view_details'),
                            height: 38.0,
                            borderRadius: 8.0,
                            onPressed: onTileTap ?? () => _handleCardTap(context),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8.0),
                      _buildActionMenu(context),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // -----------------------------------------------------------------------------
  // 3. MOBILE VERTICAL CARD LAYOUT
  // -----------------------------------------------------------------------------
  Widget _buildMobileLayout(BuildContext context) {
    final imageUrl = property.medias.isNotEmpty ? property.medias.first.url : null;
    final addressText = property.address?.fullAddress ??
        '${property.address?.city ?? "Surat"}, ${property.address?.state ?? "Gujarat"}';
    final formattedPrice = _formatCurrency(property.price);

    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: AppCardContainer(
        borderRadius: 16.0,
        onTap: () => _handleCardTap(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                CachedImage(
                  imageUrl,
                  height: 180.0,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16.0),
                  ),
                ),
                Positioned(
                  top: 10,
                  left: 10,
                  child: _buildStatusBadge(context, property.propertyStatus),
                ),
                Positioned(
                  bottom: 10,
                  right: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8.0,
                      vertical: 4.0,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.65),
                      borderRadius: BorderRadius.circular(6.0),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.photo_camera_outlined,
                          color: Colors.white,
                          size: 12.0,
                        ),
                        const SizedBox(width: 4.0),
                        Text(
                          context.tr(
                            'photos_count',
                            arguments: {
                              'count':
                                  '${property.medias.isNotEmpty ? property.medias.length : 1}',
                            },
                          ),
                          style: AppTextStyles.caption.copyWith(
                            color: Colors.white,
                            fontSize: 11.0,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(14.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          property.propertyTitle,
                          style: AppTextStyles.heading3.copyWith(
                            fontWeight: FontWeight.bold,
                            fontSize: 16.0,
                            color: AppColors.textPrimary,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8.0),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            formattedPrice,
                            style: AppTextStyles.heading3.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                              fontSize: 17.0,
                            ),
                          ),
                          Text(
                            property.listingType == ListingType.rent
                                ? context.tr('per_month')
                                : context.tr('total_price'),
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.textMuted,
                              fontSize: 10.0,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 6.0),
                  _buildAddressRow(addressText, iconSize: 14.0, fontSize: 12.0),
                  const SizedBox(height: 10.0),
                  Wrap(
                    spacing: 6.0,
                    runSpacing: 4.0,
                    children: [
                      _buildChip(
                        label: PropertyLocalizer.getLocalizedListingType(
                          context,
                          property.listingType,
                        ).toUpperCase(),
                        color: AppColors.primary,
                        isOutline: true,
                      ),
                      _buildChip(
                        label: PropertyLocalizer.getLocalizedPropertyType(
                          context,
                          property.propertyType,
                        ),
                        color: AppColors.textSecondary,
                        isOutline: true,
                      ),
                      if (property.bedrooms > 0)
                        _buildChip(
                          label: '${property.bedrooms} BHK',
                          color: AppColors.textSecondary,
                          isOutline: true,
                        ),
                    ],
                  ),
                  const SizedBox(height: 14.0),
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 38.0,
                          child: AppButton(
                            text: context.tr('view_details'),
                            height: 38.0,
                            borderRadius: 8.0,
                            onPressed: onTileTap ?? () => _handleCardTap(context),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8.0),
                      _buildActionMenu(context),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // -----------------------------------------------------------------------------
  // HELPER WIDGETS & METHODS
  // -----------------------------------------------------------------------------
  Widget _buildAddressRow(String addressText, {double iconSize = 14.0, double fontSize = 12.0}) {
    return Row(
      children: [
        Icon(
          Icons.location_on_outlined,
          size: iconSize,
          color: AppColors.primary,
        ),
        const SizedBox(width: 4.0),
        Expanded(
          child: Text(
            addressText,
            style: AppTextStyles.body2.copyWith(
              color: AppColors.textSecondary,
              fontSize: fontSize,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildImageSection(
    BuildContext context,
    String? imageUrl,
    double width,
    double height,
  ) {
    return Stack(
      children: [
        CachedImage(
          imageUrl,
          width: width,
          height: height,
          fit: BoxFit.cover,
          borderRadius: BorderRadius.circular(12.0),
        ),
        Positioned(
          bottom: 8,
          left: 8,
          right: 8,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8.0,
                  vertical: 4.0,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.65),
                  borderRadius: BorderRadius.circular(6.0),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.photo_library_outlined,
                      color: Colors.white,
                      size: 12.0,
                    ),
                    const SizedBox(width: 4.0),
                    Text(
                      context.tr(
                        'photos_count',
                        arguments: {
                          'count':
                              '${property.medias.isNotEmpty ? property.medias.length : 1}',
                        },
                      ),
                      style: AppTextStyles.caption.copyWith(
                        color: Colors.white,
                        fontSize: 11.0,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionMenu(BuildContext context) {
    return Container(
      width: 38.0,
      height: 38.0,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(19.0),
        border: Border.all(color: AppColors.border, width: 1.0),
      ),
      alignment: Alignment.center,
      child: AppPopupMenuButton<String>(
        triggerIcon: Icons.more_vert_rounded,
        triggerIconSize: 18.0,
        triggerIconColor: AppColors.textSecondary,
        borderRadius: 12.0,
        elevation: 4,
        onSelected: (value) {
          if (value == 'delete') {
            _confirmAndDeleteProperty(context);
          } else if (value == 'edit') {
            if (onEditTap != null) {
              onEditTap!();
            }
          }
        },
        items: [
          AppPopupMenuItem<String>(
            value: 'edit',
            label: context.tr('edit_property'),
            iconData: Icons.edit_outlined,
            iconColor: AppColors.textPrimary,
            textColor: AppColors.textPrimary,
          ),
          AppPopupMenuItem<String>(
            value: 'delete',
            label: context.tr('delete_property'),
            iconData: Icons.delete_outline_rounded,
            iconColor: AppColors.error,
            textColor: AppColors.error,
          ),
        ],
      ),
    );
  }

  Future<void> _confirmAndDeleteProperty(BuildContext context) async {
    final propId = property.id;
    if (propId == null || propId.isEmpty) return;

    final confirmed = await AppDialog.showConfirmationDialog(
      context,
      title: context.tr('delete_property'),
      description: context.tr('delete_property_confirm_desc', arguments: {'title': property.propertyTitle}),
      type: DialogType.error,
      confirmText: context.tr('delete'),
      cancelText: context.tr('cancel'),
    );

    if (confirmed == true && context.mounted) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final propertyProvider = Provider.of<PropertyProvider>(context, listen: false);
      final brokerId = property.brokerId?.id ?? authProvider.userProfile?.brokerId?.id ?? '';

      final success = await propertyProvider.deleteProperty(propId, brokerId: brokerId);
      if (success && context.mounted) {
        AppToast.showSuccess('Property Deleted', 'The property has been deleted successfully.');
      } else if (context.mounted) {
        AppToast.showError('Error', propertyProvider.errorMessage ?? 'Could not delete property.');
      }
    }
  }

  Widget _buildStatusBadge(BuildContext context, dynamic status) {
    final localizedStatus = PropertyLocalizer.getLocalizedPropertyStatus(
      context,
      status,
    );
    final statusStr = status is PropertyStatus ? status.name : status.toString();
    final isAvailable = statusStr.toLowerCase() == 'available';
    final badgeColor = isAvailable ? AppColors.success : AppColors.warning;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      decoration: BoxDecoration(
        color: badgeColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6.0),
        border: Border.all(color: badgeColor.withValues(alpha: 0.3)),
      ),
      child: Text(
        localizedStatus.toUpperCase(),
        style: AppTextStyles.caption.copyWith(
          color: badgeColor,
          fontSize: 10.0,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildChip({
    required String label,
    required Color color,
    bool isOutline = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 3.0),
      decoration: BoxDecoration(
        color: isOutline ? color.withValues(alpha: 0.08) : color,
        borderRadius: BorderRadius.circular(6.0),
        border: isOutline ? Border.all(color: color.withValues(alpha: 0.3)) : null,
      ),
      child: Text(
        label,
        style: AppTextStyles.caption.copyWith(
          color: isOutline ? color : Colors.white,
          fontWeight: FontWeight.w600,
          fontSize: 10.5,
        ),
      ),
    );
  }

  String _formatCurrency(double amount) {
    if (amount >= 10000000) {
      return '₹ ${(amount / 10000000).toStringAsFixed(2)} Cr';
    } else if (amount >= 100000) {
      return '₹ ${(amount / 100000).toStringAsFixed(2)} Lakh';
    } else {
      return '₹ ${amount.toStringAsFixed(0)}';
    }
  }
}
