// File: lib/widgets/media/media_collage_widget.dart
// Purpose: A reusable, premium media collage grid widget used across
//          property preview dialogs and property detail screens.

import 'package:flutter/material.dart';
import '../../models/media_model.dart';
import '../../app/app_colors.dart';
import '../inputs/app_square_media_picker.dart';
import '../images/cached_image.dart';

/// Callback signature: provides the tapped media index.
typedef MediaTapCallback = void Function(int index);

/// Callback signature: triggered when the "+N" overflow tile is tapped.
typedef OverflowTapCallback = void Function();

class MediaCollageWidget extends StatelessWidget {
  /// The list of media items to display in the collage.
  final List<MediaModel> medias;

  /// Height of the collage container.
  final double height;

  /// Border radius applied to the outer container.
  final BorderRadius borderRadius;

  /// Called when any individual media tile is tapped.
  /// If null, tiles are not tappable.
  final MediaTapCallback? onMediaTap;

  /// Called when the "+N" overflow tile is tapped.
  /// If null and there is overflow, tapping the overflow tile
  /// falls through to [onMediaTap] with the last visible index.
  final OverflowTapCallback? onOverflowTap;

  /// Whether to show the empty-state placeholder when [medias] is empty.
  final bool showEmptyState;

  const MediaCollageWidget({
    super.key,
    required this.medias,
    this.height = 240.0,
    this.borderRadius = const BorderRadius.all(Radius.circular(16.0)),
    this.onMediaTap,
    this.onOverflowTap,
    this.showEmptyState = true,
  });

  @override
  Widget build(BuildContext context) {
    if (medias.isEmpty) {
      if (!showEmptyState) return const SizedBox.shrink();
      return Container(
        height: height,
        width: double.infinity,
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: borderRadius,
          border: Border.all(color: AppColors.border),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.image_not_supported_outlined,
                size: 48.0, color: AppColors.textSecondary),
            SizedBox(height: 8.0),
            Text(
              'No Media Attached',
              style: TextStyle(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600),
            ),
          ],
        ),
      );
    }

    final total = medias.length;

    return SizedBox(
      height: height,
      width: double.infinity,
      child: ClipRRect(
        borderRadius: borderRadius,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isMobileCompact = constraints.maxWidth < 460;
            return _buildGalleryGrid(context, total, isMobileCompact);
          },
        ),
      ),
    );
  }

  // ───────────────────────────────────────────────
  // Grid Layout Builders
  // ───────────────────────────────────────────────

  Widget _buildGalleryGrid(BuildContext context, int total, bool isMobileCompact) {
    if (total == 1) {
      return _buildTile(context, 0);
    }

    if (total == 2) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(flex: 3, child: _buildTile(context, 0)),
          const SizedBox(width: 4.0),
          Expanded(flex: 2, child: _buildTile(context, 1)),
        ],
      );
    }

    // Mobile compact: 1 main + 2 stacked (with potential overflow on last)
    if (isMobileCompact) {
      final extraCount = total - 3;
      return Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(flex: 3, child: _buildTile(context, 0)),
          const SizedBox(width: 4.0),
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: _buildTile(context, 1)),
                const SizedBox(height: 4.0),
                Expanded(
                  child: _buildOverflowTile(context, 2, extraCount),
                ),
              ],
            ),
          ),
        ],
      );
    }

    // Desktop / Tablet Layouts
    if (total == 3) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(flex: 3, child: _buildTile(context, 0)),
          const SizedBox(width: 4.0),
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: _buildTile(context, 1)),
                const SizedBox(height: 4.0),
                Expanded(child: _buildTile(context, 2)),
              ],
            ),
          ),
        ],
      );
    }

    if (total == 4) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(flex: 3, child: _buildTile(context, 0)),
          const SizedBox(width: 4.0),
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: _buildTile(context, 1)),
                const SizedBox(height: 4.0),
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(child: _buildTile(context, 2)),
                      const SizedBox(width: 4.0),
                      Expanded(child: _buildTile(context, 3)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    // 5+ images
    final extraCount = total - 5;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(flex: 3, child: _buildTile(context, 0)),
        const SizedBox(width: 4.0),
        Expanded(
          flex: 2,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(child: _buildTile(context, 1)),
                    const SizedBox(width: 4.0),
                    Expanded(child: _buildTile(context, 2)),
                  ],
                ),
              ),
              const SizedBox(height: 4.0),
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(child: _buildTile(context, 3)),
                    const SizedBox(width: 4.0),
                    Expanded(
                      child: _buildOverflowTile(context, 4, extraCount),
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

  // ───────────────────────────────────────────────
  // Individual Tile Builders
  // ───────────────────────────────────────────────

  /// Standard image/video tile.
  Widget _buildTile(BuildContext context, int index) {
    return _wrapWithTap(
      context,
      index,
      _buildMediaContent(medias[index]),
    );
  }

  /// Tile that shows a "+N" overlay when [extraCount] > 0.
  Widget _buildOverflowTile(BuildContext context, int index, int extraCount) {
    final hasOverflow = extraCount > 0;

    final child = Stack(
      fit: StackFit.expand,
      children: [
        _buildMediaContent(medias[index]),
        if (hasOverflow)
          Container(
            color: Colors.black.withValues(alpha: 0.55),
            alignment: Alignment.center,
            child: Text(
              '+$extraCount',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20.0,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
      ],
    );

    if (hasOverflow && onOverflowTap != null) {
      return MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: onOverflowTap,
          child: child,
        ),
      );
    }

    return _wrapWithTap(context, index, child);
  }

  /// Wraps a child widget with a GestureDetector wired to [onMediaTap].
  Widget _wrapWithTap(BuildContext context, int index, Widget child) {
    if (onMediaTap == null) return child;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => onMediaTap!(index),
        child: child,
      ),
    );
  }

  /// Renders the media content (image or video thumbnail with play icon).
  Widget _buildMediaContent(MediaModel media) {
    return Stack(
      fit: StackFit.expand,
      children: [
        if (media.type == 'video')
          _buildVideoThumbnail(media)
        else
          CachedImage(
            media.url,
            imageBytes: media.bytes,
            fit: BoxFit.cover,
          ),
        if (media.type == 'video')
          const Center(
            child: Icon(
              Icons.play_circle_fill_rounded,
              color: Colors.white,
              size: 40.0,
            ),
          ),
      ],
    );
  }

  Widget _buildVideoThumbnail(MediaModel media) {
    if (media.thumbnailBytes != null) {
      return CachedImage(
        null,
        imageBytes: media.thumbnailBytes,
        fit: BoxFit.cover,
      );
    }
    return VideoThumbnailWidget(
      videoUrl: media.url ?? '',
      videoBytes: media.bytes,
    );
  }
}
