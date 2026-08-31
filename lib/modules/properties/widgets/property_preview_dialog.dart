// File: lib/modules/properties/widgets/property_preview_dialog.dart
// Purpose: A standalone premium dialog for reviewing listing details and managing multi-stage uploads.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/services/supabase_storage_service.dart';
import '../../../app/app_colors.dart';
import '../../../app/app_text_styles.dart';
import '../../../models/property_model.dart';
import '../../../models/media_model.dart';
import '../../../providers/auth/auth_provider.dart';
import '../../../providers/property/property_provider.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/localization/property_localizer.dart';
import '../../../widgets/toast/app_toast.dart';
import './property_preview_media_gallery.dart';
import './property_preview_specs_grid.dart';
import './property_preview_buttons.dart';
import './property_location_card.dart';
import './property_amenities_wrap.dart';
import 'package:flutter/foundation.dart';
import '../../../core/utils/video_thumbnail_helper.dart';
import '../screens/view_property_screen.dart';
import '../../../app/app_routes.dart';
import '../../../widgets/dialogs/app_base_dialog.dart';
import '../../../widgets/buttons/app_button.dart';

class PropertyPreviewDialog extends StatefulWidget {
  final PropertyModel property;
  final bool isEdit;
  final PropertyProvider propertyProvider;
  final ValueChanged<PropertyModel?> onSuccess;

  const PropertyPreviewDialog({
    super.key,
    required this.property,
    required this.isEdit,
    required this.propertyProvider,
    required this.onSuccess,
  });

  @override
  State<PropertyPreviewDialog> createState() => _PropertyPreviewDialogState();
}

class _PropertyPreviewDialogState extends State<PropertyPreviewDialog> {
  String _uploadStatusText = "";
  bool _isPublishing = false;

  bool _showSuccessScreen = false;
  PropertyModel? _savedProperty;

  Future<String> _uploadFileToSupabase(
    String bucketName,
    String path,
    Uint8List bytes,
    String mimeType,
  ) async {
    final publicUrl = await SupabaseStorageService.uploadFile(
      filePath: path,
      bucketName: bucketName,
      customFileName: path.contains('/') ? path.split('/').last : path,
      folderName: path.contains('/') ? path.split('/').first : null,
      fileBytes: bytes,
    );
    return publicUrl ?? '';
  }

  Future<void> _uploadAndSaveProperty(BuildContext dialogContext) async {
    final isEdit = widget.isEdit;
    final property = widget.property;
    final authProvider = Provider.of<AuthProvider>(dialogContext, listen: false);

    final successTitle = isEdit
        ? dialogContext.tr('toast_property_updated_title')
        : dialogContext.tr('toast_property_published_title');
    final successDesc = isEdit
        ? dialogContext.tr('toast_property_updated_desc')
        : dialogContext.tr('toast_property_published_desc');
    final saveFailedTitle = dialogContext.tr('save_failed');
    final genericErrorText = dialogContext.tr('error_generic');

    try {
      final updatedMedias = <MediaModel>[];
      final totalMedias = property.medias.length;
      final bucketName = 'property_media';

      for (int i = 0; i < totalMedias; i++) {
        final media = property.medias[i];

        if (media.bytes != null) {
          setState(() {
            _uploadStatusText = "Uploading media ${i + 1} of $totalMedias...";
          });

          final ext = media.type == 'video' ? 'mp4' : 'jpg';
          final mimeType = media.type == 'video' ? 'video/mp4' : 'image/jpeg';
          final uniqueName =
              '${DateTime.now().millisecondsSinceEpoch}_$i.$ext';
          final path = 'listings/$uniqueName';

          final publicUrl = await _uploadFileToSupabase(
            bucketName,
            path,
            media.bytes!,
            mimeType,
          );

          String? thumbUrl;
          if (media.type == 'video') {
            Uint8List? thumbBytes = media.thumbnailBytes;
            if (thumbBytes == null && !kIsWeb && media.url != null && !media.url!.startsWith('http')) {
              thumbBytes = await VideoThumbnailHelper.generateThumbnail(filePath: media.url!);
            }
            if (thumbBytes != null) {
              setState(() {
                _uploadStatusText = "Uploading video thumbnail...";
              });
              final thumbName =
                  'thumb_${DateTime.now().millisecondsSinceEpoch}_$i.jpg';
              final thumbPath = 'listings/$thumbName';
              thumbUrl = await _uploadFileToSupabase(
                bucketName,
                thumbPath,
                thumbBytes,
                'image/jpeg',
              );
            }
          }

          updatedMedias.add(MediaModel(
            type: media.type,
            url: publicUrl,
            thumbnail: thumbUrl,
          ));
        } else {
          updatedMedias.add(media);
        }
      }

      setState(() {
        _uploadStatusText = "Saving property to server...";
      });

      final finalProperty = property.copyWith(
        medias: updatedMedias,
      );

      final savedProperty = await widget.propertyProvider.saveProperty(
        finalProperty,
        isEdit: isEdit,
        authProvider: authProvider,
      );

      if (!mounted) return;

      if (savedProperty != null) {
        setState(() {
          _uploadStatusText = "Published successfully!";
          _savedProperty = savedProperty;
          _showSuccessScreen = true;
        });
        AppToast.showSuccess(successTitle, successDesc);
      } else {
        final err = widget.propertyProvider.errorMessage ?? genericErrorText;
        AppToast.showError(saveFailedTitle, err);
        setState(() {
          _isPublishing = false;
        });
      }
    } catch (e) {
      debugPrint("Error publishing property: $e");
      if (mounted) {
        AppToast.showError("Publishing Error", e.toString());
        setState(() {
          _isPublishing = false;
        });
      }
    }
  }

