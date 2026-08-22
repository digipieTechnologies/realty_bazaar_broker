// File: lib/modules/properties/services/media_export_service.dart
// Purpose: Bakes sticker overlays (title, handle, location, contact) onto images
//          and videos. Uses dart:ui Canvas for images and FFmpeg drawtext for videos.
//          Also generates video thumbnails after export.

import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:ffmpeg_kit_flutter_new_min_gpl/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new_min_gpl/return_code.dart';
import 'package:dio/dio.dart';

import 'package:image/image.dart' as img;

import '../../../app/app_colors.dart';
import '../../../core/utils/video_thumbnail_helper.dart';
import '../../../providers/social/social_provider.dart';

/// Configuration for sticker overlay rendering.
class StickerConfig {
  final String titleText;
  final String handleText;
  final String locationText;
  final String contactText;
  final String theme; // 'classic', 'dark', 'gold', 'minimal', 'white'
  final bool isTransparent; // true → 15-20% opacity badge backgrounds
  final bool enableOverlay;

  const StickerConfig({
    required this.titleText,
    required this.handleText,
    required this.locationText,
    required this.contactText,
    this.theme = 'classic',
    this.isTransparent = false,
    this.enableOverlay = true,
  });
}

class MediaExportService {
  MediaExportService._();

  /// Exports all selected media with sticker overlays baked in.
  /// Returns a new list of [PickedMedia] with processed bytes.
  static Future<List<PickedMedia>> exportAll({
    required List<PickedMedia> mediaList,
    required StickerConfig config,
    void Function(double)? onProgress,
  }) async {
    if (!config.enableOverlay) {
      // If overlay is disabled, return copies with original bytes.
      return List<PickedMedia>.from(mediaList);
    }

    final List<PickedMedia> exported = [];

    for (int i = 0; i < mediaList.length; i++) {
      final media = mediaList[i];
      final baseProgress = i / mediaList.length;
      final nextProgress = (i + 1) / mediaList.length;
      final progressStep = 1.0 / mediaList.length;

      onProgress?.call(baseProgress);

      final pathLower = media.path.toLowerCase();
      final isImgExt = pathLower.endsWith('.jpg') ||
          pathLower.endsWith('.jpeg') ||
          pathLower.endsWith('.png') ||
          pathLower.endsWith('.webp') ||
          pathLower.endsWith('.gif');
      final isVideo = !isImgExt &&
          (media.type.toLowerCase() == 'video' ||
              pathLower.endsWith('.mp4') ||
              pathLower.endsWith('.mov'));

      // Start a timer to simulate progress for this item during heavy export tasks
      double currentItemProgress = 0.0;
      final timer = Timer.periodic(const Duration(milliseconds: 200), (t) {
        currentItemProgress += 0.05;
        if (currentItemProgress > 0.92) {
          currentItemProgress = 0.92;
        }
        onProgress?.call(baseProgress + currentItemProgress * progressStep);
      });

      PickedMedia result;
      try {
        if (isVideo) {
          result = await _exportVideo(media, config, i);
        } else {
          result = await _exportImage(media, config);
        }
      } finally {
        timer.cancel();
      }

      exported.add(result);
      onProgress?.call(nextProgress);
    }

    return exported;
  }

  // ── Image Export (dart:ui Canvas) ─────────────────────────────────────────

