// File: lib/core/utils/video_thumbnail_helper.dart
// Purpose: Helper class to extract video frames/thumbnails locally across iOS, Android, and macOS desktop.

import 'dart:io' as io;
import 'package:flutter/foundation.dart';
import 'package:video_thumbnail/video_thumbnail.dart' as vt;

class VideoThumbnailHelper {
  VideoThumbnailHelper._();

  /// Generates a thumbnail image from a video file.
  /// Returns the image bytes or null if generation fails or is unsupported.
  static Future<Uint8List?> generateThumbnail({
    required String filePath,
  }) async {
    if (kIsWeb) return null;

    // 1. Try native video_thumbnail plugin (iOS / Android)
    try {
      final bytes = await vt.VideoThumbnail.thumbnailData(
        video: filePath,
        imageFormat: vt.ImageFormat.JPEG,
        maxWidth: 400,
        quality: 80,
      );
      if (bytes != null && bytes.isNotEmpty) return bytes;
    } catch (e) {
      debugPrint('[VideoThumbnailHelper] vt.VideoThumbnail notice: $e');
    }

    // 2. Fallback for macOS Desktop: use native macOS qlmanage command
    if (!kIsWeb && io.Platform.isMacOS) {
      try {
        final tempDir = io.Directory.systemTemp;
        final result = await io.Process.run('qlmanage', [
          '-t',
          '-s',
          '400',
          '-o',
          tempDir.path,
          filePath,
        ]);

        if (result.exitCode == 0) {
          final fileName = filePath.split(io.Platform.pathSeparator).last;
          final pngFile = io.File('${tempDir.path}/$fileName.png');
          if (await pngFile.exists()) {
            final bytes = await pngFile.readAsBytes();
            try {
              await pngFile.delete();
            } catch (_) {}
            if (bytes.isNotEmpty) return bytes;
          }
        }
      } catch (e) {
        debugPrint('[VideoThumbnailHelper] qlmanage error: $e');
      }
    }

    return null;
  }
}
