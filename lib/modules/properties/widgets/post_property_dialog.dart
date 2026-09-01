// File: lib/modules/properties/widgets/post_property_dialog.dart
// Purpose: Multi-step social posting dialog (Platform → Media → Overlay Editor → Caption → Publishing).
//          All social content is generated ONCE when the user advances from the Media step.
//          Generated data persists in dialog state; going back never triggers a re-fetch.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../app/app_colors.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../models/property_model.dart';
import '../../../providers/auth/auth_provider.dart';
import '../../../providers/social/social_provider.dart';
import '../../../widgets/buttons/app_button.dart';
import '../../../widgets/dialogs/app_base_dialog.dart';
import '../../../widgets/toast/app_toast.dart';
import '../services/media_export_service.dart';
import '../services/post_content_service.dart';
import 'post_dialog/step_caption_review.dart';
import 'post_dialog/step_media_preview_edit.dart';
import 'post_dialog/step_media_selection.dart';
import 'post_dialog/step_platform_selection.dart';
import 'post_dialog/step_publishing_progress.dart';

class PostPropertyDialog extends StatefulWidget {
  final PropertyModel? property;
  final String brokerId;

  const PostPropertyDialog({super.key, this.property, required this.brokerId});

  @override
  State<PostPropertyDialog> createState() => _PostPropertyDialogState();
}

class _PostPropertyDialogState extends State<PostPropertyDialog> {
  // ── Step tracking ───────────────────────────────────────────────────────
  // 0: Platform Selection
  // 1: Media Selection
  // 2: Overlay / Reel Editor
  // 3: Caption Review
  // 4: Publishing Progress
  int _currentStep = 0;

  // ── Platform selection ──────────────────────────────────────────────────
  bool _selectInstagram = true;
  bool _selectFacebook = false;
  String? _connectionErrorMessage;

  // ── Media ───────────────────────────────────────────────────────────────
  final List<PickedMedia> _selectedMedia = [];
  final List<PickedMedia> _exportedMedia = [];

  // ── Sticker & Theme Settings ─────────────────────────────────────────────
  String _selectedTheme = 'black';
  bool _isTransparent = false;
  bool _enableOverlay = true;
  bool _isExporting = false;
  double _exportProgress = 0.0;

  // ── Generated content (single fetch, persisted until dialog closes) ─────
  bool _isFetchingContent = false;
  bool _isPublishing = false;
  PostContentResult? _postContent;

  // Caption controller — driven by _postContent.caption but freely editable.
  late TextEditingController _captionController;

  // Sticker overlay controllers — driven by _postContent, freely editable.
  late TextEditingController _titleBadgeController;
  late TextEditingController _handleBadgeController;
  late TextEditingController _locationBadgeController;
  late TextEditingController _contactBadgeController;

  @override
  void initState() {
    super.initState();

    final socialProvider = Provider.of<SocialProvider>(context, listen: false);
    _selectInstagram = socialProvider.isInstagramConnected;
    _selectFacebook = socialProvider.isFacebookConnected;
    if (!_selectInstagram && !_selectFacebook) _selectInstagram = true;

    _captionController = TextEditingController();
    _titleBadgeController = TextEditingController();
    _handleBadgeController = TextEditingController();
    _locationBadgeController = TextEditingController();
    _contactBadgeController = TextEditingController();
  }

  @override
  void dispose() {
    _captionController.dispose();
    _titleBadgeController.dispose();
    _handleBadgeController.dispose();
    _locationBadgeController.dispose();
    _contactBadgeController.dispose();
    super.dispose();
  }

  // ── Step transition helpers ─────────────────────────────────────────────

  void _validatePlatformStep() {
    setState(() => _connectionErrorMessage = null);

    if (!_selectInstagram && !_selectFacebook) {
      AppToast.showError(context.tr('select_platform'), context.tr('select_platform_error'));
      return;
    }

    final sp = Provider.of<SocialProvider>(context, listen: false);
    final missing = <String>[];
    if (_selectInstagram && !sp.isInstagramConnected) {
      missing.add('Instagram Account');
    }
    if (_selectFacebook && !sp.isFacebookConnected) {
      missing.add('Facebook Page');
    }

    if (missing.isNotEmpty) {
      final errText =
          'Cannot proceed: ${missing.join(" and ")} not connected. Go to Home Dashboard to connect.';
      setState(() => _connectionErrorMessage = errText);
      AppToast.showError('Account Not Connected', errText);
      return;
    }

    setState(() => _currentStep = 1);
  }

