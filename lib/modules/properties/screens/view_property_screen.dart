// File: lib/modules/properties/screens/view_property_screen.dart
// Purpose: Premium full-screen property details view with responsive desktop/mobile layout, top app bar AppButton actions, and dedicated marketing section.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../app/app_colors.dart';
import '../../../app/app_text_styles.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/localization/property_localizer.dart';
import '../../../models/property_enums.dart';
import '../../../models/property_model.dart';
import '../../../providers/auth/auth_provider.dart';
import '../../../providers/property/property_provider.dart';
import '../../../widgets/buttons/app_button.dart';
import '../../../widgets/common/common_app_bar.dart';
import '../../../widgets/common/currency_text.dart';
import '../../../widgets/dialogs/app_dialog.dart';
import '../../../widgets/dialogs/video_request_dialog.dart';
import '../../../widgets/shimmer/property_view_shimmer_widget.dart';
import '../../../widgets/toast/app_toast.dart';
import '../widgets/post_property_dialog.dart';
import '../widgets/property_amenities_wrap.dart';
import '../widgets/property_details_grid.dart';
import '../widgets/property_location_card.dart';
import '../widgets/property_preview_media_gallery.dart';
import '../widgets/property_preview_specs_grid.dart';
import 'add_edit_property_screen.dart';

class ViewPropertyScreen extends StatefulWidget {
  final PropertyModel? property;
  final String? propertyId;

  const ViewPropertyScreen({super.key, this.property, this.propertyId});

  @override
  State<ViewPropertyScreen> createState() => _ViewPropertyScreenState();
}

class _ViewPropertyScreenState extends State<ViewPropertyScreen> {
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

  Future<void> _onEditTap() async {
    if (_property == null) return;
    final updated = await Navigator.of(context, rootNavigator: true).push<PropertyModel>(
      MaterialPageRoute(builder: (context) => AddEditPropertyScreen(propertyToEdit: _property)),
    );
    if (updated != null && mounted) {
      setState(() {
        _property = updated;
      });
    }
  }

