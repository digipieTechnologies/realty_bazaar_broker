// File: lib/modules/properties/widgets/post_dialog/step_caption_review.dart
// Purpose: Step 3 UI for Gemini AI caption review and media summary. Matches Step 2's side-by-side desktop layout.

import 'package:flutter/material.dart';
import '../../../../app/app_colors.dart';
import '../../../../app/app_text_styles.dart';
import '../../../../providers/social/social_provider.dart';
import '../../../../widgets/images/cached_image.dart';
import '../../../../models/media_model.dart';
import '../../../../widgets/media/full_screen_media_viewer.dart';
import 'step_media_preview_edit.dart';

class StepCaptionReview extends StatefulWidget {
  final TextEditingController captionController;
  final bool isGeneratingCaption;
  final VoidCallback onRegenerateAICaption;
  final List<PickedMedia> selectedMedia;
  final bool selectInstagram;
  final bool selectFacebook;

  const StepCaptionReview({
    super.key,
    required this.captionController,
    required this.isGeneratingCaption,
    required this.onRegenerateAICaption,
    required this.selectedMedia,
    required this.selectInstagram,
    required this.selectFacebook,
  });

  @override
  State<StepCaptionReview> createState() => _StepCaptionReviewState();
}

class _StepCaptionReviewState extends State<StepCaptionReview> {
  int _currentMediaIndex = 0;

  @override
  Widget build(BuildContext context) {
    if (widget.selectedMedia.isEmpty) {
      return Center(
        child: Text(
          'No media selected.',
          style: AppTextStyles.body2.copyWith(color: AppColors.textSecondary),
        ),
      );
    }

    // Clamp index just in case the list changed
    if (_currentMediaIndex >= widget.selectedMedia.length) {
      _currentMediaIndex = 0;
    }

    final currentMedia = widget.selectedMedia[_currentMediaIndex];
    final pathLower = currentMedia.path.toLowerCase();
    final isImgExt = pathLower.endsWith('.jpg') ||
        pathLower.endsWith('.jpeg') ||
        pathLower.endsWith('.png') ||
        pathLower.endsWith('.webp') ||
        pathLower.endsWith('.gif');
    final isVideo = !isImgExt &&
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
          // Section Title Row
          Row(
            children: [
              const Icon(Icons.rate_review_rounded, color: AppColors.primary, size: 18.0),
              const SizedBox(width: 6.0),
              Expanded(
                child: Text(
                  'Review Captions & Media',
                  style: AppTextStyles.heading3.copyWith(fontWeight: FontWeight.bold, fontSize: 14.5),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12.0),

          // Main Editor Layout: Media Preview Box + Information Panel
          if (isDesktop)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Reel Preview Device Mockup Box
                SizedBox(
                  width: 260.0,
                  height: 440.0,
                  child: _buildReelPreviewDevice(currentMedia, isVideo),
                ),
                const SizedBox(width: 16.0),
                // Customization Controls Panel
                Expanded(
                  child: _buildInfoPanel(),
                ),
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
                _buildInfoPanel(),
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
            Positioned.fill(
              child: _buildMediaView(media, isVideo),
            ),

            // Tap detector on top of media (excluding navigation arrows)
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: () => _showFullScreenMedia(context, media),
                child: const SizedBox.expand(),
              ),
            ),

            // Page indicator in top right
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
                        child: const Icon(
                          Icons.arrow_back_ios_rounded,
                          color: Colors.white,
                          size: 13.0,
                        ),
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
                        child: const Icon(
                          Icons.arrow_forward_ios_rounded,
                          color: Colors.white,
                          size: 13.0,
                        ),
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
        key: ValueKey('caption_preview_${media.path.hashCode}'),
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
      child: const Center(
        child: Icon(Icons.image_rounded, color: Colors.white54, size: 36.0),
      ),
    );
  }

