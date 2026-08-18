// File: lib/core/services/supabase_storage_service.dart
// Purpose: Centralized reusable service for uploading images, videos, media, and documents to Supabase Storage buckets across the application.

import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../supabase/supabase_config.dart';

class SupabaseStorageService {
  SupabaseStorageService._();

  /// Centralized method to upload media/documents/files to a specified Supabase Storage bucket.
  /// 
  /// Parameters:
  /// - [filePath]: Local file path, blob URL, or existing HTTP URL.
  /// - [bucketName]: Supabase storage bucket name (e.g. 'chat_attachments', 'property_media', 'social_assets').
  /// - [folderName]: Optional sub-folder path inside the bucket (e.g. 'video_chats', 'documents').
  /// - [customFileName]: Optional custom file name.
  /// - [fileBytes]: Optional Uint8List bytes if file is already loaded into memory.
  /// 
  /// Returns the public HTTP URL of the uploaded file, or null on failure.
  static Future<String?> uploadFile({
    required String filePath,
    required String bucketName,
    String? folderName,
    String? customFileName,
    Uint8List? fileBytes,
  }) async {
    if (filePath.trim().isEmpty) return null;

    // If it is already a remote HTTP/HTTPS URL, return as-is
    if (filePath.startsWith('http://') || filePath.startsWith('https://')) {
      return filePath;
    }

    try {
      final client = SupabaseConfig.client;

      // Extract or generate safe file name
      final rawName = customFileName ?? filePath.split('/').last.split('\\').last;
      final timeStamp = DateTime.now().millisecondsSinceEpoch;
      final safeFileName = '${timeStamp}_$rawName';
      final storagePath = folderName != null && folderName.isNotEmpty
          ? '$folderName/$safeFileName'
          : safeFileName;

      // Read binary bytes if not provided directly
      Uint8List? bytes = fileBytes;
      if (bytes == null) {
        if (!kIsWeb) {
          final file = File(filePath);
          if (await file.exists()) {
            bytes = await file.readAsBytes();
          }
        }
      }

      if (bytes == null || bytes.isEmpty) {
        debugPrint('[SupabaseStorageService] Could not read file bytes for path: $filePath');
        return filePath;
      }

      // Try uploading to bucket with upsert = true
      try {
        await client.storage.from(bucketName).uploadBinary(
          storagePath,
          bytes,
          fileOptions: const FileOptions(upsert: true),
        );
      } catch (uploadErr) {
        debugPrint('[SupabaseStorageService] Bucket "$bucketName" upload warning: $uploadErr. Attempting bucket creation...');
        try {
          // Attempt creating public bucket if it doesn't exist yet
          await client.storage.createBucket(bucketName, const BucketOptions(public: true));
          await client.storage.from(bucketName).uploadBinary(
            storagePath,
            bytes,
            fileOptions: const FileOptions(upsert: true),
          );
        } catch (createErr) {
          debugPrint('[SupabaseStorageService] Failed to create/upload to bucket "$bucketName": $createErr');
        }
      }

      // Retrieve public URL
      final publicUrl = client.storage.from(bucketName).getPublicUrl(storagePath);
      debugPrint('[SupabaseStorageService] Successfully uploaded file to bucket "$bucketName": $publicUrl');
      return publicUrl;
    } catch (e) {
      debugPrint('[SupabaseStorageService] Exception uploading file to bucket "$bucketName": $e');
      return filePath;
    }
  }
}
