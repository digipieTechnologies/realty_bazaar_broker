import 'dart:async';
import 'package:flutter/material.dart';
import '../../util/app_events.dart';
import '../../models/social_account_model.dart';

class SocialAccountListenerWidget extends StatefulWidget {
  final Widget child;
  final void Function(
    String platform,
    bool isConnected,
    SocialAccountModel? account,
  )? onSocialAccountListener;

  const SocialAccountListenerWidget({
    super.key,
    required this.child,
    this.onSocialAccountListener,
  });

  @override
  State<SocialAccountListenerWidget> createState() =>
      _SocialAccountListenerWidgetState();
}

class _SocialAccountListenerWidgetState
    extends State<SocialAccountListenerWidget> {
  StreamSubscription<OnSocialAccountUpdated>? _subscription;

  @override
  void initState() {
    super.initState();
    _subscription = eventBus.on<OnSocialAccountUpdated>().listen((event) {
      if (widget.onSocialAccountListener != null) {
        widget.onSocialAccountListener!(
          event.platform,
          event.isConnected,
          event.account,
        );
      }
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
