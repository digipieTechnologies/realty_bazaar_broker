// File: lib/widgets/icons/call_icon_widget.dart
// Purpose: Modular reusable Call image icon widget.

import 'package:flutter/material.dart';

class CallIconWidget extends StatelessWidget {
  final double size;

  const CallIconWidget({
    super.key,
    this.size = 20.0,
  });

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/icons/call.png',
      width: size,
      height: size,
      fit: BoxFit.contain,
    );
  }
}
