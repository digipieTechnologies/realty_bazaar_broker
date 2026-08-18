// File: lib/modules/properties/widgets/post_dialog/step_media_selection.dart
// Purpose: Step 1 UI for selecting listing photos & videos via GridView with selection checkmarks, video frame thumbnail generator, and custom file additions.

import 'dart:convert';
import 'dart:io' as io;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../../../../app/app_colors.dart';
import '../../../../app/app_text_styles.dart';
import '../../../../models/property_model.dart';
import '../../../../models/media_model.dart';
import '../../../../providers/social/social_provider.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../widgets/images/cached_image.dart';

class StepMediaSelection extends StatelessWidget {
  final PropertyModel? property;
  final List<PickedMedia> selectedMedia;
  final ValueChanged<List<PickedMedia>> onMediaSelectionChanged;

  const StepMediaSelection({
    super.key,
    required this.property,
    required this.selectedMedia,
    required this.onMediaSelectionChanged,
  });

  bool _isMediaSelected(MediaModel media) {
    return selectedMedia.any((m) => m.path == media.url);
  }

  void _toggleMedia(MediaModel media, int index) {
    final List<PickedMedia> updated = List.from(selectedMedia);
    final url = media.url ?? '';
    if (url.isEmpty) return;

    final existingIndex = updated.indexWhere((m) => m.path == url);
    if (existingIndex >= 0) {
      updated.removeAt(existingIndex);
    } else {
      updated.add(PickedMedia(
        path: url,
        name: 'property_media_${index + 1}.jpg',
        bytes: media.bytes ?? Uint8List(0),
        type: media.type ?? 'image',
      ));
    }
    onMediaSelectionChanged(updated);
  }

  void _selectAll(List<MediaModel> allMedias) {
    final List<PickedMedia> updated = [];
    int idx = 0;
    for (final m in allMedias) {
      if (m.url != null && m.url!.isNotEmpty) {
        idx++;
        updated.add(PickedMedia(
          path: m.url!,
          name: 'property_media_$idx.jpg',
          bytes: m.bytes ?? Uint8List(0),
          type: m.type ?? 'image',
        ));
      }
    }
    onMediaSelectionChanged(updated);
  }

  void _clearAll() {
    onMediaSelectionChanged([]);
  }

  Widget _buildMediaThumbnail(MediaModel media, bool isVideo) {
    // 1. If thumbnail image URL is provided
    if (media.thumbnail != null && media.thumbnail!.isNotEmpty && media.thumbnail!.startsWith('http')) {
      return CachedImage(media.thumbnail!, fit: BoxFit.cover);
    }
    // 2. If thumbnail bytes are available
    if (media.thumbnailBytes != null && media.thumbnailBytes!.isNotEmpty) {
      return CachedImage(null, imageBytes: media.thumbnailBytes!, fit: BoxFit.cover);
    }
    // 3. If image bytes are available
    if (media.bytes != null && media.bytes!.isNotEmpty && !isVideo) {
      return CachedImage(null, imageBytes: media.bytes!, fit: BoxFit.cover);
    }
    // 4. If media URL is a normal web image
    final url = media.url ?? '';
    final isVideoExtension = url.toLowerCase().endsWith('.mp4') || url.toLowerCase().endsWith('.mov') || isVideo;
    if (url.startsWith('http') && !isVideoExtension) {
      return CachedImage(url, fit: BoxFit.cover);
    }
    // 5. If it's a video file URL / path, use VideoThumbnailWidget to render video frame
    if (isVideoExtension && url.isNotEmpty) {
      return VideoThumbnailWidget(
        key: ValueKey('vid_${url.hashCode}'),
        videoUrl: url,
        videoBytes: media.bytes,
      );
    }
    // 6. Fallback container
    return Container(
      color: AppColors.border,
      child: Icon(
        isVideo ? Icons.videocam_rounded : Icons.image_rounded,
        color: AppColors.textSecondary,
        size: 32.0,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final medias = property?.medias ?? [];
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 540;
    final crossAxisCount = isMobile ? 2 : 3;

    return SingleChildScrollView(
      padding: EdgeInsets.all(isMobile ? 12.0 : 18.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.tr('select_listing_media'),
                      style: AppTextStyles.heading3.copyWith(fontWeight: FontWeight.bold, fontSize: 16.0),
                    ),
                    const SizedBox(height: 2.0),
                    Text(
                      context.tr('select_listing_media_desc'),
                      style: AppTextStyles.body2.copyWith(color: AppColors.textSecondary, fontSize: 12.0),
                    ),
                  ],
                ),
              ),
              // Selection Counter Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 5.0),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20.0),
                ),
                child: Text(
                  context.tr('selected_count', arguments: {'count': selectedMedia.length.toString()}),
                  style: AppTextStyles.caption.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                    fontSize: 11.0,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14.0),

