// File: lib/modules/properties/screens/view_property_screen.dart
// Purpose: Fully locked responsive Property Details layout for Web matching therealtybazaar.com design reference.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../app/app_colors.dart';
import '../../../app/app_text_styles.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/localization/property_localizer.dart';
import '../../../models/property_enums.dart';
import '../../../models/property_model.dart';
import '../../../providers/auth/auth_provider.dart';
import '../../../providers/property/property_provider.dart';
import '../../../util/common_ext.dart';
import '../../../widgets/buttons/app_button.dart';
import '../../../widgets/common/common_app_bar.dart';
import '../../../widgets/common/currency_text.dart';
import '../../../widgets/dialogs/app_dialog.dart';
import '../../../widgets/dialogs/video_request_dialog.dart';
import '../../../widgets/images/cached_image.dart';
import '../../../widgets/shimmer/property_view_shimmer_widget.dart';
import '../../../widgets/toast/app_toast.dart';
import '../widgets/post_property_dialog.dart';
import '../widgets/property_amenities_wrap.dart';
import '../widgets/property_details_grid.dart';
import '../widgets/property_location_card.dart';
import '../widgets/property_preview_media_gallery.dart';
import '../widgets/property_preview_specs_grid.dart';
import '../../visits/widgets/schedule_visit_dialog.dart';
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
    final updated = await Navigator.of(
      context,
      rootNavigator: true,
    ).push<PropertyModel>(MaterialPageRoute(builder: (context) => AddEditPropertyScreen(propertyToEdit: _property)));
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
        AppToast.showSuccess(context.tr('toast_property_deleted_title'), context.tr('toast_property_deleted_desc'));
        Navigator.of(context).pop();
      } else if (context.mounted) {
        AppToast.showError(context.tr('error_generic'), propertyProvider.errorMessage ?? 'Could not delete property.');
      }
    }
  }

  void _handleShare(BuildContext context) {
    if (_property == null) return;
    final code = _property!.propertyCode ?? _property!.id ?? '';
    final url = 'https://therealtybazaar.com/properties/$code';
    Clipboard.setData(ClipboardData(text: url));
    AppToast.showSuccess('Link Copied', 'Property link copied to clipboard.');
  }

  void _openFullscreenViewer(BuildContext context, int initialIndex) {
    final medias = _property?.medias ?? [];
    if (medias.isEmpty) return;

    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.9),
      builder: (ctx) {
        final PageController pageController = PageController(initialPage: initialIndex);
        int currentIndex = initialIndex;

        return StatefulBuilder(
          builder: (context, setState) {
            return Stack(
              children: [
                PageView.builder(
                  controller: pageController,
                  itemCount: medias.length,
                  onPageChanged: (idx) => setState(() => currentIndex = idx),
                  itemBuilder: (context, idx) {
                    return InteractiveViewer(
                      child: Center(
                        child: CachedImage(
                          medias[idx].url,
                          fit: BoxFit.contain,
                          width: double.infinity,
                          height: double.infinity,
                        ),
                      ),
                    );
                  },
                ),

                // Top Controls: Close button & Counter
                Positioned(
                  top: 24.0,
                  left: 24.0,
                  right: 24.0,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 7.0),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(20.0),
                        ),
                        child: Text(
                          '${currentIndex + 1} / ${medias.length}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14.0,
                            fontWeight: FontWeight.w700,
                            decoration: TextDecoration.none,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, color: Colors.white, size: 28.0),
                        onPressed: () => Navigator.of(ctx).pop(),
                      ),
                    ],
                  ),
                ),

                // Previous Image Arrow
                if (currentIndex > 0)
                  Positioned(
                    left: 20.0,
                    top: 0,
                    bottom: 0,
                    child: Center(
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white, size: 32.0),
                        onPressed: () {
                          pageController.previousPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                        },
                      ),
                    ),
                  ),

                // Next Image Arrow
                if (currentIndex < medias.length - 1)
                  Positioned(
                    right: 20.0,
                    top: 0,
                    bottom: 0,
                    child: Center(
                      child: IconButton(
                        icon: const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 32.0),
                        onPressed: () {
                          pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
                        },
                      ),
                    ),
                  ),
              ],
            );
          },
        );
      },
    );
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
    final isDesktop = context.isDesktop;
    final isTablet = context.isTablet;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: isDesktop
          ? null
          : CommonAppBar(title: property.propertyTitle, actions: _buildMobileAppBarActions(context)),
      body: ScrollConfiguration(
        behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: isDesktop ? 24.0 : 14.0, vertical: isDesktop ? 24.0 : 14.0),
          child: Align(
            alignment: Alignment.topCenter,
            child: isDesktop ? _buildDesktopLayout(context, property) : _buildMobileLayout(context, property),
          ),
        ),
      ),
      bottomNavigationBar: isDesktop ? null : _buildStickyBottomPostBar(context, isTablet: isTablet),
    );
  }

  // ---------------------------------------------------------------------------
  // 1. DESKTOP WEB LAYOUT (Locked & responsive)
  // ---------------------------------------------------------------------------
  Widget _buildDesktopLayout(BuildContext context, PropertyModel property) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Adapt container width dynamically:
        // On very wide screens (>1300), take ~78% up to 1200px max.
        // On narrower desktop viewports (900-1300), take 94% width to provide ample breathing room.
        final double maxAllowed = constraints.maxWidth;
        final double targetWidth = maxAllowed > 1300 ? 1200.0 : maxAllowed * 0.94;
        final bool isNarrowDesktop = targetWidth < 840.0;

        return SizedBox(
          width: targetWidth,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // A. TOP HERO HEADER CARD
              _buildTopHeroCard(context, property),
              const SizedBox(height: 24.0),

              // B. 2-COLUMN MAIN CONTENT (or Stacked if viewport gets very narrow)
              if (isNarrowDesktop) ...[
                _buildWebHeroImage(context, property),
                const SizedBox(height: 20.0),
                _buildQuickFeatureTiles(context, property),
                const SizedBox(height: 20.0),
                _buildAboutPropertyCard(property),
                const SizedBox(height: 20.0),
                if (property.amenities.isNotEmpty) ...[
                  _buildAmenitiesCard(context, property),
                  const SizedBox(height: 20.0),
                ],
                _buildPropertyOverviewCard(context, property),
                const SizedBox(height: 20.0),
                _buildSidebarPostPropertyCard(context),
                const SizedBox(height: 20.0),
                _buildSidebarVideoRequestCard(context),
                const SizedBox(height: 20.0),
                _buildSidebarManageCard(context),
              ] else ...[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // LEFT COLUMN (Takes all remaining flexible space)
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildWebHeroImage(context, property),
                          const SizedBox(height: 20.0),
                          _buildQuickFeatureTiles(context, property),
                          const SizedBox(height: 20.0),
                          _buildAboutPropertyCard(property),
                          const SizedBox(height: 20.0),
                          if (property.amenities.isNotEmpty) ...[
                            _buildAmenitiesCard(context, property),
                            const SizedBox(height: 20.0),
                          ],
                          _buildPropertyOverviewCard(context, property),
                        ],
                      ),
                    ),
                    const SizedBox(width: 24.0),

                    // RIGHT COLUMN (Locked comfortable width of 285px)
                    SizedBox(
                      width: 285.0,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSidebarPostPropertyCard(context),
                          const SizedBox(height: 20.0),
                          _buildSidebarVideoRequestCard(context),
                          const SizedBox(height: 20.0),
                          _buildSidebarManageCard(context),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 40.0),
            ],
          ),
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // A. TOP HERO HEADER CARD (Responsive to prevent overflow)
  // ---------------------------------------------------------------------------
  Widget _buildTopHeroCard(BuildContext context, PropertyModel property) {
    final listingLabel = property.listingType == ListingType.rent ? 'For Rent' : 'For Sale';
    final categoryLabel = PropertyLocalizer.getLocalizedPropertyType(context, property.propertyType).toUpperCase();
    final addressText =
        property.address?.fullAddress ??
        '${property.address?.city ?? "Surat"}, ${property.address?.state ?? "Gujarat"}';

    final double areaValue = property.area > 0 ? property.area : 1;
    final double ratePerSqft = property.price / areaValue;
    final double areaSqm = property.area / 10.764;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24.0),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20.0),
        border: Border.all(color: AppColors.border, width: 1.0),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10.0, offset: const Offset(0, 2)),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isWideHeader = constraints.maxWidth >= 760.0;

          final statsAndActionsRow = Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Stat 1: Price
              _buildHeroStatColumn(
                icon: Icons.currency_rupee_rounded,
                label: 'PRICE',
                mainValue: CurrencyText(
                  amount: property.price,
                  style: AppTextStyles.heading2.copyWith(
                    fontSize: 20.0,
                    fontWeight: FontWeight.w900,
                    color: AppColors.textPrimary,
                  ),
                ),
                subValue: property.listingType == ListingType.rent
                    ? 'Per Month'
                    : '₹${ratePerSqft.toStringAsFixed(0)} / sq ft',
              ),
              Container(
                height: 44.0,
                width: 1.0,
                color: AppColors.border,
                margin: const EdgeInsets.symmetric(horizontal: 14.0),
              ),

              // Stat 2: Super Built-up Area
              _buildHeroStatColumn(
                icon: Icons.crop_square_rounded,
                label: 'SUPER BUILT-UP',
                mainValue: Text(
                  '${property.area.toStringAsFixed(0)} sq ft',
                  style: AppTextStyles.heading2.copyWith(
                    fontSize: 19.0,
                    fontWeight: FontWeight.w900,
                    color: AppColors.textPrimary,
                  ),
                ),
                subValue: '${areaSqm.toStringAsFixed(1)} sq m',
              ),
              Container(
                height: 44.0,
                width: 1.0,
                color: AppColors.border,
                margin: const EdgeInsets.symmetric(horizontal: 14.0),
              ),

              // Stat 3: Configuration
              _buildHeroStatColumn(
                icon: Icons.hotel_rounded,
                label: 'CONFIGURATION',
                mainValue: Text(
                  '${property.bedrooms} BHK',
                  style: AppTextStyles.heading2.copyWith(
                    fontSize: 19.0,
                    fontWeight: FontWeight.w900,
                    color: AppColors.textPrimary,
                  ),
                ),
                subValue: '${property.bedrooms} Beds · ${property.bathrooms} Baths',
              ),
              const SizedBox(width: 16.0),

              // Quick Share & Save Buttons
              Column(
                children: [
                  _buildOutlinedSmallAction(
                    icon: Icons.share_outlined,
                    label: 'Share',
                    onTap: () => _handleShare(context),
                  ),
                  const SizedBox(height: 6.0),
                  _buildOutlinedSmallAction(
                    icon: Icons.favorite_border_rounded,
                    label: 'Save',
                    onTap: () => AppToast.showSuccess('Saved', 'Added to saved properties.'),
                  ),
                ],
              ),
            ],
          );

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Row: Back button & Badges
              Wrap(
                spacing: 8.0,
                runSpacing: 8.0,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  InkWell(
                    onTap: () => Navigator.of(context).maybePop(),
                    borderRadius: BorderRadius.circular(8.0),
                    child: Container(
                      padding: const EdgeInsets.all(6.0),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8.0),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: const Icon(Icons.arrow_back_rounded, size: 18.0, color: AppColors.textPrimary),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 6.0),
                    decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(20.0)),
                    child: Text(
                      listingLabel,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12.0),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(8.0),
                      border: Border.all(color: const Color(0xFFDBEAFE)),
                    ),
                    child: Text(
                      categoryLabel,
                      style: const TextStyle(
                        color: Color(0xFF2563EB),
                        fontWeight: FontWeight.w800,
                        fontSize: 11.5,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  if (property.propertyCode != null && property.propertyCode!.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(8.0),
                        border: Border.all(color: const Color(0xFFDBEAFE)),
                      ),
                      child: Text(
                        '#${property.propertyCode}',
                        style: const TextStyle(color: Color(0xFF2563EB), fontWeight: FontWeight.w800, fontSize: 11.5),
                      ),
                    ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 5.0),
                    decoration: BoxDecoration(
                      color: const Color(0xFFECFDF5),
                      borderRadius: BorderRadius.circular(20.0),
                      border: Border.all(color: const Color(0xFFA7F3D0)),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check_circle_rounded, size: 14.0, color: Color(0xFF059669)),
                        SizedBox(width: 4.0),
                        Text(
                          'Verified Listing',
                          style: TextStyle(color: Color(0xFF059669), fontWeight: FontWeight.w700, fontSize: 11.5),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18.0),

              // Main Header Layout
              if (isWideHeader)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title & Location
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            property.propertyTitle,
                            style: AppTextStyles.heading1.copyWith(
                              fontSize: 23.0,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                              height: 1.25,
                            ),
                          ),
                          const SizedBox(height: 10.0),
                          Row(
                            children: [
                              const Icon(Icons.location_on_outlined, size: 16.0, color: AppColors.primary),
                              const SizedBox(width: 4.0),
                              Expanded(
                                child: Text(
                                  addressText,
                                  style: AppTextStyles.body2.copyWith(color: AppColors.textSecondary, fontSize: 13.5),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 20.0),

                    // Stats & Action buttons (scaled down automatically if space is tight)
                    FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerRight, child: statsAndActionsRow),
                  ],
                )
              else
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      property.propertyTitle,
                      style: AppTextStyles.heading1.copyWith(
                        fontSize: 21.0,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 8.0),
                    Row(
                      children: [
                        const Icon(Icons.location_on_outlined, size: 16.0, color: AppColors.primary),
                        const SizedBox(width: 4.0),
                        Expanded(
                          child: Text(
                            addressText,
                            style: AppTextStyles.body2.copyWith(color: AppColors.textSecondary, fontSize: 13.0),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16.0),
                    const Divider(color: AppColors.border, height: 1.0),
                    const SizedBox(height: 16.0),
                    FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerLeft, child: statsAndActionsRow),
                  ],
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHeroStatColumn({
    required IconData icon,
    required String label,
    required Widget mainValue,
    required String subValue,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13.0, color: AppColors.primary),
            const SizedBox(width: 4.0),
            Text(
              label,
              style: const TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
                color: AppColors.textSecondary,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4.0),
        mainValue,
        const SizedBox(height: 2.0),
        Text(
          subValue,
          style: const TextStyle(fontSize: 11.5, color: AppColors.textMuted, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  Widget _buildOutlinedSmallAction({required IconData icon, required String label, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10.0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 6.0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10.0),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14.0, color: AppColors.textPrimary),
            const SizedBox(width: 6.0),
            Text(
              label,
              style: const TextStyle(fontSize: 12.0, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 1. HERO PROPERTY IMAGE CONTAINER
  // ---------------------------------------------------------------------------
  Widget _buildWebHeroImage(BuildContext context, PropertyModel property) {
    final imageUrl = property.medias.isNotEmpty ? property.medias.first.url : null;
    final mediasCount = property.medias.length;

    return Container(
      height: 440.0,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20.0),
        border: Border.all(color: AppColors.border),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10.0)],
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(20.0),
            child: GestureDetector(
              onTap: () => _openFullscreenViewer(context, 0),
              child: CachedImage(imageUrl, fit: BoxFit.cover, width: double.infinity, height: double.infinity),
            ),
          ),

          // Bottom Left: Photos Counter Tag
          if (mediasCount > 0)
            Positioned(
              bottom: 16.0,
              left: 16.0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.75),
                  borderRadius: BorderRadius.circular(20.0),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.photo_library_outlined, color: Colors.white, size: 14.0),
                    const SizedBox(width: 6.0),
                    Text(
                      '1 of $mediasCount Photos',
                      style: const TextStyle(color: Colors.white, fontSize: 12.0, fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
            ),

          // Bottom Right: View Fullscreen Button
          Positioned(
            bottom: 16.0,
            right: 16.0,
            child: InkWell(
              onTap: () => _openFullscreenViewer(context, 0),
              borderRadius: BorderRadius.circular(20.0),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 7.0),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.75),
                  borderRadius: BorderRadius.circular(20.0),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.fullscreen_rounded, color: Colors.white, size: 16.0),
                    SizedBox(width: 6.0),
                    Text(
                      'View Fullscreen',
                      style: TextStyle(color: Colors.white, fontSize: 12.0, fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 2. QUICK FEATURE TILES (Responsive Wrap Grid)
  // ---------------------------------------------------------------------------
  Widget _buildQuickFeatureTiles(BuildContext context, PropertyModel property) {
    final floorText = property.floorNumber != null
        ? '${property.floorNumber}th of ${property.totalFloors ?? 1} Floors'
        : (property.totalFloors != null ? '${property.totalFloors} Floors' : '1st Floor');

    final facingText = property.facing != null ? '${property.facing!.displayName} Facing' : 'North East Facing';

    final possessionText = property.constructionStatus == ConstructionStatus.readyToMove
        ? 'Ready To Move'
        : 'Under Construction';

    final tiles = [
      _FeatureTileData(icon: Icons.bed_outlined, label: 'BEDROOMS', value: '${property.bedrooms}'),
      _FeatureTileData(icon: Icons.bathtub_outlined, label: 'BATHROOMS', value: '${property.bathrooms}'),
      _FeatureTileData(icon: Icons.balcony_outlined, label: 'BALCONY', value: '${property.balconies}'),
      _FeatureTileData(icon: Icons.apartment_outlined, label: 'FLOOR', value: floorText),
      _FeatureTileData(icon: Icons.domain_outlined, label: 'PROPERTY TYPE', value: property.propertyType.displayName),
      _FeatureTileData(icon: Icons.key_outlined, label: 'POSSESSION', value: possessionText),
      _FeatureTileData(icon: Icons.explore_outlined, label: 'FACING', value: facingText),
      _FeatureTileData(icon: Icons.directions_car_outlined, label: 'PARKING', value: '${property.parking} Reserved'),
    ];

    return Container(
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20.0),
        border: Border.all(color: AppColors.border),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final columns = constraints.maxWidth >= 540.0 ? 4 : 2;
          const spacing = 12.0;
          final itemWidth = (constraints.maxWidth - (spacing * (columns - 1))) / columns;

          return Wrap(
            spacing: spacing,
            runSpacing: spacing,
            children: tiles.map((tile) {
              return SizedBox(
                width: itemWidth,
                child: _buildFeatureTileItem(icon: tile.icon, label: tile.label, value: tile.value),
              );
            }).toList(),
          );
        },
      ),
    );
  }

  Widget _buildFeatureTileItem({required IconData icon, required String label, required String value}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 12.0),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14.0),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(7.0),
            decoration: BoxDecoration(color: const Color(0xFFEFF6FF), borderRadius: BorderRadius.circular(10.0)),
            child: Icon(icon, color: const Color(0xFF3B82F6), size: 18.0),
          ),
          const SizedBox(width: 8.0),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 10.0,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textSecondary,
                    letterSpacing: 0.3,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2.0),
                Text(
                  value,
                  style: const TextStyle(fontSize: 13.0, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 3. ABOUT THIS PROPERTY CARD
  // ---------------------------------------------------------------------------
  Widget _buildAboutPropertyCard(PropertyModel property) {
    final desc = (property.propertyDescription != null && property.propertyDescription!.trim().isNotEmpty)
        ? property.propertyDescription!.trim()
        : 'Serene urban home with modern architecture, premium specifications, and custom fittings.';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24.0),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20.0),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'About This Property',
            style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 14.0),
          Text(desc, style: const TextStyle(fontSize: 14.0, color: Color(0xFF475569), height: 1.6)),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 4. AMENITIES & FACILITIES CARD
  // ---------------------------------------------------------------------------
  Widget _buildAmenitiesCard(BuildContext context, PropertyModel property) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24.0),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20.0),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Amenities & Facilities',
            style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 16.0),
          Wrap(
            spacing: 12.0,
            runSpacing: 12.0,
            children: property.amenities.map((amenity) {
              final localizedLabel = PropertyLocalizer.getLocalizedAmenity(context, amenity);
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12.0),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 16.0),
                    const SizedBox(width: 8.0),
                    Text(
                      localizedLabel,
                      style: const TextStyle(fontSize: 13.0, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 5. PROPERTY OVERVIEW CARD (3-Column Grid)
  // ---------------------------------------------------------------------------
  Widget _buildPropertyOverviewCard(BuildContext context, PropertyModel property) {
    final floorText = property.floorNumber != null
        ? '${property.floorNumber}th of ${property.totalFloors ?? 1} Floors'
        : (property.totalFloors != null ? '${property.totalFloors} Floors' : '-');

    final localityText = property.address?.landmark?.trim().isNotEmpty == true
        ? property.address!.landmark!
        : (property.address?.city ?? '-');

    final dateString = property.createdAt != null
        ? DateFormat('d MMMM yyyy').format(property.createdAt!)
        : '1 September 2026';

    final overviewItems = [
      _OverviewBox(label: 'PROPERTY CODE', value: '#${property.propertyCode ?? "JU1-001"}'),
      _OverviewBox(label: 'PROPERTY TYPE', value: property.propertyType.displayName.toUpperCase()),
      _OverviewBox(label: 'TRANSACTION', value: property.listingType.displayName),
      _OverviewBox(label: 'CITY', value: property.address?.city ?? 'Pune'),
      _OverviewBox(label: 'LOCALITY', value: localityText),
      _OverviewBox(label: 'FLOOR', value: floorText),
      _OverviewBox(label: 'FACING', value: '${property.facing?.displayName ?? "North East"} Facing'),
      _OverviewBox(label: 'FURNISHING', value: property.furnishingStatus.displayName.toUpperCase()),
      _OverviewBox(label: 'POSSESSION STATUS', value: property.constructionStatus.displayName.toUpperCase()),
      _OverviewBox(label: 'BALCONIES', value: '${property.balconies} Balconies'),
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24.0),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20.0),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Property Overview',
            style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 18.0),

          // Responsive Grid of Overview Boxes
          LayoutBuilder(
            builder: (context, constraints) {
              final columns = constraints.maxWidth >= 520.0 ? 3 : 2;
              const spacing = 12.0;
              final itemWidth = (constraints.maxWidth - (spacing * (columns - 1))) / columns;

              return Wrap(
                spacing: spacing,
                runSpacing: spacing,
                children: overviewItems.map((item) {
                  return SizedBox(
                    width: itemWidth,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 12.0),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(14.0),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.label,
                            style: const TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textSecondary,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 4.0),
                          Text(
                            item.value,
                            style: const TextStyle(
                              fontSize: 13.0,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              );
            },
          ),
          const SizedBox(height: 20.0),

          // Date Footer
          Row(
            children: [
              const Icon(Icons.calendar_today_outlined, size: 14.0, color: AppColors.textMuted),
              const SizedBox(width: 6.0),
              Text(
                'Listed on $dateString',
                style: const TextStyle(fontSize: 12.0, color: AppColors.textMuted, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // RIGHT COLUMN: POST PROPERTY, VIDEO REQUEST & MANAGE BUTTONS
  // ---------------------------------------------------------------------------
  Widget _buildSidebarPostPropertyCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20.0),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10.0),
                decoration: const BoxDecoration(color: Color(0xFFEFF6FF), shape: BoxShape.circle),
                child: const Icon(Icons.campaign_outlined, color: AppColors.primary, size: 22.0),
              ),
              const SizedBox(width: 12.0),
              Expanded(
                child: Text(
                  context.tr('post_property'),
                  style: AppTextStyles.heading3.copyWith(
                    fontWeight: FontWeight.w800,
                    fontSize: 16.0,
                    color: AppColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10.0),
          Text(
            context.tr('post_property_feature_desc'),
            style: AppTextStyles.body2.copyWith(color: AppColors.textSecondary, fontSize: 12.5, height: 1.45),
          ),
          const SizedBox(height: 18.0),
          SizedBox(
            width: double.infinity,
            child: AppButton.solid(
              iconData: Icons.campaign_outlined,
              text: context.tr('post_property'),
              color: AppColors.primary,
              height: 44.0,
              borderRadius: 12.0,
              onPressed: () => _openPostPropertyDialog(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarVideoRequestCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20.0),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10.0),
                decoration: const BoxDecoration(color: Color(0xFFEFF6FF), shape: BoxShape.circle),
                child: const Icon(Icons.videocam_outlined, color: AppColors.primary, size: 22.0),
              ),
              const SizedBox(width: 12.0),
              Expanded(
                child: Text(
                  context.tr('video_request'),
                  style: AppTextStyles.heading3.copyWith(
                    fontWeight: FontWeight.w800,
                    fontSize: 16.0,
                    color: AppColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10.0),
          Text(
            context.tr('video_request_feature_desc'),
            style: AppTextStyles.body2.copyWith(color: AppColors.textSecondary, fontSize: 12.5, height: 1.45),
          ),
          const SizedBox(height: 18.0),
          SizedBox(
            width: double.infinity,
            child: AppButton(
              variant: AppButtonVariant.secondary,
              iconData: Icons.videocam_outlined,
              text: context.tr('video_request'),
              height: 44.0,
              borderRadius: 12.0,
              onPressed: () => _openVideoRequestDialog(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarManageCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20.0),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Manage Property',
            style: TextStyle(fontSize: 16.0, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 6.0),
          const Text(
            'Edit property specifications or permanently remove this listing.',
            style: TextStyle(fontSize: 12.0, color: AppColors.textSecondary, height: 1.4),
          ),
          const SizedBox(height: 16.0),

          // Schedule Site Visit Button
          SizedBox(
            width: double.infinity,
            child: AppButton.solid(
              iconData: Icons.calendar_today_rounded,
              text: context.tr('schedule_site_visit'),
              color: AppColors.primary,
              height: 44.0,
              borderRadius: 12.0,
              onPressed: () {
                if (_property != null) {
                  showDialog(
                    context: context,
                    builder: (context) => ScheduleVisitDialog(preselectedProperty: _property),
                  );
                }
              },
            ),
          ),
          const SizedBox(height: 10.0),

          // Edit Button
          SizedBox(
            width: double.infinity,
            child: AppButton.outline(
              iconData: Icons.edit_outlined,
              text: 'Edit Property',
              height: 44.0,
              borderRadius: 12.0,
              onPressed: _onEditTap,
            ),
          ),
          const SizedBox(height: 10.0),

          // Delete Button
          SizedBox(
            width: double.infinity,
            child: AppButton.solid(
              iconData: Icons.delete_outline_rounded,
              text: 'Delete Property',
              color: AppColors.error,
              height: 44.0,
              borderRadius: 12.0,
              onPressed: () => _confirmAndDeleteProperty(context),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // MOBILE LAYOUT (Preserved intact)
  // ---------------------------------------------------------------------------
  List<Widget> _buildMobileAppBarActions(BuildContext context) {
    return [
      AppButton.outline(
        iconData: Icons.edit_outlined,
        width: 38.0,
        height: 38.0,
        borderRadius: 8.0,
        padding: EdgeInsets.zero,
        onPressed: _onEditTap,
      ),
      const SizedBox(width: 8.0),
      AppButton(
        variant: AppButtonVariant.danger,
        iconData: Icons.delete_outline_rounded,
        width: 38.0,
        height: 38.0,
        borderRadius: 8.0,
        padding: EdgeInsets.zero,
        onPressed: () => _confirmAndDeleteProperty(context),
      ),
      const SizedBox(width: 8.0),
    ];
  }

  Widget _buildMobileLayout(BuildContext context, PropertyModel property) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PropertyPreviewMediaGallery(medias: property.medias, height: 260.0),
        const SizedBox(height: 14.0),
        _buildMobileMainInfoCard(property),
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
        _buildActionFeatureCard(
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
        ),
        const SizedBox(height: 14.0),
        _buildActionFeatureCard(
          icon: Icons.calendar_month_outlined,
          color: AppColors.secondary,
          title: context.tr('site_visits'),
          description: context.tr('schedule_visit_subtitle'),
          actionButton: AppButton(
            variant: AppButtonVariant.secondary,
            iconData: Icons.calendar_today_rounded,
            text: context.tr('schedule_site_visit'),
            height: 44.0,
            borderRadius: 10.0,
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => ScheduleVisitDialog(preselectedProperty: property),
              );
            },
          ),
        ),
        const SizedBox(height: 30.0),
      ],
    );
  }

  Widget _buildMobileMainInfoCard(PropertyModel property) {
    final categoryLabel = PropertyLocalizer.getLocalizedPropertyType(context, property.propertyType);
    final listingLabel = PropertyLocalizer.getLocalizedListingType(context, property.listingType);
    final constStatusLabel = PropertyLocalizer.getLocalizedConstructionStatus(context, property.constructionStatus);
    final propertyStatusLabel = PropertyLocalizer.getLocalizedPropertyStatus(context, property.propertyStatus);

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
          Wrap(
            spacing: 8.0,
            runSpacing: 8.0,
            children: [
              if (property.propertyCode != null && property.propertyCode!.isNotEmpty)
                _buildBadge('${property.propertyCode}', AppColors.tagIndigo),
              _buildBadge(categoryLabel, AppColors.primary),
              _buildBadge(listingLabel, AppColors.secondary),
              _buildBadge(constStatusLabel, AppColors.success),
              _buildBadge(propertyStatusLabel, _statusColor(property.propertyStatus)),
            ],
          ),
          const SizedBox(height: 14.0),
          CurrencyText(
            amount: property.price,
            style: AppTextStyles.heading1.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w800,
              fontSize: 24.0,
            ),
          ),
          if (property.listingType == ListingType.rent)
            Text(context.tr('per_month'), style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary)),
          const SizedBox(height: 6.0),
          Text(property.propertyTitle, style: AppTextStyles.heading2.copyWith(fontWeight: FontWeight.bold)),
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

  Widget _buildSectionCard({required String title, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18.0),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18.0),
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

  Widget _buildStickyBottomPostBar(BuildContext context, {required bool isTablet}) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    return Container(
      padding: EdgeInsets.fromLTRB(16.0, 12.0, 16.0, 12.0 + (bottomPadding > 0 ? bottomPadding : 4.0)),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: const Border(top: BorderSide(color: AppColors.border, width: 1.0)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 12.0, offset: const Offset(0, -4)),
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
                  style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary, fontSize: 11.5, height: 1.35),
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
}

class _OverviewBox {
  final String label;
  final String value;

  const _OverviewBox({required this.label, required this.value});
}

class _FeatureTileData {
  final IconData icon;
  final String label;
  final String value;

  const _FeatureTileData({required this.icon, required this.label, required this.value});
}
