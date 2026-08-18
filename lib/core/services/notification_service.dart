// File: lib/core/services/notification_service.dart
// Purpose: Cross-platform Push Notification service for OneSignal using pure String.fromEnvironment with tap routing.

import 'package:flutter/foundation.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import '../../app/app_routes.dart';
import '../../models/notification_enums.dart';

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  bool _isInitialized = false;

  /// Initializes OneSignal SDK using ONE_SIGNAL_APP_ID passed via --dart-define-from-file=config.json.
  Future<void> initialize() async {
    if (defaultTargetPlatform != TargetPlatform.android) {
      debugPrint('OneSignal is only enabled for Android. Skipping initialization on this platform.');
      return;
    }

    if (_isInitialized) return;

    try {
      const String oneSignalAppId = String.fromEnvironment('ONE_SIGNAL_APP_ID');

      if (oneSignalAppId.isNotEmpty) {
        OneSignal.Debug.setLogLevel(OSLogLevel.verbose);
        OneSignal.initialize(oneSignalAppId);
        OneSignal.Notifications.requestPermission(true);

        OneSignal.Notifications.addClickListener((event) {
          final data = event.notification.additionalData;
          if (data != null) {
            _handleNotificationClick(Map<String, dynamic>.from(data));
          }
        });

        _isInitialized = true;
        debugPrint('OneSignal NotificationService initialized successfully with App ID: $oneSignalAppId');
      } else {
        debugPrint('ONE_SIGNAL_APP_ID missing from String.fromEnvironment. Make sure to build/run with --dart-define-from-file=config.json');
      }
    } catch (e) {
      debugPrint('Error initializing OneSignal NotificationService: $e');
    }
  }

  /// Binds logged in user's Supabase UUID to OneSignal's external_id.
  Future<void> bindUserToOneSignal(String userId) async {
    if (defaultTargetPlatform != TargetPlatform.android) {
      return;
    }

    try {
      if (!_isInitialized) {
        await initialize();
      }
      if (_isInitialized) {
        await OneSignal.login(userId);
        debugPrint('OneSignal user logged in with ID: $userId');
      }
    } catch (e) {
      debugPrint('Error logging user into OneSignal: $e');
    }
  }

  /// Unbinds user from OneSignal on logout.
  Future<void> unbindUserFromOneSignal() async {
    if (defaultTargetPlatform != TargetPlatform.android) {
      return;
    }

    try {
      if (_isInitialized) {
        await OneSignal.logout();
        debugPrint('OneSignal user logged out.');
      }
    } catch (e) {
      debugPrint('Error logging out from OneSignal: $e');
    }
  }

  /// Routes user according to NotificationType payload data.
  void _handleNotificationClick(Map<String, dynamic> data) {
    try {
      final rawType = data['notification_type']?.toString() ?? data['type']?.toString();
      final notificationType = NotificationType.fromDbValue(rawType);

      debugPrint('Routing notification type: $notificationType with data: $data');

      switch (notificationType) {
        case NotificationType.videoRequest:
        case NotificationType.lead:
          AppRoutes.router.push(AppRoutes.home);
          break;
      }
    } catch (e) {
      debugPrint('Error routing notification click: $e');
    }
  }
}
