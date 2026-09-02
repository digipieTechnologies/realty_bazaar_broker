// File: lib/core/utils/media_picker_helper.dart
// Purpose: Centralized utility for requesting permissions, picking images/videos via FilePicker, generating thumbnails, decoding dimensions (width/height/ratio), and enforcing max attachment limits.

import 'dart:io' as io;
import 'dart:ui' as ui;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../models/media_model.dart';
import '../../widgets/toast/app_toast.dart';
import '../constants/chat_constants.dart';
import '../services/permission_service.dart';
import 'video_thumbnail_helper.dart';

class MediaPickerHelper {
  MediaPickerHelper._();

  /// Decodes raw image bytes to extract exact width, height, and aspect ratio
  static Future<Map<String, double>?> _decodeDimensions(Uint8List bytes) async {
    try {
      final codec = await ui.instantiateImageCodec(bytes);
      final frameInfo = await codec.getNextFrame();
      final width = frameInfo.image.width.toDouble();
      final height = frameInfo.image.height.toDouble();
      frameInfo.image.dispose();
      codec.dispose();
      if (width > 0 && height > 0) {
        return {'width': width, 'height': height, 'aspectRatio': width / height};
      }
    } catch (e) {
      debugPrint('[MediaPickerHelper] Error decoding dimensions: $e');
    }
    return null;
  }

  /// Generic method to pick both images & videos at once up to [maxMedia] (default 5).
  /// Enforces limits, decodes aspect ratios, and triggers Toast if exceeded.
  static Future<List<MediaModel>> pickMedia({
    required BuildContext context,
    List<MediaModel> currentMedias = const [],
    int maxMedia = ChatConstants.maxAttachmentsPerMessage,
  }) async {
    final hasPermission = await PermissionService.requestMediaPermission(context);
    if (!hasPermission) return [];

    final currentCount = currentMedias.length;
    if (currentCount >= maxMedia) {
      AppToast.showError('Attachment Limit', 'Maximum $maxMedia media attachments allowed at a time.');
      return [];
    }

    try {
      final result = await FilePicker.pickFiles(
        allowMultiple: true,
        type: FileType.custom,
        allowedExtensions: [
          'jpg',
          'jpeg',
          'png',
          'webp',
          'heic',
          'gif',
          'mp4',
          'mov',
          'avi',
          'mkv',
          'webm',
          '3gp',
        ],
        withData: kIsWeb,
      );

      if (result == null || result.files.isEmpty) return [];

      final allowedCount = maxMedia - currentCount;
      if (result.files.length > allowedCount) {
        AppToast.showError('Attachment Limit', 'Maximum $maxMedia media attachments allowed at a time.');
      }

      final filesToProcess = result.files.take(allowedCount).toList();
      final newMediaList = <MediaModel>[];
      bool duplicateFound = false;

      for (final file in filesToProcess) {
        try {
          final pathOrName = file.path ?? file.name;
          final ext = (file.extension ?? pathOrName.split('.').last).toLowerCase();
          final isVideo = ['mp4', 'mov', 'avi', 'mkv', 'webm', '3gp'].contains(ext);
          final isImage = ['jpg', 'jpeg', 'png', 'webp', 'heic', 'gif', 'bmp'].contains(ext);
          if (!isVideo && !isImage) {
            continue;
          }
          final typeStr = isVideo ? 'video' : 'image';

          final isDuplicate =
              currentMedias.any((m) => m.url == pathOrName) || newMediaList.any((m) => m.url == pathOrName);

          if (isDuplicate) {
            duplicateFound = true;
            continue;
          }

          Uint8List? bytes;
          if (kIsWeb) {
            if (file.bytes == null) continue;
            bytes = file.bytes!;
          } else if (file.path != null && !isVideo) {
            try {
              bytes = file.bytes ?? await io.File(file.path!).readAsBytes();
            } catch (e) {
              debugPrint('[MediaPickerHelper] Could not read bytes for $pathOrName: $e');
            }
          }

          double? width;
          double? height;
          double? aspectRatio;
          Uint8List? thumbBytes;

          if (isVideo) {
            if (!kIsWeb && file.path != null) {
              try {
                thumbBytes = await VideoThumbnailHelper.generateThumbnail(filePath: file.path!);
                if (thumbBytes != null) {
                  final dims = await _decodeDimensions(thumbBytes);
                  if (dims != null) {
                    width = dims['width'];
                    height = dims['height'];
                    aspectRatio = dims['aspectRatio'];
                  }
                }
              } catch (e) {
                debugPrint('[MediaPickerHelper] Thumbnail error: $e');
              }
            }
          } else if (isImage && bytes != null) {
            final dims = await _decodeDimensions(bytes);
            if (dims != null) {
              width = dims['width'];
              height = dims['height'];
              aspectRatio = dims['aspectRatio'];
            }
          }

          newMediaList.add(
            MediaModel(
              type: typeStr,
              url: pathOrName,
              bytes: bytes,
              thumbnailBytes: thumbBytes,
              width: width,
              height: height,
              aspectRatio: aspectRatio,
            ),
          );
        } catch (fileErr) {
          debugPrint('[MediaPickerHelper] Error processing file ${file.name}: $fileErr');
        }
      }

      if (duplicateFound) {
        AppToast.showError('Duplicate File', 'Some files were ignored because they are already added.');
      }

      return newMediaList;
    } catch (e) {
      debugPrint('[MediaPickerHelper] Error picking media: $e');
      AppToast.showError('Selection Error', 'Failed to pick files: $e');
      return [];
    }
  }

