// File: lib/widgets/inputs/app_square_media_picker.dart
// Purpose: Reusable Meesho-style square media picker for images and videos with local thumbnail generation and readOnly support in brokerflow-app.

import 'dart:convert';
import 'dart:io' as io;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../../app/app_colors.dart';
import '../../app/app_text_styles.dart';
import '../../core/utils/media_picker_helper.dart';
import '../../models/media_model.dart';
import '../images/cached_image.dart';
import '../media/full_screen_media_viewer.dart';

class AppSquareMediaPicker extends StatefulWidget {
  final List<MediaModel> medias;
  final ValueChanged<List<MediaModel>> onMediasChanged;
  final int maxImages;
  final int maxVideos;
  final bool readOnly;

  const AppSquareMediaPicker({
    super.key,
    required this.medias,
    required this.onMediasChanged,
    this.maxImages = 6,
    this.maxVideos = 2,
    this.readOnly = false,
  });

  @override
  State<AppSquareMediaPicker> createState() => _AppSquareMediaPickerState();
}

class _AppSquareMediaPickerState extends State<AppSquareMediaPicker> {
  bool _isProcessingMedia = false;

  // Pick Images
  Future<void> _pickImages() async {
    if (widget.readOnly) return;
    setState(() => _isProcessingMedia = true);
    try {
      final picked = await MediaPickerHelper.pickImages(
        context: context,
        currentMedias: widget.medias,
        maxImages: widget.maxImages,
      );
      if (picked.isNotEmpty) {
        final updatedMedias = List<MediaModel>.from(widget.medias)..addAll(picked);
        widget.onMediasChanged(updatedMedias);
      }
    } finally {
      if (mounted) setState(() => _isProcessingMedia = false);
    }
  }

  // Pick Videos
  Future<void> _pickVideos() async {
    if (widget.readOnly) return;
    setState(() => _isProcessingMedia = true);
    try {
      final picked = await MediaPickerHelper.pickVideos(
        context: context,
        currentMedias: widget.medias,
        maxVideos: widget.maxVideos,
      );
      if (picked.isNotEmpty) {
        final updatedMedias = List<MediaModel>.from(widget.medias)..addAll(picked);
        widget.onMediasChanged(updatedMedias);
      }
    } finally {
      if (mounted) setState(() => _isProcessingMedia = false);
    }
  }

  void _removeMediaModel(MediaModel item) {
    if (widget.readOnly) return;
    final updated = List<MediaModel>.from(widget.medias);
    updated.remove(item);
    widget.onMediasChanged(updated);
  }

