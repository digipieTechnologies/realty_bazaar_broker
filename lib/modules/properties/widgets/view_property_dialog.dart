// File: lib/modules/properties/widgets/view_property_dialog.dart
// Purpose: Standalone premium modal dialog for viewing property details with top-right actions menu.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../app/app_colors.dart';
import '../../../app/app_text_styles.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/localization/property_localizer.dart';
import '../../../models/property_model.dart';
import '../../../models/property_enums.dart';
import '../../../providers/auth/auth_provider.dart';
import '../../../providers/property/property_provider.dart';
import '../../../widgets/buttons/app_popup_menu_button.dart';
import '../../../widgets/dialogs/app_dialog.dart';
import '../../../widgets/dialogs/video_request_dialog.dart';
import '../../../widgets/toast/app_toast.dart';
import '../screens/add_edit_property_screen.dart';
import 'post_property_dialog.dart';
import 'property_preview_media_gallery.dart';
import 'property_preview_specs_grid.dart';
import 'property_details_grid.dart';
import 'property_location_card.dart';
import 'property_amenities_wrap.dart';
import '../../../widgets/dialogs/app_base_dialog.dart';
import '../../../widgets/shimmer/property_view_shimmer_widget.dart';

class ViewPropertyDialog extends StatefulWidget {
  final PropertyModel? property;
  final String? propertyId;

  const ViewPropertyDialog({
    super.key,
    this.property,
    this.propertyId,
  });

  static Future<void> show(
    BuildContext context, {
    PropertyModel? property,
    String? propertyId,
  }) {
    return showDialog(
      context: context,
      builder: (dialogContext) => ViewPropertyDialog(
        property: property,
        propertyId: propertyId,
      ),
    );
  }

  @override
  State<ViewPropertyDialog> createState() => _ViewPropertyDialogState();
}