  void _openPostPropertyDialog(BuildContext context) {
    if (_property == null) return;
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final brokerId = authProvider.userProfile?.brokerId?.id ?? '';
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) => PostPropertyDialog(property: _property!, brokerId: brokerId),
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
      builder: (dialogCtx) => VideoRequestDialog(propertyId: propertyId, brokerId: brokerId),
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
        AppToast.showSuccess(
          context.tr('toast_property_deleted_title'),
          context.tr('toast_property_deleted_desc'),
        );
        Navigator.of(context).pop();
      } else if (context.mounted) {
        AppToast.showError(
          context.tr('error_generic'),
          propertyProvider.errorMessage ?? 'Could not delete property.',
        );
      }
    }
  }

  List<Widget> _buildAppBarActions(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    return [
      AppButton.outline(
        iconData: Icons.edit_outlined,
        text: isMobile ? null : context.tr('edit'),
        width: isMobile ? 38.0 : null,
        height: 38.0,
        borderRadius: 8.0,
        padding: isMobile ? EdgeInsets.zero : const EdgeInsets.symmetric(horizontal: 12.0),
        onPressed: _onEditTap,
      ),
      const SizedBox(width: 8.0),
      AppButton(
        variant: AppButtonVariant.danger,
        iconData: Icons.delete_outline_rounded,
        text: isMobile ? null : context.tr('delete'),
        width: isMobile ? 38.0 : null,
        height: 38.0,
        borderRadius: 8.0,
        padding: isMobile ? EdgeInsets.zero : const EdgeInsets.symmetric(horizontal: 12.0),
        onPressed: () => _confirmAndDeleteProperty(context),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: CommonAppBar(title: context.tr('loading')),
        body: const PropertyViewShimmerWidget(),
      );
    }

    if (_property == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: CommonAppBar(title: context.tr('property_details')),
        body: Center(
          child: Text(
            _errorMessage ?? context.tr('no_properties_found'),
            style: AppTextStyles.body1.copyWith(color: AppColors.textSecondary),
          ),
        ),
      );
    }

    final property = _property!;
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > 900;
    final isTablet = screenWidth >= 600 && screenWidth <= 900;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: CommonAppBar(title: property.propertyTitle, actions: _buildAppBarActions(context)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(14.0),
        child: isDesktop
            ? Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Left Column: Media, Main Info, Specs & Marketing (flex: 3)
                  Expanded(
                    flex: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        PropertyPreviewMediaGallery(medias: property.medias, height: 360.0),
                        const SizedBox(height: 14.0),
                        _buildMainInfoCard(property),
                        const SizedBox(height: 14.0),
                        PropertyPreviewSpecsGrid(property: property),
                        const SizedBox(height: 14.0),
                        _buildMarketingActionsCard(context, includePostCard: true),
                      ],
                    ),
                  ),
                  const SizedBox(width: 14.0),
                  // Right Column: Details, Location, Amenities (flex: 2)
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionCard(
                          title: context.tr('property_details'),
                          child: PropertyDetailsGrid(property: property),
                        ),
                        const SizedBox(height: 14.0),
                        _buildSectionCard(
                          title: context.tr('location'),
                          child: PropertyLocationCard(address: property.address),
                        ),
                        if (property.amenities.isNotEmpty) ...[
                          const SizedBox(height: 14.0),
                          _buildSectionCard(
                            title: context.tr('section_amenities'),
                            child: PropertyAmenitiesWrap(amenities: property.amenities),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  PropertyPreviewMediaGallery(medias: property.medias, height: 260.0),
                  const SizedBox(height: 14.0),
                  _buildMainInfoCard(property),
                  const SizedBox(height: 14.0),
                  PropertyPreviewSpecsGrid(property: property),
                  const SizedBox(height: 14.0),
                  _buildSectionCard(
                    title: context.tr('property_details'),
                    child: PropertyDetailsGrid(property: property),
                  ),
                  const SizedBox(height: 14.0),
                  _buildSectionCard(
                    title: context.tr('location'),
                    child: PropertyLocationCard(address: property.address),
                  ),
                  if (property.amenities.isNotEmpty) ...[
                    const SizedBox(height: 14.0),
                    _buildSectionCard(
                      title: context.tr('section_amenities'),
                      child: PropertyAmenitiesWrap(amenities: property.amenities),
                    ),
                  ],
                  const SizedBox(height: 14.0),
                  _buildMarketingActionsCard(context, includePostCard: false),
                ],
              ),
      ),
      bottomNavigationBar: isDesktop ? null : _buildStickyBottomPostBar(context, isTablet: isTablet),
    );
  }

  Widget _buildStickyBottomPostBar(BuildContext context, {required bool isTablet}) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    return Container(
      padding: EdgeInsets.fromLTRB(16.0, 12.0, 16.0, 12.0 + (bottomPadding > 0 ? bottomPadding : 4.0)),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: const Border(top: BorderSide(color: AppColors.border, width: 1.0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12.0,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: isTablet
          ? Row(
              children: [
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6.0),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.campaign_outlined, color: AppColors.primary, size: 16.0),
                          ),
                          const SizedBox(width: 8.0),
                          Text(
                            context.tr('post_property'),
                            style: AppTextStyles.heading3.copyWith(
                              fontWeight: FontWeight.bold,
                              fontSize: 15.0,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4.0),
                      Text(
                        context.tr('post_property_feature_desc'),
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.textSecondary,
                          fontSize: 11.5,
                          height: 1.35,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16.0),
                SizedBox(
                  width: 220.0,
                  child: AppButton.solid(
                    iconData: Icons.campaign_outlined,
                    text: context.tr('post_property'),
                    color: AppColors.primary,
                    height: 44.0,
                    borderRadius: 10.0,
                    onPressed: () => _openPostPropertyDialog(context),
                  ),
                ),
              ],
            )
          : Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6.0),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.campaign_outlined, color: AppColors.primary, size: 16.0),
                    ),
                    const SizedBox(width: 8.0),
                    Expanded(
                      child: Text(
                        context.tr('post_property'),
                        style: AppTextStyles.heading3.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: 14.5,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4.0),
                Text(
                  context.tr('post_property_feature_desc'),
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textSecondary,
                    fontSize: 11.5,
                    height: 1.35,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 10.0),
                SizedBox(
                  width: double.infinity,
                  child: AppButton.solid(
                    iconData: Icons.campaign_outlined,
                    text: context.tr('post_property'),
                    color: AppColors.primary,
                    height: 44.0,
                    borderRadius: 10.0,
                    onPressed: () => _openPostPropertyDialog(context),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildMainInfoCard(PropertyModel property) {
    final categoryLabel = PropertyLocalizer.getLocalizedPropertyType(context, property.propertyType);
    final listingLabel = PropertyLocalizer.getLocalizedListingType(context, property.listingType);
    final constStatusLabel = PropertyLocalizer.getLocalizedConstructionStatus(
      context,
      property.constructionStatus,
    );
    final propertyStatusLabel = PropertyLocalizer.getLocalizedPropertyStatus(
      context,
      property.propertyStatus,
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14.0),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Badges Row
          Wrap(
            spacing: 8.0,
            runSpacing: 8.0,
            children: [
              if (property.propertyCode != null && property.propertyCode!.isNotEmpty)
                _buildBadge('${property.propertyCode}', AppColors.tagIndigo),
              _buildBadge(categoryLabel, AppColors.primary),
              _buildBadge(listingLabel, AppColors.primary800),
              _buildBadge(constStatusLabel, AppColors.success),
              _buildBadge(propertyStatusLabel, _statusColor(property.propertyStatus)),
            ],
          ),
          const SizedBox(height: 14.0),

          // Price & Title
          CurrencyText(
            amount: property.price,
            style: AppTextStyles.heading1.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w800,
              fontSize: 24.0,
            ),
          ),
          if (property.listingType == ListingType.rent)
            Text('Per Month', style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary)),
          const SizedBox(height: 6.0),
          Text(property.propertyTitle, style: AppTextStyles.heading2.copyWith(fontWeight: FontWeight.bold)),

          // Property Description
          if (property.propertyDescription != null && property.propertyDescription!.trim().isNotEmpty) ...[
            const SizedBox(height: 12.0),
            Text(
              property.propertyDescription!.trim(),
              style: AppTextStyles.body2.copyWith(color: AppColors.textSecondary, height: 1.5),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActionFeatureCard({
    required IconData icon,
    required Color color,
    required String title,
    required String description,
    required Widget actionButton,
  }) {
    return Container(
      padding: const EdgeInsets.all(14.0),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10.0),
                decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
                child: Icon(icon, color: color, size: 22.0),
              ),
              const SizedBox(width: 12.0),
              Expanded(
                child: Text(
                  title,
                  style: AppTextStyles.heading3.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                    fontSize: 15.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10.0),
          Text(
            description,
            style: AppTextStyles.body2.copyWith(color: AppColors.textSecondary, fontSize: 12.5, height: 1.45),
          ),
          const SizedBox(height: 16.0),
          SizedBox(width: double.infinity, child: actionButton),
        ],
      ),
    );
  }

  Widget _buildMarketingActionsCard(BuildContext context, {bool includePostCard = true}) {
    final postCard = _buildActionFeatureCard(
      icon: Icons.campaign_outlined,
      color: AppColors.primary,
      title: context.tr('post_property'),
      description: context.tr('post_property_feature_desc'),
      actionButton: AppButton.solid(
        iconData: Icons.campaign_outlined,
        text: context.tr('post_property'),
        color: AppColors.primary,
        height: 44.0,
        borderRadius: 10.0,
        onPressed: () => _openPostPropertyDialog(context),
      ),
    );

    final videoCard = _buildActionFeatureCard(
      icon: Icons.videocam_outlined,
      color: AppColors.primary,
      title: context.tr('video_request'),
      description: context.tr('video_request_feature_desc'),
      actionButton: AppButton(
        variant: AppButtonVariant.secondary,
        iconData: Icons.videocam_outlined,
        text: context.tr('video_request'),
        height: 44.0,
        borderRadius: 10.0,
        onPressed: () => _openVideoRequestDialog(context),
      ),
    );

    if (!includePostCard) {
      return videoCard;
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 640;
        if (isNarrow) {
          return Column(children: [postCard, const SizedBox(height: 14.0), videoCard]);
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: postCard),
            const SizedBox(width: 14.0),
            Expanded(child: videoCard),
          ],
        );
      },
    );
  }

  Widget _buildSectionCard({required String title, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14.0),
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
              fontSize: 16.0,
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
        style: AppTextStyles.caption.copyWith(color: color, fontWeight: FontWeight.bold, fontSize: 11.0),
      ),
    );
  }

  Color _statusColor(dynamic status) {
    final statusStr = status is PropertyStatus ? status.displayName : status.toString();
    switch (statusStr.toLowerCase()) {
      case 'available':
        return AppColors.success;
      case 'sold':
        return AppColors.error;
      case 'rented':
        return AppColors.warning;
      case 'under offer':
        return AppColors.tagIndigo;
      default:
        return AppColors.textSecondary;
    }
  }
}