  @override
  Widget build(BuildContext context) {
    final images = widget.medias.where((m) => m.type == 'image').toList();
    final videos = widget.medias.where((m) => m.type == 'video').toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_isProcessingMedia)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
            margin: const EdgeInsets.only(bottom: 16.0),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(10.0),
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
            ),
            child: const Row(
              children: [
                SizedBox(
                  width: 16.0,
                  height: 16.0,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.0,
                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                  ),
                ),
                SizedBox(width: 12.0),
                Text(
                  'Processing selected media files...',
                  style: TextStyle(
                    fontSize: 13.0,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),

        // Photos Section
        _buildMeeshoStyleImageSection(images),
        const SizedBox(height: 24.0),

        // Videos Section
        _buildMeeshoStyleVideoSection(videos),
      ],
    );
  }

  Widget _buildMeeshoStyleImageSection(List<MediaModel> images) {
    final isFull = images.length >= widget.maxImages;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Property Photos',
                style: AppTextStyles.heading3.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                  fontSize: 16.0,
                ),
              ),
            ),
            const SizedBox(width: 8.0),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 2.0),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12.0),
              ),
              child: Text(
                '${images.length}/${widget.maxImages}',
                style: const TextStyle(
                  fontSize: 11.0,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4.0),
        Text(
          'Upload high-quality images of exterior, rooms, kitchen & amenities.',
          style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: 12.0),

        Wrap(
          spacing: 12.0,
          runSpacing: 12.0,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            for (final media in images)
              _buildMediaSquareItem(
                key: ValueKey('${media.type}_${media.url ?? media.hashCode}'),
                media: media,
                onDelete: () => _removeMediaModel(media),
              ),
            if (!isFull && !widget.readOnly)
              _buildAddSquareButton(
                label: 'Add Photo',
                icon: Icons.add_a_photo_rounded,
                onTap: _pickImages,
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildMeeshoStyleVideoSection(List<MediaModel> videos) {
    final isFull = videos.length >= widget.maxVideos;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Property Videos & Walkthroughs',
                style: AppTextStyles.heading3.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                  fontSize: 16.0,
                ),
              ),
            ),
            const SizedBox(width: 8.0),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 2.0),
              decoration: BoxDecoration(
                color: AppColors.secondary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12.0),
              ),
              child: Text(
                '${videos.length}/${widget.maxVideos}',
                style: const TextStyle(
                  fontSize: 11.0,
                  fontWeight: FontWeight.bold,
                  color: AppColors.secondary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4.0),
        Text(
          'Upload property walkthrough videos or virtual tour clips (MP4, MOV).',
          style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: 12.0),

        Wrap(
          spacing: 12.0,
          runSpacing: 12.0,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            for (final media in videos)
              _buildMediaSquareItem(
                key: ValueKey('${media.type}_${media.url ?? media.hashCode}'),
                media: media,
                isVideo: true,
                onDelete: () => _removeMediaModel(media),
              ),
            if (!isFull && !widget.readOnly)
              _buildAddSquareButton(
                label: 'Add Video',
                icon: Icons.video_call_rounded,
                isSecondary: true,
                onTap: _pickVideos,
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildAddSquareButton({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
    bool isSecondary = false,
  }) {
    final accentColor = isSecondary ? AppColors.secondary : AppColors.primary;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 105.0,
          height: 105.0,
          decoration: BoxDecoration(
            color: accentColor.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(14.0),
            border: Border.all(
              color: accentColor.withValues(alpha: 0.4),
              width: 1.5,
              style: BorderStyle.solid,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(8.0),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: accentColor,
                  size: 22.0,
                ),
              ),
              const SizedBox(height: 8.0),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12.0,
                  fontWeight: FontWeight.bold,
                  color: accentColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMediaSquareItem({
    Key? key,
    required MediaModel media,
    bool isVideo = false,
    required VoidCallback onDelete,
  }) {
    final hasThumbnailBytes = media.thumbnailBytes != null && media.thumbnailBytes!.isNotEmpty;
    final hasImageBytes = media.bytes != null && media.bytes!.isNotEmpty;
    final displayUrl = (isVideo ? (media.thumbnail ?? media.url) : media.url) ?? '';

    return Container(
      key: key,
      width: 105.0,
      height: 105.0,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14.0),
        border: Border.all(color: AppColors.border, width: 1.0),
        color: AppColors.background,
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: GestureDetector(
              onTap: () {
                final index = widget.medias.indexOf(media);
                if (index != -1) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => FullScreenMediaViewer(
                        medias: widget.medias,
                        initialIndex: index,
                      ),
                    ),
                  );
                }
              },
              child: MouseRegion(
                cursor: SystemMouseCursors.click,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(13.0),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Positioned.fill(
                        child: Builder(
                          builder: (context) {
                            if (isVideo) {
                              if (hasThumbnailBytes) {
                                return CachedImage(
                                  null,
                                  imageBytes: media.thumbnailBytes!,
                                  fit: BoxFit.cover,
                                  width: 105.0,
                                  height: 105.0,
                                  borderRadius: BorderRadius.circular(13.0),
                                );
                              }
                              if (media.thumbnail != null && media.thumbnail!.isNotEmpty) {
                                return CachedImage(
                                  media.thumbnail!,
                                  width: 105.0,
                                  height: 105.0,
                                  fit: BoxFit.cover,
                                  borderRadius: BorderRadius.circular(13.0),
                                );
                              }
                              return VideoThumbnailWidget(
                                key: ValueKey('player_${media.url ?? media.hashCode}'),
                                videoUrl: media.url ?? '',
                                videoBytes: media.bytes,
                              );
                            }
                            return CachedImage(
                              displayUrl,
                              imageBytes: hasImageBytes ? media.bytes : null,
                              width: 105.0,
                              height: 105.0,
                              fit: BoxFit.cover,
                              borderRadius: BorderRadius.circular(13.0),
                            );
                          },
                        ),
                      ),
                      if (isVideo)
                        Positioned.fill(
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.3),
                              borderRadius: BorderRadius.circular(13.0),
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.play_circle_fill_rounded,
                                color: Colors.white,
                                size: 36.0,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (!widget.readOnly)
            Positioned(
              top: -6.0,
              right: -6.0,
              child: MouseRegion(
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                  onTap: onDelete,
                  child: Container(
                    padding: const EdgeInsets.all(4.0),
                    decoration: const BoxDecoration(
                      color: AppColors.error,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 4,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.close_rounded,
                      color: Colors.white,
                      size: 13.0,
                    ),
                  ),
                ),
              ),
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
