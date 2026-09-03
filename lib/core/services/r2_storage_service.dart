// File: lib/core/services/r2_storage_service.dart
// Purpose: Centralized reusable service for uploading images, videos, media, and documents to Cloudflare R2 via r2-upload Edge Function.

import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../supabase/supabase_config.dart';

class R2StorageService {
  R2StorageService._();

  static const String _functionName = 'r2-upload';

  /// Uploads a file (or raw bytes) to Cloudflare R2 via the `r2-upload` Edge Function presigned URL.
  /// Returns the public Cloudflare R2 URL on success, or null on failure.
  static Future<String?> uploadFile({
    required String filePath,
    String entityType = 'general',
    String? entityId,
    String? customFileName,
    Uint8List? fileBytes,
    bool skipDbInsert = true,
  }) async {
    if (filePath.trim().isEmpty && (fileBytes == null || fileBytes.isEmpty)) return null;

    if (filePath.startsWith('http://') || filePath.startsWith('https://')) {
      return filePath;
    }

    try {
      final client = SupabaseConfig.client;

      final rawName =
          customFileName ?? (filePath.isNotEmpty ? filePath.split('/').last.split('\\').last : 'file');
      final ext = rawName.contains('.') ? rawName.split('.').last.toLowerCase() : 'jpg';
      final mimeType = _getContentType(ext);

      int fileSize = 0;
      File? nativeFile;
      Uint8List? bytes = fileBytes;

      if (bytes != null) {
        fileSize = bytes.length;
      } else if (!kIsWeb && filePath.isNotEmpty) {
        final file = File(filePath);
        if (await file.exists()) {
          nativeFile = file;
          fileSize = await file.length();
        }
      }

      if (fileSize <= 0 && bytes == null && nativeFile == null) {
        debugPrint('[R2StorageService] File is empty or not found: $filePath');
        return filePath;
      }

      final safeEntityId = (entityId == null || entityId.isEmpty) ? 'general' : entityId;

      // 1. Get presigned upload URL from r2-upload Edge Function
      final presignResult = await client.functions.invoke(
        _functionName,
        queryParameters: {'action': 'presign'},
        body: {
          'entityType': entityType,
          'entityId': safeEntityId,
          'fileName': rawName,
          'mimeType': mimeType,
          'fileSize': fileSize,
          'skipDbInsert': skipDbInsert,
        },
      );

      if (presignResult.status != 200 || presignResult.data == null) {
        final err = presignResult.data is Map ? presignResult.data['error'] : presignResult.data;
        throw Exception('Failed to get presigned URL from r2-upload: $err');
      }

      final presignedUrl = presignResult.data['presignedUrl'] as String?;
      final publicUrl = presignResult.data['publicUrl'] as String?;

      if (presignedUrl == null || publicUrl == null) {
        throw Exception('Invalid response received from r2-upload function');
      }

      // 2. Direct PUT upload to Cloudflare R2
      if (nativeFile != null && !kIsWeb) {
        // Stream native file directly to presigned URL (prevents Out of Memory on large videos)
        final request = http.StreamedRequest('PUT', Uri.parse(presignedUrl));
        request.headers['Content-Type'] = mimeType;
        request.headers['Content-Length'] = fileSize.toString();

        final fileStream = nativeFile.openRead();
        fileStream.listen(
          request.sink.add,
          onDone: () => request.sink.close(),
          onError: (err) => request.sink.addError(err),
          cancelOnError: true,
        );

        final streamedResponse = await request.send();
        final putResponse = await http.Response.fromStream(streamedResponse);

        if (putResponse.statusCode != 200 && putResponse.statusCode != 204) {
          throw Exception(
            'Cloudflare R2 direct PUT upload failed (${putResponse.statusCode}): ${putResponse.body}',
          );
        }
      } else {
        if (bytes == null || bytes.isEmpty) {
          throw Exception('File bytes are empty for $filePath');
        }
        final putResponse = await http.put(
          Uri.parse(presignedUrl),
          headers: {'Content-Type': mimeType, 'Content-Length': bytes.length.toString()},
          body: bytes,
        );

        if (putResponse.statusCode != 200 && putResponse.statusCode != 204) {
          throw Exception(
            'Cloudflare R2 direct PUT upload failed (${putResponse.statusCode}): ${putResponse.body}',
          );
        }
      }

      debugPrint('[R2StorageService] Successfully uploaded to R2: $publicUrl');
      return publicUrl;
    } catch (e) {
      debugPrint('[R2StorageService] Upload failed for $filePath: $e');
      rethrow;
    }
  }

  static String _getContentType(String ext) {
    switch (ext.toLowerCase()) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'webp':
        return 'image/webp';
      case 'heic':
        return 'image/heic';
      case 'gif':
        return 'image/gif';
      case 'mp4':
        return 'video/mp4';
      case 'mov':
        return 'video/quicktime';
      case 'avi':
        return 'video/x-msvideo';
      case 'mkv':
        return 'video/x-matroska';
      case 'webm':
        return 'video/webm';
      case 'pdf':
        return 'application/pdf';
      default:
        return 'application/octet-stream';
    }
  }
}
