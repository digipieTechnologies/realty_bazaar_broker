// File: lib/core/services/clarity_stub.dart
// Purpose: Web/Stub implementation of Clarity SDK types when building for Web/unsupported platforms.

import 'package:flutter/widgets.dart';

enum LogLevel { None, Error, Info, Debug, Verbose }

class ClarityConfig {
  final String projectId;
  final LogLevel logLevel;
  ClarityConfig({required this.projectId, this.logLevel = LogLevel.None});
}

class Clarity {
  static bool initialize(BuildContext context, ClarityConfig config) => false;
  static void setCustomUserId(String userId) {}
  static void setCustomTag(String key, String value) {}
  static void sendCustomEvent(String eventName) {}
  static void setCurrentScreenName(String screenName) {}
  static String? getCurrentSessionUrl() => null;
}

class ClarityWidget extends StatelessWidget {
  final Widget app;
  final ClarityConfig clarityConfig;
  const ClarityWidget({super.key, required this.app, required this.clarityConfig});

  @override
  Widget build(BuildContext context) => app;
}
