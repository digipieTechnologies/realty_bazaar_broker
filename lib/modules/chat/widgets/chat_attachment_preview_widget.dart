// File: lib/modules/chat/widgets/chat_attachment_preview_widget.dart
// Purpose: Multi-attachment horizontal preview strip rendering images/videos as thumbnails and non-image files as grey extension cards (matching SS 3).

import 'dart:io' as io;
import 'package:flutter/material.dart';
import '../../../app/app_colors.dart';
import '../../../models/models.dart';
import '../../../widgets/media/full_screen_media_viewer.dart';

class ChatAttachmentPreviewWidget extends StatelessWidget {
  final List<MediaModel> attachments;
  final Function(int index) onRemoveAttachment;

  const ChatAttachmentPreviewWidget({
    super.key,
    required this.attachments,
    required this.onRemoveAttachment,
  });

  void _openAttachmentViewer(BuildContext context, int initialIndex) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => FullScreenMediaViewer(
          medias: attachments,
          initialIndex: initialIndex,
        ),
      ),
    );
  }

  String _getFileExtension(String? path) {
    if (path == null || path.isEmpty) return 'file';
    final fileName = path.split('/').last.split('\\').last;
    if (fileName.contains('.')) {
      return fileName.split('.').last.toLowerCase();
    }
    return 'file';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 94.0,
      padding: const EdgeInsets.only(top: 8.0, bottom: 4.0),
      child: ListView.separated(
        clipBehavior: Clip.none,
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        scrollDirection: Axis.horizontal,
        itemCount: attachments.length,
        separatorBuilder: (context, index) => const SizedBox(width: 12.0),
        itemBuilder: (context, index) {
          final item = attachments[index];
          final isVideo = item.isVideo;
          final isImage = item.type == 'image' || item.thumbnailBytes != null ||
              (item.url != null && (item.url!.endsWith('.png') || item.url!.endsWith('.jpg') || item.url!.endsWith('.jpeg')));

          final ext = _getFileExtension(item.url);

          return Stack(
            clipBehavior: Clip.none,
            children: [
              GestureDetector(
                onTap: (isImage || isVideo)
                    ? () => _openAttachmentViewer(context, index)
                    : null,
                child: Container(
                  width: 76.0,
                  height: 76.0,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12.0),
                    border: Border.all(color: AppColors.border),
                    color: isImage || isVideo ? AppColors.surfaceLight : const Color(0xFFCCCCCC),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: isImage || isVideo
                      ? Stack(
                          alignment: Alignment.center,
                          children: [
                            if (item.thumbnailBytes != null)
                              Image.memory(
                                item.thumbnailBytes!,
                                width: 76.0,
                                height: 76.0,
                                fit: BoxFit.cover,
                              )
                            else if (item.url != null && item.url!.isNotEmpty && !item.url!.startsWith('http'))
                              Image.file(
                                io.File(item.url!),
                                width: 76.0,
                                height: 76.0,
                                fit: BoxFit.cover,
                              )
                            else
                              const Icon(Icons.insert_drive_file_rounded, size: 28.0, color: AppColors.textMuted),
                            if (isVideo)
                              Container(
                                padding: const EdgeInsets.all(4.0),
                                decoration: const BoxDecoration(
                                  color: Colors.black45,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 20.0),
                              ),
                          ],
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.article_rounded,
                              size: 32.0,
                              color: Color(0xFF374151),
                            ),
                            const SizedBox(height: 4.0),
                            Text(
                              ext,
                              style: const TextStyle(
                                fontSize: 12.0,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1F2937),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                ),
              ),

              Positioned(
                top: -4.0,
                right: -4.0,
                child: GestureDetector(
                  onTap: () => onRemoveAttachment(index),
                  child: Container(
                    padding: const EdgeInsets.all(3.0),
                    decoration: BoxDecoration(
                      color: AppColors.error,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.15),
                          blurRadius: 3.0,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.close_rounded,
                      size: 13.0,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