  Widget _buildInfoPanel() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Gemini AI Generation Loading Animation Card
        if (widget.isGeneratingCaption) ...[
          Container(
            padding: const EdgeInsets.all(14.0),
            margin: const EdgeInsets.only(bottom: 16.0),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(12.0),
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                const SizedBox(
                  width: 20.0,
                  height: 20.0,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                  ),
                ),
                const SizedBox(width: 12.0),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '✨ Gemini AI is generating viral caption...',
                        style: AppTextStyles.body2.copyWith(fontWeight: FontWeight.bold, color: AppColors.primary, fontSize: 13.0),
                      ),
                      const SizedBox(height: 2.0),
                      Text(
                        'Analyzing property details, price, location & reels hashtags...',
                        style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary, fontSize: 11.0),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],

        // Caption TextField
        TextField(
          controller: widget.captionController,
          enabled: !widget.isGeneratingCaption,
          minLines: 8,
          maxLines: null, // grows to fit full rich caption
          style: AppTextStyles.body2.copyWith(fontSize: 13.0, height: 1.55),
          decoration: InputDecoration(
            hintText: widget.isGeneratingCaption ? 'Generating AI caption with Gemini...' : 'Write caption for your social post...',
            filled: true,
            fillColor: AppColors.background,
            contentPadding: const EdgeInsets.all(14.0),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.0),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.0),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.0),
              borderSide: BorderSide(color: AppColors.primary.withValues(alpha: 0.3)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.0),
              borderSide: const BorderSide(color: AppColors.primary),
            ),
          ),
        ),
        const SizedBox(height: 16.0),

        // Selected Channels Summary Pills
        Text(
          'Publishing To:',
          style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.bold, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 8.0),
        Wrap(
          spacing: 8.0,
          runSpacing: 8.0,
          children: [
            if (widget.selectInstagram)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 6.0),
                decoration: BoxDecoration(
                  color: const Color(0xFFE1306C).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20.0),
                  border: Border.all(color: const Color(0xFFE1306C).withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Image.asset(
                      'assets/icons/instagram.png',
                      width: 16.0,
                      height: 16.0,
                      errorBuilder: (context, error, stackTrace) => const Icon(Icons.camera_alt_rounded, size: 16.0, color: Color(0xFFE1306C)),
                    ),
                    const SizedBox(width: 6.0),
                    const Text(
                      'Instagram Feed & Reels',
                      style: TextStyle(color: Color(0xFFE1306C), fontSize: 12.0, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            if (widget.selectFacebook)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 6.0),
                decoration: BoxDecoration(
                  color: const Color(0xFF1877F2).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20.0),
                  border: Border.all(color: const Color(0xFF1877F2).withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Image.asset(
                      'assets/icons/facebook.png',
                      width: 16.0,
                      height: 16.0,
                      errorBuilder: (context, error, stackTrace) => const Icon(Icons.facebook_rounded, size: 16.0, color: Color(0xFF1877F2)),
                    ),
                    const SizedBox(width: 6.0),
                    const Text(
                      'Facebook Page',
                      style: TextStyle(color: Color(0xFF1877F2), fontSize: 12.0, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ],
    );
  }

  void _showFullScreenMedia(BuildContext context, PickedMedia media) {
    final mediaModels = widget.selectedMedia.map((m) {
      final pathLower = m.path.toLowerCase();
      final isImgExt = pathLower.endsWith('.jpg') ||
          pathLower.endsWith('.jpeg') ||
          pathLower.endsWith('.png') ||
          pathLower.endsWith('.webp') ||
          pathLower.endsWith('.gif');
      final type = !isImgExt &&
              (m.type.toLowerCase() == 'video' ||
                  pathLower.endsWith('.mp4') ||
                  pathLower.endsWith('.mov'))
          ? 'video'
          : 'image';
      return MediaModel(
        url: m.path,
        type: type,
        bytes: m.bytes,
      );
    }).toList();

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FullScreenMediaViewer(
          medias: mediaModels,
          initialIndex: widget.selectedMedia.indexOf(media),
        ),
      ),
    );
  }
}