  /// Called when the user presses Next on the Media step.
  /// Generates content ONCE; if already generated, just advances.
  Future<void> _validateMediaStep() async {
    if (_selectedMedia.isEmpty) {
      AppToast.showError(context.tr('select_media'), context.tr('select_media_error'));
      return;
    }

    final videoCount = _selectedMedia.where((m) => m.type == 'video').length;
    if (_selectFacebook && videoCount > 1) {
      AppToast.showError(
        'Facebook Video Limit',
        'Facebook supports at most 1 video per post. Please select 1 video or uncheck Facebook in the first step.',
      );
      return;
    }

    // Already fetched — skip to overlay editor immediately.
    if (_postContent != null) {
      setState(() => _currentStep = 2);
      return;
    }

    setState(() => _isFetchingContent = true);
    try {
      final sp = Provider.of<SocialProvider>(context, listen: false);
      final ap = Provider.of<AuthProvider>(context, listen: false);

      final result = await PostContentService.generate(
        property: widget.property,
        socialProvider: sp,
        localBrokerPhone: ap.userProfile?.phone,
        localBrokerName: ap.userProfile?.name,
      );

      if (!mounted) return;

      _postContent = result;

      // Populate text editing controllers ONCE.
      _captionController.text = result.caption;
      _titleBadgeController.text = result.topHeader;
      _handleBadgeController.text = result.instagramHandle;
      _locationBadgeController.text = result.location;
      _contactBadgeController.text = result.bottomContact;

      setState(() => _currentStep = 2);
    } catch (e) {
      debugPrint('Post content generation failed: $e');
      if (mounted) {
        AppToast.showError('Generation Failed', 'Could not generate post content. Please try again.');
      }
    } finally {
      if (mounted) setState(() => _isFetchingContent = false);
    }
  }

  /// Called when advancing from step 2 (Overlay Editor) -> step 3 (Caption Review).
  /// Flattens the active sticker configuration directly onto each picked media file
  /// so that published posts have the overlay permanently burned in.
  Future<void> _exportEditedMedia() async {
    if (_isExporting) return;

    setState(() {
      _isExporting = true;
      _exportProgress = 0.0;
    });

    try {
      final config = StickerConfig(
        titleText: _titleBadgeController.text,
        handleText: _handleBadgeController.text,
        locationText: _locationBadgeController.text,
        contactText: _contactBadgeController.text,
        theme: _selectedTheme,
        isTransparent: _isTransparent,
        enableOverlay: _enableOverlay,
      );

      final result = await MediaExportService.exportAll(
        mediaList: _selectedMedia,
        config: config,
        onProgress: (progress) {
          if (mounted) {
            setState(() {
              _exportProgress = progress;
            });
          }
        },
      );

      if (!mounted) return;

      setState(() {
        _exportedMedia.clear();
        _exportedMedia.addAll(result);
        _isExporting = false;
        _currentStep = 3;
      });
    } catch (e) {
      debugPrint('[PostPropertyDialog] Media export failed: $e');
      if (mounted) {
        setState(() => _isExporting = false);
        AppToast.showError('Overlay Export Failed', e.toString());
      }
    }
  }

