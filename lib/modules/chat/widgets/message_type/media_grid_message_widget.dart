// File: lib/modules/chat/widgets/message_type/media_grid_message_widget.dart
// Purpose: Reusable media grid widget displaying single or multi-media attachments in WhatsApp style (+X overlay for >4 items) opening FullScreenMediaViewer on tap.

import 'package:flutter/material.dart';
import '../../../../models/models.dart';
import '../../../../widgets/images/cached_image.dart';
import '../../../../widgets/media/full_screen_media_viewer.dart';

class MediaGridMessageWidget extends StatelessWidget {
  final List<MediaModel> medias;
  final String? caption;
  final bool isMe;

  const MediaGridMessageWidget({
    super.key,
    required this.medias,
    this.caption,
    required this.isMe,
  });

  void _openMediaViewer(BuildContext context, int initialIndex) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => FullScreenMediaViewer(
          medias: medias,
          initialIndex: initialIndex,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (medias.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12.0),
          child: _buildGrid(context),
        ),

        if (caption != null && caption!.trim().isNotEmpty) ...[
          const SizedBox(height: 6.0),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 2.0),
            child: Text(
              caption!,
              style: TextStyle(
                fontSize: 13.0,
                color: isMe ? Colors.white : Colors.black87,
                height: 1.3,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildGrid(BuildContext context) {
    final count = medias.length;

    if (count == 1) {
      return _buildMediaTile(context, medias[0], 0, height: 200.0, width: 240.0);
    } else if (count == 2) {
      return SizedBox(
        width: 240.0,
        height: 140.0,
        child: Row(
          children: [
            Expanded(child: _buildMediaTile(context, medias[0], 0)),
            const SizedBox(width: 2.0),
            Expanded(child: _buildMediaTile(context, medias[1], 1)),
          ],
        ),
      );
    } else if (count == 3) {
      return SizedBox(
        width: 240.0,
        height: 160.0,
        child: Row(
          children: [
            Expanded(flex: 2, child: _buildMediaTile(context, medias[0], 0)),
            const SizedBox(width: 2.0),
            Expanded(
              flex: 1,
              child: Column(
                children: [
                  Expanded(child: _buildMediaTile(context, medias[1], 1)),
                  const SizedBox(height: 2.0),
                  Expanded(child: _buildMediaTile(context, medias[2], 2)),
                ],
              ),
            ),
          ],
        ),
      );
    } else {
      final extraCount = count - 4;
      return SizedBox(
        width: 240.0,
        height: 240.0,
        child: Column(
          children: [
            Expanded(
              child: Row(
                children: [
                  Expanded(child: _buildMediaTile(context, medias[0], 0)),
                  const SizedBox(width: 2.0),
                  Expanded(child: _buildMediaTile(context, medias[1], 1)),
                ],
              ),
            ),
            const SizedBox(height: 2.0),
            Expanded(
              child: Row(
                children: [
                  Expanded(child: _buildMediaTile(context, medias[2], 2)),
                  const SizedBox(width: 2.0),
                  Expanded(
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        _buildMediaTile(context, medias[3], 3),
                        if (extraCount > 0)
                          GestureDetector(
                            onTap: () => _openMediaViewer(context, 3),
                            child: Container(
                              color: Colors.black54,
                              alignment: Alignment.center,
                              child: Text(
                                '+$extraCount',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 22.0,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }
  }

  Widget _buildMediaTile(
    BuildContext context,
    MediaModel media,
    int index, {
    double? width,
    double? height,
  }) {
    final imagePathOrUrl = media.displayImageUrl;

    return GestureDetector(
      onTap: () => _openMediaViewer(context, index),
      child: SizedBox(
        width: width,
        height: height,
        child: Stack(
          fit: StackFit.expand,
          children: [
            CachedImage(
              imagePathOrUrl,
              fit: BoxFit.cover,
              width: width,
              height: height,
            ),
            if (media.isVideo)
              Center(
                child: Container(
                  padding: const EdgeInsets.all(8.0),
                  decoration: const BoxDecoration(
                    color: Colors.black45,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.play_arrow_rounded,
                    color: Colors.white,
                    size: 28.0,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
