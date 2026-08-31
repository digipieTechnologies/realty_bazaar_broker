// File: lib/widgets/images/cached_image.dart
// Purpose: Unified, robust image caching widget handling network URLs, local image files, asset images, memory bytes, and video file fallbacks cleanly without raw decoding exceptions.

import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../app/app_assets.dart';
import '../../app/app_colors.dart';

class CachedImage extends StatelessWidget {
  final String? imageUrl;
  final Uint8List? imageBytes;
  final double? height;
  final double? width;
  final double borderWidth;
  final BoxFit fit;
  final String? placeholder;
  final Color? borderColor;
  final Color? backgroundColor;
  final BorderRadius borderRadius;
  final Widget? errorWidget;

  const CachedImage(
    this.imageUrl, {
    super.key,
    this.height,
    this.width,
    this.fit = BoxFit.cover,
    this.placeholder,
    this.imageBytes,
    this.borderRadius = BorderRadius.zero,
    this.borderColor,
    this.backgroundColor,
    this.borderWidth = 1.0,
    this.errorWidget,
  });

  bool _isVideoFile(String path) {
    final lower = path.toLowerCase();
    return lower.endsWith('.mp4') ||
        lower.endsWith('.mov') ||
        lower.endsWith('.avi') ||
        lower.endsWith('.mkv') ||
        lower.endsWith('.webm');
  }

  @override
  Widget build(BuildContext context) {
    final Widget defaultFallback =
        errorWidget ??
        Container(
          height: height,
          width: width,
          decoration: BoxDecoration(color: backgroundColor ?? Colors.transparent, borderRadius: borderRadius),
          child: Center(
            child: Image.asset(
              placeholder ?? AppAssets.logoTransparent,
              height: height,
              width: width,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) =>
                  const Icon(Icons.image_not_supported_outlined, color: AppColors.textMuted, size: 28.0),
            ),
          ),
        );

    final Widget content = Builder(
      builder: (context) {
        // 1. Image Bytes (Memory)
        if (imageBytes != null && imageBytes!.isNotEmpty) {
          return Image.memory(
            imageBytes!,
            fit: fit,
            height: height,
            width: width,
            errorBuilder: (context, error, stackTrace) => defaultFallback,
          );
        }

        final url = imageUrl?.trim() ?? '';
        if (url.isEmpty) return defaultFallback;

        // 2. Asset Image
        if (url.startsWith('assets/')) {
          return Image.asset(
            url,
            fit: fit,
            height: height,
            width: width,
            errorBuilder: (context, error, stackTrace) => defaultFallback,
          );
        }

        // 3. Network Image
        if (url.startsWith('http://') || url.startsWith('https://')) {
          return CachedNetworkImage(
            imageUrl: url,
            cacheKey: url,
            fit: fit,
            height: height,
            width: width,
            fadeInDuration: const Duration(milliseconds: 150),
            placeholder: (context, url) => defaultFallback,
            errorWidget: (context, url, error) => defaultFallback,
          );
        }

        // 4. Video file path guard (never pass raw MP4 files to Image.file)
        if (_isVideoFile(url)) {
          return Container(
            height: height,
            width: width,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.grey.shade900, Colors.black87],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: const Center(child: Icon(Icons.videocam_rounded, color: Colors.white70, size: 30.0)),
          );
        }

        // 5. Local File Image
        try {
          final file = File(url);
          return Image.file(
            file,
            fit: fit,
            height: height,
            width: width,
            errorBuilder: (context, error, stackTrace) => defaultFallback,
          );
        } catch (e) {
          return defaultFallback;
        }
      },
    );

    return Container(
      height: height,
      width: width,
      decoration: BoxDecoration(
        border: borderColor != null ? Border.all(color: borderColor!, width: borderWidth) : null,
        borderRadius: borderRadius,
      ),
      child: ClipRRect(borderRadius: borderRadius, child: content),
    );
  }
}