class _ViewPropertyDialogState extends State<ViewPropertyDialog> {
  PropertyModel? _property;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    if (widget.property != null) {
      _property = widget.property;
    } else if (widget.propertyId != null && widget.propertyId!.isNotEmpty) {
      _isLoading = true;
      _fetchProperty(widget.propertyId!);
    }
  }

  Future<void> _fetchProperty(String id) async {
    try {
      final provider = Provider.of<PropertyProvider>(context, listen: false);
      final fetched = await provider.fetchPropertyById(id);
      if (mounted) {
        setState(() {
          _property = fetched;
          _isLoading = false;
          if (fetched == null) {
            _errorMessage = 'Property details not found.';
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Error loading property details.';
        });
      }
    }
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

  void _onMenuSelected(String value) async {
    if (_property == null) return;

    if (value == 'edit') {
      final updated = await Navigator.push<PropertyModel>(
        context,
        MaterialPageRoute(
          builder: (context) => AddEditPropertyScreen(propertyToEdit: _property),
        ),
      );
      if (updated != null && mounted) {
        setState(() {
          _property = updated;
        });
      }
    } else if (value == 'post') {
      _openPostPropertyDialog(context);
    } else if (value == 'video_request') {
      _openVideoRequestDialog(context);
    } else if (value == 'delete') {
      _confirmAndDeleteProperty(context);
    }
  }

  void _openPostPropertyDialog(BuildContext context) {
    if (_property == null) return;
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final brokerId = authProvider.userProfile?.brokerId?.id ?? '';
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) => PostPropertyDialog(
        property: _property!,
        brokerId: brokerId,
      ),
    );
  }

  void _openVideoRequestDialog(BuildContext context) {
    if (_property == null) return;
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final brokerId = authProvider.userProfile?.brokerId?.id ?? '';
    final propertyId = _property!.id ?? '';
    if (propertyId.isEmpty || brokerId.isEmpty) {
      AppToast.showError('Error', 'Missing property or broker information.');
      return;
    }
    showDialog(
      context: context,
      builder: (dialogCtx) => VideoRequestDialog(
        propertyId: propertyId,
        brokerId: brokerId,
      ),
    );
  }

  Future<void> _confirmAndDeleteProperty(BuildContext context) async {
    if (_property == null || _property!.id == null) return;
    final prop = _property!;

    final confirmed = await AppDialog.showConfirmationDialog(
      context,
      title: context.tr('delete_property'),
      description: context.tr('delete_property_confirm_desc', arguments: {'title': prop.propertyTitle}),
      type: DialogType.error,
      confirmText: context.tr('delete'),
      cancelText: context.tr('cancel'),
    );

    if (confirmed == true && context.mounted) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final propertyProvider = Provider.of<PropertyProvider>(context, listen: false);
      final brokerId = prop.brokerId?.id ?? authProvider.userProfile?.brokerId?.id ?? '';

      final success = await propertyProvider.deleteProperty(prop.id!, brokerId: brokerId);
      if (success && context.mounted) {
        AppToast.showSuccess('Property Deleted', 'The property has been deleted successfully.');
        Navigator.of(context).pop();
      } else if (context.mounted) {
        AppToast.showError('Error', propertyProvider.errorMessage ?? 'Could not delete property.');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const AppBaseDialog(
        headerIcon: Icons.apartment_rounded,
        title: 'Loading Property...',
        content: PropertyViewShimmerWidget(),
      );
    }

    if (_property == null) {
      return AppBaseDialog(
        headerIcon: Icons.apartment_rounded,
        title: 'Property Details',
        content: SizedBox(
          height: 180.0,
          child: Center(
            child: Text(
              _errorMessage ?? 'Property details not found.',
              style: AppTextStyles.body1.copyWith(color: AppColors.textSecondary),
            ),
          ),
        ),
      );
    }

    final property = _property!;
    final categoryLabel = PropertyLocalizer.getLocalizedPropertyType(context, property.propertyType);
    final listingLabel = PropertyLocalizer.getLocalizedListingType(context, property.listingType);
    final constStatusLabel = PropertyLocalizer.getLocalizedConstructionStatus(context, property.constructionStatus);
    final propertyStatusLabel = PropertyLocalizer.getLocalizedPropertyStatus(context, property.propertyStatus);

    return AppBaseDialog(
      headerIcon: Icons.apartment_rounded,
      title: property.propertyTitle,
      headerActions: [
        AppPopupMenuButton<String>(
          triggerIconColor: AppColors.textPrimary,
          borderRadius: 12.0,
          elevation: 4,
          onSelected: _onMenuSelected,
          items: [
            AppPopupMenuItem<String>(
              value: 'edit',
              iconData: Icons.edit_outlined,
              label: context.tr('edit_property'),
              iconColor: AppColors.textPrimary,
              textColor: AppColors.textPrimary,
            ),
            AppPopupMenuItem<String>(
              value: 'post',
              iconData: Icons.campaign_outlined,
              label: context.tr('post_property'),
              iconColor: AppColors.textPrimary,
              textColor: AppColors.textPrimary,
            ),
            AppPopupMenuItem<String>(
              value: 'video_request',
              iconData: Icons.videocam_outlined,
              label: context.tr('video_request'),
              iconColor: AppColors.textPrimary,
              textColor: AppColors.textPrimary,
            ),
            AppPopupMenuItem<String>(
              value: 'delete',
              iconData: Icons.delete_outline_rounded,
              label: context.tr('delete_property'),
              iconColor: AppColors.error,
              textColor: AppColors.error,
            ),
          ],
        ),
      ],
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Media Gallery (Collage / Carousel)
          PropertyPreviewMediaGallery(medias: property.medias, height: 260.0),
          const SizedBox(height: 20.0),

                // 2. Badges Row
                Wrap(
                  spacing: 8.0,
                  runSpacing: 8.0,
                  children: [
                    _buildBadge(categoryLabel, AppColors.primary),
                    _buildBadge(listingLabel, AppColors.secondary),
                    _buildBadge(constStatusLabel, const Color(0xFF10B981)),
                    _buildBadge(propertyStatusLabel, _statusColor(property.propertyStatus)),
                  ],
                ),
                const SizedBox(height: 16.0),

                // 3. Price & Title
                Text(
                  _formatCurrency(property.price),
                  style: AppTextStyles.heading1.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w800,
                    fontSize: 22.0,
                  ),
                ),
                if (property.listingType == ListingType.rent)
                  Text(
                    'Per Month',
                    style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
                  ),
                const SizedBox(height: 6.0),
                Text(
                  property.propertyTitle,
                  style: AppTextStyles.heading3.copyWith(fontWeight: FontWeight.bold),
                ),

                // 4. Property Description
                if (property.propertyDescription != null && property.propertyDescription!.trim().isNotEmpty) ...[
                  const SizedBox(height: 12.0),
                  Text(
                    property.propertyDescription!.trim(),
                    style: AppTextStyles.body2.copyWith(color: AppColors.textSecondary, height: 1.5),
                  ),
                ],
                const SizedBox(height: 20.0),

                // 5. Specifications Grid
                PropertyPreviewSpecsGrid(property: property),
                const SizedBox(height: 20.0),

                // 6. Section: Property Details
                _buildSectionCard(
                  title: 'Property Details',
                  child: PropertyDetailsGrid(property: property),
                ),
                const SizedBox(height: 16.0),

                // 7. Section: Location
                _buildSectionCard(
                  title: 'Location',
                  child: PropertyLocationCard(address: property.address),
                ),
                const SizedBox(height: 16.0),

                // 8. Section: Facilities & Amenities
                if (property.amenities.isNotEmpty) ...[
                  _buildSectionCard(
                    title: 'Facilities & Amenities',
                    child: PropertyAmenitiesWrap(amenities: property.amenities),
                  ),
                ],
              ],
            ),
    );
  }

  Widget _buildSectionCard({required String title, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTextStyles.heading3.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
              fontSize: 15.0,
            ),
          ),
          const SizedBox(height: 14.0),
          child,
        ],
      ),
    );
  }

  Widget _buildBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 4.0),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20.0),
        border: Border.all(color: color.withValues(alpha: 0.2), width: 1.0),
      ),
      child: Text(
        text,
        style: AppTextStyles.caption.copyWith(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 11.0,
        ),
      ),
    );
  }

  Color _statusColor(dynamic status) {
    final statusStr = status is PropertyStatus ? status.name : status.toString();
    switch (statusStr.toLowerCase()) {
      case 'available':
        return const Color(0xFF10B981);
      case 'sold':
        return const Color(0xFFEF4444);
      case 'rented':
        return const Color(0xFFF59E0B);
      case 'under offer':
        return const Color(0xFF6366F1);
      default:
        return AppColors.textSecondary;
    }
  }
}
