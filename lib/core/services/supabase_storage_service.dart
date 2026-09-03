// File: lib/core/services/supabase_storage_service.dart
// Purpose: Backward compatibility wrapper redirecting all storage uploads to Cloudflare R2 via R2StorageService.

import 'dart:typed_data';

import 'r2_storage_service.dart';

class SupabaseStorageService {
  SupabaseStorageService._();

  /// Centralized method that routes all storage uploads to Cloudflare R2 via [R2StorageService].
  static Future<String?> uploadFile({
    required String filePath,
    String? bucketName,
    String? folderName,
    String? customFileName,
    Uint8List? fileBytes,
  }) async {
    final entityType = folderName ?? (bucketName != null ? bucketName.replaceAll('_', '') : 'general');
    return await R2StorageService.uploadFile(
      filePath: filePath,
      entityType: entityType,
      customFileName: customFileName,
      fileBytes: fileBytes,
    );
  }
}