  Future<void> _handlePublish() async {
    final mediaToPublish = List<PickedMedia>.from(
      _exportedMedia.isNotEmpty ? _exportedMedia : _selectedMedia,
    );

    if (mediaToPublish.isEmpty) {
      AppToast.showError(context.tr('select_media'), context.tr('select_media_error'));
      return;
    }

    final finalCaption = _captionController.text.trim();
    if (finalCaption.isEmpty) {
      AppToast.showError('Empty Caption', 'Please enter or generate a caption before publishing.');
      return;
    }

    setState(() {
      _isPublishing = true;
    });

    final sp = Provider.of<SocialProvider>(context, listen: false);

    bool instagramSuccess = true;
    bool facebookSuccess = true;

    try {
      if (_selectInstagram) {
        instagramSuccess = await sp.publishInstagramPost(
          brokerId: widget.brokerId,
          propertyId: widget.property?.id,
          caption: finalCaption,
          medias: mediaToPublish,
        );
      }

      if (mounted && instagramSuccess && _selectFacebook) {
        facebookSuccess = await sp.publishFacebookPost(
          brokerId: widget.brokerId,
          propertyId: widget.property?.id,
          caption: finalCaption,
          medias: mediaToPublish,
        );
      }

      if (!mounted) return;

      if (instagramSuccess && facebookSuccess) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      debugPrint('Error publishing post: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isPublishing = false;
        });
      }
    }
  }

  // ── Build ───────────────────────────────────────────────────────────────

  // ── Build ───────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final socialProvider = Provider.of<SocialProvider>(context);

    return AppBaseDialog(
      headerIcon: Icons.campaign_rounded,
      title: context.tr('post_property_title'),
      subtitle: context.tr('post_property_subtitle'),
      maxWidth: 620.0,
      isCloseDisabled: socialProvider.isPublishing || _isExporting,
      contentPadding: EdgeInsets.zero,
      isScrollable: false,
      footer: _currentStep < 4 ? _buildFooter() : null,
      content: Column(
        children: [
          if (_currentStep < 4)
            LinearProgressIndicator(
              value: (_currentStep + 1) / 4.0,
              backgroundColor: AppColors.primary.withValues(alpha: 0.1),
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
              minHeight: 3.5,
            ),
          Expanded(child: _buildStepContent(socialProvider)),
        ],
      ),
    );
  }

  Widget _buildStepContent(SocialProvider socialProvider) {
    switch (_currentStep) {
      case 0:
        return StepPlatformSelection(
          selectInstagram: _selectInstagram,
          selectFacebook: _selectFacebook,
          onSelectInstagramChanged: (val) => setState(() => _selectInstagram = val),
          onSelectFacebookChanged: (val) => setState(() => _selectFacebook = val),
          connectionErrorMessage: _connectionErrorMessage,
          brokerId: widget.brokerId,
          socialProvider: socialProvider,
          property: widget.property,
        );

      case 1:
        return StepMediaSelection(
          property: widget.property,
          selectedMedia: _selectedMedia,
          onMediaSelectionChanged: (updatedList) => setState(() {
            _selectedMedia.clear();
            _selectedMedia.addAll(updatedList);
          }),
        );

      case 2:
        return StepMediaPreviewEdit(
          property: widget.property,
          selectedMedia: _selectedMedia,
          socialProvider: socialProvider,
          titleBadgeController: _titleBadgeController,
          handleBadgeController: _handleBadgeController,
          locationBadgeController: _locationBadgeController,
          contactBadgeController: _contactBadgeController,
          selectedTheme: _selectedTheme,
          onThemeChanged: (theme) => setState(() => _selectedTheme = theme),
          isTransparent: _isTransparent,
          onTransparentChanged: (val) => setState(() => _isTransparent = val),
          enableOverlay: _enableOverlay,
          onEnableOverlayChanged: (val) => setState(() => _enableOverlay = val),
          isExporting: _isExporting,
        );

      case 3:
        return StepCaptionReview(
          captionController: _captionController,
          isGeneratingCaption: false,
          onRegenerateAICaption: () async {
            setState(() => _isFetchingContent = true);
            try {
              final sp = Provider.of<SocialProvider>(context, listen: false);
              final ap = Provider.of<AuthProvider>(context, listen: false);
              final result = await PostContentService.generate(
                property: widget.property,
                socialProvider: sp,
                localBrokerPhone: ap.userProfile?.phone,
                localBrokerName: ap.userProfile?.name,
              );
              if (!mounted) return;
              _postContent = result;
              _captionController.text = result.caption;
              _titleBadgeController.text = result.topHeader;
              _handleBadgeController.text = result.instagramHandle;
              _locationBadgeController.text = result.location;
              _contactBadgeController.text = result.bottomContact;
              setState(() {});
            } finally {
              if (mounted) setState(() => _isFetchingContent = false);
            }
          },
          selectedMedia: _exportedMedia.isNotEmpty ? _exportedMedia : _selectedMedia,
          selectInstagram: _selectInstagram,
          selectFacebook: _selectFacebook,
        );

      case 4:
        return StepPublishingProgress(socialProvider: socialProvider);

      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildFooter() {
    final socialProvider = Provider.of<SocialProvider>(context);
    final isPublishing = _isPublishing || socialProvider.isPublishing;
    final isNextLoading =
        (_isFetchingContent && _currentStep == 1) ||
        (_isExporting && _currentStep == 2) ||
        (isPublishing && _currentStep == 3);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        if (_currentStep == 0)
          AppButton.outline(
            text: context.tr('cancel'),
            height: 42.0,
            borderRadius: 10.0,
            onPressed: (isNextLoading || isPublishing) ? null : () => Navigator.of(context).pop(),
          )
        else
          AppButton.outline(
            text: context.tr('back'),
            iconData: Icons.chevron_left_rounded,
            height: 42.0,
            borderRadius: 10.0,
            onPressed: (isNextLoading || isPublishing) ? null : () => setState(() => _currentStep--),
          ),

        AppButton(
          text: isPublishing
              ? 'Publishing...'
              : (_currentStep == 3
                    ? context.tr('publish_now')
                    : (_isExporting && _currentStep == 2
                          ? 'Exporting (${(_exportProgress * 100).round()}%)'
                          : (_isFetchingContent && _currentStep == 1
                                ? 'Generating...'
                                : context.tr('next')))),
          iconData: (isPublishing || (_isExporting && _currentStep == 2))
              ? null
              : (_currentStep == 3 ? Icons.send_rounded : Icons.chevron_right_rounded),
          height: 42.0,
          borderRadius: 10.0,
          isLoading: isNextLoading && !(_isExporting && _currentStep == 2),
          isDisabled:
              isPublishing ||
              (_isExporting && _currentStep == 2) ||
              (_currentStep == 0 && (!_selectInstagram && !_selectFacebook)) ||
              (_currentStep == 1 && _selectedMedia.isEmpty),
          onPressed: (isPublishing || (_isExporting && _currentStep == 2))
              ? null
              : () {
                  if (_currentStep == 0) {
                    _validatePlatformStep();
                  } else if (_currentStep == 1) {
                    _validateMediaStep();
                  } else if (_currentStep == 2) {
                    _exportEditedMedia();
                  } else if (_currentStep == 3) {
                    _handlePublish();
                  }
                },
        ),
      ],
    );
  }
}
