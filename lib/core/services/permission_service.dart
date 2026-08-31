// File: lib/core/services/permission_service.dart
// Purpose: Centralized service for requesting, handling, and checking device runtime permissions across platforms.

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../app/app_strings.dart';
import '../../widgets/dialogs/permission_dialog.dart';

class PermissionService {
  PermissionService._();

  /// Requests storage/photos/videos media permission prior to launching media picker.
  /// 1. First requests the default platform native permission prompt.
  /// 2. Returns `true` if permission is granted or limited.
  /// 3. If the user does NOT allow (denies or permanently denies), shows the custom PermissionDialog.
  static Future<bool> requestMediaPermission(BuildContext context) async {
    // 1. Web and Desktop handle media access natively
    if (kIsWeb ||
        defaultTargetPlatform == TargetPlatform.macOS ||
        defaultTargetPlatform == TargetPlatform.windows ||
        defaultTargetPlatform == TargetPlatform.linux) {
      return true;
    }

    // 2. Select default target permission
    Permission targetPermission = Permission.photos;
    PermissionStatus status = await targetPermission.status;

    // Check if granted or limited initially
    if (status.isGranted || status.isLimited) {
      return true;
    }

    // Step 1: Prompt default platform native permission dialog first
    if (status.isDenied) {
      final newStatus = await targetPermission.request();
      if (newStatus.isGranted || newStatus.isLimited) {
        return true;
      }
      status = newStatus;
    }

    // Fallback check for storage permission on older Android versions (API < 33)
    if (!status.isGranted && !status.isLimited && defaultTargetPlatform == TargetPlatform.android) {
      final storageStatus = await Permission.storage.status;
      if (storageStatus.isGranted) {
        return true;
      }
      if (storageStatus.isDenied) {
        final newStorageStatus = await Permission.storage.request();
        if (newStorageStatus.isGranted) {
          return true;
        }
        status = newStorageStatus;
      }
    }

    // Step 2: If user did NOT allow (denied or permanently denied in platform dialog), show custom PermissionDialog
    if (status.isPermanentlyDenied || status.isDenied) {
      if (!context.mounted) return false;
      await showPermissionExplanationDialog(
        context: context,
        title: 'Photos & Media Permission',
        description:
            '${AppStrings.appName} needs access to your photos and media library to select and upload property images and videos. Please allow access in App Settings.',
        icon: Icons.photo_library_rounded,
        primaryButtonText: 'Open Settings',
        onPrimaryPressed: () async {
          await openAppSettings();
        },
      );
      return false;
    }

    return false;
  }

  /// Requests camera permission for capturing live photos/videos.
  /// 1. First requests the default platform native permission dialog.
  /// 2. Returns `true` if permission is granted.
  /// 3. If the user does NOT allow, shows the custom PermissionDialog.
  static Future<bool> requestCameraPermission(BuildContext context) async {
    if (kIsWeb ||
        defaultTargetPlatform == TargetPlatform.macOS ||
        defaultTargetPlatform == TargetPlatform.windows ||
        defaultTargetPlatform == TargetPlatform.linux) {
      return true;
    }

    PermissionStatus status = await Permission.camera.status;

    if (status.isGranted) return true;

    // Step 1: Prompt default platform native permission dialog first
    if (status.isDenied) {
      final newStatus = await Permission.camera.request();
      if (newStatus.isGranted) return true;
      status = newStatus;
    }

    // Step 2: If user did NOT allow, show custom PermissionDialog
    if (status.isPermanentlyDenied || status.isDenied) {
      if (!context.mounted) return false;
      await showPermissionExplanationDialog(
        context: context,
        title: 'Camera Permission Required',
        description:
            '${AppStrings.appName} needs camera access so you can capture property photos and videos directly in the app. Please allow access in App Settings.',
        icon: Icons.camera_alt_rounded,
        primaryButtonText: 'Open Settings',
        onPrimaryPressed: () async {
          await openAppSettings();
        },
      );
      return false;
    }

    return false;
  }

  /// Requests location permission.
  /// 1. First prompts default platform native OS permission dialog.
  /// 2. Returns `true` if user grants location access.
  /// 3. If user denies or permanently denies in native popup, shows custom PermissionDialog.
  static Future<bool> requestLocationPermission(BuildContext context) async {
    if (kIsWeb ||
        defaultTargetPlatform == TargetPlatform.macOS ||
        defaultTargetPlatform == TargetPlatform.windows ||
        defaultTargetPlatform == TargetPlatform.linux) {
      return true;
    }

    Permission targetPermission = Permission.locationWhenInUse;
    PermissionStatus status = await targetPermission.status;

    if (status.isGranted) return true;

    // Step 1: Prompt default platform native permission popup first
    if (status.isDenied || status.isRestricted) {
      final newStatus = await targetPermission.request();
      if (newStatus.isGranted) return true;
      status = newStatus;
    }

    // Secondary check for general location permission if needed
    if (!status.isGranted) {
      final genStatus = await Permission.location.status;
      if (genStatus.isGranted) return true;
      if (genStatus.isDenied) {
        final newGenStatus = await Permission.location.request();
        if (newGenStatus.isGranted) return true;
        status = newGenStatus;
      }
    }

    // Step 2: If user did NOT allow (denied or permanently denied), show custom PermissionDialog
    if (status.isPermanentlyDenied || status.isDenied) {
      if (!context.mounted) return false;
      await showPermissionExplanationDialog(
        context: context,
        title: 'Location Permission Required',
        description:
            '${AppStrings.appName} needs access to your device location to share your current position. Please allow location access in App Settings.',
        icon: Icons.location_on_rounded,
        primaryButtonText: 'Open Settings',
        onPrimaryPressed: () async {
          await openAppSettings();
        },
      );
      return false;
    }

    return false;
  }

  /// Requests notification permission natively without showing any custom dialog.
  /// Prompts default platform native OS permission popup if status is not granted.
  static Future<bool> requestNotificationPermissionDirectly() async {
    if (kIsWeb ||
        defaultTargetPlatform == TargetPlatform.macOS ||
        defaultTargetPlatform == TargetPlatform.windows ||
        defaultTargetPlatform == TargetPlatform.linux) {
      return true;
    }

    try {
      final status = await Permission.notification.status;
      if (status.isGranted) {
        return true;
      }
      if (status.isDenied || status.isProvisional) {
        final newStatus = await Permission.notification.request();
        return newStatus.isGranted;
      }
    } catch (e) {
      debugPrint('Error requesting notification permission: $e');
    }
    return false;
  }

  /// Shows the reusable permission explanation dialog.
  static Future<bool> showPermissionExplanationDialog({
    required BuildContext context,
    required String title,
    required String description,
    IconData icon = Icons.security_rounded,
    String primaryButtonText = 'Open Settings',
    required VoidCallback onPrimaryPressed,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (dialogCtx) => PermissionDialog(
        title: title,
        description: description,
        icon: icon,
        primaryButtonText: primaryButtonText,
        onPrimaryPressed: onPrimaryPressed,
      ),
    );

    return result ?? false;
  }
}