  static Future<PickedMedia> _exportImage(
    PickedMedia media,
    StickerConfig config,
  ) async {
    try {
      // 1. Decode the source image
      Uint8List sourceBytes = media.bytes;
      if (sourceBytes.isEmpty && media.path.startsWith('http')) {
        // Download network image using dio (cross-platform compatible)
        final response = await Dio().get<List<int>>(
          media.path,
          options: Options(responseType: ResponseType.bytes),
        );
        if (response.data != null) {
          sourceBytes = Uint8List.fromList(response.data!);
        }
      }

      if (sourceBytes.isEmpty) {
        return media; // Can't process without bytes
      }

      final codec = await ui.instantiateImageCodec(sourceBytes);
      final frame = await codec.getNextFrame();
      final sourceImage = frame.image;

      final imgW = sourceImage.width.toDouble();
      final imgH = sourceImage.height.toDouble();

      // Centered 9:16 portrait crop calculation
      double targetW = imgW;
      double targetH = imgH;
      if (imgW / imgH > 9.0 / 16.0) {
        // Wider than 9:16, crop sides
        targetW = imgH * (9.0 / 16.0);
      } else {
        // Taller than 9:16, crop top/bottom
        targetH = imgW * (16.0 / 9.0);
      }

      final double srcX = (imgW - targetW) / 2.0;
      final double srcY = (imgH - targetH) / 2.0;

      final srcRect = Rect.fromLTWH(srcX, srcY, targetW, targetH);
      final destRect = Rect.fromLTWH(0, 0, targetW, targetH);

      // 2. Create canvas of the target cropped dimensions
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder, destRect);

      // Draw the cropped portion of original image
      canvas.drawImageRect(sourceImage, srcRect, destRect, Paint());

      // 3. Draw sticker overlays
      _drawStickersOnCanvas(canvas, targetW, targetH, config);

      // 4. Export to image bytes
      final picture = recorder.endRecording();
      final outputImage = await picture.toImage(targetW.toInt(), targetH.toInt());
      final byteData =
          await outputImage.toByteData(format: ui.ImageByteFormat.png);

      sourceImage.dispose();
      outputImage.dispose();

      if (byteData == null) return media;

      final pngBytes = byteData.buffer.asUint8List();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      Uint8List finalJpgBytes = pngBytes;

      try {
        final decodedImage = img.decodePng(pngBytes);
        if (decodedImage != null) {
          finalJpgBytes = Uint8List.fromList(img.encodeJpg(decodedImage, quality: 92));
        }
      } catch (e) {
        debugPrint('[MediaExportService] JPEG encoding fallback: $e');
      }

      return PickedMedia(
        path: media.path,
        name: 'exported_image_$timestamp.jpg',
        bytes: finalJpgBytes,
        type: 'image',
        thumbnailBytes: media.thumbnailBytes,
        thumbnailName: media.thumbnailName,
      );
    } catch (e) {
      debugPrint('[MediaExportService] Image export failed: $e');
      return media; // Return original on failure
    }
  }

  static void _drawStickersOnCanvas(
    Canvas canvas,
    double imgW,
    double imgH,
    StickerConfig config,
  ) {
    final double scaleFactor = imgW / 360.0; // Scale relative to 360px preview
    final double hPad = 14.0 * scaleFactor;
    final double vPad = 16.0 * scaleFactor;

    // Top gradient
    final topGradientPaint = Paint()
      ..shader = ui.Gradient.linear(
        Offset(0, 0),
        Offset(0, 90 * scaleFactor),
        [Colors.black.withValues(alpha: 0.5), Colors.transparent],
      );
    canvas.drawRect(
      Rect.fromLTWH(0, 0, imgW, 90 * scaleFactor),
      topGradientPaint,
    );

    // Bottom gradient
    final bottomGradientPaint = Paint()
      ..shader = ui.Gradient.linear(
        Offset(0, imgH - 120 * scaleFactor),
        Offset(0, imgH),
        [Colors.transparent, Colors.black.withValues(alpha: 0.6)],
      );
    canvas.drawRect(
      Rect.fromLTWH(0, imgH - 120 * scaleFactor, imgW, 120 * scaleFactor),
      bottomGradientPaint,
    );

    double topY = vPad + 16 * scaleFactor;

    // Title Badge
    if (config.titleText.trim().isNotEmpty) {
      topY = _drawBadge(
        canvas,
        config.titleText.trim(),
        imgW,
        topY,
        hPad,
        scaleFactor,
        bgColor: _getTitleBg(config),
        textColor: _getTitleTextColor(config),
        fontSize: 10.0,
        fontWeight: FontWeight.w900,
        paddingH: 12.0,
        paddingV: 8.0,
        borderRadius: 10.0,
        centered: true,
      );
      topY += 6 * scaleFactor;
    }

    // Handle Badge
    if (config.handleText.trim().isNotEmpty) {
      topY = _drawBadge(
        canvas,
        config.handleText.trim(),
        imgW,
        topY,
        hPad,
        scaleFactor,
        bgColor: _getHandleBg(config),
        textColor: _getHandleTextColor(config),
        fontSize: 9.0,
        fontWeight: FontWeight.bold,
        paddingH: 10.0,
        paddingV: 4.0,
        borderRadius: 6.0,
        centered: true,
      );
    }

    // Bottom stickers
    double bottomY = imgH - vPad - 12 * scaleFactor;

    // Contact Badge (bottom-most)
    if (config.contactText.trim().isNotEmpty) {
      bottomY = _drawBadgeFromBottom(
        canvas,
        config.contactText.trim(),
        imgW,
        bottomY,
        hPad,
        scaleFactor,
        bgColor: _getContactBg(config),
        textColor: _getContactTextColor(config),
        fontSize: 9.0,
        fontWeight: FontWeight.bold,
        paddingH: 12.0,
        paddingV: 6.0,
        borderRadius: 8.0,
        centered: true,
      );
      bottomY -= 5 * scaleFactor;
    }

    // Location Badge
    if (config.locationText.trim().isNotEmpty) {
      _drawBadgeFromBottom(
        canvas,
        '📍 ${config.locationText.trim()}',
        imgW,
        bottomY,
        hPad,
        scaleFactor,
        bgColor: _getLocationBg(config),
        textColor: _getLocationTextColor(config),
        fontSize: 9.5,
        fontWeight: FontWeight.bold,
        paddingH: 10.0,
        paddingV: 5.0,
        borderRadius: 6.0,
        centered: true,
      );
    }
  }

  /// Draws a badge at a given Y position (top-down). Returns the new Y after the badge.
  static double _drawBadge(
    Canvas canvas,
    String text,
    double imgW,
    double y,
    double hPad,
    double scale, {
    required Color bgColor,
    required Color textColor,
    required double fontSize,
    required FontWeight fontWeight,
    required double paddingH,
    required double paddingV,
    required double borderRadius,
    bool centered = true,
  }) {
    final textSpan = TextSpan(
      text: text,
      style: TextStyle(
        color: textColor,
        fontSize: fontSize * scale,
        fontWeight: fontWeight,
        letterSpacing: 0.3,
        height: 1.25,
      ),
    );
    final tp = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
      maxLines: 3,
    )..layout(maxWidth: imgW - hPad * 2 - paddingH * scale * 2);

    final badgeW = tp.width + paddingH * scale * 2;
    final badgeH = tp.height + paddingV * scale * 2;
    final badgeX = centered ? (imgW - badgeW) / 2 : hPad;

    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(badgeX, y, badgeW, badgeH),
      Radius.circular(borderRadius * scale),
    );

    // Background
    canvas.drawRRect(rrect, Paint()..color = bgColor);

    // Text
    tp.paint(canvas, Offset(badgeX + paddingH * scale, y + paddingV * scale));

    return y + badgeH;
  }

  /// Draws a badge from the bottom up. Returns the new Y (top of the badge).
  static double _drawBadgeFromBottom(
    Canvas canvas,
    String text,
    double imgW,
    double bottomY,
    double hPad,
    double scale, {
    required Color bgColor,
    required Color textColor,
    required double fontSize,
    required FontWeight fontWeight,
    required double paddingH,
    required double paddingV,
    required double borderRadius,
    bool centered = true,
  }) {
    final textSpan = TextSpan(
      text: text,
      style: TextStyle(
        color: textColor,
        fontSize: fontSize * scale,
        fontWeight: fontWeight,
        letterSpacing: 0.4,
        height: 1.2,
      ),
    );
    final tp = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
      maxLines: 3,
    )..layout(maxWidth: imgW - hPad * 2 - paddingH * scale * 2);

    final badgeW = tp.width + paddingH * scale * 2;
    final badgeH = tp.height + paddingV * scale * 2;
    final badgeX = centered ? (imgW - badgeW) / 2 : hPad;
    final badgeY = bottomY - badgeH;

    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(badgeX, badgeY, badgeW, badgeH),
      Radius.circular(borderRadius * scale),
    );

    canvas.drawRRect(rrect, Paint()..color = bgColor);
    tp.paint(
        canvas, Offset(badgeX + paddingH * scale, badgeY + paddingV * scale));

    return badgeY;
  }

  // ── Video Export (FFmpeg drawtext) ────────────────────────────────────────

  static Future<PickedMedia> _exportVideo(
    PickedMedia media,
    StickerConfig config,
    int index,
  ) async {
    if (kIsWeb) {
      // FFmpeg not available on web
      return media;
    }

    try {
      final tempDir = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;

      // Resolve input path
      String inputPath = media.path;
      if (media.path.startsWith('http')) {
        final response = await Dio().get<List<int>>(
          media.path,
          options: Options(responseType: ResponseType.bytes),
        );
        final bytes = response.data != null ? Uint8List.fromList(response.data!) : Uint8List(0);

        inputPath = '${tempDir.path}/input_${timestamp}_$index.mp4';
        await File(inputPath).writeAsBytes(bytes);
      } else if (media.bytes.isNotEmpty) {
        inputPath = '${tempDir.path}/input_${timestamp}_$index.mp4';
        await File(inputPath).writeAsBytes(media.bytes);
      }

      const int finalW = 1080;
      const int finalH = 1920;

      // Draw stickers overlay canvas matching target dimensions (1080x1920)
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder, const Rect.fromLTWH(0, 0, 1080, 1920));
      _drawStickersOnCanvas(canvas, finalW.toDouble(), finalH.toDouble(), config);

      final picture = recorder.endRecording();
      final overlayImg = await picture.toImage(finalW, finalH);
      final byteData = await overlayImg.toByteData(format: ui.ImageByteFormat.png);
      overlayImg.dispose();

      if (byteData == null) return media;

      final overlayPath = '${tempDir.path}/overlay_${timestamp}_$index.png';
      await File(overlayPath).writeAsBytes(byteData.buffer.asUint8List());

      final outputPath = '${tempDir.path}/exported_${timestamp}_$index.mp4';

      // Combine crop and image overlay in one filter graph.
      // We crop the video to 9:16 first, scale to 1080x1920 (Full HD), then overlay the sticker PNG on top.
      final command =
          '-i "$inputPath" -i "$overlayPath" -filter_complex '
          '"[0:v]crop=w=\'min(iw,ih*9/16)\':h=\'min(ih,iw*16/9)\',scale=1080:1920[cropped];'
          '[cropped][1:v]overlay=0:0[outv]" '
          '-map "[outv]" -map 0:a? -c:v libx264 -preset ultrafast -pix_fmt yuv420p -c:a copy -y "$outputPath"';

      debugPrint('[MediaExportService] FFmpeg command: $command');

      final session = await FFmpegKit.execute(command);
      final returnCode = await session.getReturnCode();

      // Clean up temporary overlay file
      try {
        await File(overlayPath).delete();
      } catch (_) {}

      if (ReturnCode.isSuccess(returnCode)) {
        final outputFile = File(outputPath);
        final exportedBytes = await outputFile.readAsBytes();

        // Generate thumbnail
        Uint8List? thumbBytes;
        if (!kIsWeb) {
          thumbBytes = await VideoThumbnailHelper.generateThumbnail(
            filePath: outputPath,
          );
          
          thumbBytes ??= await _extractThumbnailWithFFmpeg(
            outputPath,
            tempDir,
            index,
          );
        }

        return PickedMedia(
          path: outputPath,
          name: 'exported_video_${index + 1}.mp4',
          bytes: exportedBytes,
          type: 'video',
          thumbnailBytes: thumbBytes,
          thumbnailName: 'thumb_video_${index + 1}.jpg',
        );
      } else {
        final logs = await session.getAllLogsAsString();
        debugPrint('[MediaExportService] FFmpeg failed: $logs');
        return media; // Return original on failure
      }
    } catch (e) {
      debugPrint('[MediaExportService] Video export failed: $e');
      return media;
    }
  }

  static Future<Uint8List?> _extractThumbnailWithFFmpeg(
    String videoPath,
    Directory tempDir,
    int index,
  ) async {
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final thumbPath = '${tempDir.path}/thumb_${timestamp}_$index.jpg';
      final command = '-ss 00:00:00.000 -i "$videoPath" -vframes 1 -q:v 2 -y "$thumbPath"';
      
      debugPrint('[MediaExportService] Extracting thumbnail with FFmpeg: $command');
      final session = await FFmpegKit.execute(command);
      final returnCode = await session.getReturnCode();
      
      if (ReturnCode.isSuccess(returnCode)) {
        final file = File(thumbPath);
        if (await file.exists()) {
          final bytes = await file.readAsBytes();
          try {
            await file.delete();
          } catch (_) {}
          return bytes;
        }
      } else {
        final logs = await session.getAllLogsAsString();
        debugPrint('[MediaExportService] FFmpeg thumbnail extraction failed: $logs');
      }
    } catch (e) {
      debugPrint('[MediaExportService] Error extracting thumbnail with FFmpeg: $e');
    }
    return null;
  }

  // ── Theme Color Helpers ──────────────────────────────────────────────────

  static Color _getTitleBg(StickerConfig config) {
    final alpha = config.isTransparent ? 0.25 : 1.0;
    Color base;
    switch (config.theme) {
      case 'black':
        base = Colors.black;
        break;
      case 'gold':
        base = AppColors.posterGoldLight;
        break;
      case 'minimal':
        base = AppColors.posterNeutralLight;
        break;
      case 'white':
        base = Colors.white;
        break;
      case 'classic':
      default:
        base = Colors.white;
        break;
    }
    return base.withValues(alpha: alpha);
  }

  static Color _getTitleTextColor(StickerConfig config) {
    switch (config.theme) {
      case 'black':
        return Colors.white;
      case 'gold':
        return AppColors.statusWarningDarkText;
      case 'minimal':
        return AppColors.posterNeutralDark;
      case 'white':
        return Colors.black;
      case 'classic':
      default:
        return Colors.black;
    }
  }

  static Color _getHandleBg(StickerConfig config) {
    final alpha = config.isTransparent ? 0.25 : 1.0;
    Color base;
    switch (config.theme) {
      case 'black':
        base = Colors.black;
        break;
      case 'gold':
        base = AppColors.posterGold;
        break;
      case 'minimal':
        base = AppColors.posterIndigoSoft;
        break;
      case 'white':
        base = Colors.white;
        break;
      case 'classic':
      default:
        base = AppColors.posterBlueSoft;
        break;
    }
    return base.withValues(alpha: alpha);
  }

  static Color _getHandleTextColor(StickerConfig config) {
    switch (config.theme) {
      case 'white':
        return Colors.black;
      case 'black':
        return Colors.white;
      default:
        return Colors.white;
    }
  }

  static Color _getLocationBg(StickerConfig config) {
    final alpha = config.isTransparent ? 0.25 : 1.0;
    Color base;
    switch (config.theme) {
      case 'black':
        base = Colors.black;
        break;
      case 'gold':
        base = AppColors.posterGoldDark;
        break;
      case 'minimal':
        base = AppColors.posterIndigoSoft;
        break;
      case 'white':
        base = Colors.white;
        break;
      case 'classic':
      default:
        base = AppColors.posterBurgundy;
        break;
    }
    return base.withValues(alpha: alpha);
  }

  static Color _getLocationTextColor(StickerConfig config) {
    switch (config.theme) {
      case 'white':
        return Colors.black;
      case 'black':
        return Colors.white;
      default:
        return Colors.white;
    }
  }

  static Color _getContactBg(StickerConfig config) {
    final alpha = config.isTransparent ? 0.25 : 1.0;
    Color base;
    switch (config.theme) {
      case 'black':
        base = Colors.black;
        break;
      case 'gold':
        base = AppColors.posterGoldBrown;
        break;
      case 'minimal':
        base = AppColors.tagIndigo;
        break;
      case 'white':
        base = Colors.white;
        break;
      case 'classic':
      default:
        base = AppColors.posterRoseRed;
        break;
    }
    return base.withValues(alpha: alpha);
  }

  static Color _getContactTextColor(StickerConfig config) {
    switch (config.theme) {
      case 'white':
        return Colors.black;
      case 'black':
        return Colors.white;
      default:
        return Colors.white;
    }
  }
}
