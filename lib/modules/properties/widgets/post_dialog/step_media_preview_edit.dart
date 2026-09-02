// File: lib/modules/properties/widgets/post_dialog/step_media_preview_edit.dart
// Purpose: Step 2 UI — previews selected media and exposes reel/post text overlay stickers.
//          Controllers are owned by the parent dialog (PostPropertyDialog) and pre-filled
//          from the generate-post-content edge function result. No local controller lifecycle.

import 'dart:convert';
import 'dart:io' as io;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../../../../app/app_colors.dart';
import '../../../../app/app_text_styles.dart';
import '../../../../models/property_model.dart';
import '../../../../providers/social/social_provider.dart';
import '../../../../util/common_ext.dart';
import '../../../../widgets/images/cached_image.dart';

class StepMediaPreviewEdit extends StatefulWidget {
  final PropertyModel? property;
  final List<PickedMedia> selectedMedia;
  final SocialProvider socialProvider;

  // Controllers owned & disposed by parent PostPropertyDialog.
  final TextEditingController titleBadgeController;
  final TextEditingController handleBadgeController;
  final TextEditingController locationBadgeController;
  final TextEditingController contactBadgeController;

  // Lifted state from parent for export.
  final String selectedTheme;
  final ValueChanged<String> onThemeChanged;
  final bool isTransparent;
  final ValueChanged<bool> onTransparentChanged;
  final bool enableOverlay;
  final ValueChanged<bool> onEnableOverlayChanged;

  final bool isExporting;

  const StepMediaPreviewEdit({
    super.key,
    required this.property,
    required this.selectedMedia,
    required this.socialProvider,
    required this.titleBadgeController,
    required this.handleBadgeController,
    required this.locationBadgeController,
    required this.contactBadgeController,
    required this.selectedTheme,
    required this.onThemeChanged,
    required this.isTransparent,
    required this.onTransparentChanged,
    required this.enableOverlay,
    required this.onEnableOverlayChanged,
    required this.isExporting,
  });

  @override
  State<StepMediaPreviewEdit> createState() => _StepMediaPreviewEditState();
}

class _StepMediaPreviewEditState extends State<StepMediaPreviewEdit> {
  int _currentMediaIndex = 0;

  // Convenience getters — delegate to widget-supplied controllers.
  TextEditingController get _titleBadgeController => widget.titleBadgeController;

  TextEditingController get _handleBadgeController => widget.handleBadgeController;

  TextEditingController get _locationBadgeController => widget.locationBadgeController;

  TextEditingController get _contactBadgeController => widget.contactBadgeController;

  // Lifted state accessors.
  String get _selectedTheme => widget.selectedTheme;

  bool get _enableOverlay => widget.enableOverlay;

  bool get _isTransparent => widget.isTransparent;

  // No initState controller creation or dispose needed — parent owns them.

