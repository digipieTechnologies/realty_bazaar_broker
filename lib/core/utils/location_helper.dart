// File: lib/core/utils/location_helper.dart
// Purpose: Centralized helper utility for location permission checks and fetching current GPS coordinates with zero hardcoded defaults.

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../services/permission_service.dart';
import '../../widgets/toast/app_toast.dart';

class LocationHelper {
  LocationHelper._();

  /// Requests location permission (displaying explanation dialog if denied)
  /// and returns the device's live GPS coordinates as [Position?].
  /// Returns `null` by default if permission is not granted or position cannot be retrieved.
  static Future<Position?> getCurrentLocation(BuildContext context) async {
    // 1. Check & request location permission
    final hasPermission = await PermissionService.requestLocationPermission(context);
    if (!hasPermission) return null;

    // 2. Fetch live device GPS coordinates
    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 8),
        ),
      );
      return position;
    } catch (e) {
      try {
        final lastKnown = await Geolocator.getLastKnownPosition();
        if (lastKnown != null) return lastKnown;
      } catch (_) {}
    }

    if (context.mounted) {
      AppToast.showError(
        'Location Error',
        'Could not fetch your current GPS location. Please ensure location services are enabled.',
      );
    }
    return null;
  }
}