  void _onViewPropertyPressed() {
    if (_savedProperty == null) return;
    final savedProp = _savedProperty!;

    // Close the preview dialog
    Navigator.of(context).pop();

    if (widget.isEdit) {
      widget.onSuccess(savedProp);
    } else {
      widget.onSuccess(null);
    }

    final navContext = AppRoutes.rootNavigatorKey.currentContext;
    if (navContext != null) {
      Navigator.of(navContext).push(
        MaterialPageRoute(
          builder: (context) => ViewPropertyScreen(property: savedProp),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final property = _savedProperty ?? widget.property;

    if (_showSuccessScreen) {
      return Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.0)),
        backgroundColor: AppColors.surface,
        elevation: 24,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480.0),
          child: Padding(
            padding: const EdgeInsets.all(28.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_circle_outline_rounded,
                    color: Colors.green,
                    size: 54.0,
                  ),
                ),
                const SizedBox(height: 24.0),
                Text(
                  widget.isEdit ? context.tr('listing_updated_title') : context.tr('listing_published_title'),
                  style: AppTextStyles.heading2.copyWith(fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12.0),
                Text(
                  widget.isEdit
                      ? context.tr('listing_updated_desc')
                      : context.tr('listing_published_desc'),
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 13.5),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24.0),
                SizedBox(
                  width: double.infinity,
                  child: AppButton.solid(
                    text: context.tr('view_property'),
                    height: 48.0,
                    borderRadius: 12.0,
                    color: AppColors.primary,
                    onPressed: _onViewPropertyPressed,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final double priceVal = property.price;
    final formattedPrice =
        '₹ ${priceVal.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}';

    final categoryLabel = PropertyLocalizer.getLocalizedPropertyType(
        context, property.propertyType);
    final listingLabel = PropertyLocalizer.getLocalizedListingType(
        context, property.listingType);
    final constStatusLabel =
        PropertyLocalizer.getLocalizedConstructionStatus(
            context, property.constructionStatus);
    final furnishLabel =
        PropertyLocalizer.getLocalizedFurnishingStatus(
            context, property.furnishingStatus);

    return AppBaseDialog(
      headerIcon: Icons.rate_review_rounded,
      title: context.tr('listing_preview'),
      isCloseDisabled: _isPublishing,
      footer: PropertyPreviewButtons(
        isPublishing: _isPublishing,
        uploadStatusText: _uploadStatusText,
        isEdit: widget.isEdit,
        onCancel: () => Navigator.of(context).pop(),
        onConfirm: () async {
          setState(() {
            _isPublishing = true;
            _uploadStatusText = "Initializing publish...";
          });
          await _uploadAndSaveProperty(context);
        },
      ),
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PropertyPreviewMediaGallery(medias: property.medias),
          const SizedBox(height: 20.0),
          Wrap(
            spacing: 8.0,
            runSpacing: 8.0,
            children: [
              _buildBadge(context, categoryLabel, AppColors.primary),
              _buildBadge(context, listingLabel, Colors.orange),
              _buildBadge(context, constStatusLabel, Colors.green),
              if (furnishLabel.isNotEmpty)
                _buildBadge(context, furnishLabel, Colors.teal),
            ],
          ),
          const SizedBox(height: 16.0),
          Text(
            formattedPrice,
            style: AppTextStyles.heading1.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4.0),
          Text(
            property.propertyTitle,
            style: AppTextStyles.heading3.copyWith(fontWeight: FontWeight.bold),
          ),
          if (property.propertyDescription != null &&
              property.propertyDescription!.isNotEmpty) ...[
            const SizedBox(height: 12.0),
            Text(
              property.propertyDescription!,
              style: AppTextStyles.body2.copyWith(color: AppColors.textSecondary),
            ),
          ],
          const SizedBox(height: 20.0),
          PropertyPreviewSpecsGrid(property: property),
          const SizedBox(height: 20.0),
          PropertyLocationCard(address: property.address),
          const SizedBox(height: 20.0),
          if (property.amenities.isNotEmpty) ...[
            PropertyAmenitiesWrap(amenities: property.amenities),
            const SizedBox(height: 20.0),
          ],
        ],
      ),
    );
  }

  Widget _buildBadge(BuildContext context, String text, Color color) {
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
            color: color, fontWeight: FontWeight.bold, fontSize: 11.0),
      ),
    );
  }
}