          // Control Toolbar: Checkbox / Radio for Select All
          if (medias.isNotEmpty)
            InkWell(
              onTap: () {
                final isAllSelected = selectedMedia.length == medias.length;
                if (isAllSelected) {
                  _clearAll();
                } else {
                  _selectAll(medias);
                }
              },
              borderRadius: BorderRadius.circular(8.0),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    height: 24.0,
                    width: 24.0,
                    child: Checkbox(
                      value: medias.isNotEmpty && selectedMedia.length == medias.length,
                      activeColor: AppColors.primary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4.0)),
                      onChanged: (bool? val) {
                        if (val == true) {
                          _selectAll(medias);
                        } else {
                          _clearAll();
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 8.0),
                  Text(
                    context.tr('select_all'),
                    style: AppTextStyles.body2.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                      fontSize: 13.0,
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 14.0),

          // Media GridView
          if (medias.isEmpty && selectedMedia.isEmpty)
            _buildEmptyMediaState()
          else
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: 10.0,
                mainAxisSpacing: 10.0,
                childAspectRatio: 1.0,
              ),
              itemCount: medias.length,
              itemBuilder: (context, index) {
                final media = medias[index];
                final isSelected = _isMediaSelected(media);
                final urlLower = media.url?.toLowerCase() ?? '';
                final isImgExt = urlLower.endsWith('.jpg') ||
                    urlLower.endsWith('.jpeg') ||
                    urlLower.endsWith('.png') ||
                    urlLower.endsWith('.webp') ||
                    urlLower.endsWith('.gif');
                final isVideo = !isImgExt &&
                    ((media.type?.toLowerCase() == 'video') ||
                        urlLower.endsWith('.mp4') ||
                        urlLower.endsWith('.mov'));

                return InkWell(
                  onTap: () => _toggleMedia(media, index),
                  borderRadius: BorderRadius.circular(12.0),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12.0),
                      border: Border.all(
                        color: isSelected ? AppColors.primary : AppColors.border,
                        width: isSelected ? 3.0 : 1.0,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: AppColors.primary.withValues(alpha: 0.2),
                                blurRadius: 8.0,
                                offset: const Offset(0, 3),
                              )
                            ]
                          : [],
                    ),
                    child: Stack(
                      children: [
                        // Thumbnail Image/Video Cover
                        ClipRRect(
                          borderRadius: BorderRadius.circular(9.0),
                          child: SizedBox.expand(
                            child: _buildMediaThumbnail(media, isVideo),
                          ),
                        ),

                        // Dimming overlay when selected
                        if (isSelected)
                          Positioned.fill(
                            child: Container(
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(9.0),
                              ),
                            ),
                          ),

                        // Play Icon Badge for Video (No text labels)
                        if (isVideo)
                          Positioned(
                            left: 8.0,
                            bottom: 8.0,
                            child: Container(
                              padding: const EdgeInsets.all(4.0),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.65),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.play_arrow_rounded,
                                size: 14.0,
                                color: Colors.white,
                              ),
                            ),
                          ),

                        // Top-Right Checkbox Pill
                        Positioned(
                          top: 8.0,
                          right: 8.0,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            width: 24.0,
                            height: 24.0,
                            decoration: BoxDecoration(
                              color: isSelected ? AppColors.primary : Colors.black.withValues(alpha: 0.4),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isSelected ? AppColors.primary : Colors.white,
                                width: 1.5,
                              ),
                            ),
                            child: isSelected
                                ? const Icon(Icons.check_rounded, size: 15.0, color: Colors.white)
                                : null,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyMediaState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28.0),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(14.0),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Icon(Icons.photo_library_outlined, size: 44.0, color: AppColors.textMuted),
          const SizedBox(height: 12.0),
          Text(
            'No Listing Media Attached',
            style: AppTextStyles.body1.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4.0),
          Text(
            'No photos or videos are attached to this property listing.',
            style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class VideoThumbnailWidget extends StatefulWidget {
  final String videoUrl;
  final Uint8List? videoBytes;

  const VideoThumbnailWidget({
    super.key,
    required this.videoUrl,
    this.videoBytes,
  });

  @override
  State<VideoThumbnailWidget> createState() => _VideoThumbnailWidgetState();
}

class _VideoThumbnailWidgetState extends State<VideoThumbnailWidget> {
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
      final controller = kIsWeb && widget.videoBytes != null
          ? VideoPlayerController.networkUrl(
              Uri.parse('data:video/mp4;base64,${base64Encode(widget.videoBytes!)}'),
            )
          : (widget.videoUrl.startsWith('http')
              ? VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl))
              : VideoPlayerController.file(io.File(widget.videoUrl)));

      _controller = controller;
      await controller.initialize();
      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    } catch (e) {
      debugPrint('Error initializing video preview thumbnail: $e');
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
        color: AppColors.primary.withValues(alpha: 0.05),
        child: const Center(
          child: Icon(
            Icons.videocam_rounded,
            color: AppColors.primary,
            size: 28.0,
          ),
        ),
      );
    }

    if (!_isInitialized || _controller == null) {
      return const Center(
        child: SizedBox(
          width: 18.0,
          height: 18.0,
          child: CircularProgressIndicator(
            strokeWidth: 2.0,
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
          ),
        ),
      );
    }

    return SizedBox.expand(
      child: FittedBox(
        fit: BoxFit.cover,
        clipBehavior: Clip.hardEdge,
        child: SizedBox(
          width: _controller!.value.size.width,
          height: _controller!.value.size.height,
          child: VideoPlayer(_controller!),
        ),
      ),
    );
  }
}
