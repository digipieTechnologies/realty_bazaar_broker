import 'package:flutter/material.dart';
import '../../../models/media_model.dart';
import '../../../app/app_colors.dart';
import '../../../app/app_text_styles.dart';
import '../../../widgets/inputs/app_square_media_picker.dart';
import '../../../widgets/media/full_screen_media_viewer.dart';
import '../../../widgets/images/cached_image.dart';

class AllPhotosDialog extends StatelessWidget {
  final List<MediaModel> medias;
  final String title;

  const AllPhotosDialog({
    super.key,
    required this.medias,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.0)),
      backgroundColor: AppColors.surface,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 800.0, maxHeight: 600.0),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'All Media ($title)',
                      style: AppTextStyles.heading3.copyWith(fontWeight: FontWeight.bold),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: AppColors.textSecondary),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 16.0),

              // Media Grid List
              Expanded(
                child: GridView.builder(
                  itemCount: medias.length,
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 220.0,
                    mainAxisSpacing: 12.0,
                    crossAxisSpacing: 12.0,
                    childAspectRatio: 1.33,
                  ),
                  itemBuilder: (context, index) {
                    final media = medias[index];
                    return MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => FullScreenMediaViewer(
                                medias: medias,
                                initialIndex: index,
                              ),
                            ),
                          );
                        },
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12.0),
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              _buildMediaThumbnail(media),
                              if (media.type == 'video')
                                const Center(
                                  child: Icon(
                                    Icons.play_circle_fill_rounded,
                                    color: Colors.white,
                                    size: 40.0,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMediaThumbnail(MediaModel media) {
    if (media.type == 'video') {
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

    return CachedImage(
      media.url,
      imageBytes: media.bytes,
      fit: BoxFit.cover,
    );
  }
}
