// File: lib/core/services/clarity_service.dart
// Purpose: Microsoft Clarity analytics & session replay wrapper service.

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'clarity_stub.dart' if (dart.library.io) 'package:clarity_flutter/clarity_flutter.dart';

class ClarityService {
  ClarityService._();

  static final ClarityService instance = ClarityService._();

  static const String _defaultProjectId = String.fromEnvironment('CLARITY_PROJECT_ID');
  bool _isInitialized = false;

  bool get isInitialized => _isInitialized;

  /// Returns whether Clarity is enabled on the current runtime platform.
  /// Disabled during development/debug mode (`kDebugMode`) to avoid streaming dev sessions.
  bool get isSupportedPlatform {
    if (kIsWeb) return false;
    if (kDebugMode) return false; // Disable during dev/debug runs
    return defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS;
  }

  /// Creates a ClarityConfig instance if a valid Project ID is provided and not in dev mode.
  ClarityConfig? createConfig({
    String? projectId,
    LogLevel logLevel = LogLevel.None,
    bool forceEnableInDebug = false,
  }) {
    if (kDebugMode && !forceEnableInDebug) {
      debugPrint('ClarityService: Disabled in debug/dev mode.');
      return null;
    }
    final id = projectId ?? _defaultProjectId;
    if (id.isEmpty) {
      debugPrint('ClarityService: No Project ID configured. Clarity will be disabled.');
      return null;
    }
    return ClarityConfig(projectId: id, logLevel: logLevel);
  }

  /// Initializes Clarity with a build context (optional fallback if not wrapped via ClarityWidget).
  bool initialize(BuildContext context, {String? projectId}) {
    if (!isSupportedPlatform) return false;
    if (_isInitialized) return true;

    final config = createConfig(projectId: projectId);
    if (config == null) return false;

    try {
      _isInitialized = Clarity.initialize(context, config);
      if (_isInitialized) {
        debugPrint('ClarityService: Initialized successfully with project ID: ${config.projectId}');
      }
      return _isInitialized;
    } catch (e) {
      debugPrint('ClarityService initialization error: $e');
      return false;
    }
  }

  /// Sets a custom user identifier for the Clarity session.
  void setUserId(String userId) {
    if (!isSupportedPlatform || userId.trim().isEmpty) return;
    try {
      Clarity.setCustomUserId(userId.trim());
    } catch (e) {
      debugPrint('ClarityService.setUserId error: $e');
    }
  }

  /// Sets a custom tag for session filtering on the Clarity dashboard.
  void setCustomTag(String key, String value) {
    if (!isSupportedPlatform || key.trim().isEmpty || value.trim().isEmpty) return;
    try {
      Clarity.setCustomTag(key.trim(), value.trim());
    } catch (e) {
      debugPrint('ClarityService.setCustomTag error: $e');
    }
  }

  /// Sends a custom behavioral event to Clarity.
  void sendCustomEvent(String eventName) {
    if (!isSupportedPlatform || eventName.trim().isEmpty) return;
    try {
      Clarity.sendCustomEvent(eventName.trim());
    } catch (e) {
      debugPrint('ClarityService.sendCustomEvent error: $e');
    }
  }

  /// Sets the active screen name for page/screen transition tracking.
  void setCurrentScreenName(String screenName) {
    if (!isSupportedPlatform || screenName.trim().isEmpty) return;
    try {
      Clarity.setCurrentScreenName(screenName.trim());
    } catch (e) {
      debugPrint('ClarityService.setCurrentScreenName error: $e');
    }
  }

  /// Logs an error/exception to Clarity with custom events and tags for crash filtering.
  void logError(dynamic error, {StackTrace? stackTrace, String? reason}) {
    if (!isSupportedPlatform) return;
    try {
      final errorType = error.runtimeType.toString();
      final errorMsg = error.toString();
      sendCustomEvent('error_$errorType');
      setCustomTag('last_error_type', errorType);

      // Limit tag length to safe limit (max 255 chars)
      final safeMsg = errorMsg.length > 200 ? errorMsg.substring(0, 200) : errorMsg;
      setCustomTag('last_error_msg', safeMsg);
      if (reason != null && reason.isNotEmpty) {
        final safeReason = reason.length > 200 ? reason.substring(0, 200) : reason;
        setCustomTag('error_reason', safeReason);
      }
    } catch (e) {
      debugPrint('ClarityService.logError error: $e');
    }
  }

  /// Returns the current session recording URL if available.
  String? getCurrentSessionUrl() {
    if (!isSupportedPlatform) return null;
    try {
      return Clarity.getCurrentSessionUrl();
    } catch (e) {
      debugPrint('ClarityService.getCurrentSessionUrl error: $e');
      return null;
    }
  }
}

/// NavigatorObserver that automatically updates Microsoft Clarity's screen name on route changes.
class ClarityRouteObserver extends NavigatorObserver {
  void _sendScreenName(Route<dynamic>? route) {
    if (route == null) return;
    final name = route.settings.name ?? route.settings.toString();
    if (name.isNotEmpty) {
      ClarityService.instance.setCurrentScreenName(name);
    }
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    _sendScreenName(route);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    _sendScreenName(newRoute);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
    _sendScreenName(previousRoute);
  }
}