  @override
  Widget build(BuildContext context) {
    if (widget.selectedMedia.isEmpty) {
      return Center(
        child: Text(
          'No media selected. Please go back to select photos or videos.',
          style: AppTextStyles.body2.copyWith(color: AppColors.textSecondary),
        ),
      );
    }

    final currentMedia = widget.selectedMedia[_currentMediaIndex];
    final pathLower = currentMedia.path.toLowerCase();
    final isImgExt =
        pathLower.endsWith('.jpg') ||
        pathLower.endsWith('.jpeg') ||
        pathLower.endsWith('.png') ||
        pathLower.endsWith('.webp') ||
        pathLower.endsWith('.gif');
    final isVideo =
        !isImgExt &&
        (currentMedia.type.toLowerCase() == 'video' ||
            pathLower.endsWith('.mp4') ||
            pathLower.endsWith('.mov'));

    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 600;

    return SingleChildScrollView(
      padding: EdgeInsets.all(isDesktop ? 16.0 : 10.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Title
          Row(
            children: [
              const Icon(Icons.movie_edit, color: AppColors.primary, size: 18.0),
              const SizedBox(width: 6.0),
              Expanded(
                child: Text(
                  'Reel & Media Overlay Editor',
                  style: AppTextStyles.heading3.copyWith(fontWeight: FontWeight.bold, fontSize: 14.5),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 6.0),
              // AI pre-filled badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20.0),
                  border: Border.all(color: Colors.green.withValues(alpha: 0.4)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.auto_awesome, color: Colors.green, size: 12.0),
                    const SizedBox(width: 3.0),
                    Text(
                      'AI Filled',
                      style: AppTextStyles.caption.copyWith(
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                        fontSize: 10.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 4.0),
          Text(
            'Stickers are pre-filled by AI. Edit any field below, then tap Next.',
            style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary, fontSize: 11.5),
          ),
          const SizedBox(height: 14.0),

          // Main Editor Layout: Media Preview Box + Overlay Settings
          if (isDesktop)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Reel Preview Device Mockup Box
                SizedBox(width: 260.0, height: 440.0, child: _buildReelPreviewDevice(currentMedia, isVideo)),
                const SizedBox(width: 16.0),
                // Customization Controls Panel
                Expanded(child: _buildCustomizationControls()),
              ],
            )
          else
            Column(
              children: [
                // Reel Preview Device Mockup Box (Centered)
                Center(
                  child: SizedBox(
                    width: 240.0,
                    height: 400.0,
                    child: _buildReelPreviewDevice(currentMedia, isVideo),
                  ),
                ),
                const SizedBox(height: 16.0),
                // Customization Controls Panel
                _buildCustomizationControls(),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildReelPreviewDevice(PickedMedia media, bool isVideo) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(20.0),
        border: Border.all(color: AppColors.border, width: 2.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 16.0,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18.0),
        child: Stack(
          children: [
            // Media Background (Photo or Video Player)
            Positioned.fill(child: _buildMediaView(media, isVideo)),

            // Top Gradient Dimming
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: 90,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.black.withValues(alpha: 0.5), Colors.transparent],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ),

            // Bottom Gradient Dimming
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              height: 120,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.transparent, Colors.black.withValues(alpha: 0.6)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ),

            // Floating Text Stickers Stack Overlay
            if (_enableOverlay)
              Positioned.fill(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 16.0),
                  child: Column(
                    children: [
                      const SizedBox(height: 16.0),

                      // 1. Top Title & Sqft Sticker Badge (White card with bold dark text)
                      if (_titleBadgeController.text.trim().isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                          decoration: BoxDecoration(
                            color: _getThemeTitleBg(),
                            borderRadius: BorderRadius.circular(10.0),
                          ),
                          child: Text(
                            _titleBadgeController.text.trim(),
                            style: TextStyle(
                              color: _getThemeTitleTextColor(),
                              fontSize: 10.0,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.3,
                              height: 1.25,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),

                      const SizedBox(height: 6.0),

                      // 2. Sub-badge / Handle Pill (Blue pill badge)
                      if (_handleBadgeController.text.trim().isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 4.0),
                          decoration: BoxDecoration(
                            color: _getThemeHandleBg(),
                            borderRadius: BorderRadius.circular(6.0),
                          ),
                          child: Text(
                            _handleBadgeController.text.trim(),
                            style: TextStyle(
                              color: _getThemeHandleTextColor(),
                              fontSize: 9.0,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),

                      const Spacer(),

                      // 3. Location Badge (Dark Red / Burgundy Pill)
                      if (_locationBadgeController.text.trim().isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 5.0),
                          decoration: BoxDecoration(
                            color: _getThemeLocationBg(),
                            borderRadius: BorderRadius.circular(6.0),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.location_on_rounded,
                                size: 11.0,
                                color: _getThemeLocationTextColor(),
                              ),
                              const SizedBox(width: 4.0),
                              Text(
                                _locationBadgeController.text.trim(),
                                style: TextStyle(
                                  color: _getThemeLocationTextColor(),
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.4,
                                ),
                              ),
                            ],
                          ),
                        ),

                      const SizedBox(height: 5.0),

                      // 4. Contact Badge (Dark Red Pill)
                      if (_contactBadgeController.text.trim().isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
                          decoration: BoxDecoration(
                            color: _getThemeContactBg(),
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                          child: Text(
                            _contactBadgeController.text.trim(),
                            style: TextStyle(
                              color: _getThemeContactTextColor(),
                              fontSize: 9.0,
                              fontWeight: FontWeight.bold,
                              height: 1.2,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),

                      const SizedBox(height: 12.0),
                    ],
                  ),
                ),
              ),

            // Media Counter Navigator Badge (if multiple media)
            if (widget.selectedMedia.length > 1)
              Positioned(
                top: 10.0,
                right: 10.0,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  child: Text(
                    '${_currentMediaIndex + 1}/${widget.selectedMedia.length}',
                    style: const TextStyle(color: Colors.white, fontSize: 10.0, fontWeight: FontWeight.bold),
                  ),
                ),
              ),

            // Prev / Next Navigation Arrows for Carousel
            if (widget.selectedMedia.length > 1) ...[
              if (_currentMediaIndex > 0)
                Positioned(
                  left: 8.0,
                  top: 0,
                  bottom: 0,
                  child: Center(
                    child: InkWell(
                      onTap: () => setState(() => _currentMediaIndex--),
                      borderRadius: BorderRadius.circular(20.0),
                      child: Container(
                        padding: const EdgeInsets.all(7.0),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.45),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.chevron_left_rounded, color: Colors.white, size: 18.0),
                      ),
                    ),
                  ),
                ),
              if (_currentMediaIndex < widget.selectedMedia.length - 1)
                Positioned(
                  right: 8.0,
                  top: 0,
                  bottom: 0,
                  child: Center(
                    child: InkWell(
                      onTap: () => setState(() => _currentMediaIndex++),
                      borderRadius: BorderRadius.circular(20.0),
                      child: Container(
                        padding: const EdgeInsets.all(7.0),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.45),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.chevron_right_rounded, color: Colors.white, size: 18.0),
                      ),
                    ),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMediaView(PickedMedia media, bool isVideo) {
    if (isVideo) {
      return StepVideoPreviewWidget(
        key: ValueKey('preview_${media.path.hashCode}'),
        videoUrl: media.path,
        videoBytes: media.bytes,
      );
    }

    if (media.bytes.isNotEmpty) {
      return CachedImage(null, imageBytes: media.bytes, fit: BoxFit.cover);
    }

    if (media.path.startsWith('http')) {
      return CachedImage(media.path, fit: BoxFit.cover);
    }

    return Container(
      color: Colors.grey.shade900,
      child: const Center(child: Icon(Icons.image_rounded, color: Colors.white54, size: 36.0)),
    );
  }

  Widget _buildCustomizationControls() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Enable Overlay Switch
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(12.0),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              const Icon(Icons.layers_rounded, color: AppColors.primary, size: 18.0),
              const SizedBox(width: 8.0),
              Expanded(
                child: Text(
                  'Reel Text Overlay Stickers',
                  style: AppTextStyles.body2.copyWith(fontWeight: FontWeight.bold, fontSize: 13.0),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 4.0),
              Switch(
                value: _enableOverlay,
                activeThumbColor: AppColors.primary,
                onChanged: (val) => widget.onEnableOverlayChanged(val),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12.0),

        if (_enableOverlay) ...[
          // Theme Color Preset Selector
          Text('Sticker Color Style:', style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 6.0),
          Wrap(
            spacing: 8.0,
            runSpacing: 8.0,
            children: [
              _buildThemeOption('black', 'Black', Colors.black, Colors.black),
              _buildThemeOption('white', 'White', Colors.white, Colors.white),
              _buildThemeOption('classic', 'Classic', Colors.red.shade900, Colors.blue.shade700),
              _buildThemeOption('gold', 'Gold', AppColors.warning, AppColors.warningDark),
              _buildThemeOption('minimal', 'Minimal', AppColors.primary, AppColors.primary800),
            ],
          ),
          const SizedBox(height: 8.0),

          // Transparent Badges Checkbox
          InkWell(
            onTap: () => widget.onTransparentChanged(!_isTransparent),
            borderRadius: BorderRadius.circular(8.0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  height: 22.0,
                  width: 22.0,
                  child: Checkbox(
                    value: _isTransparent,
                    activeColor: AppColors.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4.0)),
                    onChanged: (val) => widget.onTransparentChanged(val ?? false),
                  ),
                ),
                const SizedBox(width: 8.0),
                Text(
                  'Transparent Badges',
                  style: AppTextStyles.caption.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 11.0,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14.0),

          // Sticker 1: Main Header Title
          _buildTextFieldInput(
            controller: _titleBadgeController,
            label: 'Top Header Badge (Title & Sqft)',
            icon: Icons.title_rounded,
            maxLines: 2,
          ),
          const SizedBox(height: 10.0),

          // Sticker 2: Handle Pill
          _buildTextFieldInput(
            controller: _handleBadgeController,
            label: 'Instagram / Brand Handle Tag',
            icon: Icons.alternate_email_rounded,
            maxLines: 1,
          ),
          const SizedBox(height: 10.0),

          // Sticker 3: Location Pin Badge
          _buildTextFieldInput(
            controller: _locationBadgeController,
            label: 'Location Pin Text',
            icon: Icons.location_on_rounded,
            maxLines: 1,
          ),
          const SizedBox(height: 10.0),

          // Sticker 4: Contact Badge
          _buildTextFieldInput(
            controller: _contactBadgeController,
            label: 'Bottom Contact Info Badge',
            icon: Icons.phone_rounded,
            maxLines: 2,
          ),
        ],
      ],
    ).disable(isDisable: widget.isExporting);
  }

  Widget _buildThemeOption(String id, String name, Color c1, Color c2) {
    final isSelected = _selectedTheme == id;
    return InkWell(
      onTap: () => widget.onThemeChanged(id),
      borderRadius: BorderRadius.circular(8.0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 6.0),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withValues(alpha: 0.1) : AppColors.surface,
          borderRadius: BorderRadius.circular(8.0),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: 1.5, // fixed — same for both states so size never changes
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 12.0,
              height: 12.0,
              decoration: BoxDecoration(
                color: c1,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.grey.shade400, width: 0.8),
              ),
            ),
            const SizedBox(width: 4.0),
            Text(
              name,
              style: TextStyle(
                fontSize: 11.0,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? AppColors.primary : AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextFieldInput({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.bold, fontSize: 11.0)),
        const SizedBox(height: 4.0),
        TextField(
          controller: controller,
          maxLines: maxLines,
          style: AppTextStyles.body2.copyWith(fontSize: 12.0),
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 8.0),
            prefixIcon: Icon(icon, size: 16.0, color: AppColors.primary),
            fillColor: AppColors.surface,
            filled: true,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.0),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.0),
              borderSide: const BorderSide(color: AppColors.primary),
            ),
          ),
        ),
      ],
    );
  }

  Color _getThemeTitleBg() {
    Color baseColor;
    switch (_selectedTheme) {
      case 'black':
        baseColor = Colors.black;
        break;
      case 'gold':
        baseColor = AppColors.posterGoldLight;
        break;
      case 'minimal':
        baseColor = AppColors.surface;
        break;
      case 'white':
        baseColor = Colors.white;
        break;
      case 'classic':
      default:
        baseColor = Colors.white;
        break;
    }
    return _isTransparent ? baseColor.withValues(alpha: 0.25) : baseColor;
  }

  Color _getThemeTitleTextColor() {
    switch (_selectedTheme) {
      case 'black':
        return Colors.white;
      case 'gold':
        return AppColors.statusWarningDarkText;
      case 'minimal':
        return AppColors.textPrimary;
      case 'white':
        return Colors.black;
      case 'classic':
      default:
        return Colors.black;
    }
  }

  Color _getThemeHandleBg() {
    Color baseColor;
    switch (_selectedTheme) {
      case 'black':
        baseColor = Colors.black;
        break;
      case 'gold':
        baseColor = AppColors.warning;
        break;
      case 'minimal':
        baseColor = AppColors.primary;
        break;
      case 'white':
        baseColor = Colors.white;
        break;
      case 'classic':
      default:
        baseColor = AppColors.posterBlueSoft; // Soft blue
        break;
    }
    return _isTransparent ? baseColor.withValues(alpha: 0.25) : baseColor;
  }

  Color _getThemeHandleTextColor() {
    switch (_selectedTheme) {
      case 'white':
        return Colors.black;
      case 'black':
        return Colors.white;
      default:
        return Colors.white;
    }
  }

  Color _getThemeLocationBg() {
    Color baseColor;
    switch (_selectedTheme) {
      case 'black':
        baseColor = Colors.black;
        break;
      case 'gold':
        baseColor = AppColors.warningDark;
        break;
      case 'minimal':
        baseColor = AppColors.primary;
        break;
      case 'white':
        baseColor = Colors.white;
        break;
      case 'classic':
      default:
        baseColor = AppColors.posterBurgundy; // Dark red / Burgundy
        break;
    }
    return _isTransparent ? baseColor.withValues(alpha: 0.25) : baseColor;
  }

  Color _getThemeLocationTextColor() {
    switch (_selectedTheme) {
      case 'white':
        return Colors.black;
      case 'black':
        return Colors.white;
      default:
        return Colors.white;
    }
  }

  Color _getThemeContactBg() {
    Color baseColor;
    switch (_selectedTheme) {
      case 'black':
        baseColor = Colors.black;
        break;
      case 'gold':
        baseColor = AppColors.posterGoldBrown;
        break;
      case 'minimal':
        baseColor = AppColors.primary800;
        break;
      case 'white':
        baseColor = Colors.white;
        break;
      case 'classic':
      default:
        baseColor = AppColors.posterRoseRed; // Deep rose red
        break;
    }
    return _isTransparent ? baseColor.withValues(alpha: 0.25) : baseColor;
  }

  Color _getThemeContactTextColor() {
    switch (_selectedTheme) {
      case 'white':
        return Colors.black;
      case 'black':
        return Colors.white;
      default:
        return Colors.white;
    }
  }
}