  /// Picks images after verifying media permissions.
  static Future<List<MediaModel>> pickImages({
    required BuildContext context,
    List<MediaModel> currentMedias = const [],
    int maxImages = 6,
  }) async {
    final hasPermission = await PermissionService.requestMediaPermission(context);
    if (!hasPermission) return [];

    final currentImageCount = currentMedias.where((m) => m.type == 'image').length;
    if (currentImageCount >= maxImages) {
      AppToast.showError('Photo Limit Reached', 'You can upload a maximum of $maxImages property photos.');
      return [];
    }

    try {
      final result = await FilePicker.pickFiles(
        allowMultiple: true,
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'webp', 'heic'],
        withData: kIsWeb,
      );

      if (result == null || result.files.isEmpty) return [];

      final allowedCount = maxImages - currentImageCount;
      if (result.files.length > allowedCount) {
        AppToast.showError('Photo Limit Reached', 'Maximum $maxImages photos allowed.');
      }

      final filesToProcess = result.files.take(allowedCount).toList();
      final newMediaList = <MediaModel>[];
      bool duplicateFound = false;

      for (final file in filesToProcess) {
        final pathOrName = file.path ?? file.name;
        final isDuplicate =
            currentMedias.any((m) => m.url == pathOrName) || newMediaList.any((m) => m.url == pathOrName);

        if (isDuplicate) {
          duplicateFound = true;
          continue;
        }

        Uint8List bytes;
        if (kIsWeb) {
          if (file.bytes == null) continue;
          bytes = file.bytes!;
        } else {
          bytes = file.bytes ?? await io.File(file.path!).readAsBytes();
        }

        final dims = await _decodeDimensions(bytes);

        newMediaList.add(
          MediaModel(
            type: 'image',
            url: pathOrName,
            bytes: bytes,
            width: dims?['width'],
            height: dims?['height'],
            aspectRatio: dims?['aspectRatio'],
          ),
        );
      }

      if (duplicateFound) {
        AppToast.showError('Duplicate File', 'Some files were ignored because they are already added.');
      }

      return newMediaList;
    } catch (e) {
      debugPrint('Error picking property images: $e');
      AppToast.showError('Selection Error', 'Failed to pick photos: $e');
      return [];
    }
  }

  /// Picks videos after verifying media permissions.
  static Future<List<MediaModel>> pickVideos({
    required BuildContext context,
    List<MediaModel> currentMedias = const [],
    int maxVideos = 2,
  }) async {
    final hasPermission = await PermissionService.requestMediaPermission(context);
    if (!hasPermission) return [];

    final currentVideoCount = currentMedias.where((m) => m.type == 'video').length;
    if (currentVideoCount >= maxVideos) {
      AppToast.showError('Video Limit Reached', 'You can upload a maximum of $maxVideos property videos.');
      return [];
    }

    try {
      final result = await FilePicker.pickFiles(
        allowMultiple: true,
        type: FileType.custom,
        allowedExtensions: ['mp4', 'mov', 'avi', 'mkv'],
        withData: kIsWeb,
      );

      if (result == null || result.files.isEmpty) return [];

      final allowedCount = maxVideos - currentVideoCount;
      if (result.files.length > allowedCount) {
        AppToast.showError('Video Limit Reached', 'Maximum $maxVideos videos allowed.');
      }

      final filesToProcess = result.files.take(allowedCount).toList();
      final newMediaList = <MediaModel>[];
      bool duplicateFound = false;

      for (final file in filesToProcess) {
        final filePath = file.path ?? file.name;
        final isDuplicate =
            currentMedias.any((m) => m.url == filePath) || newMediaList.any((m) => m.url == filePath);

        if (isDuplicate) {
          duplicateFound = true;
          continue;
        }

        Uint8List? bytes;
        if (kIsWeb) {
          if (file.bytes == null) continue;
          bytes = file.bytes;
        }

        Uint8List? thumbBytes;
        double? width;
        double? height;
        double? aspectRatio;

        if (!kIsWeb && file.path != null) {
          thumbBytes = await VideoThumbnailHelper.generateThumbnail(filePath: file.path!);
          if (thumbBytes != null) {
            final dims = await _decodeDimensions(thumbBytes);
            if (dims != null) {
              width = dims['width'];
              height = dims['height'];
              aspectRatio = dims['aspectRatio'];
            }
          }
        }

        newMediaList.add(
          MediaModel(
            type: 'video',
            url: filePath,
            bytes: bytes,
            thumbnailBytes: thumbBytes,
            width: width,
            height: height,
            aspectRatio: aspectRatio,
          ),
        );
      }

      if (duplicateFound) {
        AppToast.showError('Duplicate File', 'Some videos were ignored because they are already added.');
      }

      return newMediaList;
    } catch (e) {
      debugPrint('Error picking property videos: $e');
      AppToast.showError('Selection Error', 'Failed to pick videos: $e');
      return [];
    }
  }
}