class StepVideoPreviewWidget extends StatefulWidget {
  final String videoUrl;
  final Uint8List? videoBytes;

  const StepVideoPreviewWidget({super.key, required this.videoUrl, this.videoBytes});

  @override
  State<StepVideoPreviewWidget> createState() => _StepVideoPreviewWidgetState();
}

class _StepVideoPreviewWidgetState extends State<StepVideoPreviewWidget> {
  VideoPlayerController? _controller;
  bool _isInitialized = false;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  Future<void> _initializePlayer() async {
    try {
      final controller = kIsWeb && widget.videoBytes != null && widget.videoBytes!.isNotEmpty
          ? VideoPlayerController.networkUrl(
              Uri.parse('data:video/mp4;base64,${base64Encode(widget.videoBytes!)}'),
            )
          : (widget.videoUrl.startsWith('http')
                ? VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl))
                : VideoPlayerController.file(io.File(widget.videoUrl)));

      _controller = controller;
      await controller.initialize();
      controller.setLooping(true);
      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    } catch (e) {
      debugPrint('Error initializing video preview player: $e');
      if (mounted) {
        setState(() {
          _hasError = true;
        });
      }
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return Container(
        color: Colors.black87,
        child: const Center(child: Icon(Icons.videocam_off_rounded, color: Colors.white54, size: 36.0)),
      );
    }

    if (!_isInitialized || _controller == null) {
      return const Center(
        child: SizedBox(
          width: 24.0,
          height: 24.0,
          child: CircularProgressIndicator(
            strokeWidth: 2.5,
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
          ),
        ),
      );
    }

    final isPlaying = _controller!.value.isPlaying;

    return GestureDetector(
      onTap: () {
        setState(() {
          if (isPlaying) {
            _controller!.pause();
          } else {
            _controller!.play();
          }
        });
      },
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned.fill(
            child: FittedBox(
              fit: BoxFit.cover,
              clipBehavior: Clip.hardEdge,
              child: SizedBox(
                width: _controller!.value.size.width,
                height: _controller!.value.size.height,
                child: VideoPlayer(_controller!),
              ),
            ),
          ),
          if (!isPlaying)
            Container(
              padding: const EdgeInsets.all(12.0),
              decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.5), shape: BoxShape.circle),
              child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 32.0),
            ),
        ],
      ),
    );
  }
}
